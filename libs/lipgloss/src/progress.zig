const std = @import("std");
const Color = @import("color.zig").Color;
const Buffer = @import("buffer.zig").Buffer;

pub const Progress = struct {
    width: usize = 40,
    full_char: []const u8 = "█",
    empty_char: []const u8 = "░",
    smooth: bool = true,
    full_color_start: Color = Color.hex("#5A56E0"), // Charm default blend
    full_color_end: Color = Color.hex("#EE6FF8"),
    empty_color: Color = Color.hex("#2B2B3B"),
    show_percentage: bool = true,
    percentage_color: Color = Color.hex("#E0E0E0"),

    const fractions = [_][]const u8{
        " ", "▏", "▎", "▍", "▌", "▋", "▊", "▉",
    };

    pub fn init() Progress {
        return .{};
    }

    pub fn setWidth(self: *Progress, w: usize) *Progress {
        self.width = w;
        return self;
    }

    pub fn setGradient(self: *Progress, start: Color, end: Color) *Progress {
        self.full_color_start = start;
        self.full_color_end = end;
        return self;
    }

    pub fn setEmptyColor(self: *Progress, c: Color) *Progress {
        self.empty_color = c;
        return self;
    }

    pub fn setChars(self: *Progress, full: []const u8, empty: []const u8) *Progress {
        self.full_char = full;
        self.empty_char = empty;
        return self;
    }

    pub fn setSmooth(self: *Progress, s: bool) *Progress {
        self.smooth = s;
        return self;
    }

    pub fn showPercent(self: *Progress, show: bool) *Progress {
        self.show_percentage = show;
        return self;
    }

    // Presets
    pub fn charm() Progress {
        var p = Progress.init();
        _ = p.setGradient(Color.hex("#5A56E0"), Color.hex("#EE6FF8"));
        return p;
    }

    pub fn sunset() Progress {
        var p = Progress.init();
        _ = p.setGradient(Color.hex("#FF416C"), Color.hex("#FF4B2B"));
        return p;
    }

    pub fn cyberpunk() Progress {
        var p = Progress.init();
        _ = p.setGradient(Color.hex("#00F2FE"), Color.hex("#4FACFE"));
        return p;
    }

    pub fn emerald() Progress {
        var p = Progress.init();
        _ = p.setGradient(Color.hex("#11998E"), Color.hex("#38EF7D"));
        return p;
    }

    pub fn rainbow() Progress {
        var p = Progress.init();
        _ = p.setGradient(Color.hex("#FF007F"), Color.hex("#7928CA"));
        return p;
    }

    /// Renders the progress bar for a given fraction 0.0 .. 1.0
    pub fn viewAs(self: Progress, allocator: std.mem.Allocator, percent: f32) ![]u8 {
        const clamped = std.math.clamp(percent, 0.0, 1.0);
        var buf = Buffer.init(allocator);
        defer buf.deinit();

        const bar_w = self.width;
        const total_units = @as(f32, @floatFromInt(bar_w)) * clamped;
        const full_cells: usize = @intFromFloat(@floor(total_units));
        const fraction_part = total_units - @floor(total_units);
        const frac_idx: usize = @min(7, @as(usize, @intFromFloat(fraction_part * 8.0)));

        const r1 = (self.full_color_start.val >> 16) & 0xFF;
        const g1 = (self.full_color_start.val >> 8) & 0xFF;
        const b1 = self.full_color_start.val & 0xFF;

        const r2 = (self.full_color_end.val >> 16) & 0xFF;
        const g2 = (self.full_color_end.val >> 8) & 0xFF;
        const b2 = self.full_color_end.val & 0xFF;

        for (0..bar_w) |i| {
            const t: f32 = if (bar_w > 1) @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(bar_w - 1)) else 0.0;
            const r: u8 = @intFromFloat(@as(f32, @floatFromInt(r1)) * (1.0 - t) + @as(f32, @floatFromInt(r2)) * t);
            const g: u8 = @intFromFloat(@as(f32, @floatFromInt(g1)) * (1.0 - t) + @as(f32, @floatFromInt(g2)) * t);
            const b: u8 = @intFromFloat(@as(f32, @floatFromInt(b1)) * (1.0 - t) + @as(f32, @floatFromInt(b2)) * t);
            const c = Color.rgb(r, g, b);

            if (i < full_cells) {
                try c.writeAnsi(&buf, false);
                try buf.writeAll(self.full_char);
            } else if (i == full_cells and self.smooth and frac_idx > 0) {
                try c.writeAnsi(&buf, false);
                try buf.writeAll(fractions[frac_idx]);
            } else {
                try self.empty_color.writeAnsi(&buf, false);
                try buf.writeAll(self.empty_char);
            }
        }

        try buf.writeAll("\x1b[0m");

        if (self.show_percentage) {
            try self.percentage_color.writeAnsi(&buf, false);
            try buf.print(" {d: >3.0}%", .{clamped * 100.0});
            try buf.writeAll("\x1b[0m");
        }

        return buf.toOwnedSlice();
    }
};

test "progress render" {
    const testing = std.testing;
    var p = Progress.charm();
    _ = p.setWidth(20);

    const res_0 = try p.viewAs(testing.allocator, 0.0);
    defer testing.allocator.free(res_0);
    try testing.expect(res_0.len > 0);

    const res_50 = try p.viewAs(testing.allocator, 0.5);
    defer testing.allocator.free(res_50);
    try testing.expect(std.mem.indexOf(u8, res_50, "50%") != null);

    const res_100 = try p.viewAs(testing.allocator, 1.0);
    defer testing.allocator.free(res_100);
    try testing.expect(std.mem.indexOf(u8, res_100, "100%") != null);
}
