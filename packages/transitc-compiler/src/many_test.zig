const std = @import("std");
const c = @import("root.zig");
const p = @import("transit_protocol");

const source =
    \\CREATE DOMAIN ItemId AS BIGINT IDENTITY 'example.item';
    \\CREATE DOMAIN OtherId AS BIGINT IDENTITY 'example.other';
    \\CREATE FUNCTION identity(entry ROW(id ItemId, note TEXT)) RETURNS ItemId AS BEGIN RETURN entry.id; END;
    \\CREATE GUARD valid(entry ROW(id ItemId, note TEXT)) EFFECTS() AS BEGIN REQUIRE identity(entry) = entry.id ELSE 'BadId'; END;
    \\CREATE MODULE Setup(element TYPE) AS BEGIN
    \\  CREATE PUBLIC TABLE items (id $element PRIMARY KEY, note TEXT);
    \\  CREATE PUBLIC TABLE output (id $element PRIMARY KEY, note TEXT);
    \\  CREATE PUBLIC QUEUE jobs (id BIGINT NOT NULL);
    \\  CREATE PUBLIC DATAFLOW route FROM QUEUE jobs AS request AS BEGIN
    \\    BEGIN ATOMIC
    \\      LET selected MANY(3) = SELECT id, note FROM items ORDER BY id;
    \\      LET alias = selected;
    \\      FOR item IN alias DO
    \\        CHECK GUARD valid(item);
    \\        INSERT INTO output VALUES (identity(item), item.note) ON CONFLICT (id) DO ASSERT SAME ROW;
    \\      END FOR;
    \\    END;
    \\  END;
    \\END;
    \\CREATE TARGET default AS BEGIN USE Setup(TYPE ItemId); END;
;
fn compile(allocator: std.mem.Allocator, text: []const u8) !*c.Product {
    var diagnostic: ?p.Diagnostic = null;
    return c.compile(allocator, &.{.{ .path = "build.transit", .text = text }}, .{ .compiler_revision = "many-test" }, &diagnostic);
}
test "MANY retains nominal rows through aliases, nested helpers and a present iterator" {
    const product = try compile(std.testing.allocator, source);
    defer product.deinit();
    const program = product.steps[3].checked.program.?;
    var collections: usize = 0;
    var iterators: usize = 0;
    for (program.nodes) |node| {
        if (node.cardinality == .many) {
            collections += 1;
            try std.testing.expectEqual(.rows, node.type.kind);
            try std.testing.expectEqual(@as(u8, 3), node.type.bound);
            try std.testing.expectEqualStrings("id", node.type.order.?);
            try std.testing.expectEqualStrings("example.item", node.type.fields[0].value.domain.?);
            try std.testing.expect(node.type.fields[1].value.nullable);
        }
        if (std.mem.eql(u8, node.kind, "iterator")) {
            iterators += 1;
            try std.testing.expectEqual(.record, node.type.kind);
            try std.testing.expectEqual(.one, node.cardinality.?);
            try std.testing.expect(!node.type.nullable);
            try std.testing.expectEqualStrings("example.item", node.type.fields[0].value.domain.?);
        }
    }
    try std.testing.expect(collections >= 2);
    try std.testing.expectEqual(@as(usize, 1), iterators);
    try std.testing.expect(std.mem.indexOf(u8, product.steps[3].sql, "ExpectedOneRow") == null);
}
test "MANY rejects foreign nominal rows, collection escapes and iterator scope capture" {
    const t = std.testing;
    inline for (.{
        .{ "USE Setup(TYPE ItemId)", "USE Setup(TYPE OtherId)", error.SourceDomainMismatch },
        .{ "CHECK GUARD valid(item);", "CHECK GUARD valid(alias);", error.ProgramTypeMismatch },
        .{ "LET alias = selected;", "LET alias = selected; LET scalar = selected IS NULL;", error.ProgramTypeMismatch },
        .{ "END FOR;", "END FOR; LET escaped = item.id;", error.UnknownProgramVariable },
        .{ "MANY(3)", "MANY(0)", error.InvalidProgramCollection },
        .{ "MANY(3)", "MANY(65)", error.InvalidProgramCollection },
        .{ "ORDER BY id", "ORDER BY note", error.InvalidProgramCollection },
        .{ "CHECK GUARD valid(item);", "LET other = SELECT id FROM items;", error.UnsupportedProgramIteration },
        .{ "CHECK GUARD valid(item);", "FOR nested IN alias DO REQUIRE TRUE ELSE 'No'; END FOR;", error.UnsupportedProgramIteration },
    }) |entry| {
        const changed = try std.mem.replaceOwned(u8, t.allocator, source, entry[0], entry[1]);
        defer t.allocator.free(changed);
        try t.expectError(entry[2], compile(t.allocator, changed));
    }
}
fn allocations(allocator: std.mem.Allocator) !void {
    const product = try compile(allocator, source);
    defer product.deinit();
}
test "MANY lowering and iterator annotations release every partial allocation" {
    try std.testing.checkAllAllocationFailures(std.testing.allocator, allocations, .{});
}
test "MANY admits a ROW callable and rejects a callable's hidden read" {
    const t = std.testing;
    const parameterized = try std.mem.replaceOwned(u8, t.allocator, source, "Setup(element TYPE)", "Setup(element TYPE, check GUARD OF valid)");
    defer t.allocator.free(parameterized);
    const called = try std.mem.replaceOwned(u8, t.allocator, parameterized, "CHECK GUARD valid(item)", "CHECK GUARD check(item)");
    defer t.allocator.free(called);
    const applied = try std.mem.replaceOwned(u8, t.allocator, called, "USE Setup(TYPE ItemId)", "USE Setup(TYPE ItemId, valid)");
    defer t.allocator.free(applied);
    const product = try compile(t.allocator, applied);
    defer product.deinit();
    try t.expectError(error.UnsupportedProgramIteration, compile(t.allocator,
        \\CREATE GUARD Exists(t TABLE(id BIGINT PRIMARY KEY), key BIGINT) EFFECTS(READ t) AS BEGIN
        \\  LET found ONE = SELECT id FROM t WHERE id = key;
        \\  REQUIRE found IS NOT NULL ELSE 'Missing';
        \\END;
        \\CREATE MODULE Run(check GUARD OF Exists) AS BEGIN
        \\  CREATE PUBLIC TABLE items(id BIGINT PRIMARY KEY);
        \\  CREATE PUBLIC QUEUE jobs(id BIGINT NOT NULL);
        \\  CREATE PUBLIC DATAFLOW route FROM QUEUE jobs AS request AS BEGIN BEGIN ATOMIC
        \\    LET batch MANY(3) = SELECT id FROM items ORDER BY id;
        \\    FOR item IN batch DO CHECK GUARD check(items, item.id); END FOR;
        \\  END; END;
        \\END;
        \\CREATE TARGET default AS BEGIN USE Run(Exists); END;
    ));
}
