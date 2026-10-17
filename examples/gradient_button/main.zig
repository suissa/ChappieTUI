const std = @import("std");
const builtin = @import("builtin");
const tui = @import("tui");
const lipgloss = @import("lipgloss");

const ButtonMode = enum { idle, fade_in, fade_out };

const button_width: usize = 28;
const button_label = "RUN ACTION";

const Model = struct {
    progress: f32 = 0,
    mode: ButtonMode = .idle,
    last_action: []const u8 = "Scroll up/down to control the gradient",
    terminal_background: [3]u8 = .{ 0, 0, 0 },
    has_terminal_background: bool = false,

    pub fn init(self: Model) tui.Cmd {
        _ = self;
        return tui.batch(&initial_cmds);
    }

    pub fn update(self: *Model, msg: tui.Msg) tui.Cmd {
        switch (msg) {
            .custom => |custom| {
                if (custom.id == 0xB011) {
                    self.terminal_background = .{
                        @intCast((custom.data >> 16) & 0xff),
                        @intCast((custom.data >> 8) & 0xff),
                        @intCast(custom.data & 0xff),
                    };
                    self.has_terminal_background = true;
                    self.last_action = "Terminal background detected via OSC 11";
                }
            },
            .key => |key| {
                if (key.matches("q") or key.matches("ctrl+c")) return tui.quit();

                if (key.matches("i") or key.matches("up")) {
                    self.mode = .fade_in;
                    self.last_action = "FadeIn: gradient expands from the center";
                    return tui.tick(24, 0);
                }
                if (key.matches("o") or key.matches("down")) {
                    self.mode = .fade_out;
                    self.last_action = "FadeOut: gradient contracts toward the center";
                    return tui.tick(24, 0);
                }
                if (key.matches("space")) {
                    self.mode = if (self.progress < 0.5) .fade_in else .fade_out;
                    self.last_action = "Animation toggled";
                    return tui.tick(24, 0);
                }
            },
            .mouse => |mouse| {
                if (mouse.action == .press) {
                    switch (mouse.button) {
                        .wheel_up => {
                            self.progress = @min(1, self.progress + 0.12);
                            self.mode = .idle;
                            self.last_action = "Scroll up: reveal the button";
                        },
                        .wheel_down => {
                            self.progress = @max(0, self.progress - 0.12);
                            self.mode = .idle;
                            self.last_action = "Scroll down: hide the button";
                        },
                        .left => {
                            if (self.progress >= 1) {
                                self.last_action = "Button activated";
                            } else {
                                self.mode = .fade_in;
                                self.last_action = "Button is revealing";
                                return tui.tick(24, 0);
                            }
                        },
                        else => {},
                    }
                }
            },
            .tick => {
                switch (self.mode) {
                    .idle => return tui.none(),
                    .fade_in => {
                        self.progress = @min(1, self.progress + 0.055);
                        if (self.progress >= 1) {
                            self.mode = .idle;
                            self.last_action = "FadeIn complete";
                        } else return tui.tick(24, 0);
                    },
                    .fade_out => {
                        self.progress = @max(0, self.progress - 0.055);
                        if (self.progress <= 0) {
                            self.mode = .idle;
                            self.last_action = "FadeOut complete";
                        } else return tui.tick(24, 0);
                    },
                }
            },
            else => {},
        }
        return tui.none();
    }

    pub fn view(self: Model, allocator: std.mem.Allocator) !tui.View {
        var buf = tui.Buffer.init(allocator);
        defer buf.deinit();

        const title_style = lipgloss.newStyle()
            .foreground(lipgloss.Color.hex("#7DDBFF"))
            .bold(true);
        const title = try title_style.render(allocator, "ChappieTUI · Gradient Button");
        defer allocator.free(title);
        try buf.writeAll("\n  ");
        try buf.writeAll(title);
        try buf.writeAll("\n\n  FadeIn/FadeOut uses an expanding radial color gradient.\n\n  ");

        const half: f32 = @as(f32, @floatFromInt(button_width - 1)) / 2.0;
        const center: f32 = half;
        const edge_width: f32 = 0.16;
        const label_start = (button_width - button_label.len) / 2;

        for (0..button_width) |i| {
            const distance = @abs(@as(f32, @floatFromInt(i)) - center) / half;
            if (distance <= self.progress) {
                const edge_ratio = if (edge_width > 0 and self.progress - distance < edge_width)
                    @max(0, (self.progress - distance) / edge_width)
                else
                    1.0;
                const scale = 0.52 + edge_ratio * 0.48;
                const red: u8 = if (self.has_terminal_background)
                    @intFromFloat(@as(f32, @floatFromInt(self.terminal_background[0])) +
                        (72.0 - @as(f32, @floatFromInt(self.terminal_background[0]))) * edge_ratio)
                else
                    @intFromFloat(72.0 * scale);
                const green: u8 = if (self.has_terminal_background)
                    @intFromFloat(@as(f32, @floatFromInt(self.terminal_background[1])) +
                        (104.0 - @as(f32, @floatFromInt(self.terminal_background[1]))) * edge_ratio)
                else
                    @intFromFloat(104.0 * scale);
                const blue: u8 = if (self.has_terminal_background)
                    @intFromFloat(@as(f32, @floatFromInt(self.terminal_background[2])) +
                        (238.0 - @as(f32, @floatFromInt(self.terminal_background[2]))) * edge_ratio)
                else
                    @intFromFloat(238.0 * scale);
                try buf.print("\x1b[48;2;{d};{d};{d}m\x1b[97m", .{ red, green, blue });
            } else {
                // SGR default background keeps the terminal's own background color.
                try buf.writeAll("\x1b[49m\x1b[39m");
            }

            if (i >= label_start and i < label_start + button_label.len) {
                try buf.writeByte(button_label[i - label_start]);
            } else {
                try buf.writeByte(' ');
            }
            try buf.writeAll("\x1b[0m");
        }

        try buf.writeAll("\n\n  ");
        const progress_style = lipgloss.newStyle().foreground(lipgloss.Color.hex("#A5A5B5"));
        const progress_text = try std.fmt.allocPrint(
            allocator,
            "Progress: {d:.0}%   State: {s}",
            .{ self.progress * 100.0, @tagName(self.mode) },
        );
        defer allocator.free(progress_text);
        const styled_progress = try progress_style.render(allocator, progress_text);
        defer allocator.free(styled_progress);
        try buf.writeAll(styled_progress);

        try buf.writeAll("\n\n  ");
        try buf.writeAll(self.last_action);
        try buf.writeAll("\n\n  Controls: [i] FadeIn  [o] FadeOut  [↑/↓] animate  [mouse wheel] scrub  [q] quit\n");

        return tui.View.init(try buf.toOwnedSlice());
    }
};



const initial_cmds = [_]tui.Cmd{
    .{ .task = requestTerminalBackground },
    .{ .tick = .{ .duration_ms = 24, .tag = 0 } },
};

fn requestTerminalBackground() ?tui.Msg {
    if (comptime builtin.os.tag != .windows) {
        const query = "\x1b]11;?\x1b\\";
        _ = std.posix.system.write(1, query.ptr, query.len);
    }
    return null;
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const options = (tui.Options{}).withMouseCellMotion().withFPS(60).withWindowTitle("ChappieTUI Gradient Button");
    var program = tui.Program(Model).initWithOptions(allocator, .{}, options);
    defer program.deinit();
    _ = try program.run();
}
