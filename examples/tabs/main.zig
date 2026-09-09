const std = @import("std");
const tui = @import("tui");

const highlight_color = tui.Color.hex("#7D56F4");

const Model = struct {
    tabs: []const []const u8 = &.{
        "Lip Gloss",
        "Blush",
        "Eye Shadow",
        "Mascara",
        "Foundation",
    },
    tab_content: []const []const u8 = &.{
        "Lip Gloss Tab",
        "Blush Tab",
        "Eye Shadow Tab",
        "Mascara Tab",
        "Foundation Tab",
    },
    active_tab: usize = 0,

    pub fn init(self: *Model) tui.Cmd {
        _ = self;
        return tui.none();
    }

    pub fn update(self: *Model, msg: tui.Msg) tui.Cmd {
        switch (msg) {
            .key => |k| {
                if (k.matches("ctrl+c") or k.matches("q")) {
                    return tui.quit();
                } else if (k.matches("right") or k.matches("l") or k.matches("n") or k.matches("tab")) {
                    if (self.active_tab < self.tabs.len - 1) {
                        self.active_tab += 1;
                    }
                } else if (k.matches("left") or k.matches("h") or k.matches("p") or k.matches("shift+tab")) {
                    if (self.active_tab > 0) {
                        self.active_tab -= 1;
                    }
                }
            },
            else => {},
        }
        return tui.none();
    }

    pub fn view(self: *const Model, allocator: std.mem.Allocator) !tui.View {
        var doc = tui.Buffer.init(allocator);

        // Render tabs row
        // Top row of tab borders
        try doc.writeAll("  "); // padding
        for (self.tabs, 0..) |_, i| {
            const is_active = (i == self.active_tab);
            if (is_active) {
                try doc.writeAll("\x1b[38;2;125;86;244m╭");
                const title_len = self.tabs[i].len;
                for (0..title_len + 2) |_| try doc.writeAll("─");
                try doc.writeAll("╮\x1b[0m");
            } else {
                try doc.writeAll("\x1b[38;2;125;86;244m┌");
                const title_len = self.tabs[i].len;
                for (0..title_len + 2) |_| try doc.writeAll("─");
                try doc.writeAll("┐\x1b[0m");
            }
        }
        try doc.writeByte('\n');

        // Middle row of tab titles
        try doc.writeAll("  ");
        for (self.tabs, 0..) |t, i| {
            const is_active = (i == self.active_tab);
            if (is_active) {
                try doc.print("\x1b[38;2;125;86;244m│\x1b[0m\x1b[1;38;2;125;86;244m {s} \x1b[0m\x1b[38;2;125;86;244m│\x1b[0m", .{t});
            } else {
                try doc.print("\x1b[38;2;125;86;244m│\x1b[0m {s} \x1b[38;2;125;86;244m│\x1b[0m", .{t});
            }
        }
        try doc.writeByte('\n');

        // Bottom row of tab headers connecting to window
        try doc.writeAll("  ");
        var total_tab_width: usize = 0;
        for (self.tabs, 0..) |_, i| {
            const is_active = (i == self.active_tab);
            const title_len = self.tabs[i].len;
            total_tab_width += title_len + 4;
            if (is_active) {
                try doc.writeAll("\x1b[38;2;125;86;244m┘");
                for (0..title_len + 2) |_| try doc.writeAll(" ");
                try doc.writeAll("└\x1b[0m");
            } else {
                try doc.writeAll("\x1b[38;2;125;86;244m┴");
                for (0..title_len + 2) |_| try doc.writeAll("─");
                try doc.writeAll("┴\x1b[0m");
            }
        }
        try doc.writeByte('\n');

        // Render main window box
        const window_width = total_tab_width;
        const content = self.tab_content[self.active_tab];

        // Top line of content box
        try doc.writeAll("  \x1b[38;2;125;86;244m│");
        for (0..window_width - 2) |_| try doc.writeAll(" ");
        try doc.writeAll("│\x1b[0m\n");

        // Centered content line
        try doc.writeAll("  \x1b[38;2;125;86;244m│");
        const pad_total = if (window_width > content.len + 2) (window_width - 2 - content.len) else 0;
        const pad_left = pad_total / 2;
        const pad_right = pad_total - pad_left;
        for (0..pad_left) |_| try doc.writeAll(" ");
        try doc.print("{s}", .{content});
        for (0..pad_right) |_| try doc.writeAll(" ");
        try doc.writeAll("│\x1b[0m\n");

        // Bottom blank line inside content box
        try doc.writeAll("  \x1b[38;2;125;86;244m│");
        for (0..window_width - 2) |_| try doc.writeAll(" ");
        try doc.writeAll("│\x1b[0m\n");

        // Bottom border of content box
        try doc.writeAll("  \x1b[38;2;125;86;244m└");
        for (0..window_width - 2) |_| try doc.writeAll("─");
        try doc.writeAll("┘\x1b[0m\n");

        return tui.View.init(try doc.toOwnedSlice());
    }
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const initial_model = Model{};
    var p = tui.Program(Model).init(allocator, initial_model);
    defer p.deinit();

    _ = try p.run();
}
