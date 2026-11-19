const std = @import("std");

const help =
    \\transitc — the Transit language compiler
    \\
    \\Usage: transitc [--help | --version]
    \\
    \\This checkout prepares the standalone compiler extraction.
    \\Compilation, dependency resolution, and test execution are not available yet.
    \\
;

pub fn main(init: std.process.Init) !void {
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    var buffer: [1024]u8 = undefined;
    if (args.len == 1 or (args.len == 2 and
        (std.mem.eql(u8, args[1], "--help") or std.mem.eql(u8, args[1], "-h"))))
    {
        var out = std.Io.File.stdout().writerStreaming(init.io, &buffer);
        try out.interface.writeAll(help);
        try out.interface.flush();
    } else if (args.len == 2 and std.mem.eql(u8, args[1], "--version")) {
        var out = std.Io.File.stdout().writerStreaming(init.io, &buffer);
        try out.interface.writeAll("transitc " ++ @import("build_options").version ++ " (bootstrap)\n");
        try out.interface.flush();
    } else {
        var err = std.Io.File.stderr().writerStreaming(init.io, &buffer);
        try err.interface.writeAll("transitc: unsupported arguments; this bootstrap supports only --help and --version\n");
        try err.interface.flush();
        std.process.exit(2);
    }
}
