const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const options = b.addOptions();
    options.addOption([]const u8, "version", "0.0.0-dev");

    const cli = b.addExecutable(.{
        .name = "transitc",
        .root_module = b.createModule(.{
            .root_source_file = b.path("apps/transitc-cli/src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    cli.root_module.addOptions("build_options", options);
    b.installArtifact(cli);
    b.step("check", "Compile the bootstrap CLI").dependOn(&cli.step);
    const run = b.addRunArtifact(cli);
    run.addPassthruArgs();
    b.step("run", "Run the bootstrap CLI").dependOn(&run.step);
}
