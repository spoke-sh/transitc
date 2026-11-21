//! Comment-preserving layout of validated source. Never rewrites syntax or literals.
const std = @import("std");
const f = @import("transit_sql_frontend");
const s = @import("Syntax.zig");
const Self = @This();
const Mark = struct { depth: u8 = 0, before: bool = false, after: bool = false, identifier: bool = false, space: bool = false };
text: []const u8,
tokens: []const s.Token,
marks: []Mark,

/// `file` must be the production parse of `text`. Allocation and output are caller-bounded.
pub fn write(a: std.mem.Allocator, text: []const u8, file: s.File, writer: *std.Io.Writer) !void {
    var scan = try f.SqlInput.CompilerScan.init(text);
    var tokens: std.ArrayList(s.Token) = .empty;
    defer tokens.deinit(a);
    while (try scan.next()) |token| if (token.kind != .space) try tokens.append(a, token);
    const marks = try a.alloc(Mark, tokens.items.len);
    defer a.free(marks);
    @memset(marks, .{});
    const self: Self = .{ .text = text, .tokens = tokens.items, .marks = marks };
    for (self.tokens, 0..) |_, i| if (self.is(i, ";")) {
        self.marks[i].after = true;
    };
    for (file.identifiers) |span| self.marks[self.index(span.start)].identifier = true;
    for (file.imports) |item| self.statementBoundary(item.span);
    for (file.dependencies) |item| self.statementBoundary(item.span);
    for (file.defaults) |item| self.statementBoundary(item.span);
    for (file.definitions) |item| {
        self.statementBoundary(item.span);
        if (item.program) |program| {
            if (program.kind != .guard_requires) {
                const close = self.lastWord(item.span, "END");
                const first = if (program.tokens.len != 0) self.index(program.tokens[0].start) else close;
                const open = self.wordBefore(first, "BEGIN");
                self.block(open, close, 0);
            }
            self.sql(program);
        } else if (item.target_of == null and switch (item.kind) {
            .module, .target, .migration_target, .test_target => true,
            else => false,
        }) {
            try self.bodyBlock(item.span, item.body, 0);
        }
    }
    try self.statements(file.statements, 0);
    try self.render(writer);
}

fn index(self: Self, offset: u32) usize {
    var lo: usize = 0;
    var hi = self.tokens.len;
    while (lo < hi) {
        const mid = lo + (hi - lo) / 2;
        if (self.tokens[mid].start < offset) lo = mid + 1 else hi = mid;
    }
    return lo;
}
fn is(self: Self, i: usize, text: []const u8) bool {
    if (i >= self.tokens.len or self.tokens[i].kind == .comment) return false;
    const token = self.tokens[i];
    return std.ascii.eqlIgnoreCase(self.text[token.start..token.end], text);
}
fn wordBefore(self: Self, before: usize, word: []const u8) usize {
    var i = before;
    while (i != 0) {
        i -= 1;
        if (self.tokens[i].kind == .word and self.is(i, word)) return i;
    }
    unreachable; // The production AST establishes the opening/closing keyword.
}
fn lastWord(self: Self, span: s.Span, word: []const u8) usize {
    return self.wordBefore(self.index(span.end), word);
}
fn statementBoundary(self: Self, span: s.Span) void {
    const first = self.index(span.start);
    const end = self.index(span.end);
    if (first < end) {
        self.marks[first].before = true;
        self.marks[end - 1].after = true;
    }
}
fn block(self: Self, open: usize, close: usize, depth: u8) void {
    var header_end = open;
    // BEGIN ATOMIC is one header even with comments between the two words.
    var next = open + 1;
    while (next < close and self.tokens[next].kind == .comment) : (next += 1) {}
    if (self.is(open, "BEGIN") and self.is(next, "ATOMIC")) header_end = next;
    self.marks[header_end].after = true;
    for (self.marks[header_end + 1 .. close]) |*mark| mark.depth = depth + 1;
    self.marks[close].depth = depth;
    self.marks[close].before = true;
}
fn bodyBlock(self: Self, span: s.Span, body: []const s.Statement, depth: u8) !void {
    const close = self.lastWord(span, "END");
    const first = if (body.len != 0) self.index(body[0].span.start) else close;
    self.block(self.wordBefore(first, "BEGIN"), close, depth);
    try self.statements(body, depth + 1);
}
fn statements(self: Self, values: []const s.Statement, depth: u8) anyerror!void {
    // MATCH arms use two indentation levels per parser nesting level.
    if (depth > 128) return error.SourceDepthLimit;
    for (values) |item| {
        self.statementBoundary(item.span);
        switch (item.value) {
            .sql => |value| self.sql(value),
            .assertion => |value| {
                self.sql(value.sql);
                if (value.expected == .rows) self.sql(value.expected.rows);
            },
            .test_case => |value| try self.bodyBlock(item.span, value.body, depth),
            .conditional => |value| {
                const close = self.lastWord(item.span, "END");
                var then = self.index(value.condition.span.end);
                while (!self.is(then, "THEN")) : (then += 1) {}
                self.block(then, close, depth);
                if (value.no.len != 0) {
                    const otherwise = self.wordBefore(self.index(value.no[0].span.start), "ELSE");
                    self.marks[otherwise] = .{ .depth = depth, .before = true, .after = true };
                } else {
                    // Empty ELSE bodies are valid and must remain distinct from no ELSE.
                    const after_yes = if (value.yes.len != 0) self.index(value.yes[value.yes.len - 1].span.end) else then + 1;
                    for (after_yes..close) |i| if (self.is(i, "ELSE")) {
                        self.marks[i] = .{ .depth = depth, .before = true, .after = true };
                    };
                }
                try self.statements(value.yes, depth + 1);
                try self.statements(value.no, depth + 1);
            },
            .match => |value| {
                const close = self.lastWord(item.span, "END");
                self.marks[close].before = true;
                for (value.arms, 0..) |arm, n| {
                    const first = self.index(arm.span.start);
                    self.marks[first].before = true;
                    self.marks[first].depth = depth + 1;
                    const end = if (n + 1 < value.arms.len) self.index(value.arms[n + 1].span.start) else close;
                    const body_start = if (arm.body.len != 0) self.index(arm.body[0].span.start) else end;
                    self.block(self.wordBefore(body_start, "THEN"), end, depth + 1);
                    try self.statements(arm.body, depth + 2);
                }
                self.marks[close].depth = depth;
            },
            else => {},
        }
    }
}

