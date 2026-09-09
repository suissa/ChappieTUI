const std = @import("std");
const Style = @import("style.zig").Style;
const Color = @import("color.zig").Color;
const Buffer = @import("buffer.zig").Buffer;

pub const ListType = enum {
    bullet,
    numbered,
    dash,
    star,
};

pub const List = struct {
    allocator: std.mem.Allocator,
    items_list: std.ArrayList([]const u8) = .empty,
    list_type: ListType = .bullet,
    bullet_style: Style = Style.init().foreground(Color.ansi256(81)),
    item_style: Style = Style.init(),
    indent_spaces: usize = 2,

    pub fn init(allocator: std.mem.Allocator) List {
        return .{
            .allocator = allocator,
            .items_list = .empty,
        };
    }

    pub fn deinit(self: *List) void {
        self.items_list.deinit(self.allocator);
    }

    pub fn item(self: *List, val: []const u8) !*List {
        try self.items_list.append(self.allocator, val);
        return self;
    }

    pub fn items(self: *List, vals: []const []const u8) !*List {
        for (vals) |v| {
            try self.items_list.append(self.allocator, v);
        }
        return self;
    }

    pub fn typeOf(self: *List, lt: ListType) *List {
        self.list_type = lt;
        return self;
    }

    pub fn styleBullet(self: *List, s: Style) *List {
        self.bullet_style = s;
        return self;
    }

    pub fn styleItem(self: *List, s: Style) *List {
        self.item_style = s;
        return self;
    }

    pub fn render(self: *List) ![]u8 {
        var out = Buffer.init(self.allocator);
        defer out.deinit();

        const reset = "\x1b[0m";

        for (self.items_list.items, 0..) |it, idx| {
            for (0..self.indent_spaces) |_| try out.writeByte(' ');

            // Render bullet / number
            if (self.bullet_style.is_bold) try out.writeAll("\x1b[1m");
            try self.bullet_style.fg.writeAnsi(&out, false);

            switch (self.list_type) {
                .bullet => try out.writeAll("• "),
                .dash => try out.writeAll("- "),
                .star => try out.writeAll("* "),
                .numbered => {
                    var num_buf: [16]u8 = undefined;
                    const num_str = std.fmt.bufPrint(&num_buf, "{d}. ", .{idx + 1}) catch "1. ";
                    try out.writeAll(num_str);
                },
            }
            try out.writeAll(reset);

            // Render item text
            if (self.item_style.is_bold) try out.writeAll("\x1b[1m");
            try self.item_style.fg.writeAnsi(&out, false);
            try self.item_style.bg.writeAnsi(&out, true);
            try out.writeAll(it);
            try out.writeAll(reset);

            if (idx + 1 < self.items_list.items.len) {
                try out.writeByte('\n');
            }
        }

        return out.toOwnedSlice();
    }
};

test "list rendering" {
    const testing = std.testing;
    var l = List.init(testing.allocator);
    defer l.deinit();

    _ = try l.item("First item");
    _ = try l.item("Second item");

    const res = try l.render();
    defer testing.allocator.free(res);

    try testing.expect(std.mem.indexOf(u8, res, "First item") != null);
    try testing.expect(std.mem.indexOf(u8, res, "• ") != null);
}
