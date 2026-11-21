const std = @import("std");
const c = @import("root.zig");
const f = @import("transit_sql_frontend");

fn expectFormat(a: std.mem.Allocator, source: []const u8, expected: []const u8) !void {
    var arena: std.heap.ArenaAllocator = .init(a);
    defer arena.deinit();
    var offset: usize = 0;
    const file = try c.Syntax.parse(arena.allocator(), source, &offset);
    var buffer: [16384]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buffer);
    try c.Format.source(a, source, file, &writer);
    const output = writer.buffered();
    try std.testing.expectEqualStrings(expected, output);

    // Compare the complete lexical stream, including comments and quoted bytes.
    // Only word case and whitespace may change; no token may vanish or merge.
    var original = try f.SqlInput.CompilerScan.init(source);
    var formatted = try f.SqlInput.CompilerScan.init(output);
    while (try significant(&original)) |before| {
        const after = (try significant(&formatted)).?;
        try std.testing.expectEqual(before.kind, after.kind);
        const left = source[before.start..before.end];
        const right = output[after.start..after.end];
        if (before.kind == .word) {
            try std.testing.expect(std.ascii.eqlIgnoreCase(left, right));
        } else try std.testing.expectEqualStrings(left, right);
    }
    try std.testing.expectEqual(null, try significant(&formatted));
    const parsed = try c.Syntax.parse(arena.allocator(), output, &offset);
    var again: [16384]u8 = undefined;
    var second: std.Io.Writer = .fixed(&again);
    try c.Format.source(a, output, parsed, &second);
    try std.testing.expectEqualStrings(output, second.buffered());
}

fn significant(scan: *f.SqlInput.CompilerScan) !?c.Syntax.Token {
    while (try scan.next()) |token| if (token.kind != .space) return token;
    return null;
}

test "source layout preserves keyword-like names, comments, sugar and quoted bytes" {
    const source = "-- banner\nimport Target from 'MiXeD.transit';\n\n\ncreate module Rows(rows bigint) as begin /* start */ use Target.Rows(n=>-7); -- note\nend;";
    const expected = "-- banner\nIMPORT Target FROM 'MiXeD.transit';\n\nCREATE MODULE Rows(rows BIGINT) AS BEGIN /* start */\n  USE Target.Rows(n => -7); -- note\nEND;\n";
    try std.testing.checkAllAllocationFailures(std.testing.allocator, expectFormat, .{ source, expected });
}

test "program layout uses parser boundaries including IF, CASE and empty ELSE" {
    try expectFormat(
        std.testing.allocator,
        "create guard check_it(rows bigint) as begin if rows>0 then require case when rows=1 then true else false end else 'bad';else end if;end;",
        "CREATE GUARD check_it(rows BIGINT) AS BEGIN\n  IF rows > 0 THEN\n    REQUIRE CASE WHEN rows = 1 THEN TRUE ELSE FALSE END ELSE 'bad';\n  ELSE\n  END IF;\nEND;\n",
    );
}

test "comments at expression and block boundaries remain present and idempotent" {
    try expectFormat(
        std.testing.allocator,
        "/*before*/ create /*header*/ module m() as begin\n-- body\nif /*condition*/ true then -- yes\n/*empty*/ else /*no*/ end if;\nend /*end*/; -- eof",
        "/*before*/\nCREATE /*header*/ MODULE m() AS BEGIN\n  -- body\n  IF /*condition*/ TRUE THEN -- yes\n    /*empty*/\n  ELSE /*no*/\n  END IF;\nEND /*end*/; -- eof\n",
    );
}

test "source writer exhaustion is explicit and never a complete result" {
    var arena: std.heap.ArenaAllocator = .init(std.testing.allocator);
    defer arena.deinit();
    var offset: usize = 0;
    const source = "CREATE TARGET default AS BEGIN END;";
    const parsed = try c.Syntax.parse(arena.allocator(), source, &offset);
    var bytes: [8]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&bytes);
    try std.testing.expectError(error.WriteFailed, c.Format.source(std.testing.allocator, source, parsed, &writer));
}
