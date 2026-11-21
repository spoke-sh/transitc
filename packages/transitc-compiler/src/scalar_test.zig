const std = @import("std");
const c = @import("root.zig");
const p = @import("transit_protocol");

fn compile(allocator: std.mem.Allocator, text: []const u8) !*c.Product {
    var diagnostic: ?p.Diagnostic = null;
    return c.compile(allocator, &.{.{ .path = "build.transit", .text = text }}, .{ .compiler_revision = "scalar-test" }, &diagnostic);
}
const dates =
    \\CREATE DOMAIN Day AS DATE IDENTITY 'example.day';
    \\CREATE DOMAIN OtherDay AS DATE IDENTITY 'example.other-day';
    \\CREATE VARIANT Selection AS (On(day Day), Off(day Day));
    \\CREATE MODULE Put(value Day, ty TYPE) AS BEGIN
    \\  CREATE PUBLIC TABLE days (day $ty PRIMARY KEY);
    \\  INSERT INTO days VALUES ($value);
    \\  SELECT * FROM days WHERE day = $value;
    \\END;
    \\CREATE MODULE Choose(value Selection) AS BEGIN
    \\  MATCH value
    \\    WHEN Selection.On(selected) THEN USE Put(selected, TYPE Day);
    \\    WHEN Selection.Off(selected) THEN USE Put(selected, TYPE Day);
    \\  END MATCH;
    \\END;
    \\CREATE TARGET default AS BEGIN
    \\  IF DATE '2024-02-29' < DATE '2024-03-01' THEN
    \\    USE Choose(Selection.On(Day(DATE '2024-02-29')));
    \\  END IF;
    \\END;
;
test "DATE source literals domains and symbolic operands bind exact date SQL" {
    const product = try compile(std.testing.allocator, dates);
    defer product.deinit();
    try std.testing.expectEqual(3, product.steps.len);
    try std.testing.expect(std.mem.indexOf(u8, product.sql, "DATE '2024-02-29'") != null);
    try std.testing.expectEqualStrings("example.day", product.steps[1].checked.operands[0].domain.?);
    const same = try compile(std.testing.allocator, "CREATE TARGET default AS BEGIN IF DATE '1970-01-01' = DATE '1970-01-01' THEN CREATE PUBLIC TABLE days (d DATE); END IF; END;");
    defer same.deinit();
    try std.testing.expectEqual(1, same.steps.len);
}
test "DATE refuses invalid dates implicit timestamps foreign domains and program values" {
    const cases = .{
        .{ "Day(DATE '2024-02-29')", "Day(DATE '2023-02-29')", error.InvalidSourceOperand },
        .{ "Day(DATE '2024-02-29')", "Day(TIMESTAMP '2024-02-29T00:00:00Z')", error.SourceTypeMismatch },
        .{ "Day(DATE '2024-02-29')", "OtherDay(DATE '2024-02-29')", error.SourceTypeMismatch },
        .{ "DATE '2024-02-29' < DATE '2024-03-01'", "DATE '2024-02-29' + DATE '2024-03-01' = DATE '2024-03-01'", error.SourceTypeMismatch },
    };
    inline for (cases) |case| {
        const text = try std.mem.replaceOwned(u8, std.testing.allocator, dates, case[0], case[1]);
        defer std.testing.allocator.free(text);
        try std.testing.expectError(case[2], compile(std.testing.allocator, text));
    }
    try std.testing.expectError(error.ProgramTypeMismatch, compile(std.testing.allocator, "CREATE TARGET default AS BEGIN CREATE PUBLIC QUEUE work (day DATE NOT NULL); CREATE PUBLIC DATAFLOW route FROM QUEUE work AS request AS BEGIN REQUIRE TRUE ELSE 'No'; END; END;"));
    try std.testing.expectError(error.ProgramTypeMismatch, compile(std.testing.allocator, "CREATE FUNCTION Identity(day DATE) RETURNS DATE AS BEGIN RETURN day; END; CREATE TARGET default AS BEGIN CREATE PUBLIC TABLE days (d DATE); END;"));
}
fn allocations(allocator: std.mem.Allocator) !void {
    const product = try compile(allocator, dates);
    defer product.deinit();
}
test "DATE allocation failures never return a partial product" {
    try std.testing.checkAllAllocationFailures(std.testing.allocator, allocations, .{});
}
