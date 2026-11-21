const std = @import("std");
const c = @import("root.zig");
const p = @import("transit_protocol");
fn compile(allocator: std.mem.Allocator, text: []const u8) !*c.Product {
    var diagnostic: ?p.Diagnostic = null;
    return c.compile(allocator, &.{.{ .path = "build.transit", .text = text }}, .{ .compiler_revision = "lossless-test" }, &diagnostic);
}
const source =
    \\CREATE DOMAIN Payload AS JSON IDENTITY 'example.payload';
    \\CREATE DOMAIN Span AS INTERVAL IDENTITY 'example.span';
    \\CREATE VARIANT Choice AS (First(payload Payload, span Span), Second(payload Payload, span Span));
    \\CREATE MODULE Put(payload Payload, span Span, jt TYPE, it TYPE) AS BEGIN
    \\  CREATE PUBLIC TABLE values_table (id BIGINT PRIMARY KEY, payload $jt NOT NULL, span $it NOT NULL);
    \\  INSERT INTO values_table VALUES (1, $payload, $span);
    \\END;
    \\CREATE MODULE Select(choice Choice) AS BEGIN
    \\  MATCH choice
    \\    WHEN Choice.First(selected, elapsed) THEN USE Put(selected, elapsed, TYPE Payload, TYPE Span);
    \\    WHEN Choice.Second(selected, elapsed) THEN USE Put(selected, elapsed, TYPE Payload, TYPE Span);
    \\  END MATCH;
    \\END;
    \\CREATE TARGET default AS BEGIN
    \\  USE Put(Payload(JSON '{"wide":9007199254740993,"fraction":0.123456789012345678901234567890123456789,"quote":"it''s exact","value":null}'), Span(INTERVAL(-2147483648, 2147483647, -9223372036854775808)), TYPE Payload, TYPE Span);
    \\END;
;
test "JSON and INTERVAL source domains preserve exact values and typed binding" {
    const result = try compile(std.testing.allocator, source);
    defer result.deinit();
    try std.testing.expectEqual(2, result.steps.len);
    try std.testing.expect(std.mem.indexOf(u8, result.sql, "9007199254740993") != null);
    try std.testing.expect(std.mem.indexOf(u8, result.sql, "0.123456789012345678901234567890123456789") != null);
    try std.testing.expect(std.mem.indexOf(u8, result.sql, "it''s exact") != null);
    try std.testing.expect(std.mem.indexOf(u8, result.sql, "-9223372036854775808") != null);
    try std.testing.expectEqualStrings("example.payload", result.steps[1].checked.operands[0].domain.?);
    try std.testing.expectEqualStrings("example.span", result.steps[1].checked.operands[1].domain.?);
}
test "JSON rejects malformed data duplicates budgets and invented comparison traits" {
    const cases = .{
        .{ "JSON '{\"a\":1,\"a\":2}'", error.DuplicateField },
        .{ "JSON '{\"a\":1,\"\\u0061\":2}'", error.DuplicateField },
        .{ "JSON '{\"a\":}'", error.InvalidJson },
        .{ "JSON '[[[[[[[[[[[[[[[[[0]]]]]]]]]]]]]]]]]'", error.JsonDepthExceeded },
        .{ "'null'", error.SourceTypeMismatch },
    };
    inline for (cases) |case| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "CREATE MODULE Put(value JSON) AS BEGIN CREATE PUBLIC TABLE t(id BIGINT PRIMARY KEY,p JSON); INSERT INTO t VALUES(1,$value); END; CREATE TARGET default AS BEGIN USE Put({s}); END;", .{case[0]});
        defer std.testing.allocator.free(text);
        try std.testing.expectError(case[1], compile(std.testing.allocator, text));
    }
    inline for (.{ "JSON 'null' = JSON 'null'", "JSON '1' < JSON '2'", "INTERVAL(0,1,0) = INTERVAL(0,1,0)", "INTERVAL(1,0,0) > INTERVAL(0,30,0)", "Payload(JSON 'null') = Payload(JSON 'null')", "Span(INTERVAL(0,1,0)) = Span(INTERVAL(0,1,0))" }) |condition| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "CREATE DOMAIN Payload AS JSON IDENTITY 'p'; CREATE DOMAIN Span AS INTERVAL IDENTITY 's'; CREATE TARGET default AS BEGIN IF {s} THEN CREATE PUBLIC TABLE t(id BIGINT); END IF; END;", .{condition});
        defer std.testing.allocator.free(text);
        try std.testing.expectError(error.SourceTypeMismatch, compile(std.testing.allocator, text));
    }
    try std.testing.expectError(error.UnsupportedRefinementPredicate, compile(std.testing.allocator, "CREATE GUARD G(a JSON,b JSON) REQUIRES a = b ELSE 'No' AS REQUIRE TRUE ELSE 'No'; CREATE TARGET default AS BEGIN CREATE PUBLIC TABLE t(id BIGINT); END;"));
}
test "INTERVAL component bounds refuse overflow and implicit duration conversion" {
    inline for (.{ "INTERVAL(2147483648,0,0)", "INTERVAL(-2147483649,0,0)", "INTERVAL(0,2147483648,0)", "INTERVAL(0,0,9223372036854775808)", "INTERVAL(0,0,-9223372036854775809)" }) |literal| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "CREATE MODULE Put(value INTERVAL) AS BEGIN CREATE PUBLIC TABLE t(span INTERVAL); INSERT INTO t VALUES($value); END; CREATE TARGET default AS BEGIN USE Put({s}); END;", .{literal});
        defer std.testing.allocator.free(text);
        try std.testing.expectError(error.Overflow, compile(std.testing.allocator, text));
    }
    try std.testing.expectError(error.SourceTypeMismatch, compile(std.testing.allocator, "CREATE MODULE Put(value INTERVAL) AS BEGIN END; CREATE TARGET default AS BEGIN USE Put(1000000); END;"));
    try std.testing.expectError(error.ProgramTypeMismatch, compile(std.testing.allocator, "CREATE FUNCTION F(value INTERVAL) RETURNS INTERVAL AS BEGIN RETURN value; END; CREATE TARGET default AS BEGIN CREATE PUBLIC TABLE t(id BIGINT); END;"));
}
test "JSON helpers preserve typed arguments results and NULL without equality" {
    const result = try compile(std.testing.allocator,
        \\CREATE FUNCTION Identity(value JSON, unused BIGINT) RETURNS JSON AS BEGIN RETURN value; END;
        \\CREATE PROCEDURE Save(events STREAM(payload JSON), value JSON) RETURNS JSON EFFECTS(PRODUCE events)
        \\REQUIRES value IS NOT NULL ELSE 'SqlNull'
        \\AS BEGIN ATOMIC PRODUCE INTO events VALUES(value); RETURN value; END;
        \\CREATE TARGET default AS BEGIN
        \\  CREATE PUBLIC STREAM events(payload JSON);
        \\  CREATE PUBLIC QUEUE jobs(payload JSON);
        \\  CREATE PUBLIC DATAFLOW route FROM QUEUE jobs AS request AS BEGIN
        \\    BEGIN ATOMIC LET saved = CALL Save(events,Identity(request.payload, 1)); END;
        \\  END;
        \\END;
    );
    defer result.deinit();
    try std.testing.expectEqual(3, result.steps.len);
}
fn allocations(allocator: std.mem.Allocator) !void {
    const result = try compile(allocator, source);
    defer result.deinit();
}
test "lossless source scalar allocation failures cannot publish partial products" {
    try std.testing.checkAllAllocationFailures(std.testing.allocator, allocations, .{});
}

