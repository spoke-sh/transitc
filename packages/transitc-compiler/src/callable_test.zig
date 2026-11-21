const std = @import("std");
const c = @import("root.zig");
const p = @import("transit_protocol");
fn compile(allocator: std.mem.Allocator, text: []const u8) !*c.Product {
    var diagnostic: ?p.Diagnostic = null;
    return c.compile(allocator, &.{.{ .path = "build.transit", .text = text }}, .{ .compiler_revision = "callable-test" }, &diagnostic);
}
const source =
    \\CREATE PROCEDURE Prototype(events STREAM(id BIGINT NOT NULL), id BIGINT) RETURNS BIGINT
    \\EFFECTS (PRODUCE events)
    \\REQUIRES id >= 1 ELSE 'Positive'
    \\ENSURES result = id ELSE 'SameResult'
    \\AS BEGIN ATOMIC PRODUCE INTO events VALUES (id); RETURN id; END;
    \\CREATE PROCEDURE Save(events STREAM(id BIGINT NOT NULL), id BIGINT) RETURNS BIGINT
    \\EFFECTS (PRODUCE events)
    \\REQUIRES id >= 1 ELSE 'Positive'
    \\ENSURES result = id ELSE 'SameResult'
    \\AS BEGIN ATOMIC
    \\  LET result_value = CALL Prototype(events, id);
    \\  RETURN result_value;
    \\END;
    \\CREATE MODULE Pipeline(events IDENTIFIER, requests IDENTIFIER, route IDENTIFIER, command PROCEDURE OF Prototype) AS BEGIN
    \\  CREATE PUBLIC STREAM $events (id BIGINT NOT NULL);
    \\  CREATE PUBLIC QUEUE $requests (id BIGINT NOT NULL);
    \\  CREATE PUBLIC DATAFLOW $route FROM QUEUE $requests AS request AS BEGIN
    \\    BEGIN ATOMIC
    \\      LET saved = CALL command($events, request.id);
    \\      REQUIRE saved = request.id ELSE 'WrongReturn';
    \\    END;
    \\  END;
    \\END;
    \\CREATE MODULE Wrap(command PROCEDURE OF Prototype) AS BEGIN
    \\  USE Pipeline(NAME 'first_events', NAME 'first_requests', NAME 'first_route', command);
    \\END;
    \\CREATE TARGET default AS BEGIN
    \\  USE Wrap(Save);
    \\  USE Pipeline(NAME 'second_events', NAME 'second_requests', NAME 'second_route', Save);
    \\END;
