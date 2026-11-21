const std = @import("std");
const c = @import("root.zig");
const p = @import("transit_protocol");
fn compile(allocator: std.mem.Allocator, text: []const u8) !*c.Product {
    var diagnostic: ?p.Diagnostic = null;
    return c.compile(allocator, &.{.{ .path = "build.transit", .text = text }}, .{ .compiler_revision = "symbolic-program-test" }, &diagnostic);
}
const source =
    \\CREATE DOMAIN MachineId AS BIGINT IDENTITY 'example.machine';
    \\CREATE DOMAIN SiteId AS BIGINT IDENTITY 'example.site';
    \\CREATE VARIANT Target AS (Machine(id MachineId), Site(id SiteId));
    \\CREATE FUNCTION identity_machine(value MachineId) RETURNS MachineId AS BEGIN RETURN value; END;
    \\CREATE FUNCTION accepts(value MachineId) RETURNS BOOLEAN AS BEGIN RETURN TRUE; END;
    \\CREATE MODULE EmitMachine(value MachineId) AS BEGIN
    \\  CREATE PUBLIC DATAFLOW machine_route FROM QUEUE requests AS request WHERE accepts($value) AS BEGIN
    \\    BEGIN ATOMIC
    \\      INSERT INTO machines VALUES (identity_machine($value)) ON CONFLICT (id) DO ASSERT SAME ROW;
    \\    END;
    \\  END;
    \\  AUTHORIZE DATAFLOW machine_route AS ROLE CURRENT_ROLE;
    \\  ACTIVATE DATAFLOW machine_route;
    \\END;
    \\CREATE MODULE EmitSite(value SiteId) AS BEGIN
    \\  CREATE PUBLIC DATAFLOW site_route FROM QUEUE requests AS request AS BEGIN
    \\    BEGIN ATOMIC
    \\      INSERT INTO sites VALUES ($value) ON CONFLICT (id) DO ASSERT SAME ROW;
    \\    END;
    \\  END;
    \\  AUTHORIZE DATAFLOW site_route AS ROLE CURRENT_ROLE;
    \\  ACTIVATE DATAFLOW site_route;
    \\END;
    \\CREATE MODULE Setup(machine TYPE, site TYPE, selected Target) AS BEGIN
    \\  CREATE PUBLIC TABLE machines (id $machine PRIMARY KEY);
    \\  CREATE PUBLIC TABLE sites (id $site PRIMARY KEY);
    \\  CREATE PUBLIC QUEUE requests (id BIGINT NOT NULL);
    \\  MATCH selected
    \\    WHEN Target.Machine(value) THEN USE EmitMachine(value);
    \\    WHEN Target.Site(value) THEN USE EmitSite(value);
    \\  END MATCH;
    \\END;
    \\CREATE TARGET default AS BEGIN USE Setup(TYPE MachineId, TYPE SiteId, Target.Machine(MachineId(7))); END;
;
test "symbolic programs check all match arms without inventing values or emitting phantom fields" {
    const product = try compile(std.testing.allocator, source);
    defer product.deinit();
    try std.testing.expectEqual(6, product.steps.len);
    for (product.steps) |step| {
        try std.testing.expect(std.mem.indexOf(u8, step.sql, "__transit$symbolic") == null);
        try std.testing.expect(std.mem.indexOf(u8, step.sql, "SITE_ROUTE") == null);
    }
    try std.testing.expectEqualStrings("CREATE QUEUE REQUESTS ( ID BIGINT NOT NULL )", product.steps[2].sql);
    const program = product.steps[3].checked.program.?;
    const insert = program.events[program.events.len - 2];
    try std.testing.expectEqualStrings("example.machine", insert.columns[0].domain.?);
}
test "unselected symbolic program preserves foreign domains and physical type errors" {
    const cases = .{
        .{ "INSERT INTO sites VALUES ($value)", "INSERT INTO machines VALUES ($value)", error.SourceDomainMismatch },
        .{ "INSERT INTO sites VALUES ($value)", "INSERT INTO sites VALUES ($value + 1)", error.UnsupportedNominalOperation },
        .{ "INSERT INTO sites VALUES ($value)", "INSERT INTO sites VALUES ('wrong')", error.ProgramTypeMismatch },
        .{ "INSERT INTO sites VALUES ($value)", "LET forged = request.\"__transit$symbolic_0\"; INSERT INTO sites VALUES ($value)", error.UnsupportedSymbolicProgram },
        .{ "ACTIVATE DATAFLOW site_route", "ACTIVATE DATAFLOW unknown_route", error.UnknownBuildProgram },
    };
    inline for (cases) |case| {
        const changed = try std.mem.replaceOwned(u8, std.testing.allocator, source, case[0], case[1]);
        defer std.testing.allocator.free(changed);
        try std.testing.expectError(case[2], compile(std.testing.allocator, changed));
    }
}
fn allocation(allocator: std.mem.Allocator) !void {
    const product = try compile(allocator, source);
    defer product.deinit();
}
test "symbolic program checking allocation failures do not escape a partial catalog" {
    try std.testing.checkAllAllocationFailures(std.testing.allocator, allocation, .{});
}
test "symbolic IF cannot introduce a program or its controls" {
    const renamed = try std.mem.replaceOwned(u8, std.testing.allocator, source, "CREATE MODULE EmitSite(", "CREATE MODULE InnerSite(");
    defer std.testing.allocator.free(renamed);
    const changed = try std.mem.replaceOwned(u8, std.testing.allocator, renamed, "CREATE MODULE Setup(", "CREATE MODULE EmitSite(value SiteId) AS BEGIN IF value = value THEN USE InnerSite(value); END IF; END; CREATE MODULE Setup(");
    defer std.testing.allocator.free(changed);
    try std.testing.expectError(error.UnsupportedSymbolicSchema, compile(std.testing.allocator, changed));
}
