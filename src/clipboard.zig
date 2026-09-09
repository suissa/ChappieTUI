const std = @import("std");

pub const ClipboardSelection = enum(u8) {
    clipboard = 'c',
    primary = 'p',
};

pub const ClipboardMsg = struct {
    content: []const u8,
    selection: ClipboardSelection = .clipboard,
};

pub fn formatSetClipboard(allocator: std.mem.Allocator, text: []const u8, selection: ClipboardSelection) ![]u8 {
    const encoder = std.base64.standard.Encoder;
    const b64_len = encoder.calcSize(text.len);
    const b64_buf = try allocator.alloc(u8, b64_len);
    defer allocator.free(b64_buf);
    _ = encoder.encode(b64_buf, text);

    return std.fmt.allocPrint(allocator, "\x1b]52;{c};{s}\x07", .{ @intFromEnum(selection), b64_buf });
}

pub fn formatReadClipboard(allocator: std.mem.Allocator, selection: ClipboardSelection) ![]u8 {
    return std.fmt.allocPrint(allocator, "\x1b]52;{c};?\x07", .{@intFromEnum(selection)});
}

test "clipboard formatting" {
    const testing = std.testing;
    const s = try formatSetClipboard(testing.allocator, "hello", .clipboard);
    defer testing.allocator.free(s);
    try testing.expect(std.mem.startsWith(u8, s, "\x1b]52;c;"));
}
