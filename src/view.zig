const std = @import("std");
pub const Cursor = @import("cursor.zig").Cursor;
pub const MouseMode = @import("mouse.zig").MouseMode;

pub const View = struct {
    content: []const u8 = "",
    window_title: ?[]const u8 = null,
    cursor: ?Cursor = null,
    alt_screen: bool = false,
    mouse_mode: MouseMode = .none,
    report_focus: bool = false,

    pub fn init(content: []const u8) View {
        return .{ .content = content };
    }
};
