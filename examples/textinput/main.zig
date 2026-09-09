const std = @import("std");
const tui = @import("tui");

const Model = struct {
    input_buf: [128]u8 = undefined,
    input_len: usize = 0,
    cursor_pos: usize = 0,
    submitted_msg: []const u8 = "Type something and hit Enter...",
    blink_state: bool = true,

    pub fn init(self: Model) tui.Cmd {
        _ = self;
        return tui.tick(500, 0);
    }

    pub fn update(self: *Model, msg: tui.Msg) tui.Cmd {
        switch (msg) {
            .key => |k| {
                if (k.matches("ctrl+c") or k.matches("esc")) {
                    return tui.quit();
                } else if (k.matches("backspace")) {
                    if (self.cursor_pos > 0 and self.input_len > 0) {
                        var i = self.cursor_pos - 1;
                        while (i < self.input_len - 1) : (i += 1) {
                            self.input_buf[i] = self.input_buf[i + 1];
                        }
                        self.input_len -= 1;
                        self.cursor_pos -= 1;
                    }
                } else if (k.matches("left")) {
                    if (self.cursor_pos > 0) self.cursor_pos -= 1;
                } else if (k.matches("right")) {
                    if (self.cursor_pos < self.input_len) self.cursor_pos += 1;
                } else if (k.matches("home")) {
                    self.cursor_pos = 0;
                } else if (k.matches("end")) {
                    self.cursor_pos = self.input_len;
                } else if (k.matches("enter")) {
                    if (self.input_len > 0) {
                        self.submitted_msg = "Successfully received input!";
                        self.input_len = 0;
                        self.cursor_pos = 0;
                    }
                } else if (k.code == .character) {
                    if (self.input_len < self.input_buf.len - 1) {
                        var i = self.input_len;
                        while (i > self.cursor_pos) : (i -= 1) {
                            self.input_buf[i] = self.input_buf[i - 1];
                        }
                        self.input_buf[self.cursor_pos] = @intCast(k.char);
                        self.input_len += 1;
                        self.cursor_pos += 1;
                    }
                }
            },
            .tick => {
                self.blink_state = !self.blink_state;
                return tui.tick(500, 0);
            },
            else => {},
        }
        return tui.none();
    }

    pub fn view(self: Model, allocator: std.mem.Allocator) !tui.View {
        var buf = tui.Buffer.init(allocator);

        var border_style = tui.Style.init();
        border_style = border_style.setBorder(tui.Border.rounded()).borderForeground(tui.Color.ansi256(39)).padding(1, 3, 1, 3);

        var inner = tui.Buffer.init(allocator);
        defer inner.deinit();

        try inner.print("  \x1b[1;38;5;39mINTERACTIVE TEXT INPUT (Zig 0.16)\x1b[0m\n\n", .{});
        try inner.print("  What is your favourite programming language?\n\n", .{});

        // Render input field with cursor
        try inner.print("  > \x1b[4m", .{});
        if (self.input_len == 0) {
            try inner.print("\x1b[38;5;245mType here...\x1b[0m\x1b[4m", .{});
        } else {
            for (self.input_buf[0..self.input_len], 0..) |c, idx| {
                if (idx == self.cursor_pos and self.blink_state) {
                    try inner.print("\x1b[7m{c}\x1b[27m", .{c});
                } else {
                    try inner.print("{c}", .{c});
                }
            }
        }
        if (self.cursor_pos == self.input_len and self.blink_state) {
            try inner.print("\x1b[7m \x1b[27m", .{});
        }
        try inner.print("\x1b[0m\n\n", .{});

        try inner.print("  Status: \x1b[38;5;48m{s}\x1b[0m\n\n", .{self.submitted_msg});
        try inner.print("  \x1b[38;5;245m[Enter] Submit | [Arrows] Navigate | [Esc] Quit\x1b[0m\n", .{});

        const card = try border_style.render(allocator, inner.items());
        try buf.writeAll(card);

        return tui.View.init(try buf.toOwnedSlice());
    }
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const initial_model = Model{};
    var p = tui.Program(Model).init(allocator, initial_model);
    defer p.deinit();

    _ = try p.run();
}