fn sql(self: Self, value: s.Template.Syntax) void {
    for (value.identifiers) |token| self.marks[self.index(token.start)].identifier = true;
    for (value.blocks) |body| {
        const open = self.index(body.open);
        self.block(open, self.index(body.close), self.marks[open].depth);
    }
    // DDL column lists use a space after the resource name.
    if (switch (value.kind) {
        .create, .create_stream, .create_queue => true,
        else => false,
    }) for (value.tokens) |token| {
        const at = self.index(token.start);
        if (self.is(at, "(")) {
            self.marks[at].space = true;
            break;
        }
    };
}

fn spaceBefore(self: Self, i: usize) bool {
    if (i == 0) return false;
    const prev = self.tokens[i - 1];
    const current = self.tokens[i];
    if (current.kind == .comment) return true;
    if (prev.kind == .comment) return !(self.is(i, ";") or self.is(i, ",") or self.is(i, ")"));
    if (self.marks[i].space) return true;
    if (s.Template.joinsLexeme(self.text, self.tokens, i)) return false;
    if ((self.is(i - 1, "<") or self.is(i - 1, ">") or self.is(i - 1, "!")) and self.is(i, "=")) return false;
    if (self.is(i - 1, "<") and self.is(i, ">")) return false;
    if (self.is(i - 1, "=") and self.is(i, ">")) return false;
    if (self.is(i, ";") or self.is(i, ",") or self.is(i, ")") or self.is(i, ".") or self.is(i, "]") or self.is(i, ":")) return false;
    if (self.is(i - 1, "(") or self.is(i - 1, ".") or self.is(i - 1, "$") or self.is(i - 1, "[") or self.is(i - 1, ":")) return false;
    if ((self.is(i - 1, "-") or self.is(i - 1, "+")) and !self.is(i, "-")) {
        if (i == 1) return false;
        const before = self.tokens[i - 2];
        if ((before.kind == .symbol and !self.is(i - 2, ")")) or
            (!self.marks[i - 2].identifier and (self.is(i - 2, "RETURN") or self.is(i - 2, "THEN") or self.is(i - 2, "ELSE")))) return false;
    }
    if (self.is(i, "(")) {
        if (self.marks[i - 1].identifier) return false;
        inline for (.{ "VALUES", "IN", "AS", "MODULES", "SUITES", "WITH", "EQUAL", "ROWS", "COMMAND", "STATEMENT", "CONFLICT", "IF", "WHEN", "THEN", "ELSE", "NOT", "AND", "OR", "RETURN", "REQUIRE", "WHERE", "ON", "CHECK" }) |word| {
            if (self.is(i - 1, word)) return true;
        }
        return prev.kind == .symbol and !self.is(i - 1, ")");
    }
    return true;
}
fn render(self: Self, writer: *std.Io.Writer) !void {
    var line_start = true;
    var pending_break = false;
    for (self.tokens, self.marks, 0..) |token, mark, i| {
        const gap = self.text[if (i == 0) 0 else self.tokens[i - 1].end..token.start];
        const original_break = std.mem.indexOfAny(u8, gap, "\r\n") != null;
        const comment = token.kind == .comment;
        const follows_comment = i != 0 and self.tokens[i - 1].kind == .comment;
        const break_line = if (comment) original_break else pending_break or mark.before or follows_comment and original_break;
        if (break_line and !line_start) {
            try writer.writeByte('\n');
            if (std.mem.count(u8, gap, "\n") >= 2) try writer.writeByte('\n');
            line_start = true;
        }
        if (line_start) {
            for (0..mark.depth) |_| try writer.writeAll("  ");
        } else if (self.spaceBefore(i)) try writer.writeByte(' ');
        const raw = self.text[token.start..token.end];
        if (token.kind == .word and !mark.identifier and !s.Template.numericWord(self.text, token)) {
            for (raw) |byte| try writer.writeByte(std.ascii.toUpper(byte));
        } else try writer.writeAll(raw);
        line_start = raw.len != 0 and raw[raw.len - 1] == '\n';
        if (comment) {
            if (std.mem.startsWith(u8, raw, "--")) pending_break = true;
        } else pending_break = mark.after;
    }
    if (!line_start) try writer.writeByte('\n');
}
