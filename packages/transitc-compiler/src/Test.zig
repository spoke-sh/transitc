//! Pure test products. SQL carries database semantics; expectations are runner controls.
const std = @import("std");
const f = @import("transit_sql_frontend");
const p = @import("transit_protocol");
const assertions = @import("transit_test_protocol").Assertions;
pub const max_cases = assertions.max_cases;
pub const max_actions = assertions.max_actions;
pub const max_rows = assertions.max_rows;
pub const max_result_bytes = assertions.max_result_bytes;
pub const max_observations = assertions.max_observations;
pub const Rows = assertions.Rows;
pub const Expectation = assertions.Expectation;
pub const Action = assertions.Action;
pub const Failure = assertions.Failure;
pub const Detail = assertions.Detail;
pub const rowBytes = assertions.rowBytes;
pub const Case = struct {
    name: []const u8,
    identity: [32]u8,
    location: p.Diagnostic.Location,
    sql: []const u8,
    sql_digest: [32]u8,
    steps: []const @import("Compiler.zig").Step,
    actions: []const Action,
};

pub fn bindRows(output: std.mem.Allocator, scratch: std.mem.Allocator, text: []const u8, schema: f.Types.Type) !Rows {
    if (schema != .structure or schema.structure.len > f.TableSchema.max_columns) return error.InvalidTestSchema;
    const retained = try schema.clone(output);
    if (text.len == 0) return .{ .schema = retained.type, .values = &.{} };
    var parser = try f.SqlTyped.init(scratch, text, null);
    var values: std.ArrayList([]const u8) = .empty;
    var cells: [f.TableSchema.max_columns]f.Types.Values.Cell = undefined;
    const encoded = try scratch.alloc(u8, f.Types.Codec.max_bytes);
    var bytes: usize = 0;
    while (true) {
        if (values.items.len == max_rows) return error.TestRowLimit;
        try parser.require(.left);
        for (schema.structure, 0..) |field, i| {
            if (i != 0) try parser.require(.comma);
            cells[i] = try parser.value(field.type);
            try cells[i].validate(field, .{});
        }
        try parser.require(.right);
        const row = try rowBytes(cells[0..schema.structure.len], schema, encoded);
        if (row.len > max_result_bytes - bytes) return error.TestResultLimit;
        bytes += row.len;
        try values.append(output, try output.dupe(u8, row));
        if (!try parser.take(.comma)) break;
    }
    try parser.finish();
    return .{ .schema = retained.type, .values = try values.toOwnedSlice(output) };
}
