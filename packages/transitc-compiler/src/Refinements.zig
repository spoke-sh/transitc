//! Bounded callable obligations over immutable scalar arguments and results.
//! Every admitted clause lowers to an ordered REQUIRE; none grants authority.
const std = @import("std");
const s = @import("Syntax.zig");
const Graph = @import("Graph.zig");
const types = @import("SourceTypes.zig");

pub fn operator(op: @FieldType(s.RefinementTerm, "op")) []const u8 {
    return switch (op) {
        .present => "IS NOT NULL",
        .equal => "=",
        .not_equal => "<>",
        .less => "<",
        .less_equal => "<=",
        .greater => ">",
        .greater_equal => ">=",
    };
}
fn scalar(graph: Graph, file: usize, def: s.Definition, name: []const u8, post: bool) !types.Scalar {
    if (std.mem.eql(u8, name, "result")) {
        if (!post or def.return_type == null) return error.InvalidRefinementBinding;
        return types.resolve(graph, file, def.return_type.?);
    }
    for (def.parameters) |param| if (std.mem.eql(u8, name, param.name)) return types.field(graph, file, param.kind) catch return error.InvalidRefinementBinding;
    return error.InvalidRefinementBinding;
}
pub fn validate(graph: Graph, file: usize, def: s.Definition) !void {
    if (def.preconditions.len == 0 and def.postconditions.len == 0) return;
    if (def.kind == .function) return error.UnsupportedRefinementContract;
    for (def.parameters) |param| if (std.mem.eql(u8, param.name, "result")) return error.InvalidRefinementBinding;
    for ([_][]const s.Refinement{ def.preconditions, def.postconditions }, 0..) |clauses, phase| {
        for (clauses) |clause| for (clause.terms) |term| {
            const left = try scalar(graph, file, def, term.left, phase == 1);
            if (term.right) |right| switch (right) {
                .integer => {
                    if (left.base != .bigint or left.domain != null) return error.UnsupportedRefinementPredicate;
                },
                .name => |name| {
                    if (term.op != .equal and term.op != .not_equal) return error.UnsupportedRefinementPredicate;
                    if (!types.Scalar.eql(left, try scalar(graph, file, def, name, phase == 1))) return error.SourceDomainMismatch;
                },
            };
        };
    }
}
