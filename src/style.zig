const std = @import("std");
const Buffer = @import("buffer.zig").Buffer;

pub const ColorType = enum {
    none,
    ansi16,
    ansi256,
    rgb,
};

pub const Color = struct {
    color_type: ColorType = .none,
    val: u32 = 0, // ANSI code or 0xRRGGBB

    pub fn none() Color {
        return .{ .color_type = .none };
    }

    pub fn ansi(code: u8) Color {
        return .{ .color_type = .ansi16, .val = code };
    }

    pub fn color256(code: u8) Color {
        return .{ .color_type = .ansi256, .val = code };
    }

    pub fn ansi256(code: u8) Color {
        return color256(code);
    }

    pub fn rgb(r: u8, g: u8, b: u8) Color {
        const val = (@as(u32, r) << 16) | (@as(u32, g) << 8) | @as(u32, b);
        return .{ .color_type = .rgb, .val = val };
    }

    pub fn hex(s: []const u8) Color {
        var str = s;
        if (std.mem.startsWith(u8, str, "#")) {
            str = str[1..];
        }
        if (str.len == 6) {
            const val = std.fmt.parseInt(u32, str, 16) catch return .none();
            return .{ .color_type = .rgb, .val = val };
        } else if (str.len <= 3) {
            const code = std.fmt.parseInt(u8, str, 10) catch return .none();
            return .{ .color_type = .ansi256, .val = code };
        }
        return .none();
    }
};

pub const Border = struct {
    top: []const u8 = "─",
    bottom: []const u8 = "─",
    left: []const u8 = "│",
    right: []const u8 = "│",
    top_left: []const u8 = "┌",
    top_right: []const u8 = "┐",
    bottom_left: []const u8 = "└",
    bottom_right: []const u8 = "┘",

    pub fn normal() Border {
        return .{
            .top = "─",
            .bottom = "─",
            .left = "│",
            .right = "│",
            .top_left = "┌",
            .top_right = "┐",
            .bottom_left = "└",
            .bottom_right = "┘",
        };
    }

    pub fn rounded() Border {
        return .{
            .top = "─",
            .bottom = "─",
            .left = "│",
            .right = "│",
            .top_left = "╭",
            .top_right = "╮",
            .bottom_left = "╰",
            .bottom_right = "╯",
        };
    }

    pub fn double() Border {
        return .{
            .top = "═",
            .bottom = "═",
            .left = "║",
            .right = "║",
            .top_left = "╔",
            .top_right = "╗",
            .bottom_left = "╚",
            .bottom_right = "╝",
        };
    }
};

pub const Align = enum {
    left,
    center,
    right,
};

