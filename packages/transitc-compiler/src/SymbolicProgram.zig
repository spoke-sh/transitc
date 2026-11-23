//! Type-only program inputs for checking every compile-time specialization arm.
//! No synthetic input, catalog entry or value is emitted into a build product.
const std = @import("std");
const f = @import("transit_sql_frontend");
const types = @import("SourceTypes.zig");
const Catalog = @import("WorkingCatalog.zig");

pub const Parameter = struct { name: []const u8, scalar: types.Scalar };
pub const Parameters = std.ArrayList(Parameter);

/// Keep immutable checking constants outside the authored Queue shape. Neither
/// field/depth budgets nor whole-input ROW semantics depend on hole count.
pub fn catalog(allocator: std.mem.Allocator, original: Catalog, parameters: []const Parameter) !Catalog {
    var result = original;
    if (parameters.len == 0) return result;
    if (parameters.len > f.ApplicationProgram.max_arguments) return error.ProgramTooComplex;
    const fields = try allocator.alloc(f.ApplicationProgram.Types.Field, parameters.len);
    for (parameters, fields) |parameter, *field| {
        field.* = .{ .name = parameter.name, .value = try f.ApplicationProgram.Schema.bindField(allocator, .{
            .name = parameter.name,
            .type = parameter.scalar.physical(),
            .nullable = false,
        }) };
    }
    result.program_parameters = fields;
    return result;
}
