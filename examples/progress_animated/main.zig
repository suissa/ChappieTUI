const std = @import("std");
const tui = @import("tui");
const lipgloss = @import("lipgloss");

const padding = 2;
const maxWidth = 80;

const Model = struct {
    progress: lipgloss.Progress = lipgloss.Progress.charm(),
    current_percent: f32 = 0.0,
    target_percent: f32 = 0.0,
    ticks: usize = 0,
    width: usize = 50,

    pub fn init(self: Model) tui.Cmd {
        _ = self;
        return tui.tick(40, 0);
    }

    pub fn update(self: *Model, msg: tui.Msg) tui.Cmd {
        switch (msg) {
            .key => {
                return tui.quit();
            },
            .window_size => |ws| {
                if (ws.width > padding * 2 + 4) {
                    var w: usize = ws.width - padding * 2 - 4;
                    if (w > maxWidth) w = maxWidth;
                    self.width = w;
                    self.progress.width = w;
                }
            },
            .tick => {
                self.ticks += 1;

                // Step targets at ticks 5, 30, 55, 80
                if (self.ticks == 5) {
                    self.target_percent = 0.25;
                } else if (self.ticks == 30) {
                    self.target_percent = 0.50;
                } else if (self.ticks == 55) {
                    self.target_percent = 0.75;
                } else if (self.ticks == 80) {
                    self.target_percent = 1.0;
                }

                // Smooth animation step towards target
                if (self.current_percent < self.target_percent) {
                    self.current_percent += (self.target_percent - self.current_percent) * 0.18 + 0.005;
                    if (self.current_percent >= self.target_percent) {
                        self.current_percent = self.target_percent;
                    }
                }

                // If reached 100% and held for ~1 second, quit
                if (self.current_percent >= 1.0 and self.ticks > 115) {
                    return tui.quit();
                }

                return tui.tick(40, 0);
            },
            else => {},
        }
        return tui.none();
    }

    pub fn view(self: Model, allocator: std.mem.Allocator) !tui.View {
        var buf = tui.Buffer.init(allocator);

        try buf.writeByte('\n');
        for (0..padding) |_| try buf.writeByte(' ');

        const bar = try self.progress.viewAs(allocator, self.current_percent);
        defer allocator.free(bar);
        try buf.writeAll(bar);
        try buf.writeAll("\n\n");

        for (0..padding) |_| try buf.writeByte(' ');
        const help_style = lipgloss.newStyle().foreground(lipgloss.Color.hex("#626262"));
        const help = try help_style.render(allocator, "Press any key to quit");
        defer allocator.free(help);
        try buf.writeAll(help);
        try buf.writeByte('\n');

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
