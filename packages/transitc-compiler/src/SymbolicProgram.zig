//! Type-only program inputs for checking every compile-time specialization arm.
//! No synthetic input, catalog entry or value is emitted into a build product.
const std = @import("std");
const f = @import("transit_sql_frontend");
const types = @import("SourceTypes.zig");
const Catalog = @import("WorkingCatalog.zig");
const Graph = @import("Graph.zig");

pub const Parameter = struct { name: []const u8, scalar: types.Scalar };
pub const Parameters = std.ArrayList(Parameter);

/// Mirror the existing helper-body checker: bind unknown scalars as typed input
/// fields, never as invented literals. The caller owns a temporary catalog copy.
pub fn catalog(allocator: std.mem.Allocator, original: Catalog, sql: []const u8, parameters: []const Parameter, location: *f.Sql.Location) !Catalog {
    var result = original;
    if (parameters.len == 0) return result;
    var parsed = try f.ApplicationProgram.parse(allocator, sql, location);
    defer parsed.deinit();
    const input = try original.findResourceQualified(parsed.program.queue_schema, parsed.program.queue);
    const entry = try allocator.create(types.Table);
    entry.* = input.*;
    const count = input.schema.columns.len;
    const columns = try allocator.alloc(f.TableSchema.Column, count + parameters.len);
    @memcpy(columns[0..count], input.schema.columns);
    const domains = try allocator.alloc(?Graph.Ref, columns.len);
    @memcpy(domains[0..count], input.domains);
    const nested = try allocator.alloc([]const types.FieldDomain, columns.len);
    @memset(nested, &.{});
    @memcpy(nested[0..input.nested_domains.len], input.nested_domains);
    for (parameters, 0..) |parameter, i| {
        for (columns[0 .. count + i]) |column| if (std.mem.eql(u8, column.name, parameter.name)) return error.UnsupportedSymbolicSchema;
        columns[count + i] = .{ .id = input.schema.next_column + i, .name = parameter.name, .type = parameter.scalar.physical(), .nullable = false };
        domains[count + i] = parameter.scalar.domain;
    }
    entry.schema.columns = columns;
    entry.schema.next_column += parameters.len;
    try entry.schema.validate();
    entry.domains = domains;
    entry.nested_domains = nested;
    result.entries = try original.entries.clone(allocator);
    for (result.entries.items) |*item| if (item.* == input) {
        item.* = entry;
        break;
    };
    return result;
}