;
test "callable module arguments preserve exact contracts nested effects and explicit instance resources" {
    const product = try compile(std.testing.allocator, source);
    defer product.deinit();
    try std.testing.expectEqual(6, product.steps.len);
    for ([_]usize{ 2, 5 }, [_][]const u8{ "first_events", "second_events" }) |index, name| {
        const program = product.steps[index].checked.program.?;
        var appends: usize = 0;
        for (program.events) |event| if (event.kind == .append) {
            appends += 1;
            try std.testing.expectEqualStrings(name, event.resource.?);
        };
        try std.testing.expectEqual(1, appends);
        try std.testing.expectEqual(2, std.mem.count(u8, product.steps[index].sql, "'Positive'"));
        try std.testing.expectEqual(2, std.mem.count(u8, product.steps[index].sql, "'SameResult'"));
        try std.testing.expect(std.mem.indexOf(u8, product.steps[index].sql, "CALL") == null);
    }
    try std.testing.expect(!std.mem.eql(u8, product.steps[2].sql, product.steps[5].sql));
}
test "exact callable signatures reject changed predicates names results and missing explicit effects" {
    const cases = .{
        .{ "USE Wrap(Save)", "USE Wrap(Other)", "CREATE PROCEDURE Other(events STREAM(id BIGINT NOT NULL), id BIGINT) RETURNS BIGINT EFFECTS (PRODUCE events) REQUIRES id >= 0 ELSE 'Positive' ENSURES result = id ELSE 'SameResult' AS BEGIN ATOMIC PRODUCE INTO events VALUES (id); RETURN id; END;", error.CallableSignatureMismatch },
        .{ "USE Wrap(Save)", "USE Wrap(Other)", "CREATE PROCEDURE Other(events STREAM(id BIGINT NOT NULL), id BIGINT) RETURNS BIGINT AS BEGIN ATOMIC PRODUCE INTO events VALUES (id); RETURN id; END;", error.MissingCallableContract },
        .{ "USE Wrap(Save)", "USE Wrap(Other)", "CREATE PROCEDURE Other(events STREAM(id BIGINT NOT NULL), id BIGINT) RETURNS TEXT EFFECTS (PRODUCE events) AS BEGIN ATOMIC PRODUCE INTO events VALUES (id); RETURN 'x'; END;", error.CallableSignatureMismatch },
        .{ "USE Wrap(Save)", "USE Wrap(Other)", "CREATE PROCEDURE Other(events STREAM(id BIGINT NOT NULL), other BIGINT) RETURNS BIGINT EFFECTS (PRODUCE events) AS BEGIN ATOMIC PRODUCE INTO events VALUES (other); RETURN other; END;", error.CallableSignatureMismatch },
    };
    inline for (cases) |case| {
        const changed = try std.mem.replaceOwned(u8, std.testing.allocator, source, case[0], case[1]);
        defer std.testing.allocator.free(changed);
        const text = try std.mem.concat(std.testing.allocator, u8, &.{ case[2], changed });
        defer std.testing.allocator.free(text);
        try std.testing.expectError(case[3], compile(std.testing.allocator, text));
    }
}
test "effect contracts reject hidden nested writes unused authority and invalid resource kinds" {
    const cases = .{
        .{ "CREATE PROCEDURE Hidden(a STREAM(id BIGINT NOT NULL),b STREAM(id BIGINT NOT NULL),id BIGINT) EFFECTS(PRODUCE a) AS BEGIN ATOMIC PRODUCE INTO a VALUES(id); PRODUCE INTO b VALUES(id); END;", error.EffectContractMismatch },
        .{ "CREATE PROCEDURE Inner(b STREAM(id BIGINT NOT NULL),id BIGINT) AS BEGIN ATOMIC PRODUCE INTO b VALUES(id); END; CREATE PROCEDURE Outer(a STREAM(id BIGINT NOT NULL),b STREAM(id BIGINT NOT NULL),id BIGINT) EFFECTS(PRODUCE a) AS BEGIN ATOMIC PRODUCE INTO a VALUES(id); CALL Inner(b,id); END;", error.EffectContractMismatch },
        .{ "CREATE GUARD G(t TABLE(id BIGINT PRIMARY KEY)) EFFECTS(READ t) AS REQUIRE TRUE ELSE 'No';", error.EffectContractMismatch },
        .{ "CREATE GUARD G(t TABLE(id BIGINT PRIMARY KEY)) EFFECTS() AS BEGIN LET r = SELECT id FROM t; REQUIRE TRUE ELSE 'No'; END;", error.EffectContractMismatch },
        .{ "CREATE PROCEDURE P(s STREAM(id BIGINT NOT NULL)) EFFECTS(READ s) AS BEGIN ATOMIC END;", error.InvalidEffectBinding },
        .{ "CREATE PROCEDURE P(s STREAM(id BIGINT NOT NULL)) EFFECTS(PRODUCE s,PRODUCE s) AS BEGIN ATOMIC END;", error.DuplicateEffectRequirement },
    };
    inline for (cases) |case| {
        const text = try std.mem.concat(std.testing.allocator, u8, &.{ case[0], " CREATE TARGET default AS BEGIN CREATE PUBLIC TABLE t (id BIGINT PRIMARY KEY); END;" });
        defer std.testing.allocator.free(text);
        try std.testing.expectError(case[1], compile(std.testing.allocator, text));
    }
}
test "pure function and read guard callable arguments lower through the same checked path" {
    const product = try compile(std.testing.allocator,
        \\CREATE FUNCTION Identity(id BIGINT) RETURNS BIGINT AS BEGIN RETURN id; END;
        \\CREATE GUARD Exists(t TABLE(id BIGINT PRIMARY KEY),key BIGINT) EFFECTS(READ t) AS BEGIN
        \\  LET found ONE = SELECT id FROM t WHERE id = key;
        \\  REQUIRE found IS NOT NULL ELSE 'Missing';
        \\END;
        \\CREATE MODULE Run(fn FUNCTION OF Identity, check GUARD OF Exists) AS BEGIN
        \\  CREATE PUBLIC TABLE items(id BIGINT PRIMARY KEY);
        \\  CREATE PUBLIC QUEUE jobs(id BIGINT NOT NULL);
        \\  CREATE PUBLIC DATAFLOW route FROM QUEUE jobs AS request AS BEGIN
        \\    CHECK GUARD check(items, fn(request.id));
        \\  END;
        \\END;
        \\CREATE TARGET default AS BEGIN USE Run(Identity, Exists); END;
    );
    defer product.deinit();
    try std.testing.expectEqual(3, product.steps.len);
}
fn allocations(allocator: std.mem.Allocator) !void {
    const product = try compile(allocator, source);
    defer product.deinit();
}
test "callable specialization remains bounded across allocation failures" {
    try std.testing.checkAllAllocationFailures(std.testing.allocator, allocations, .{});
}
