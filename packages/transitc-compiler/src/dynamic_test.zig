const std = @import("std");
const c = @import("root.zig");
const p = @import("transit_protocol");

const source =
    \\CREATE DOMAIN MachineId AS BIGINT IDENTITY 'example.machine';
    \\CREATE DOMAIN SiteId AS BIGINT IDENTITY 'example.site';
    \\CREATE VARIANT Target AS (Machine(id MachineId), Site(id SiteId));
    \\CREATE MODULE Setup(machine TYPE, site TYPE) AS BEGIN
    \\  CREATE PUBLIC QUEUE requests (target STRUCT(tag TEXT NOT NULL, machine STRUCT(id BIGINT NOT NULL), site STRUCT(id BIGINT NOT NULL)) NOT NULL);
    \\  CREATE PUBLIC TABLE machines (id $machine PRIMARY KEY);
    \\  CREATE PUBLIC TABLE sites (id $site PRIMARY KEY);
    \\  CREATE PUBLIC DATAFLOW route FROM QUEUE requests AS request AS BEGIN
    \\    BEGIN ATOMIC
    \\      MATCH request.target AS Target
    \\        WHEN Target.Machine(machine_id) THEN
    \\          INSERT INTO machines VALUES (machine_id) ON CONFLICT (id) DO ASSERT SAME ROW;
    \\        WHEN Target.Site(site_id) THEN
    \\          INSERT INTO sites VALUES (site_id) ON CONFLICT (id) DO ASSERT SAME ROW;
    \\      END MATCH;
    \\    END;
    \\  END;
    \\END;
    \\CREATE TARGET default AS BEGIN USE Setup(TYPE MachineId, TYPE SiteId); END;
;
fn compile(allocator: std.mem.Allocator, text: []const u8) !*c.Product {
    var diagnostic: ?p.Diagnostic = null;
    return c.compile(allocator, &.{.{ .path = "build.transit", .text = text }}, .{ .compiler_revision = "dynamic-match" }, &diagnostic);
}

test "runtime MATCH validates a closed record and preserves nominal arm payloads" {
    const product = try compile(std.testing.allocator, source);
    defer product.deinit();
    const step = product.steps[3];
    try std.testing.expect(std.mem.indexOf(u8, step.sql, "MATCH") == null);
    try std.testing.expect(std.mem.indexOf(u8, step.sql, "InvalidVariant") != null);
    var writes: usize = 0;
    var validation: ?usize = null;
    for (step.checked.program.?.events, 0..) |event, index| {
        if (event.kind == .require and validation == null) validation = index;
        if (event.kind == .insert) {
            try std.testing.expect(validation != null and validation.? < index);
            try std.testing.expectEqualStrings(if (writes == 0) "example.machine" else "example.site", event.columns[0].domain.?);
            writes += 1;
        }
    }
    try std.testing.expectEqual(2, writes);
}

test "runtime MATCH rejects foreign payloads missing arms malformed records and capture" {
    const cases = .{
        .{ "INSERT INTO machines", "INSERT INTO sites", error.SourceDomainMismatch },
        .{ "WHEN Target.Site(site_id) THEN\n          INSERT INTO sites VALUES (site_id) ON CONFLICT (id) DO ASSERT SAME ROW;", "", error.NonExhaustiveSourceMatch },
        .{ "WHEN Target.Site(site_id)", "WHEN Target.Machine(site_id)", error.DuplicateSourceMatchArm },
        .{ "Target.Machine(machine_id)", "Target.Machine()", error.SourceArgumentCount },
        .{ "Target.Machine(machine_id)", "Target.Machine(request)", error.DuplicateProgramVariable },
        .{ "machine STRUCT(id BIGINT NOT NULL)", "machine STRUCT(id TEXT NOT NULL)", error.ProgramTypeMismatch },
        .{ "machine STRUCT(id BIGINT NOT NULL)", "machine STRUCT(id BIGINT)", error.ProgramTypeMismatch },
        .{ "tag TEXT NOT NULL", "tag BIGINT NOT NULL", error.ProgramTypeMismatch },
        .{ "MATCH request.target", "MATCH request", error.UnknownProgramField },
        .{ "VALUES (machine_id)", "VALUES (\"__t$2_variant\".machine.id)", error.UnknownProgramVariable },
    };
    inline for (cases) |case| {
        const changed = try std.mem.replaceOwned(u8, std.testing.allocator, source, case[0], case[1]);
        defer std.testing.allocator.free(changed);
        try std.testing.expect(!std.mem.eql(u8, source, changed));
        try std.testing.expectError(case[2], compile(std.testing.allocator, changed));
    }
}

