const std = @import("std");

pub const CursorStyle = enum {
    default_style,
    block,
    underline,
    bar,

    pub const default = CursorStyle.default_style;
};

pub const Cursor = struct {
    x: i32 = 0,
    y: i32 = 0,
    visible: bool = true,
    blink: bool = false,
    style: CursorStyle = .default_style,

    pub fn toAnsi(self: Cursor, writer: anytype) !void {
        // Move cursor: CSI line ; col H (1-based)
        if (self.visible) {
            try writer.print("\x1b[{d};{d}H", .{ self.y + 1, self.x + 1 });
            try writer.writeAll("\x1b[?25h"); // Show cursor

            // Cursor style escape codes
            const code: u8 = switch (self.style) {
                .block => if (self.blink) 1 else 2,
                .underline => if (self.blink) 3 else 4,
                .bar => if (self.blink) 5 else 6,
                .default_style => 0,
            };
            if (code > 0) {
                try writer.print("\x1b[{d} q", .{code});
            }
        } else {
            try writer.writeAll("\x1b[?25l"); // Hide cursor
        }
    }
};
