const std = @import("std");

pub const KeyCode = enum {
    none,
    character,
    up,
    down,
    right,
    left,
    home,
    end,
    page_up,
    page_down,
    insert,
    delete,
    enter,
    escape,
    tab,
    backspace,
    f1,
    f2,
    f3,
    f4,
    f5,
    f6,
    f7,
    f8,
    f9,
    f10,
    f11,
    f12,
};

pub const Key = struct {
    code: KeyCode = .none,
    char: u21 = 0,
    ctrl: bool = false,
    alt: bool = false,
    shift: bool = false,
    is_repeat: bool = false,

    /// Returns true if this key matches the given string representation,
    /// e.g. "ctrl+c", "q", "up", "enter", "space", "shift+tab".
    pub fn matches(self: Key, repr: []const u8) bool {
        var buf: [32]u8 = undefined;
        const str = self.toString(&buf);
        return std.mem.eql(u8, str, repr);
    }

    /// Formats key into canonical Bubble Tea string notation, e.g. "ctrl+c", "q", "up".
    pub fn toString(self: Key, buf: []u8) []const u8 {
        var len: usize = 0;
        const append = struct {
            fn f(b: []u8, l: *usize, str: []const u8) void {
                if (l.* + str.len <= b.len) {
                    @memcpy(b[l.* .. l.* + str.len], str);
                    l.* += str.len;
                }
            }
        }.f;

        if (self.ctrl) append(buf, &len, "ctrl+");
        if (self.alt) append(buf, &len, "alt+");
        if (self.shift and self.code != .character) append(buf, &len, "shift+");

        switch (self.code) {
            .character => {
                if (self.char == ' ') {
                    append(buf, &len, "space");
                } else if (self.char < 128) {
                    if (len < buf.len) {
                        buf[len] = @intCast(self.char);
                        len += 1;
                    }
                } else {
                    var utf8_buf: [4]u8 = undefined;
                    const ulen = std.unicode.utf8Encode(@intCast(self.char), &utf8_buf) catch 0;
                    append(buf, &len, utf8_buf[0..ulen]);
                }
            },
            .up => append(buf, &len, "up"),
            .down => append(buf, &len, "down"),
            .left => append(buf, &len, "left"),
            .right => append(buf, &len, "right"),
            .enter => append(buf, &len, "enter"),
            .escape => append(buf, &len, "esc"),
            .tab => append(buf, &len, "tab"),
            .backspace => append(buf, &len, "backspace"),
            .delete => append(buf, &len, "delete"),
            .insert => append(buf, &len, "insert"),
            .home => append(buf, &len, "home"),
            .end => append(buf, &len, "end"),
            .page_up => append(buf, &len, "pgup"),
            .page_down => append(buf, &len, "pgdown"),
            .f1 => append(buf, &len, "f1"),
            .f2 => append(buf, &len, "f2"),
            .f3 => append(buf, &len, "f3"),
            .f4 => append(buf, &len, "f4"),
            .f5 => append(buf, &len, "f5"),
            .f6 => append(buf, &len, "f6"),
            .f7 => append(buf, &len, "f7"),
            .f8 => append(buf, &len, "f8"),
            .f9 => append(buf, &len, "f9"),
            .f10 => append(buf, &len, "f10"),
            .f11 => append(buf, &len, "f11"),
            .f12 => append(buf, &len, "f12"),
            .none => append(buf, &len, "none"),
        }

        return buf[0..len];
    }

    /// Parses an input byte slice (which may start with an ANSI sequence) into a Key.
    /// Returns the parsed Key and the number of bytes consumed.
    pub fn parse(bytes: []const u8) ?struct { key: Key, consumed: usize } {
        if (bytes.len == 0) return null;

        // Escape sequence
        if (bytes[0] == 0x1B) {
            if (bytes.len == 1) {
                return .{ .key = .{ .code = .escape }, .consumed = 1 };
            }

            // CSI sequence: ESC [
            if (bytes[1] == '[') {
                if (bytes.len == 2) return null; // Incomplete sequence

                // Shift-Tab: ESC [ Z
                if (bytes[2] == 'Z') {
                    return .{ .key = .{ .code = .tab, .shift = true }, .consumed = 3 };
                }

                // Arrow keys: ESC [ A / B / C / D
                if (bytes[2] == 'A') return .{ .key = .{ .code = .up }, .consumed = 3 };
                if (bytes[2] == 'B') return .{ .key = .{ .code = .down }, .consumed = 3 };
                if (bytes[2] == 'C') return .{ .key = .{ .code = .right }, .consumed = 3 };
                if (bytes[2] == 'D') return .{ .key = .{ .code = .left }, .consumed = 3 };
                if (bytes[2] == 'H') return .{ .key = .{ .code = .home }, .consumed = 3 };
                if (bytes[2] == 'F') return .{ .key = .{ .code = .end }, .consumed = 3 };

                // Extended CSI keys: ESC [ <num> ~
                var i: usize = 2;
                while (i < bytes.len and (bytes[i] >= '0' and bytes[i] <= '9' or bytes[i] == ';')) : (i += 1) {}
                if (i < bytes.len and bytes[i] == '~') {
                    const seq = bytes[2..i];
                    var num: u32 = 0;
                    var mod: u32 = 0;
                    var has_mod = false;
                    var cur: u32 = 0;
                    for (seq) |c| {
                        if (c >= '0' and c <= '9') {
                            cur = cur * 10 + (c - '0');
                        } else if (c == ';') {
                            num = cur;
                            cur = 0;
                            has_mod = true;
                        }
                    }
                    if (has_mod) {
                        mod = cur;
                    } else {
                        num = cur;
                    }

                    var key: Key = .{};
                    switch (num) {
                        1, 7 => key.code = .home,
                        2 => key.code = .insert,
                        3 => key.code = .delete,
                        4, 8 => key.code = .end,
                        5 => key.code = .page_up,
                        6 => key.code = .page_down,
                        11...15 => key.code = @enumFromInt(@intFromEnum(KeyCode.f1) + (num - 11)),
                        17...21 => key.code = @enumFromInt(@intFromEnum(KeyCode.f6) + (num - 17)),
                        23...24 => key.code = @enumFromInt(@intFromEnum(KeyCode.f11) + (num - 23)),
                        else => key.code = .none,
                    }

                    if (mod > 0) {
                        applyModifier(&key, mod);
                    }
                    return .{ .key = key, .consumed = i + 1 };
                }

                // CSI with modifier: ESC [ 1 ; <mod> <A/B/C/D>
                if (i < bytes.len and (bytes[i] == 'A' or bytes[i] == 'B' or bytes[i] == 'C' or bytes[i] == 'D' or bytes[i] == 'H' or bytes[i] == 'F')) {
                    var key: Key = switch (bytes[i]) {
                        'A' => .{ .code = .up },
                        'B' => .{ .code = .down },
                        'C' => .{ .code = .right },
                        'D' => .{ .code = .left },
                        'H' => .{ .code = .home },
                        'F' => .{ .code = .end },
                        else => .{ .code = .none },
                    };
                    const seq = bytes[2..i];
                    if (std.mem.indexOfScalar(u8, seq, ';')) |semi| {
                        if (semi + 1 < seq.len) {
                            const mod_val = std.fmt.parseInt(u32, seq[semi + 1 ..], 10) catch 0;
                            applyModifier(&key, mod_val);
                        }
                    }
                    return .{ .key = key, .consumed = i + 1 };
                }

                return .{ .key = .{ .code = .escape }, .consumed = 2 };
            }

            // SS3: ESC O <letter> (F1-F4)
            if (bytes[1] == 'O' and bytes.len >= 3) {
                const code: KeyCode = switch (bytes[2]) {
                    'P' => .f1,
                    'Q' => .f2,
                    'R' => .f3,
                    'S' => .f4,
                    else => .none,
                };
                if (code != .none) {
                    return .{ .key = .{ .code = code }, .consumed = 3 };
                }
            }

            // Alt + character: ESC <char>
            var key: Key = .{ .alt = true };
            const sub = parse(bytes[1..]);
            if (sub) |s| {
                key.code = s.key.code;
                key.char = s.key.char;
                key.ctrl = s.key.ctrl;
                key.shift = s.key.shift;
                return .{ .key = key, .consumed = 1 + s.consumed };
            }

            return .{ .key = .{ .code = .escape }, .consumed = 1 };
        }

        const b = bytes[0];

        // Control characters: 0x01 .. 0x1A (Ctrl+A .. Ctrl+Z)
        if (b >= 1 and b <= 26) {
            if (b == 9) { // Tab
                return .{ .key = .{ .code = .tab }, .consumed = 1 };
            }
            if (b == 10 or b == 13) { // Enter / Return
                return .{ .key = .{ .code = .enter }, .consumed = 1 };
            }
            return .{
                .key = .{
                    .code = .character,
                    .char = 'a' + (b - 1),
                    .ctrl = true,
                },
                .consumed = 1,
            };
        }

        // Backspace / Delete
        if (b == 0x7F or b == 0x08) {
            return .{ .key = .{ .code = .backspace }, .consumed = 1 };
        }

        // Space
        if (b == ' ') {
            return .{ .key = .{ .code = .character, .char = ' ' }, .consumed = 1 };
        }

        // Single byte ASCII
        if (b >= 32 and b < 127) {
            return .{
                .key = .{
                    .code = .character,
                    .char = b,
                    .shift = (b >= 'A' and b <= 'Z'),
                },
                .consumed = 1,
            };
        }

        // Multi-byte UTF-8 character
        const utf8_len = std.unicode.utf8ByteSequenceLength(b) catch 1;
        if (bytes.len >= utf8_len) {
            const cp = std.unicode.utf8Decode(bytes[0..utf8_len]) catch b;
            return .{
                .key = .{
                    .code = .character,
                    .char = cp,
                },
                .consumed = utf8_len,
            };
        }

        return .{
            .key = .{ .code = .character, .char = b },
            .consumed = 1,
        };
    }

    fn applyModifier(key: *Key, mod: u32) void {
        // Standard Xterm modifiers:
        // 2 = Shift, 3 = Alt, 4 = Shift+Alt, 5 = Ctrl, 6 = Ctrl+Shift, 7 = Ctrl+Alt, 8 = Ctrl+Alt+Shift
        switch (mod) {
            2 => key.shift = true,
            3 => key.alt = true,
            4 => {
                key.shift = true;
                key.alt = true;
            },
            5 => key.ctrl = true,
            6 => {
                key.ctrl = true;
                key.shift = true;
            },
            7 => {
                key.ctrl = true;
                key.alt = true;
            },
            8 => {
                key.ctrl = true;
                key.alt = true;
                key.shift = true;
            },
            else => {},
        }
    }
};

test "key parsing and matching" {
    const k_ctrl_c = Key.parse("\x03").?.key;
    try std.testing.expect(k_ctrl_c.matches("ctrl+c"));

    const k_q = Key.parse("q").?.key;
    try std.testing.expect(k_q.matches("q"));

    const k_up = Key.parse("\x1b[A").?.key;
    try std.testing.expect(k_up.matches("up"));

    const k_down = Key.parse("\x1b[B").?.key;
    try std.testing.expect(k_down.matches("down"));

    const k_shift_tab = Key.parse("\x1b[Z").?.key;
    try std.testing.expect(k_shift_tab.matches("shift+tab"));

    const k_enter = Key.parse("\r").?.key;
    try std.testing.expect(k_enter.matches("enter"));
}
