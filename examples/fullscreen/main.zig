const std = @import("std");
const tui = @import("tui");

const Model = struct {
    width: u16 = 80,
    height: u16 = 24,
    color_profile: []const u8 = "TrueColor",

    pub fn init(self: Model) tui.Cmd {
        _ = self;
        return tui.none();
    }

    pub fn update(self: *Model, msg: tui.Msg) tui.Cmd {
        switch (msg) {
            .key => |k| {
                if (k.matches("q") or k.matches("esc") or k.matches("ctrl+c")) {
                    return tui.quit();
                }
            },
            .window_size => |ws| {
                self.width = ws.width;
                self.height = ws.height;
            },
            else => {},
        }
        return tui.none();
    }

    pub fn view(self: Model, allocator: std.mem.Allocator) !tui.View {
        var buf = tui.Buffer.init(allocator);

        var border_style = tui.Style.init();
        border_style = border_style.setBorder(tui.Border.double()).borderForeground(tui.Color.ansi256(205)).padding(1, 4, 1, 4);

        var inner = tui.Buffer.init(allocator);
        defer inner.deinit();

        try inner.print("  \x1b[1;38;5;213mFULLSCREEN RESPONSIVE LAYOUT\x1b[0m\n\n", .{});
        try inner.print("  Terminal Dimensions:  \x1b[1;38;5;48m{d} cols × {d} rows\x1b[0m\n", .{ self.width, self.height });
        try inner.print("  Color Support:        \x1b[38;5;81m{s}\x1b[0m\n", .{self.color_profile});
        try inner.print("  Buffer Mode:          \x1b[38;5;178mAlternate Screen Buffer\x1b[0m\n\n", .{});
        try inner.print("  Resize your terminal window to see real-time updates!\n\n", .{});
        try inner.print("  \x1b[38;5;245mPress 'q' or 'esc' to exit fullscreen.\x1b[0m\n", .{});

        const card = try border_style.render(allocator, inner.items());

        // Vertical padding to center on screen
        const card_lines = 10;
        const top_pad = if (self.height > card_lines) (self.height - card_lines) / 2 else 0;
        for (0..top_pad) |_| {
            try buf.writeByte('\n');
        }

        try buf.writeAll(card);

        var v = tui.View.init(try buf.toOwnedSlice());
        v.alt_screen = true;
        v.window_title = "Fullscreen App (Zig 0.16)";
        return v;
    }
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const initial_model = Model{};
    var opt = tui.Options{};
    opt = opt.withAltScreen().withWindowTitle("Bubble Tea Fullscreen");

    var p = tui.Program(Model).initWithOptions(allocator, initial_model, opt);
    defer p.deinit();

    _ = try p.run();
}
