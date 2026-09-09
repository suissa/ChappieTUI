const std = @import("std");
const builtin = @import("builtin");

pub const Profile = enum {
    ascii,
    ansi,
    ansi256,
    truecolor,

    pub fn detect() Profile {
        if (builtin.os.tag == .windows) {
            return .truecolor;
        }

        if (std.posix.getenv("COLORTERM")) |ct| {
            if (std.mem.eql(u8, ct, "truecolor") or std.mem.eql(u8, ct, "24bit")) {
                return .truecolor;
            }
        }

        if (std.posix.getenv("TERM")) |term| {
            if (std.mem.indexOf(u8, term, "256color") != null) {
                return .ansi256;
            }
            if (std.mem.eql(u8, term, "dumb")) {
                return .ascii;
            }
            return .ansi;
        }

        return .truecolor;
    }
};

pub const ColorType = enum {
    none,
    ansi16,
    ansi256,
    rgb,
};

pub const Color = struct {
    color_type: ColorType = .none,
    val: u32 = 0,

    pub fn none() Color {
        return .{ .color_type = .none, .val = 0 };
    }

    pub fn ansi16(code: u8) Color {
        return .{ .color_type = .ansi16, .val = code };
    }

    pub fn ansi256(code: u8) Color {
        return .{ .color_type = .ansi256, .val = code };
    }

    pub fn rgb(r: u8, g: u8, b: u8) Color {
        const val = (@as(u32, r) << 16) | (@as(u32, g) << 8) | @as(u32, b);
        return .{ .color_type = .rgb, .val = val };
    }

    pub fn hex(s: []const u8) Color {
        if (std.mem.startsWith(u8, s, "#")) {
            const str = s[1..];
            if (str.len == 6) {
                const val = std.fmt.parseInt(u32, str, 16) catch return .none();
                return .{ .color_type = .rgb, .val = val };
            } else if (str.len == 3) {
                const r_nib = std.fmt.parseInt(u8, str[0..1], 16) catch return .none();
                const g_nib = std.fmt.parseInt(u8, str[1..2], 16) catch return .none();
                const b_nib = std.fmt.parseInt(u8, str[2..3], 16) catch return .none();
                return rgb(r_nib * 17, g_nib * 17, b_nib * 17);
            }
        }

        // Check if decimal ANSI color 0-255
        if (std.fmt.parseInt(u8, s, 10)) |code| {
            return .{ .color_type = .ansi256, .val = code };
        } else |_| {}

        // Fallback: 6-character hex without '#'
        if (s.len == 6) {
            if (std.fmt.parseInt(u32, s, 16)) |val| {
                return .{ .color_type = .rgb, .val = val };
            } else |_| {}
        }

        return .none();
    }

    pub fn parse(s: []const u8) Color {
        return hex(s);
    }

    /// Downsamples this color to an ANSI 256 color index
    pub fn toAnsi256(self: Color) u8 {
        switch (self.color_type) {
            .none => return 0,
            .ansi16 => return @intCast(self.val & 0xFF),
            .ansi256 => return @intCast(self.val & 0xFF),
            .rgb => {
                const r: u8 = @intCast((self.val >> 16) & 0xFF);
                const g: u8 = @intCast((self.val >> 8) & 0xFF);
                const b: u8 = @intCast(self.val & 0xFF);

                // Grayscale ramp check
                if (r == g and g == b) {
                    if (r < 8) return 16;
                    if (r > 248) return 231;
                    return @intCast(232 + @divTrunc((@as(u16, r) - 8) * 24, 240));
                }

                // 6x6x6 color cube
                const r_idx: u8 = @intCast(@divTrunc(@as(u16, r) * 5, 255));
                const g_idx: u8 = @intCast(@divTrunc(@as(u16, g) * 5, 255));
                const b_idx: u8 = @intCast(@divTrunc(@as(u16, b) * 5, 255));
                return 16 + 36 * r_idx + 6 * g_idx + b_idx;
            },
        }
    }

    /// Writes the ANSI escape sequence for this color (foreground or background)
    pub fn writeAnsi(self: Color, writer: anytype, is_bg: bool) !void {
        const bg_offset: u8 = if (is_bg) 10 else 0;
        switch (self.color_type) {
            .none => {},
            .ansi16 => {
                const c = self.val;
                if (c < 8) {
                    try writer.print("\x1b[{d}m", .{(30 + bg_offset) + c});
                } else {
                    try writer.print("\x1b[{d}m", .{(90 + bg_offset) + (c - 8)});
                }
            },
            .ansi256 => {
                const prefix: []const u8 = if (is_bg) "48;5;" else "38;5;";
                try writer.print("\x1b[{s}{d}m", .{ prefix, self.val });
            },
            .rgb => {
                const r = (self.val >> 16) & 0xFF;
                const g = (self.val >> 8) & 0xFF;
                const b = self.val & 0xFF;
                const prefix: []const u8 = if (is_bg) "48;2;" else "38;2;";
                try writer.print("\x1b[{s}{d};{d};{d}m", .{ prefix, r, g, b });
            },
        }
    }
};

pub const AdaptiveColor = struct {
    light: Color,
    dark: Color,

    pub fn init(light_hex: []const u8, dark_hex: []const u8) AdaptiveColor {
        return .{
            .light = Color.hex(light_hex),
            .dark = Color.hex(dark_hex),
        };
    }

    pub fn resolve(self: AdaptiveColor, has_dark_bg: bool) Color {
        return if (has_dark_bg) self.dark else self.light;
    }
};

pub const CompleteColor = struct {
    truecolor: Color,
    ansi256: Color,
    ansi: Color,

    pub fn init(tc_hex: []const u8, a256: u8, a16: u8) CompleteColor {
        return .{
            .truecolor = Color.hex(tc_hex),
            .ansi256 = Color.ansi256(a256),
            .ansi = Color.ansi16(a16),
        };
    }

    pub fn resolve(self: CompleteColor, profile: Profile) Color {
        return switch (profile) {
            .truecolor => self.truecolor,
            .ansi256 => self.ansi256,
            .ansi => self.ansi,
            .ascii => .none(),
        };
    }
};

test "color hex parsing and downsampling" {
    const testing = std.testing;

    const c1 = Color.hex("#FF5733");
    try testing.expectEqual(ColorType.rgb, c1.color_type);

    const c2 = Color.hex("#F00");
    try testing.expectEqual(ColorType.rgb, c2.color_type);

    const c3 = Color.hex("205");
    try testing.expectEqual(ColorType.ansi256, c3.color_type);

    const idx = c1.toAnsi256();
    try testing.expect(idx >= 16);
}
