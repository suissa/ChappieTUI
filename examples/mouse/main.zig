const std = @import("std");
const tui = @import("tui");

const Model = struct {
    last_action: []const u8 = "None",
    last_button: []const u8 = "None",
    last_x: i32 = 0,
    last_y: i32 = 0,
    clicks_count: usize = 0,
    mouse_mode_name: []const u8 = "Cell Motion",
    cell_motion: bool = true,

    pub fn init(self: Model) tui.Cmd {
        _ = self;
        return tui.none();
    }

    pub fn update(self: *Model, msg: tui.Msg) tui.Cmd {
        switch (msg) {
            .key => |k| {
                if (k.matches("q") or k.matches("ctrl+c")) {
                    return tui.quit();
                } else if (k.matches("c")) {
                    self.cell_motion = true;
                    self.mouse_mode_name = "Cell Motion";
                    return tui.enableMouse(true);
                } else if (k.matches("a")) {
                    self.cell_motion = false;
                    self.mouse_mode_name = "All Motion";
                    return tui.enableMouse(false);
                } else if (k.matches("d")) {
                    self.mouse_mode_name = "Disabled";
                    return tui.disableMouse();
                }
            },
            .mouse => |m| {
                self.last_x = m.x;
                self.last_y = m.y;
                self.clicks_count += 1;

                self.last_action = switch (m.action) {
                    .press => "Press",
                    .release => "Release",
                    .motion => "Motion",
                };

                self.last_button = switch (m.button) {
                    .left => "Left Button",
                    .right => "Right Button",
                    .middle => "Middle Button",
                    .wheel_up => "Wheel Up",
                    .wheel_down => "Wheel Down",
                    .wheel_left => "Wheel Left",
                    .wheel_right => "Wheel Right",
                    .none => "None",
                };
            },
            else => {},
        }
        return tui.none();
    }

    pub fn view(self: Model, allocator: std.mem.Allocator) !tui.View {
        var buf = tui.Buffer.init(allocator);

        var title_style = tui.Style.init();
        title_style = title_style.setBold(true).foreground(tui.Color.ansi256(81));

        var border_style = tui.Style.init();
        border_style = border_style.setBorder(tui.Border.rounded()).borderForeground(tui.Color.ansi256(69)).padding(1, 2, 1, 2);

        var inner = tui.Buffer.init(allocator);
        defer inner.deinit();

        try inner.print("  \x1b[1;38;5;81mBubble Tea Mouse Tracker (Zig 0.16)\x1b[0m\n\n", .{});
        try inner.print("  Tracking Mode:  \x1b[38;5;48m{s}\x1b[0m\n", .{self.mouse_mode_name});
        try inner.print("  Coordinates:    \x1b[1mX: {d}, Y: {d}\x1b[0m\n", .{ self.last_x, self.last_y });
        try inner.print("  Last Button:    \x1b[38;5;214m{s}\x1b[0m\n", .{self.last_button});
        try inner.print("  Last Action:    \x1b[38;5;178m{s}\x1b[0m\n", .{self.last_action});
        try inner.print("  Total Events:   \x1b[38;5;141m{d}\x1b[0m\n\n", .{self.clicks_count});
        try inner.print("  \x1b[38;5;245mControls: [c] Cell Motion | [a] All Motion | [d] Disable | [q] Quit\x1b[0m\n", .{});

        const rendered_box = try border_style.render(allocator, inner.items());
        try buf.writeAll(rendered_box);

        var v = tui.View.init(try buf.toOwnedSlice());
        v.alt_screen = true;
        v.mouse_mode = if (self.cell_motion) .cell_motion else .all_motion;
        return v;
    }
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const initial_model = Model{};
    var opt = tui.Options{};
    opt = opt.withAltScreen().withMouseCellMotion().withWindowTitle("Bubble Tea Mouse Tracker");

    var p = tui.Program(Model).initWithOptions(allocator, initial_model, opt);
    defer p.deinit();

    _ = try p.run();
}
