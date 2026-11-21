const std = @import("std");
const c = @import("root.zig");
const p = @import("transit_protocol");

fn compile(allocator: std.mem.Allocator, text: []const u8) !*c.Product {
    var diagnostic: ?p.Diagnostic = null;
    return c.compile(allocator, &.{.{ .path = "build.transit", .text = text }}, .{ .compiler_revision = "refinement-test" }, &diagnostic);
}
const source =
    \\CREATE PROCEDURE Bounded(events STREAM(id BIGINT NOT NULL, amount BIGINT NOT NULL), id BIGINT, amount BIGINT, returned BIGINT) RETURNS BIGINT
    \\REQUIRES amount IS NOT NULL ELSE 'MissingAmount'
    \\REQUIRES amount >= 1 AND amount <= 10 ELSE 'AmountBounds'
    \\ENSURES result = amount ELSE 'ChangedAmount'
    \\AS BEGIN ATOMIC
    \\  PRODUCE INTO events VALUES (id, amount);
    \\  RETURN returned;
    \\END;
    \\CREATE TARGET default AS BEGIN
    \\  CREATE PUBLIC STREAM events (id BIGINT NOT NULL, amount BIGINT NOT NULL);
    \\  CREATE PUBLIC STREAM after_call (id BIGINT NOT NULL, amount BIGINT NOT NULL);
    \\  CREATE PUBLIC QUEUE requests (id BIGINT NOT NULL, amount BIGINT, returned BIGINT);
    \\  CREATE PUBLIC DATAFLOW route FROM QUEUE requests AS request AS BEGIN
    \\    BEGIN ATOMIC
    \\      LET answer = CALL Bounded(events, request.id, request.amount + 1, request.returned);
    \\      PRODUCE INTO after_call VALUES (request.id, answer);
    \\    END;
    \\  END;
    \\END;
;
test "bounded helper obligations validate after one argument evaluation and before dependent effects" {
    const product = try compile(std.testing.allocator, source);
    defer product.deinit();
    const sql = product.steps[3].sql;
    try std.testing.expectEqual(1, std.mem.count(u8, sql, "+ 1"));
    try std.testing.expect(std.mem.indexOf(u8, sql, "'AmountBounds'").? < std.mem.indexOf(u8, sql, "PRODUCE").?);
    try std.testing.expect(std.mem.indexOf(u8, sql, "'ChangedAmount'").? > std.mem.indexOf(u8, sql, "PRODUCE").?);
    const expected = [_][]const u8{ "acquire", "atomic_begin", "let", "let", "let", "require", "require", "append", "let", "require", "let", "append", "atomic_end" };
    const events = product.steps[3].checked.program.?.events;
    try std.testing.expectEqual(expected.len, events.len);
    for (expected, events) |kind, event| try std.testing.expectEqualStrings(kind, @tagName(event.kind));
}
test "refinement clauses reject unknown names foreign domains nonconstant bounds and pure expression effects" {
    const cases = .{
        .{ "amount >= 1", "unknown >= 1", error.InvalidRefinementBinding },
        .{ "amount >= 1", "amount >= returned", error.UnsupportedRefinementPredicate },
        .{ "amount >= 1", "result >= 1", error.InvalidRefinementBinding },
        .{ "amount >= 1 AND", "amount >= 1 OR", error.InvalidSourceSyntax },
        .{ "ENSURES result = amount", "ENSURES result = events", error.InvalidRefinementBinding },
    };
    inline for (cases) |case| {
        const text = try std.mem.replaceOwned(u8, std.testing.allocator, source, case[0], case[1]);
        defer std.testing.allocator.free(text);
        try std.testing.expectError(case[2], compile(std.testing.allocator, text));
    }
    try std.testing.expectError(error.UnsupportedRefinementContract, compile(std.testing.allocator, "CREATE FUNCTION Pure(n BIGINT) RETURNS BIGINT REQUIRES n >= 0 ELSE 'No' AS BEGIN RETURN n; END; CREATE TARGET default AS BEGIN CREATE PUBLIC TABLE t (id BIGINT PRIMARY KEY); END;"));
    try std.testing.expectError(error.SourceDomainMismatch, compile(std.testing.allocator, "CREATE DOMAIN A AS BIGINT IDENTITY 'a'; CREATE DOMAIN B AS BIGINT IDENTITY 'b'; CREATE GUARD G(a A,b B) REQUIRES a = b ELSE 'Different' AS REQUIRE TRUE ELSE 'No'; CREATE TARGET default AS BEGIN CREATE PUBLIC TABLE t (id BIGINT PRIMARY KEY); END;"));
    try std.testing.expectError(error.UnsupportedRefinementPredicate, compile(std.testing.allocator, "CREATE DOMAIN A AS BIGINT IDENTITY 'a'; CREATE GUARD G(a A) REQUIRES a >= 1 ELSE 'No' AS REQUIRE TRUE ELSE 'No'; CREATE TARGET default AS BEGIN CREATE PUBLIC TABLE t (id BIGINT PRIMARY KEY); END;"));
}
test "same-domain equality obligations preserve nominal values" {
    const product = try compile(std.testing.allocator, "CREATE DOMAIN A AS BIGINT IDENTITY 'a'; CREATE GUARD G(a A,b A) REQUIRES a = b ELSE 'Different' AS REQUIRE TRUE ELSE 'No'; CREATE TARGET default AS BEGIN CREATE PUBLIC TABLE t (id BIGINT PRIMARY KEY); END;");
    defer product.deinit();
}
fn allocations(allocator: std.mem.Allocator) !void {
    const product = try compile(allocator, source);
    defer product.deinit();
}
test "refinement allocation failures do not return partial products" {
    try std.testing.checkAllAllocationFailures(std.testing.allocator, allocations, .{});
}
