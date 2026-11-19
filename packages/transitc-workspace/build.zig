const std = @import("std");
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const module = b.addModule("transitc_workspace", .{ .root_source_file = b.path("src/root.zig"), .target = target, .optimize = optimize, .link_libc = true });
    const shared = b.lazyDependency("transit_shared", .{ .target = target, .optimize = optimize }) orelse return;
    const compiler = (b.lazyDependency("transitc_compiler", .{ .target = target, .optimize = optimize }) orelse return).module("transitc_compiler");
    inline for (.{ "transit_sql_frontend", "transit_protocol", "transit_memory", "transit_test_protocol" }) |name| {
        module.addImport(name, shared.module(name));
    }
    module.addImport("transit_compiler", compiler);
    b.modules.put(b.allocator, "transitc_compiler", compiler) catch @panic("out of memory");
    const tests = b.addTest(.{ .root_module = module });
    b.step("check", "Compile workspace tests").dependOn(&tests.step);
    b.step("test", "Run source capture and diagnostic checks").dependOn(&b.addRunArtifact(tests).step);
}
