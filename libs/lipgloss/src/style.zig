const std = @import("std");
const Color = @import("color.zig").Color;
const Border = @import("border.zig").Border;
const Position = @import("position.zig").Position;
const Align = @import("position.zig").Align;
const size = @import("size.zig");
const Buffer = @import("buffer.zig").Buffer;

pub const Style = struct {
    // Colors
    fg: Color = .none(),
    bg: Color = .none(),

    // Attributes
    is_bold: bool = false,
    is_italic: bool = false,
    is_underline: bool = false,
    is_strikethrough: bool = false,
    is_reverse: bool = false,
    is_blink: bool = false,
    is_faint: bool = false,

    // Padding
    pad_top: usize = 0,
    pad_right: usize = 0,
    pad_bottom: usize = 0,
    pad_left: usize = 0,

    // Margin
    marg_top: usize = 0,
    marg_right: usize = 0,
    marg_bottom: usize = 0,
    marg_left: usize = 0,
    marg_bg: Color = .none(),

    // Dimensions & Alignment
    target_width: ?usize = null,
    target_height: ?usize = null,
    max_w: ?usize = null,
    max_h: ?usize = null,
    align_h: Align = .left,
    align_v: Position = .top,

    // Border
    active_border: ?Border = null,
    border_fg: Color = .none(),
    border_bg: Color = .none(),
    b_top: bool = true,
    b_right: bool = true,
    b_bottom: bool = true,
    b_left: bool = true,

    // Border per-side colors (if unset, uses border_fg)
    b_top_fg: Color = .none(),
    b_right_fg: Color = .none(),
    b_bottom_fg: Color = .none(),
    b_left_fg: Color = .none(),

    pub fn init() Style {
        return .{};
    }

    pub fn copy(self: Style) Style {
        return self;
    }

    // Color setters
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

    // Attribute setters
    pub fn bold(self: Style, b: bool) Style {
        var s = self;
        s.is_bold = b;
        return s;
    }

    pub fn italic(self: Style, i: bool) Style {
        var s = self;
        s.is_italic = i;
        return s;
    }

    pub fn underline(self: Style, u: bool) Style {
        var s = self;
        s.is_underline = u;
        return s;
    }

    pub fn strikethrough(self: Style, st: bool) Style {
        var s = self;
        s.is_strikethrough = st;
        return s;
    }

    pub fn reverse(self: Style, r: bool) Style {
        var s = self;
        s.is_reverse = r;
        return s;
    }

    pub fn blink(self: Style, bl: bool) Style {
        var s = self;
        s.is_blink = bl;
        return s;
    }

    pub fn faint(self: Style, f: bool) Style {
        var s = self;
        s.is_faint = f;
        return s;
    }

    // Padding setters
    pub fn padding(self: Style, top: usize, right: usize, bottom: usize, left: usize) Style {
        var s = self;
        s.pad_top = top;
        s.pad_right = right;
        s.pad_bottom = bottom;
        s.pad_left = left;
        return s;
    }

    pub fn pad(self: Style, y: usize, x: usize) Style {
        return self.padding(y, x, y, x);
    }

    pub fn paddingTop(self: Style, val: usize) Style {
        var s = self;
        s.pad_top = val;
        return s;
    }

    pub fn paddingRight(self: Style, val: usize) Style {
        var s = self;
        s.pad_right = val;
        return s;
    }

    pub fn paddingBottom(self: Style, val: usize) Style {
        var s = self;
        s.pad_bottom = val;
        return s;
    }

    pub fn paddingLeft(self: Style, val: usize) Style {
        var s = self;
        s.pad_left = val;
        return s;
    }

    // Margin setters
    pub fn margin(self: Style, top: usize, right: usize, bottom: usize, left: usize) Style {
        var s = self;
        s.marg_top = top;
        s.marg_right = right;
        s.marg_bottom = bottom;
        s.marg_left = left;
        return s;
    }

    pub fn marginBackground(self: Style, c: Color) Style {
        var s = self;
        s.marg_bg = c;
        return s;
    }

    pub fn marginTop(self: Style, val: usize) Style {
        var s = self;
        s.marg_top = val;
        return s;
    }

    pub fn marginRight(self: Style, val: usize) Style {
        var s = self;
        s.marg_right = val;
        return s;
    }

    pub fn marginBottom(self: Style, val: usize) Style {
        var s = self;
        s.marg_bottom = val;
        return s;
    }

    pub fn marginLeft(self: Style, val: usize) Style {
        var s = self;
        s.marg_left = val;
        return s;
    }

    // Dimensions
    pub fn width(self: Style, w: usize) Style {
        var s = self;
        s.target_width = w;
        return s;
    }

    pub fn height(self: Style, h: usize) Style {
        var s = self;
        s.target_height = h;
        return s;
    }

    pub fn maxWidth(self: Style, mw: usize) Style {
        var s = self;
        s.max_w = mw;
        return s;
    }

    pub fn maxHeight(self: Style, mh: usize) Style {
        var s = self;
        s.max_h = mh;
        return s;
    }

    pub fn @"align"(self: Style, a: Align) Style {
        var s = self;
        s.align_h = a;
        return s;
    }

    pub fn alignHorizontal(self: Style, p: Position) Style {
        var s = self;
        s.align_h = switch (p) {
            .left, .top, .bottom => .left,
            .center => .center,
            .right => .right,
        };
        return s;
    }

    pub fn alignVertical(self: Style, p: Position) Style {
        var s = self;
        s.align_v = p;
        return s;
    }

    // Borders
    pub fn border(self: Style, b: Border) Style {
        var s = self;
        s.active_border = b;
        return s;
    }

    pub fn borderColor(self: Style, color: Color) Style {
        var s = self;
        s.border_fg = color;
        return s;
    }

    pub fn borderBackground(self: Style, color: Color) Style {
        var s = self;
        s.border_bg = color;
        return s;
    }

    pub fn borderTop(self: Style, b: bool) Style {
        var s = self;
        s.b_top = b;
        return s;
    }

    pub fn borderRight(self: Style, b: bool) Style {
        var s = self;
        s.b_right = b;
        return s;
    }

    pub fn borderBottom(self: Style, b: bool) Style {
        var s = self;
        s.b_bottom = b;
        return s;
    }

    pub fn borderLeft(self: Style, b: bool) Style {
        var s = self;
        s.b_left = b;
        return s;
    }

    pub fn borderTopForeground(self: Style, c: Color) Style {
        var s = self;
        s.b_top_fg = c;
        return s;
    }

    pub fn borderRightForeground(self: Style, c: Color) Style {
        var s = self;
        s.b_right_fg = c;
        return s;
    }

    pub fn borderBottomForeground(self: Style, c: Color) Style {
        var s = self;
        s.b_bottom_fg = c;
        return s;
    }

    pub fn borderLeftForeground(self: Style, c: Color) Style {
        var s = self;
        s.b_left_fg = c;
        return s;
    }

    // Inheritance
    pub fn inherit(self: Style, parent: Style) Style {
        var s = self;
        if (s.fg.color_type == .none) s.fg = parent.fg;
        if (s.bg.color_type == .none) s.bg = parent.bg;
        if (!s.is_bold and parent.is_bold) s.is_bold = true;
        if (!s.is_italic and parent.is_italic) s.is_italic = true;
        if (!s.is_underline and parent.is_underline) s.is_underline = true;
        if (s.active_border == null and parent.active_border != null) s.active_border = parent.active_border;
        return s;
    }

    /// Renders text with all configured styling, borders, padding, and margins
    pub fn render(self: Style, allocator: std.mem.Allocator, text: []const u8) ![]u8 {
        var raw_lines: std.ArrayList([]const u8) = .empty;
        defer raw_lines.deinit(allocator);

        var it = std.mem.splitScalar(u8, text, '\n');
        while (it.next()) |line| {
            try raw_lines.append(allocator, line);
        }

        // Measure content width
        var content_w: usize = 0;
        for (raw_lines.items) |l| {
            const w = size.width(l);
            if (w > content_w) content_w = w;
        }

        const border_w: usize = (if (self.active_border != null and self.b_left) @as(usize, 1) else 0) +
            (if (self.active_border != null and self.b_right) @as(usize, 1) else 0);
        const extra_w = self.pad_left + self.pad_right + border_w;

        // Apply width if set (in Lipgloss, Width sets total framed box width)
        if (self.target_width) |tw| {
            if (tw > extra_w) {
                const target_content_w = tw - extra_w;
                if (target_content_w > content_w) content_w = target_content_w;
            }
        }
        if (self.max_w) |mw| {
            if (mw > extra_w) {
                const max_content_w = mw - extra_w;
                if (content_w > max_content_w) content_w = max_content_w;
            }
        }

        const inner_w = content_w + self.pad_left + self.pad_right;

        var out = Buffer.init(allocator);
        defer out.deinit();

        // 1. Margin Top
        for (0..self.marg_top) |_| {
            try out.writeByte('\n');
        }

        // Helper to write color SGR
        const reset_seq = "\x1b[0m";

        // 2. Border Top
        if (self.active_border) |b| {
            if (self.b_top) {
                for (0..self.marg_left) |_| try out.writeByte(' ');

                const top_color = if (self.b_top_fg.color_type != .none) self.b_top_fg else self.border_fg;
                try top_color.writeAnsi(&out, false);
                try self.border_bg.writeAnsi(&out, true);

                if (self.b_left) try out.writeAll(b.top_left);
                for (0..inner_w) |_| try out.writeAll(b.top);
                if (self.b_right) try out.writeAll(b.top_right);

                try out.writeAll(reset_seq);
                try out.writeByte('\n');
            }
        }

        // 3. Padding Top lines
        for (0..self.pad_top) |_| {
            try self.renderPaddedLine(&out, "", inner_w, reset_seq);
        }

        // 4. Content lines
        for (raw_lines.items) |line| {
            try self.renderContentLine(&out, line, content_w, inner_w, reset_seq);
        }

        // 5. Padding Bottom lines
        for (0..self.pad_bottom) |_| {
            try self.renderPaddedLine(&out, "", inner_w, reset_seq);
        }

        // 6. Border Bottom
        if (self.active_border) |b| {
            if (self.b_bottom) {
                for (0..self.marg_left) |_| try out.writeByte(' ');

                const bot_color = if (self.b_bottom_fg.color_type != .none) self.b_bottom_fg else self.border_fg;
                try bot_color.writeAnsi(&out, false);
                try self.border_bg.writeAnsi(&out, true);

                if (self.b_left) try out.writeAll(b.bottom_left);
                for (0..inner_w) |_| try out.writeAll(b.bottom);
                if (self.b_right) try out.writeAll(b.bottom_right);

                try out.writeAll(reset_seq);
                try out.writeByte('\n');
            }
        }

        // 7. Margin Bottom
        for (0..self.marg_bottom) |_| {
            try out.writeByte('\n');
        }

        return out.toOwnedSlice();
    }

    fn renderPaddedLine(self: Style, out: *Buffer, _: []const u8, inner_w: usize, reset_seq: []const u8) !void {
        for (0..self.marg_left) |_| try out.writeByte(' ');

        if (self.active_border) |b| {
            if (self.b_left) {
                const left_color = if (self.b_left_fg.color_type != .none) self.b_left_fg else self.border_fg;
                try left_color.writeAnsi(out, false);
                try out.writeAll(b.left);
                try out.writeAll(reset_seq);
            }
        }

        // Background color for padding area if set
        try self.bg.writeAnsi(out, true);
        for (0..inner_w) |_| try out.writeByte(' ');
        try out.writeAll(reset_seq);

        if (self.active_border) |b| {
            if (self.b_right) {
                const right_color = if (self.b_right_fg.color_type != .none) self.b_right_fg else self.border_fg;
                try right_color.writeAnsi(out, false);
                try out.writeAll(b.right);
                try out.writeAll(reset_seq);
            }
        }

        try out.writeByte('\n');
    }

    fn renderContentLine(self: Style, out: *Buffer, line: []const u8, content_w: usize, _: usize, reset_seq: []const u8) !void {
        for (0..self.marg_left) |_| try out.writeByte(' ');

        if (self.active_border) |b| {
            if (self.b_left) {
                const left_color = if (self.b_left_fg.color_type != .none) self.b_left_fg else self.border_fg;
                try left_color.writeAnsi(out, false);
                try out.writeAll(b.left);
                try out.writeAll(reset_seq);
            }
        }

        // Left padding
        try self.bg.writeAnsi(out, true);
        for (0..self.pad_left) |_| try out.writeByte(' ');

        // Alignment spaces
        const line_w = size.width(line);
        var align_left_pad: usize = 0;
        var align_right_pad: usize = 0;

        if (content_w > line_w) {
            switch (self.align_h) {
                .left => {
                    align_right_pad = content_w - line_w;
                },
                .right => {
                    align_left_pad = content_w - line_w;
                },
                .center => {
                    align_left_pad = (content_w - line_w) / 2;
                    align_right_pad = content_w - line_w - align_left_pad;
                },
            }
        }

        for (0..align_left_pad) |_| try out.writeByte(' ');

        // Text formatting attributes
        if (self.is_bold) try out.writeAll("\x1b[1m");
        if (self.is_faint) try out.writeAll("\x1b[2m");
        if (self.is_italic) try out.writeAll("\x1b[3m");
        if (self.is_underline) try out.writeAll("\x1b[4m");
        if (self.is_blink) try out.writeAll("\x1b[5m");
        if (self.is_reverse) try out.writeAll("\x1b[7m");
        if (self.is_strikethrough) try out.writeAll("\x1b[9m");

        try self.fg.writeAnsi(out, false);
        try self.bg.writeAnsi(out, true);

        try out.writeAll(line);
        try out.writeAll(reset_seq);

        // Right alignment spaces and right padding
        try self.bg.writeAnsi(out, true);
        for (0..align_right_pad) |_| try out.writeByte(' ');
        for (0..self.pad_right) |_| try out.writeByte(' ');
        try out.writeAll(reset_seq);

        if (self.active_border) |b| {
            if (self.b_right) {
                const right_color = if (self.b_right_fg.color_type != .none) self.b_right_fg else self.border_fg;
                try right_color.writeAnsi(out, false);
                try out.writeAll(b.right);
                try out.writeAll(reset_seq);
            }
        }

        try out.writeByte('\n');
    }
};

test "style render" {
    const testing = std.testing;
    var s = Style.init();
    s = s.bold(true).foreground(Color.hex("#FF00FF")).padding(1, 2, 1, 2).border(Border.rounded());

    const res = try s.render(testing.allocator, "Lipgloss in Zig!");
    defer testing.allocator.free(res);

    try testing.expect(res.len > 0);
    try testing.expect(std.mem.indexOf(u8, res, "Lipgloss in Zig!") != null);
}