test "JSON and INTERVAL symbolic Table parameters retain the native refusal" {
    const text = try std.mem.replaceOwned(u8, std.testing.allocator, source, "USE Put(Payload(JSON", "USE Select(Choice.First(Payload(JSON");
    defer std.testing.allocator.free(text);
    const complete = try std.mem.replaceOwned(u8, std.testing.allocator, text, ")), TYPE Payload, TYPE Span);", "))));");
    defer std.testing.allocator.free(complete);
    try std.testing.expectError(error.UnsupportedComparison, compile(std.testing.allocator, complete));
}

test "JSON source literals do not bypass the native program grammar" {
    try std.testing.expectError(error.ProgramTypeMismatch, compile(std.testing.allocator,
        \\CREATE MODULE Run(data JSON) AS BEGIN
        \\  CREATE PUBLIC QUEUE work(id BIGINT NOT NULL);
        \\  CREATE PUBLIC DATAFLOW route FROM QUEUE work AS request AS BEGIN LET payload = $data; END;
        \\END;
        \\CREATE TARGET default AS BEGIN USE Run(JSON 'null'); END;
    ));
}

test "unselected JSON source holes cannot enter program literals through symbolic checking" {
    try std.testing.expectError(error.ProgramTypeMismatch, compile(std.testing.allocator,
        \\CREATE VARIANT Choice AS (Run(data JSON), Skip(data JSON));
        \\CREATE MODULE Emit(data JSON) AS BEGIN
        \\  CREATE PUBLIC DATAFLOW route FROM QUEUE work AS request AS BEGIN LET payload = $data; END;
        \\END;
        \\CREATE MODULE Choose(choice Choice) AS BEGIN
        \\  CREATE PUBLIC QUEUE work(id BIGINT NOT NULL);
        \\  MATCH choice
        \\    WHEN Choice.Run(selected) THEN USE Emit(selected);
        \\    WHEN Choice.Skip(selected) THEN CREATE PUBLIC TABLE t(id BIGINT);
        \\  END MATCH;
        \\END;
        \\CREATE TARGET default AS BEGIN USE Choose(Choice.Skip(JSON 'null')); END;
    ));
}
