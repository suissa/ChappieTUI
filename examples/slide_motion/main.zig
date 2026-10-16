const std = @import("std");
const tui = @import("tui");
const lipgloss = @import("lipgloss");
const motion = @import("tui").motion;

const motions = [_]motion.Motion{
    .slide_in_right, .slide_in_left, .slide_in_up, .slide_in_down,
    .slide_out_right, .slide_out_left, .slide_out_up, .slide_out_down,
};

const Model = struct {
    orchestrator: motion.Orchestrator = .{},
    selected: usize = 0,
    elapsed_ms: u64 = 0,
    duration_ms: u64 = 900,
    scroll_mode: bool = false,
    width: usize = 70,
    height: usize = 20,
    last_trigger: []const u8 = "Timed sequence",

    pub fn init(self: Model) tui.Cmd {
        _ = self;
        return tui.batch(&.{
            tui.enableMouse(false),
            tui.tick(30, 0),
        });
    }

    pub fn update(self: *Model, msg: tui.Msg) tui.Cmd {
        switch (msg) {
            .key => |key| {
                if (key.matches("q") or key.matches("ctrl+c")) return tui.quit();
                if (key.matches("m")) {
                    self.scroll_mode = !self.scroll_mode;
                    self.last_trigger = if (self.scroll_mode) "Scroll-triggered mode" else "Timed sequence mode";
                    self.orchestrator.start(motions[self.selected], self.duration_ms);
                    self.elapsed_ms = 0;
                } else if (key.matches("+") or key.matches("=")) {
                    self.duration_ms = @min(self.duration_ms + 100, 5000);
                    self.last_trigger = "Duration increased";
                } else if (key.matches("-")) {
                    self.duration_ms = @max(self.duration_ms -| 100, 100);
                    self.last_trigger = "Duration decreased";
                } else if (key.matches("n")) {
                    self.selected = (self.selected + 1) % motions.len;
                    self.orchestrator.start(motions[self.selected], self.duration_ms);
                    self.elapsed_ms = 0;
                    self.last_trigger = "Manual next animation";
                }
            },
            .mouse => |mouse| {
                if (mouse.button == .wheel_down or mouse.button == .wheel_up) {
                    const step: usize = if (mouse.button == .wheel_down) 1 else motions.len - 1;
                    self.selected = (self.selected + step) % motions.len;
                    self.orchestrator.start(motions[self.selected], self.duration_ms);
                    self.elapsed_ms = 0;
                    self.last_trigger = if (mouse.button == .wheel_down) "Scroll down triggered animation" else "Scroll up triggered animation";
                }
            },
            .window_size => |size| {
                self.width = @max(@as(usize, 20), @as(usize, size.width));
                self.height = @max(@as(usize, 8), @as(usize, size.height));
            },
            .tick => {
                if (!self.scroll_mode) {
                    self.orchestrator.advance(30);
                    self.elapsed_ms += 30;
                    if (self.orchestrator.phase == .finished) {
                        self.selected = (self.selected + 1) % motions.len;
                        self.orchestrator.start(motions[self.selected], self.duration_ms);
                        self.elapsed_ms = 0;
                    }
                } else if (self.orchestrator.phase == .entering) {
                    self.orchestrator.advance(30);
                }
                return tui.tick(30, 0);
            },
            else => {},
        }
        return tui.none();
    }

    pub fn view(self: Model, allocator: std.mem.Allocator) !tui.View {
        var buf = tui.Buffer.init(allocator);
        defer buf.deinit();

        const title_style = lipgloss.newStyle()
            .bold(true)
            .foreground(lipgloss.Color.hex("#00D2FD"));
        const button_style = lipgloss.newStyle()
            .bold(true)
            .foreground(lipgloss.Color.hex("#FFFFFF"))
            .background(lipgloss.Color.hex("#0072FC"))
            .padding(1, 3, 1, 3);
        const muted_style = lipgloss.newStyle().foreground(lipgloss.Color.hex("#9CA3AF"));

        const title = try title_style.render(allocator, "ChappieTUI • Slide Motion Maestro");
        defer allocator.free(title);
        const button = try button_style.render(allocator, "  BUTTON WIDGET  ");
        defer allocator.free(button);
        const status = try std.fmt.allocPrint(allocator,
            "Motion: {s} | Phase: {s} | Duration: {d}ms | Progress: {d:.0}%",
            .{ motions[self.selected].name(), @tagName(self.orchestrator.phase), self.duration_ms, self.orchestrator.progress() * 100.0 });
        defer allocator.free(status);
        const mode_line = if (self.scroll_mode)
            "Mode: SCROLL • mouse wheel triggers the next slide"
        else
            "Mode: TIMED • automatically runs every slide";
        const help = " [m] toggle mode  [+/-] duration  [n] next  [wheel] trigger  [q] quit ";

        try buf.writeAll(title);
        try buf.writeAll("\n\n");
        try buf.writeAll(status);
        try buf.writeAll("\n");
        try buf.writeAll(mode_line);
        try buf.writeAll("\n");
        const trigger = try muted_style.render(allocator, self.last_trigger);
        defer allocator.free(trigger);
        try buf.writeAll(trigger);
        try buf.writeAll("\n\n");

        const displacement = self.orchestrator.offset(self.width / 2, self.height / 2);
        const base_y: i32 = 5;
        const row_position = @max(0, base_y + displacement.y);
        const rows: usize = @intCast(@min(row_position, @as(i32, @intCast(self.height))));
        for (0..rows) |_| try buf.writeByte('\n');
        if (displacement.x > 0) {
            const spaces: usize = @intCast(@min(displacement.x, @as(i32, @intCast(self.width))));
            for (0..spaces) |_| try buf.writeByte(' ');
        }
        if (displacement.x < 0) {
            const spaces: usize = @intCast(@min(-displacement.x, @as(i32, @intCast(self.width))));
            for (0..spaces) |_| try buf.writeByte(' ');
        }
        if (self.orchestrator.phase != .finished or motions[self.selected].isEntering()) {
            try buf.writeAll(button);
        }
        try buf.writeAll("\n\n");
        try buf.writeAll(help);
        try buf.writeByte('\n');

        var view = tui.View.init(try buf.toOwnedSlice());
        view.alt_screen = true;
        view.mouse_mode = .all_motion;
        return view;
    }
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var options = tui.Options{};
    options = options.withAltScreen().withMouseAllMotion().withWindowTitle("Slide Motion Maestro");
    var program = tui.Program(Model).initWithOptions(allocator, .{}, options);
    defer program.deinit();
    _ = try program.run();
}