fn allocations(allocator: std.mem.Allocator) !void {
    const product = try compile(allocator, source);
    defer product.deinit();
}
test "runtime MATCH allocation failures do not expose a partial product" {
    try std.testing.checkAllAllocationFailures(std.testing.allocator, allocations, .{});
}

test "runtime MATCH in an inline guard checks patterns separately from calls" {
    const helper =
        \\CREATE GUARD Validate(value ROW(tag TEXT, machine ROW(id BIGINT), site ROW(id BIGINT))) AS BEGIN
        \\  MATCH value AS Target
        \\    WHEN Target.Machine(machine_id) THEN REQUIRE machine_id IS NOT NULL ELSE 'NoMachine';
        \\    WHEN Target.Site(site_id) THEN REQUIRE site_id IS NOT NULL ELSE 'NoSite';
        \\  END MATCH;
        \\END;
    ;
    const with_helper = try std.mem.concat(std.testing.allocator, u8, &.{ helper, source });
    defer std.testing.allocator.free(with_helper);
    const called = try std.mem.replaceOwned(u8, std.testing.allocator, with_helper, "FROM QUEUE requests AS request AS BEGIN", "FROM QUEUE requests AS request AS BEGIN CHECK GUARD Validate(request.target);");
    defer std.testing.allocator.free(called);
    const product = try compile(std.testing.allocator, called);
    defer product.deinit();
    try std.testing.expect(std.mem.indexOf(u8, product.steps[3].sql, "MATCH") == null);
    try std.testing.expectEqual(2, std.mem.count(u8, product.steps[3].sql, "'InvalidVariant'"));
}

test "runtime MATCH keeps explicit instances separate" {
    var arena: std.heap.ArenaAllocator = .init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var text = try std.mem.replaceOwned(u8, allocator, source, "Setup(machine TYPE, site TYPE)", "Setup(machine TYPE, site TYPE, input_name IDENTIFIER, machines_name IDENTIFIER, sites_name IDENTIFIER, route_name IDENTIFIER)");
    const names = .{ .{ "QUEUE requests", "QUEUE $input_name" }, .{ "TABLE machines", "TABLE $machines_name" }, .{ "INTO machines", "INTO $machines_name" }, .{ "TABLE sites", "TABLE $sites_name" }, .{ "INTO sites", "INTO $sites_name" }, .{ "DATAFLOW route", "DATAFLOW $route_name" } };
    inline for (names) |pair| text = try std.mem.replaceOwned(u8, allocator, text, pair[0], pair[1]);
    text = try std.mem.replaceOwned(u8, allocator, text, "USE Setup(TYPE MachineId, TYPE SiteId);", "USE Setup(TYPE MachineId, TYPE SiteId, NAME 'input_a', NAME 'machines_a', NAME 'sites_a', NAME 'route_a'); USE Setup(TYPE MachineId, TYPE SiteId, NAME 'input_b', NAME 'machines_b', NAME 'sites_b', NAME 'route_b');");
    const product = try compile(std.testing.allocator, text);
    defer product.deinit();
    try std.testing.expectEqual(8, product.steps.len);
    for ([_]usize{ 3, 7 }, [_][]const u8{ "machines_a", "machines_b" }) |index, name| {
        const events = product.steps[index].checked.program.?.events;
        for (events) |event| if (event.kind == .insert) {
            try std.testing.expectEqualStrings(name, event.resource.?);
            break;
        };
    }
}
