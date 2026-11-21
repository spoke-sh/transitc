//! Exact resource-operation contracts over fully inlined ordinary helper SQL.
const std = @import("std");
const a = @import("transit_sql_frontend").ApplicationProgram;
const s = @import("Syntax.zig");
const types = @import("SourceTypes.zig");
const Catalog = @import("WorkingCatalog.zig");
const Context = @import("SourceDiagnostic.zig").Context;
pub const Binding = struct { name: []const u8, table: *const types.Table };
const Operation = @FieldType(s.Effect, "operation");

pub fn label(operation: Operation) []const u8 {
    return switch (operation) {
        .read => "READ",
        .insert => "INSERT",
        .produce => "PRODUCE",
        .enqueue => "ENQUEUE",
    };
}
pub fn same(left: []const s.Effect, right: []const s.Effect) bool {
    if (left.len != right.len) return false;
    for (left) |l| {
        for (right) |r| {
            if (l.operation == r.operation and std.mem.eql(u8, l.resource, r.resource)) break;
        } else return false;
    }
    return true;
}
pub fn validate(def: s.Definition) !void {
    for (def.effects orelse return, 0..) |effect, i| {
        for (def.effects.?[0..i]) |prior| if (prior.operation == effect.operation and std.mem.eql(u8, prior.resource, effect.resource)) return error.DuplicateEffectRequirement;
        const kind = for (def.parameters) |param| {
            if (std.mem.eql(u8, param.name, effect.resource)) break param.kind;
        } else return error.InvalidEffectBinding;
        switch (effect.operation) {
            .read, .insert => if (kind != .table) return error.InvalidEffectBinding,
            .produce => if (kind != .stream) return error.InvalidEffectBinding,
            .enqueue => if (kind != .queue) return error.InvalidEffectBinding,
        }
    }
}
pub fn check(allocator: std.mem.Allocator, catalog: *Catalog, effects: ?[]const s.Effect, bindings: []const Binding, instructions: []const a.Instruction, context: *Context) !void {
    const declared = effects orelse return;
    const used = try allocator.alloc(bool, declared.len);
    @memset(used, false);
    var self: Checker = .{ .catalog = catalog, .effects = declared, .bindings = bindings, .used = used, .context = context };
    try self.block(instructions);
    for (used) |present| if (!present) return error.EffectContractMismatch;
}
const Checker = struct {
    catalog: *Catalog,
    effects: []const s.Effect,
    bindings: []const Binding,
    used: []bool,
    context: *Context,

    fn access(self: *Checker, operation: Operation, schema: ?[]const u8, name: []const u8, offset: usize) !void {
        const resource = try self.catalog.findResourceQualified(schema, name);
        self.context.* = .{ .offset = offset, .name = name, .actual = label(operation) };
        for (self.effects, 0..) |effect, i| {
            if (effect.operation != operation) continue;
            for (self.bindings) |binding| if (std.mem.eql(u8, binding.name, effect.resource) and binding.table == resource) {
                self.used[i] = true;
                return;
            };
        }
        return error.EffectContractMismatch;
    }
    fn block(self: *Checker, instructions: []const a.Instruction) anyerror!void {
        for (instructions) |instruction| switch (instruction.value) {
            .let => |binding| switch (binding.value) {
                .expression => {},
                .select => |read| try self.access(.read, read.schema, read.target, instruction.span.start),
                else => return error.EffectContractMismatch,
            },
            .require => {},
            .atomic => |body| try self.block(body),
            .conditional => |branch| {
                try self.block(branch.yes);
                try self.block(branch.no);
            },
            .insert => |write| try self.access(.insert, write.target_schema, write.target, instruction.span.start),
            .append => |write| try self.access(if (write.kind == .stream) .produce else .enqueue, write.target_schema, write.target, instruction.span.start),
            else => return error.EffectContractMismatch,
        };
    }
};
