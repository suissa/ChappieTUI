const std = @import("std");
const tui = @import("tui");

const Model = struct {
    cursor: usize = 0,
    choices: []const []const u8 = &.{
        "Buy carrots",
        "Buy celery",
        "Buy kohlrabi",
    },
    selected: [3]bool = .{ false, false, false },

    pub fn init(self: *Model) tui.Cmd {
        _ = self;
        return tui.none();
    }

    pub fn update(self: *Model, msg: tui.Msg) tui.Cmd {
        switch (msg) {
            .key => |k| {
                if (k.matches("ctrl+c") or k.matches("q")) {
                    return tui.quit();
                } else if (k.matches("up") or k.matches("k")) {
                    if (self.cursor > 0) {
                        self.cursor -= 1;
                    }
                } else if (k.matches("down") or k.matches("j")) {
                    if (self.cursor < self.choices.len - 1) {
                        self.cursor += 1;
                    }
                } else if (k.matches("enter") or k.matches("space")) {
                    if (self.cursor < self.selected.len) {
                        self.selected[self.cursor] = !self.selected[self.cursor];
                    }
                }
            },
            else => {},
        }
        return tui.none();
    }

    pub fn view(self: *const Model, allocator: std.mem.Allocator) !tui.View {
        var buf = tui.Buffer.init(allocator);

        try buf.writeAll("What should we buy at the market?\n\n");

        for (self.choices, 0..) |choice, i| {
            const cursor_str: []const u8 = if (self.cursor == i) ">" else " ";
            const checked_str: []const u8 = if (self.selected[i]) "x" else " ";
            try buf.print("{s} [{s}] {s}\n", .{ cursor_str, checked_str, choice });
        }

        try buf.writeAll("\nPress q to quit.\n");

        var v = tui.View.init(try buf.toOwnedSlice());
        v.window_title = "Grocery List";
        return v;
    }
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const initial_model = Model{};
    var p = tui.Program(Model).init(allocator, initial_model);
    defer p.deinit();

    _ = try p.run();
}
