const std = @import("std");

pub const MouseButton = enum {
    none,
    left,
    middle,
    right,
    wheel_up,
    wheel_down,
    wheel_left,
    wheel_right,
};

pub const MouseAction = enum {
    press,
    release,
    motion,
};

pub const MouseMode = enum {
    none,
    cell_motion,
    all_motion,
};

pub const MouseMsg = struct {
    x: i32 = 0,
    y: i32 = 0,
    button: MouseButton = .none,
    action: MouseAction = .press,
    alt: bool = false,
    ctrl: bool = false,
    shift: bool = false,

    /// Parses an SGR mouse sequence: ESC [ < b ; x ; y M (or m)
    pub fn parseSGR(bytes: []const u8) ?struct { msg: MouseMsg, consumed: usize } {
        if (bytes.len < 6) return null;
        if (bytes[0] != 0x1B or bytes[1] != '[' or bytes[2] != '<') return null;

        var i: usize = 3;
        var parts: [3]i32 = .{ 0, 0, 0 };
        var part_idx: usize = 0;

        while (i < bytes.len and (bytes[i] >= '0' and bytes[i] <= '9' or bytes[i] == ';')) : (i += 1) {
            if (bytes[i] == ';') {
                part_idx += 1;
                if (part_idx >= 3) return null;
            } else {
                parts[part_idx] = parts[part_idx] * 10 + (bytes[i] - '0');
            }
        }

        if (i >= bytes.len) return null;
        const term_char = bytes[i];
        if (term_char != 'M' and term_char != 'm') return null;

        const b = parts[0];
        const x = parts[1] - 1; // 1-based to 0-based
        const y = parts[2] - 1;

        var msg: MouseMsg = .{
            .x = x,
            .y = y,
            .shift = (b & 4) != 0,
            .alt = (b & 8) != 0,
            .ctrl = (b & 16) != 0,
        };

        if (term_char == 'm') {
            msg.action = .release;
        } else if ((b & 32) != 0) {
            msg.action = .motion;
        } else {
            msg.action = .press;
        }

        const button_code = b & 3;
        if ((b & 64) != 0) {
            if (button_code == 0) {
                msg.button = .wheel_up;
            } else if (button_code == 1) {
                msg.button = .wheel_down;
            } else if (button_code == 2) {
                msg.button = .wheel_left;
            } else if (button_code == 3) {
                msg.button = .wheel_right;
            }
        } else {
            switch (button_code) {
                0 => msg.button = .left,
                1 => msg.button = .middle,
                2 => msg.button = .right,
                else => msg.button = .none,
            }
        }

        return .{ .msg = msg, .consumed = i + 1 };
    }
};

test "mouse SGR parsing" {
    // Left click at (10, 20) -> 1-based (11, 21): ESC [ < 0 ; 11 ; 21 M
    const parsed = MouseMsg.parseSGR("\x1b[<0;11;21M").?;
    try std.testing.expectEqual(@as(i32, 10), parsed.msg.x);
    try std.testing.expectEqual(@as(i32, 20), parsed.msg.y);
    try std.testing.expectEqual(MouseButton.left, parsed.msg.button);
    try std.testing.expectEqual(MouseAction.press, parsed.msg.action);
}
