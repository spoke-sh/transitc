//! Offline source formatting and per-file atomic replacement.
const std = @import("std");
const c = @import("transit_compiler");
const Sources = @import("BuildSources.zig");
const Diagnostic = @import("Diagnostic.zig");
const escaped = @import("EnvelopeDiagnostic.zig").escaped;
const Self = @This();
const file_limit = 1024 * 1024;

pub const Options = struct {
    check: bool = false,
    stdin: bool = false,
    help: bool = false,
    paths: [256][]const u8 = undefined,
    paths_len: usize = 0,

    pub fn parse(args: []const []const u8, diagnostic: *Diagnostic) !Options {
        diagnostic.command = "transitc fmt";
        diagnostic.help = "transitc fmt --help";
        var result: Options = .{};
        var positional = false;
        for (args, 1..) |arg, i| {
            diagnostic.atArgument(i, null);
            if (!positional and std.mem.eql(u8, arg, "--")) {
                positional = true;
            } else if (!positional and std.mem.eql(u8, arg, "--check")) {
                result.check = true;
            } else if (!positional and std.mem.eql(u8, arg, "--stdin")) {
                result.stdin = true;
            } else if (!positional and (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h"))) {
                result.help = true;
            } else {
                if (!positional and std.mem.startsWith(u8, arg, "-")) return diagnostic.invalidArgument("unknown fmt option; use transitc fmt --help");
                if (arg.len == 0) return diagnostic.invalidArgument("empty path");
                if (result.paths_len == result.paths.len) return diagnostic.invalidInvocation("fmt accepts at most 256 paths");
                result.paths[result.paths_len] = arg;
                result.paths_len += 1;
            }
        }
        if (result.stdin and (result.check or result.paths_len != 0)) return diagnostic.invalidInvocation("--stdin cannot be combined with paths or --check");
        return result;
    }
};

a: std.mem.Allocator,
scratch_parent: std.mem.Allocator,
io: std.Io,
cwd: []const u8,
files: std.StringHashMap(void),
directories: std.StringHashMap(void),
entries: usize = 0,
ok: bool = true,

const Failure = struct {
    report: c.SourceDiagnostic.Report = .{},
    line: ?usize = null,
    column: usize = 1,
};

pub fn run(init: std.process.Init, options: Options) !bool {
    var budget: @import("transit_memory").Budget = .{ .parent = init.gpa, .limit = 256 * 1024 * 1024 };
    var arena: std.heap.ArenaAllocator = .init(budget.allocator());
    defer arena.deinit();
    const a = arena.allocator();
    if (options.stdin) {
        var failure: Failure = .{};
        formatStdin(a, init.io, &failure) catch |err| {
            try emitFailure(init.io, "<stdin>", &failure, err);
            return false;
        };
        return true;
    }
    var self: Self = .{
        .a = a,
        .scratch_parent = budget.allocator(),
        .io = init.io,
        .cwd = try std.process.currentPathAlloc(init.io, a),
        .files = .init(a),
        .directories = .init(a),
    };
    const paths: []const []const u8 = if (options.paths_len == 0) &.{"."} else options.paths[0..options.paths_len];
    for (paths) |path| {
        const absolute = try std.fs.path.resolve(a, &.{ self.cwd, path });
        self.collect(absolute, 0, true) catch |err| try self.noteFailure(path, err);
    }
    const files = try a.alloc([]const u8, self.files.count());
    var keys = self.files.keyIterator();
    for (files) |*file| file.* = keys.next().?.*;
    std.mem.sort([]const u8, files, {}, struct {
        fn less(_: void, lhs: []const u8, rhs: []const u8) bool {
            return std.mem.lessThan(u8, lhs, rhs);
        }
    }.less);
    for (files) |path| {
        var scratch: std.heap.ArenaAllocator = .init(self.scratch_parent);
        defer scratch.deinit();
        const relative = try std.fs.path.relativeAlloc(scratch.allocator(), self.cwd, null, self.cwd, path);
        var failure: Failure = .{};
        const changed = self.formatFile(scratch.allocator(), path, options.check, &failure) catch |err| {
            try emitFailure(self.io, relative, &failure, err);
            self.ok = false;
            continue;
        };
        if (changed) {
            var buffer: [4096]u8 = undefined;
            var out = std.Io.File.stdout().writerStreaming(self.io, &buffer);
            try escaped(&out.interface, relative);
            try out.interface.writeByte('\n');
            try out.interface.flush();
            if (options.check) self.ok = false;
        }
    }
    return self.ok;
}

fn noteFailure(self: *Self, path: []const u8, err: anyerror) !void {
    var detail: Failure = .{};
    try emitFailure(self.io, path, &detail, err);
    self.ok = false;
}

fn collect(self: *Self, absolute: []const u8, depth: usize, explicit: bool) anyerror!void {
    if (depth > 64) return error.SourceDepthLimit;
    const parent = try Sources.openRoot(self.io, std.fs.path.dirname(absolute) orelse "/");
    defer parent.close(self.io);
    const name = if (std.mem.eql(u8, absolute, "/")) "." else std.fs.path.basename(absolute);
    const stat = try parent.statFile(self.io, name, .{ .follow_symlinks = false });
    switch (stat.kind) {
        .directory => {
            const seen = try self.directories.getOrPut(absolute);
            if (seen.found_existing) return;
            const directory = try parent.openDir(self.io, name, .{ .iterate = true, .follow_symlinks = false });
            defer directory.close(self.io);
            var it = directory.iterate();
            while (try it.next(self.io)) |entry| {
                self.entries += 1;
                if (self.entries > 16384) return error.SourceTreeEntryLimit;
                if (entry.name[0] == '.' or std.mem.eql(u8, entry.name, "node_modules") or std.mem.eql(u8, entry.name, "zig-out") or std.mem.eql(u8, entry.name, "zig-pkg")) continue;
                if (entry.kind == .sym_link) continue;
                if (entry.kind != .directory and entry.kind != .unknown and !std.mem.endsWith(u8, entry.name, ".transit")) continue;
                const child = try std.fs.path.join(self.a, &.{ absolute, entry.name });
                self.collect(child, depth + 1, false) catch |err| try self.noteFailure(child, err);
            }
        },
        .file => {
            if (!std.mem.endsWith(u8, name, ".transit")) {
                if (explicit) return error.ExpectedTransitFile;
                return;
            }
            if (self.files.count() >= 4096 and !self.files.contains(absolute)) return error.SourceFileLimit;
            try self.files.put(absolute, {});
        },
        .sym_link => if (explicit) return error.UnsupportedSourceFileKind,
        else => if (explicit or std.mem.endsWith(u8, name, ".transit")) return error.UnsupportedSourceFileKind,
    }
}

fn formatFile(self: Self, a: std.mem.Allocator, path: []const u8, check: bool, detail: *Failure) !bool {
    const parent = try Sources.openRoot(self.io, std.fs.path.dirname(path).?);
    defer parent.close(self.io);
    const name = std.fs.path.basename(path);
    const before = try parent.statFile(self.io, name, .{ .follow_symlinks = false });
    const original = try Sources.read(a, self.io, parent, name, file_limit);
    const output = try formatted(a, original, detail);
    if (std.mem.eql(u8, original, output)) return false;
    if (check) return true;
    if (before.nlink != 1) return error.HardLinkedSource;
    if (before.permissions.toMode() & 0o222 == 0) return error.AccessDenied;
    var replacement = try parent.createFileAtomic(self.io, name, .{ .replace = true, .permissions = before.permissions });
    defer replacement.deinit(self.io);
    try replacement.file.writeStreamingAll(self.io, output);
    try replacement.file.setPermissions(self.io, before.permissions);
    try replacement.file.sync(self.io);
    // Catch edits/replacements made while parsing, before the atomic rename.
    const latest = try Sources.read(a, self.io, parent, name, file_limit);
    const after = try parent.statFile(self.io, name, .{ .follow_symlinks = false });
    if (before.inode != after.inode or before.nlink != after.nlink or !std.meta.eql(before.mtime, after.mtime) or !std.meta.eql(before.ctime, after.ctime) or !std.mem.eql(u8, original, latest)) return error.SourceChangedDuringFormat;
    try replacement.replace(self.io);
    try Sources.syncDirectory(parent);
    return true;
}

fn formatted(a: std.mem.Allocator, text: []const u8, detail: *Failure) ![]const u8 {
    var offset: usize = 0;
    const file = c.Syntax.parseReported(a, text, &offset, null, &detail.report) catch |err| {
        detail.line = 1;
        const end = @min(text.len, if (detail.report.has_span) detail.report.span.start else offset);
        for (text[0..end]) |byte| {
            if (byte == '\n') {
                detail.line.? += 1;
                detail.column = 1;
            } else detail.column += 1;
        }
        return err;
    };
    var writer: std.Io.Writer = .fixed(try a.alloc(u8, file_limit));
    c.Format.source(a, text, file, &writer) catch |err| return if (err == error.WriteFailed) error.SourceFileBytesLimit else err;
    const output = writer.buffered();
    // Never publish output which no longer satisfies the production grammar.
    _ = try c.Syntax.parse(a, output, &offset);
    return output;
}

fn formatStdin(a: std.mem.Allocator, io: std.Io, detail: *Failure) !void {
    var reader = std.Io.File.stdin().readerStreaming(io, &.{});
    const text = try reader.interface.allocRemaining(a, .limited(file_limit + 1));
    if (text.len > file_limit) return error.SourceReadLimit;
    const output = try formatted(a, text, detail);
    try std.Io.File.stdout().writeStreamingAll(io, output);
}

fn emitFailure(io: std.Io, path: []const u8, detail: *Failure, err: anyerror) !void {
    detail.report.finalize(err, .{});
    const message = switch (err) {
        error.ExpectedTransitFile => "expected a .transit file or directory",
        error.HardLinkedSource => "cannot replace a file with multiple hard links",
        error.SourceChangedDuringFormat => "source changed while formatting; retry",
        error.AccessDenied => "permission denied",
        error.FileNotFound => "path does not exist",
        error.SourceReadLimit, error.SourceFileBytesLimit => "formatting exceeds the 1 MiB source file limit",
        else => detail.report.headline() orelse @errorName(err),
    };
    var buffer: [4096]u8 = undefined;
    var out = std.Io.File.stderr().writerStreaming(io, &buffer);
    try escaped(&out.interface, path);
    if (detail.line) |line| try out.interface.print(":{d}:{d}", .{ line, detail.column });
    try out.interface.writeAll(": error: ");
    try escaped(&out.interface, message);
    try out.interface.writeByte('\n');
    try out.interface.flush();
}
