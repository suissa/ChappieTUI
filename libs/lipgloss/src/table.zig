const std = @import("std");
const Style = @import("style.zig").Style;
const Border = @import("border.zig").Border;
const Color = @import("color.zig").Color;
const size = @import("size.zig");
const Buffer = @import("buffer.zig").Buffer;

pub const Table = struct {
    allocator: std.mem.Allocator,
    headers_list: ?[]const []const u8 = null,
    rows_list: std.ArrayList([]const []const u8) = .empty,
    header_style: Style = Style.init().bold(true).foreground(Color.ansi256(81)),
    row_style: Style = Style.init(),
    even_row_style: ?Style = null,
    border_val: Border = Border.rounded(),
    border_color: Color = Color.ansi256(240),
    col_padding: usize = 1,

    pub fn init(allocator: std.mem.Allocator) Table {
        return .{
            .allocator = allocator,
            .rows_list = .empty,
        };
    }

    pub fn deinit(self: *Table) void {
        self.rows_list.deinit(self.allocator);
    }

    pub fn headers(self: *Table, h: []const []const u8) *Table {
        self.headers_list = h;
        return self;
    }

    pub fn row(self: *Table, r: []const []const u8) !*Table {
        try self.rows_list.append(self.allocator, r);
        return self;
    }

    pub fn rows(self: *Table, r: []const []const []const u8) !*Table {
        for (r) |item| {
            try self.rows_list.append(self.allocator, item);
        }
        return self;
    }

    pub fn border(self: *Table, b: Border) *Table {
        self.border_val = b;
        return self;
    }

    pub fn borderColor(self: *Table, c: Color) *Table {
        self.border_color = c;
        return self;
    }

    pub fn styleHeader(self: *Table, s: Style) *Table {
        self.header_style = s;
        return self;
    }

    pub fn styleRows(self: *Table, s: Style) *Table {
        self.row_style = s;
        return self;
    }

    pub fn styleEvenRows(self: *Table, s: Style) *Table {
        self.even_row_style = s;
        return self;
    }

    pub fn render(self: *Table) ![]u8 {
        var num_cols: usize = 0;
        if (self.headers_list) |h| {
            num_cols = h.len;
        }
        for (self.rows_list.items) |r| {
            if (r.len > num_cols) num_cols = r.len;
        }

        if (num_cols == 0) return self.allocator.dupe(u8, "");

        // Compute column widths
        var col_widths = try self.allocator.alloc(usize, num_cols);
        defer self.allocator.free(col_widths);
        @memset(col_widths, 0);

        if (self.headers_list) |h| {
            for (h, 0..) |cell, i| {
                const w = size.width(cell);
                if (w > col_widths[i]) col_widths[i] = w;
            }
        }

        for (self.rows_list.items) |r| {
            for (r, 0..) |cell, i| {
                if (i < num_cols) {
                    const w = size.width(cell);
                    if (w > col_widths[i]) col_widths[i] = w;
                }
            }
        }

        var out = Buffer.init(self.allocator);
        defer out.deinit();

        const b = self.border_val;
        const reset = "\x1b[0m";

        // Top Border
        try self.border_color.writeAnsi(&out, false);
        try out.writeAll(b.top_left);
        for (col_widths, 0..) |cw, i| {
            if (i > 0) try out.writeAll(b.middle_top);
            for (0..(cw + self.col_padding * 2)) |_| try out.writeAll(b.top);
        }
        try out.writeAll(b.top_right);
        try out.writeAll(reset);
        try out.writeByte('\n');

        // Headers row
        if (self.headers_list) |h| {
            try self.border_color.writeAnsi(&out, false);
            try out.writeAll(b.left);
            try out.writeAll(reset);

            for (0..num_cols) |i| {
                const text = if (i < h.len) h[i] else "";
                const cw = col_widths[i];

                for (0..self.col_padding) |_| try out.writeByte(' ');

                // Apply header style
                if (self.header_style.is_bold) try out.writeAll("\x1b[1m");
                try self.header_style.fg.writeAnsi(&out, false);
                try self.header_style.bg.writeAnsi(&out, true);
                try out.writeAll(text);
                try out.writeAll(reset);

                const w = size.width(text);
                if (cw > w) {
                    for (0..(cw - w)) |_| try out.writeByte(' ');
                }

                for (0..self.col_padding) |_| try out.writeByte(' ');

                try self.border_color.writeAnsi(&out, false);
                if (i + 1 < num_cols) {
                    try out.writeAll(b.left);
                } else {
                    try out.writeAll(b.right);
                }
                try out.writeAll(reset);
            }
            try out.writeByte('\n');

            // Header separator border
            try self.border_color.writeAnsi(&out, false);
            try out.writeAll(b.middle_left);
            for (col_widths, 0..) |cw, i| {
                if (i > 0) try out.writeAll(b.middle);
                for (0..(cw + self.col_padding * 2)) |_| try out.writeAll(b.top);
            }
            try out.writeAll(b.middle_right);
            try out.writeAll(reset);
            try out.writeByte('\n');
        }

        // Data Rows
        for (self.rows_list.items, 0..) |r, row_idx| {
            const cur_style = if (row_idx % 2 == 1 and self.even_row_style != null)
                self.even_row_style.?
            else
                self.row_style;

            try self.border_color.writeAnsi(&out, false);
            try out.writeAll(b.left);
            try out.writeAll(reset);

            for (0..num_cols) |i| {
                const text = if (i < r.len) r[i] else "";
                const cw = col_widths[i];

                for (0..self.col_padding) |_| try out.writeByte(' ');

                if (cur_style.is_bold) try out.writeAll("\x1b[1m");
                try cur_style.fg.writeAnsi(&out, false);
                try cur_style.bg.writeAnsi(&out, true);
                try out.writeAll(text);
                try out.writeAll(reset);

                const w = size.width(text);
                if (cw > w) {
                    for (0..(cw - w)) |_| try out.writeByte(' ');
                }

                for (0..self.col_padding) |_| try out.writeByte(' ');

                try self.border_color.writeAnsi(&out, false);
                if (i + 1 < num_cols) {
                    try out.writeAll(b.left);
                } else {
                    try out.writeAll(b.right);
                }
                try out.writeAll(reset);
            }
            try out.writeByte('\n');
        }

        // Bottom Border
        try self.border_color.writeAnsi(&out, false);
        try out.writeAll(b.bottom_left);
        for (col_widths, 0..) |cw, i| {
            if (i > 0) try out.writeAll(b.middle_bottom);
            for (0..(cw + self.col_padding * 2)) |_| try out.writeAll(b.bottom);
        }
        try out.writeAll(b.bottom_right);
        try out.writeAll(reset);
        try out.writeByte('\n');

        return out.toOwnedSlice();
    }
};

test "table rendering" {
    const testing = std.testing;
    var t = Table.init(testing.allocator);
    defer t.deinit();

    _ = t.headers(&.{ "NAME", "STATUS", "LATENCY" });
    _ = try t.row(&.{ "API Gateway", "Online", "4ms" });
    _ = try t.row(&.{ "Postgres", "Online", "1ms" });

    const rendered = try t.render();
    defer testing.allocator.free(rendered);

    try testing.expect(rendered.len > 0);
    try testing.expect(std.mem.indexOf(u8, rendered, "API Gateway") != null);
}
