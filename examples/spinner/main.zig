const std = @import("std");
const tui = @import("tui");

const SpinnerType = enum {
    dots,
    line,
    pulse,
};

const dots_frames = [_][]const u8{ "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" };
const line_frames = [_][]const u8{ "-", "\\", "|", "/" };
const pulse_frames = [_][]const u8{ "█", "▓", "▒", "░", "▒", "▓" };

const Model = struct {
    frame_index: usize = 0,
    spinner_type: SpinnerType = .dots,
    spinning: bool = true,
    message: []const u8 = "Downloading packages from upstream repository...",

    pub fn init(self: Model) tui.Cmd {
        _ = self;
        return tui.tick(80, 0);
    }

    pub fn update(self: *Model, msg: tui.Msg) tui.Cmd {
        switch (msg) {
            .key => |k| {
                if (k.matches("q") or k.matches("ctrl+c")) {
                    return tui.quit();
                } else if (k.matches("s")) {
                    self.spinner_type = switch (self.spinner_type) {
                        .dots => .line,
                        .line => .pulse,
                        .pulse => .dots,
                    };
                    self.frame_index = 0;
                } else if (k.matches(" ")) {
                    self.spinning = !self.spinning;
                }
            },
            .tick => {
                if (self.spinning) {
                    const max_len = switch (self.spinner_type) {
                        .dots => dots_frames.len,
                        .line => line_frames.len,
                        .pulse => pulse_frames.len,
                    };
                    self.frame_index = (self.frame_index + 1) % max_len;
                }
                return tui.tick(80, 0);
            },
            else => {},
        }
        return tui.none();
    }

    pub fn view(self: Model, allocator: std.mem.Allocator) !tui.View {
        var buf = tui.Buffer.init(allocator);

        const icon = switch (self.spinner_type) {
            .dots => dots_frames[self.frame_index],
            .line => line_frames[self.frame_index],
            .pulse => pulse_frames[self.frame_index],
        };

        var box_style = tui.Style.init();
        box_style = box_style.setBorder(tui.Border.rounded()).borderForeground(tui.Color.ansi256(141)).padding(1, 3, 1, 3);

        var inner = tui.Buffer.init(allocator);
        defer inner.deinit();

        try inner.print("  \x1b[1;38;5;141mANIMATED SPINNER (Zig 0.16)\x1b[0m\n\n", .{});
        try inner.print("  \x1b[1;38;5;81m{s}\x1b[0m  {s}\n\n", .{ icon, self.message });
        try inner.print("  Type: \x1b[38;5;214m{s}\x1b[0m  |  Status: \x1b[38;5;48m{s}\x1b[0m\n\n", .{
            @tagName(self.spinner_type),
            if (self.spinning) "Active" else "Paused",
        });
        try inner.print("  \x1b[38;5;245mControls: [s] Switch Style | [Space] Pause/Resume | [q] Quit\x1b[0m\n", .{});

        const card = try box_style.render(allocator, inner.items());
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