pub const Style = struct {
    fg: Color = .none(),
    bg: Color = .none(),
    bold: bool = false,
    italic: bool = false,
    underline: bool = false,
    dim: bool = false,
    reverse: bool = false,

    padding_top: usize = 0,
    padding_right: usize = 0,
    padding_bottom: usize = 0,
    padding_left: usize = 0,

    margin_top: usize = 0,
    margin_right: usize = 0,
    margin_bottom: usize = 0,
    margin_left: usize = 0,

    border: ?Border = null,
    border_fg: Color = .none(),
    border_top: bool = true,
    border_bottom: bool = true,
    border_left: bool = true,
    border_right: bool = true,

    width: ?usize = null,
    height: ?usize = null,
    align_mode: Align = .left,

    pub fn init() Style {
        return .{};
    }

    pub fn foreground(self: Style, color: Color) Style {
        var s = self;
        s.fg = color;
        return s;
    }

    pub fn background(self: Style, color: Color) Style {
        var s = self;
        s.bg = color;
        return s;
    }

    pub fn setBold(self: Style, b: bool) Style {
        var s = self;
        s.bold = b;
        return s;
    }

    pub fn setItalic(self: Style, i: bool) Style {
        var s = self;
        s.italic = i;
        return s;
    }

    pub fn setUnderline(self: Style, u: bool) Style {
        var s = self;
        s.underline = u;
        return s;
    }

    pub fn setDim(self: Style, d: bool) Style {
        var s = self;
        s.dim = d;
        return s;
    }

    pub fn padding(self: Style, top: usize, right: usize, bottom: usize, left: usize) Style {
        var s = self;
        s.padding_top = top;
        s.padding_right = right;
        s.padding_bottom = bottom;
        s.padding_left = left;
        return s;
    }

    pub fn paddingLeft(self: Style, val: usize) Style {
        var s = self;
        s.padding_left = val;
        return s;
    }

    pub fn paddingRight(self: Style, val: usize) Style {
        var s = self;
        s.padding_right = val;
        return s;
    }

    pub fn paddingTop(self: Style, val: usize) Style {
        var s = self;
        s.padding_top = val;
        return s;
    }

    pub fn paddingBottom(self: Style, val: usize) Style {
        var s = self;
        s.padding_bottom = val;
        return s;
    }

    pub fn margin(self: Style, top: usize, right: usize, bottom: usize, left: usize) Style {
        var s = self;
        s.margin_top = top;
        s.margin_right = right;
        s.margin_bottom = bottom;
        s.margin_left = left;
        return s;
    }

    pub fn marginLeft(self: Style, val: usize) Style {
        var s = self;
        s.margin_left = val;
        return s;
    }

    pub fn setBorder(self: Style, b: Border) Style {
        var s = self;
        s.border = b;
        return s;
    }

    pub fn borderForeground(self: Style, color: Color) Style {
        var s = self;
        s.border_fg = color;
        return s;
    }

    pub fn borderColor(self: Style, color: Color) Style {
        return self.borderForeground(color);
    }

    pub fn unsetBorderTop(self: Style) Style {
        var s = self;
        s.border_top = false;
        return s;
    }

    pub fn unsetBorderBottom(self: Style) Style {
        var s = self;
        s.border_bottom = false;
        return s;
    }

    pub fn setWidth(self: Style, w: usize) Style {
        var s = self;
        s.width = w;
        return s;
    }

    pub fn setHeight(self: Style, h: usize) Style {
        var s = self;
        s.height = h;
        return s;
    }

    pub fn setAlign(self: Style, a: Align) Style {
        var s = self;
        s.align_mode = a;
        return s;
    }

    /// Renders text with styles into a newly allocated string.
    /// Renders text with styles into a newly allocated string.
    pub fn render(self: Style, allocator: std.mem.Allocator, text: []const u8) ![]const u8 {
        var writer = Buffer.init(allocator);
        defer writer.deinit();

        // Split incoming text into lines
        var line_it = std.mem.splitScalar(u8, text, '\n');
        var raw_lines: std.ArrayList([]const u8) = .empty;
        defer raw_lines.deinit(allocator);

        var max_line_len: usize = 0;
        while (line_it.next()) |line| {
            try raw_lines.append(allocator, line);
            if (line.len > max_line_len) max_line_len = line.len;
        }

        const effective_width = if (self.width) |w| @max(w, max_line_len) else max_line_len;

        // Top margin
        for (0..self.margin_top) |_| {
            try writer.writeByte('\n');
        }

        // Top border
        if (self.border) |b| {
            if (self.border_top) {
                // Left margin
                for (0..self.margin_left) |_| try writer.writeByte(' ');

                try writeColor(&writer, self.border_fg, false);
                if (self.border_left) try writer.writeAll(b.top_left);
                const border_width = effective_width + self.padding_left + self.padding_right;
                for (0..border_width) |_| try writer.writeAll(b.top);
                if (self.border_right) try writer.writeAll(b.top_right);
                try writeReset(&writer);
                try writer.writeByte('\n');
            }
        }

        // Top padding
        for (0..self.padding_top) |_| {
            for (0..self.margin_left) |_| try writer.writeByte(' ');
            if (self.border) |b| {
                if (self.border_left) {
                    try writeColor(&writer, self.border_fg, false);
                    try writer.writeAll(b.left);
                    try writeReset(&writer);
                }
            }
            const padded_len = effective_width + self.padding_left + self.padding_right;
            for (0..padded_len) |_| try writer.writeByte(' ');
            if (self.border) |b| {
                if (self.border_right) {
                    try writeColor(&writer, self.border_fg, false);
                    try writer.writeAll(b.right);
                    try writeReset(&writer);
                }
            }
            try writer.writeByte('\n');
        }

        // Content lines
        for (raw_lines.items) |line| {
            // Margin left
            for (0..self.margin_left) |_| try writer.writeByte(' ');

            // Border left
            if (self.border) |b| {
                if (self.border_left) {
                    try writeColor(&writer, self.border_fg, false);
                    try writer.writeAll(b.left);
                    try writeReset(&writer);
                }
            }

            // Padding left
            for (0..self.padding_left) |_| try writer.writeByte(' ');

            // Alignment calculation
            const padding_needed = if (effective_width > line.len) effective_width - line.len else 0;
            const align_left_pad = switch (self.align_mode) {
                .left => 0,
                .center => padding_needed / 2,
                .right => padding_needed,
            };
            const align_right_pad = padding_needed - align_left_pad;

            for (0..align_left_pad) |_| try writer.writeByte(' ');

            // Styled text
            try writeStyleHeader(&writer, self);
            try writer.writeAll(line);
            try writeReset(&writer);

            for (0..align_right_pad) |_| try writer.writeByte(' ');

            // Padding right
            for (0..self.padding_right) |_| try writer.writeByte(' ');

            // Border right
            if (self.border) |b| {
                if (self.border_right) {
                    try writeColor(&writer, self.border_fg, false);
                    try writer.writeAll(b.right);
                    try writeReset(&writer);
                }
            }

            try writer.writeByte('\n');
        }

        // Bottom padding
        for (0..self.padding_bottom) |_| {
            for (0..self.margin_left) |_| try writer.writeByte(' ');
            if (self.border) |b| {
                if (self.border_left) {
                    try writeColor(&writer, self.border_fg, false);
                    try writer.writeAll(b.left);
                    try writeReset(&writer);
                }
            }
            const padded_len = effective_width + self.padding_left + self.padding_right;
            for (0..padded_len) |_| try writer.writeByte(' ');
            if (self.border) |b| {
                if (self.border_right) {
                    try writeColor(&writer, self.border_fg, false);
                    try writer.writeAll(b.right);
                    try writeReset(&writer);
                }
            }
            try writer.writeByte('\n');
        }

        // Bottom border
        if (self.border) |b| {
            if (self.border_bottom) {
                for (0..self.margin_left) |_| try writer.writeByte(' ');
                try writeColor(&writer, self.border_fg, false);
                if (self.border_left) try writer.writeAll(b.bottom_left);
                const border_width = effective_width + self.padding_left + self.padding_right;
                for (0..border_width) |_| try writer.writeAll(b.bottom);
                if (self.border_right) try writer.writeAll(b.bottom_right);
                try writeReset(&writer);
                try writer.writeByte('\n');
            }
        }

        // Bottom margin
        for (0..self.margin_bottom) |_| {
            try writer.writeByte('\n');
        }

        // Remove trailing newline if single line and no border/margins
        if (self.border == null and self.margin_top == 0 and self.margin_bottom == 0 and raw_lines.items.len <= 1) {
            writer.popTrailingNewline();
        }
        return writer.toOwnedSlice();
    }

    fn writeStyleHeader(writer: anytype, style: Style) !void {
        if (style.bold) try writer.writeAll("\x1b[1m");
        if (style.dim) try writer.writeAll("\x1b[2m");
        if (style.italic) try writer.writeAll("\x1b[3m");
        if (style.underline) try writer.writeAll("\x1b[4m");
        if (style.reverse) try writer.writeAll("\x1b[7m");

        try writeColor(writer, style.fg, false);
        try writeColor(writer, style.bg, true);
    }

    fn writeColor(writer: anytype, color: Color, is_bg: bool) !void {
        const offset: u8 = if (is_bg) 10 else 0;
        switch (color.color_type) {
            .none => {},
            .ansi16 => {
                const code = color.val;
                if (code < 8) {
                    try writer.print("\x1b[{d}m", .{30 + offset + code});
                } else {
                    try writer.print("\x1b[{d}m", .{90 + offset + (code - 8)});
                }
            },
            .ansi256 => {
                const prefix: u8 = if (is_bg) 48 else 38;
                try writer.print("\x1b[{d};5;{d}m", .{ prefix, color.val });
            },
            .rgb => {
                const r: u8 = @intCast((color.val >> 16) & 0xFF);
                const g: u8 = @intCast((color.val >> 8) & 0xFF);
                const b: u8 = @intCast(color.val & 0xFF);
                const prefix: u8 = if (is_bg) 48 else 38;
                try writer.print("\x1b[{d};2;{d};{d};{d}m", .{ prefix, r, g, b });
            },
        }
    }

    fn writeReset(writer: anytype) !void {
        try writer.writeAll("\x1b[0m");
    }
};

test "style rendering" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const style = Style.init()
        .foreground(Color.ansi(2)) // green
        .setBold(true)
        .paddingLeft(2);

    const rendered = try style.render(allocator, "Hello Zig!");
    defer allocator.free(rendered);

    try testing.expect(rendered.len > 0);
    try testing.expect(std.mem.indexOf(u8, rendered, "Hello Zig!") != null);
}
