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
test "ordinary scalar refusals retain input diagnostics instead of internal failures" {
    const cases = .{
        .{ "amount NUMERIC(5,2)", "1000.00", error.Overflow },
        .{ "amount NUMERIC(5,2)", "1.001", error.Inexact },
        .{ "payload JSON", "JSON '{\"a\":1,\"a\":2}'", error.DuplicateField },
        .{ "span INTERVAL", "INTERVAL(2147483648,0,0)", error.Overflow },
    };
    inline for (cases) |case| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "CREATE TARGET default AS BEGIN CREATE PUBLIC TABLE t (id BIGINT PRIMARY KEY, {s}); INSERT INTO t VALUES (1, {s}); END;", .{ case[0], case[1] });
        defer std.testing.allocator.free(text);
        var diagnostic: ?p.Diagnostic = null;
        try std.testing.expectError(case[2], c.compile(std.testing.allocator, &.{.{ .path = "build.transit", .text = text }}, .{ .compiler_revision = "test" }, &diagnostic));
        try std.testing.expectEqualStrings("application.source.type", diagnostic.?.code.slice());
        try std.testing.expectEqual(.not_submitted, diagnostic.?.outcome);
        try std.testing.expect(diagnostic.?.location != null);
    }
}

const numeric =
    \\CREATE DOMAIN Amount AS NUMERIC(38,9) IDENTITY 'example.amount';
    \\CREATE DOMAIN OtherAmount AS NUMERIC(38,9) IDENTITY 'example.other-amount';
    \\CREATE VARIANT Selection AS (On(value Amount), Off(value Amount));
    \\CREATE MODULE Put(value Amount, ty TYPE) AS BEGIN
    \\  CREATE PUBLIC TABLE amounts (id BIGINT PRIMARY KEY, amount $ty NOT NULL);
    \\  INSERT INTO amounts VALUES (1, $value);
    \\END;
    \\CREATE MODULE Choose(value Selection) AS BEGIN
    \\  MATCH value
    \\    WHEN Selection.On(selected) THEN USE Put(selected, TYPE Amount);
    \\    WHEN Selection.Off(selected) THEN USE Put(selected, TYPE Amount);
    \\  END MATCH;
    \\END;
    \\CREATE TARGET default AS BEGIN
    \\  IF NUMERIC(38,9) '9007199254740993.123456789' > NUMERIC(38,9) '9007199254740993.123456788' THEN
    \\    USE Choose(Selection.On(Amount(NUMERIC(38,9) '9007199254740993.123456789')));
    \\  END IF;
    \\END;
;
test "NUMERIC source preserves exact coefficients and nominal descriptor through symbolic arms" {
    const product = try compile(std.testing.allocator, numeric);
    defer product.deinit();
    try std.testing.expectEqual(2, product.steps.len);
    try std.testing.expect(std.mem.indexOf(u8, product.sql, "9007199254740993.123456789") != null);
    try std.testing.expectEqualStrings("example.amount", product.steps[1].checked.operands[0].domain.?);
    const spellings = .{
        .{ "NUMERIC(1,0)", "-9", "-9" },
        .{ "NUMERIC(38,38)", "0.00000000000000000000000000000000000001", "0.00000000000000000000000000000000000001" },
        .{ "NUMERIC(5,2)", "-0", "0.00" },
        .{ "NUMERIC(5,2)", "12.3", "12.30" },
        .{ "NUMERIC(38,9)", "-99999999999999999999999999999.999999999", "-99999999999999999999999999999.999999999" },
    };
    inline for (spellings) |case| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "CREATE MODULE Put(value {s}, ty TYPE) AS BEGIN CREATE PUBLIC TABLE t (id BIGINT PRIMARY KEY, n $ty); INSERT INTO t VALUES (1, $value); END; CREATE TARGET default AS BEGIN USE Put({s} '{s}', TYPE {s}); END;", .{ case[0], case[0], case[1], case[0] });
        defer std.testing.allocator.free(text);
        const result = try compile(std.testing.allocator, text);
        defer result.deinit();
        try std.testing.expect(std.mem.indexOf(u8, result.steps[1].sql, case[2]) != null);
    }
}
test "NUMERIC rejects overflow rounding descriptor conversion foreign domains arithmetic and program values" {
    const cases = .{
        .{ "Amount(NUMERIC(38,9) '9007199254740993.123456789')", "OtherAmount(NUMERIC(38,9) '9007199254740993.123456789')", error.SourceTypeMismatch },
        .{ "Amount(NUMERIC(38,9) '9007199254740993.123456789')", "Amount(NUMERIC(38,8) '1')", error.SourceTypeMismatch },
        .{ "Amount(NUMERIC(38,9) '9007199254740993.123456789')", "Amount(1)", error.SourceTypeMismatch },
        .{ "Amount(NUMERIC(38,9) '9007199254740993.123456789')", "Amount(NUMERIC(38,9) '0.0000000001')", error.Inexact },
        .{ "Amount(NUMERIC(38,9) '9007199254740993.123456789')", "Amount(NUMERIC(38,9) '100000000000000000000000000000')", error.Overflow },
        .{ "NUMERIC(38,9)", "NUMERIC(0,0)", error.InvalidDecimal },
        .{ "NUMERIC(38,9)", "NUMERIC(39,9)", error.InvalidDecimal },
        .{ "NUMERIC(38,9)", "NUMERIC(2,3)", error.InvalidDecimal },
        .{ "NUMERIC(38,9) '9007199254740993.123456789' >", "NUMERIC(38,9) '1' + NUMERIC(38,9) '2' >", error.SourceTypeMismatch },
    };
    inline for (cases) |case| {
        const text = try std.mem.replaceOwned(u8, std.testing.allocator, numeric, case[0], case[1]);
        defer std.testing.allocator.free(text);
        try std.testing.expectError(case[2], compile(std.testing.allocator, text));
    }
    try std.testing.expectError(error.ProgramTypeMismatch, compile(std.testing.allocator, "CREATE FUNCTION Identity(n NUMERIC(5,2)) RETURNS NUMERIC(5,2) AS BEGIN RETURN n; END; CREATE TARGET default AS BEGIN CREATE PUBLIC TABLE t (id BIGINT PRIMARY KEY); END;"));
    try std.testing.expectError(error.ModuleInterfaceMismatch, compile(std.testing.allocator, "CREATE INTERFACE I(n NUMERIC(5,2)); CREATE MODULE Put(n NUMERIC(6,2)) AS BEGIN END; CREATE MODULE UseIt(m MODULE I) AS BEGIN END; CREATE TARGET default AS BEGIN USE UseIt(Put); END;"));
}
fn numericAllocations(allocator: std.mem.Allocator) !void {
    const product = try compile(allocator, numeric);
    defer product.deinit();
}
test "NUMERIC allocation failures never return a partial product" {
    try std.testing.checkAllAllocationFailures(std.testing.allocator, numericAllocations, .{});
}
