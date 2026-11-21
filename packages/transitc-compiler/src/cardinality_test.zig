const std = @import("std");
const c = @import("root.zig");
const p = @import("transit_protocol");

fn compile(allocator: std.mem.Allocator, text: []const u8) !*c.Product {
    var diagnostic: ?p.Diagnostic = null;
    return c.compile(allocator, &.{.{ .path = "build.transit", .text = text }}, .{ .compiler_revision = "cardinality-test" }, &diagnostic);
}
const source =
    \\CREATE DOMAIN ItemId AS BIGINT IDENTITY 'example.item';
    \\CREATE MODULE Setup(element TYPE) AS BEGIN
    \\  CREATE PUBLIC TABLE items (id $element PRIMARY KEY, note TEXT);
    \\  CREATE PUBLIC TABLE found_items (id $element PRIMARY KEY, note TEXT);
    \\  CREATE PUBLIC QUEUE jobs (id $element NOT NULL);
    \\  CREATE PUBLIC DATAFLOW route FROM QUEUE jobs AS request AS BEGIN
    \\    BEGIN ATOMIC
    \\      LET found ONE = SELECT id, note FROM items WHERE id = request.id;
    \\      INSERT INTO found_items VALUES (found.id, found.note) ON CONFLICT (id) DO ASSERT SAME ROW;
    \\    END;
    \\  END;
    \\END;
    \\CREATE TARGET default AS BEGIN USE Setup(TYPE ItemId); END;
;
test "ONE result validation precedes effects and retains nominal fields and nullable cells" {
    const product = try compile(std.testing.allocator, source);
    defer product.deinit();
    const program = product.steps[3].checked.program.?;
    const events = program.events;
    const expected = [_][]const u8{ "acquire", "atomic_begin", "read", "require", "let", "insert", "atomic_end" };
    try std.testing.expectEqual(expected.len, events.len);
    for (expected, events) |kind, event| try std.testing.expectEqualStrings(kind, @tagName(event.kind));
    var narrowed = false;
    for (program.nodes) |node| if (node.cardinality == .one) {
        narrowed = true;
        try std.testing.expectEqualStrings("example.item", node.type.fields[0].value.domain.?);
        try std.testing.expect(node.type.fields[1].value.nullable);
    };
    try std.testing.expect(narrowed);
    try std.testing.expect(std.mem.indexOf(u8, product.steps[3].sql, "'ExpectedOneRow'") != null);
}
test "OPTIONAL preserves row absence without asserting a nullable field" {
    const text = try std.mem.replaceOwned(u8, std.testing.allocator, source, "found ONE", "found OPTIONAL");
    try std.testing.expectError(error.OptionalRowRequiresPresence, compile(std.testing.allocator, text));
    defer std.testing.allocator.free(text);
    const guarded = try std.mem.replaceOwned(u8, std.testing.allocator, text, "INSERT INTO found_items", "REQUIRE found IS NOT NULL ELSE 'Absent'; INSERT INTO found_items");
    defer std.testing.allocator.free(guarded);
    const product = try compile(std.testing.allocator, guarded);
    defer product.deinit();
    try std.testing.expect(std.mem.indexOf(u8, product.steps[3].sql, "ExpectedOneRow") == null);
}
test "result cardinality is restricted to SELECT and does not admit many-row materialization" {
    inline for (.{ "LET found ONE = 7;", "LET found OPTIONAL = request;", "LET found MANY = SELECT id FROM items;" }) |statement| {
        const text = try std.mem.replaceOwned(u8, std.testing.allocator, source, "LET found ONE = SELECT id, note FROM items WHERE id = request.id;", statement);
        defer std.testing.allocator.free(text);
        try std.testing.expectError(error.InvalidSourceTemplate, compile(std.testing.allocator, text));
    }
}
fn allocations(allocator: std.mem.Allocator) !void {
    const product = try compile(allocator, source);
    defer product.deinit();
}
test "result cardinality checking respects allocation failure boundaries" {
    try std.testing.checkAllAllocationFailures(std.testing.allocator, allocations, .{});
}

test "optional presence refinement is branch-local and CASE cannot erase absence" {
    var arena: std.heap.ArenaAllocator = .init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const text = try std.mem.replaceOwned(u8, a, source, "found ONE", "found OPTIONAL");
    const write = "INSERT INTO found_items VALUES (found.id, found.note) ON CONFLICT (id) DO ASSERT SAME ROW;";
    const checked = try std.mem.replaceOwned(u8, a, text, write, "IF found IS NULL THEN REQUIRE TRUE ELSE 'Ignored'; ELSE " ++ write ++ " END IF;");
    const product = try compile(std.testing.allocator, checked);
    defer product.deinit();
    inline for (.{
        "IF found IS NOT NULL THEN " ++ write ++ " ELSE " ++ write ++ " END IF;",
        "IF found IS NOT NULL THEN " ++ write ++ " END IF; " ++ write,
        "REQUIRE found.note IS NOT NULL ELSE 'WrongPresenceTest'; " ++ write,
        "REQUIRE found IS NOT NULL ELSE 'Absent'; LET maybe = CASE WHEN TRUE THEN found ELSE NULL END; INSERT INTO found_items VALUES (maybe.id, maybe.note) ON CONFLICT (id) DO ASSERT SAME ROW;",
    }) |replacement| {
        const bad = try std.mem.replaceOwned(u8, a, text, write, replacement);
        try std.testing.expectError(error.OptionalRowRequiresPresence, compile(std.testing.allocator, bad));
    }
}
