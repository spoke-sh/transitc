//! Exact decimal spelling after the native binder has checked precision/scale.
const std = @import("std");
const Numeric = @import("SourceTypes.zig").Numeric;

pub fn write(writer: anytype, value: Numeric) !void {
    var buffer: [40]u8 = undefined;
    const digits = try std.fmt.bufPrint(&buffer, "{d}", .{@abs(value.coefficient)});
    if (value.coefficient < 0) try writer.writeByte('-');
    const scale = value.type.scale;
    if (scale == 0) return writer.writeAll(digits);
    if (digits.len > scale) {
        try writer.writeAll(digits[0 .. digits.len - scale]);
        try writer.writeByte('.');
        try writer.writeAll(digits[digits.len - scale ..]);
    } else {
        try writer.writeAll("0.");
        for (0..scale - digits.len) |_| try writer.writeByte('0');
        try writer.writeAll(digits);
    }
}
