const std = @import("std");
const tui = @import("tui");
const components = @import("components");
const maestro = @import("maestro");

const Service = struct {
    name: []const u8,
    latency_ms: u32,
    online: bool,
};

const Model = struct {
    ticks: u64 = 0,
    selected: usize = 0,
    cpu: u32 = 38,
    memory: u32 = 61,
    transition: maestro.Maestro = .{},
    services: [4]Service = .{
        .{ .name = "API Gateway", .latency_ms = 4, .online = true },
        .{ .name = "Postgres", .latency_ms = 2, .online = true },
        .{ .name = "Agent Workers", .latency_ms = 18, .online = false },
        .{ .name = "Event Stream", .latency_ms = 7, .online = true },
    },

    pub fn init(self: Model) tui.Cmd {
        _ = self;
        return tui.tick(80, 0);
    }

    pub fn update(self: *Model, msg: tui.Msg) tui.Cmd {
        switch (msg) {
            .key => |key| {
                if (key.matches("q") or key.matches("ctrl+c")) return tui.quit();
                if (key.matches("up") or key.matches("k")) {
                    if (self.selected > 0) self.selected -= 1;
                    self.transition.start(.slide_in_left, 220);
                } else if (key.matches("down") or key.matches("j")) {
                    self.selected = (self.selected + 1) % self.services.len;
                    self.transition.start(.slide_in_right, 220);
                } else if (key.matches("space") or key.matches("enter") or key.matches("s")) {
                    self.services[self.selected].online = !self.services[self.selected].online;
                } else if (key.matches("r")) {
                    self.cpu = 38;
                    self.memory = 61;
                    self.ticks = 0;
                    self.transition.start(.slide_in_down, 300);
                }
            },
            .tick => {
                self.ticks +%= 1;
                self.cpu = 25 + @as(u32, @intCast((self.ticks * 7) % 55));
                self.memory = 40 + @as(u32, @intCast((self.ticks * 3) % 45));
                self.transition.advance(80);
                return tui.tick(80, 0);
            },
            else => {},
        }
        return tui.none();
    }

    pub fn view(self: Model, allocator: std.mem.Allocator) !tui.View {
        var buf = tui.Buffer.init(allocator);
        defer buf.deinit();

        const cpu = components.Progress{ .value = @floatFromInt(self.cpu), .max = 100 };
        const memory = components.Progress{ .value = @floatFromInt(self.memory), .max = 100 };
        const state = components.Badge{ .label = "LIVE", .tone = .success };
        const current_motion = self.transition.motion.name();

        try buf.writeAll("\x1b[1;38;5;81m CHAPPIETUI / MAESTRO DASHBOARD \x1b[0m\n");
        try buf.writeAll(" Real-time service overview · Zig 0.16 · q to quit\n");
        try buf.writeAll(" ──────────────────────────────────────────────────────────────\n\n");
        try buf.print("  {s}   CPU {d: >2}%   MEMORY {d: >2}%   TICKS {d}\n\n", .{
            state.label, self.cpu, self.memory, self.ticks,
        });
        try buf.print("  CPU     [{s}] {d: >3}%\n", .{ bar(cpu.ratio()), self.cpu });
        try buf.print("  MEMORY  [{s}] {d: >3}%\n\n", .{ bar(memory.ratio()), self.memory });
        try buf.writeAll("  SERVICES\n");
        try buf.writeAll("  ──────────────────────────────────────────────────────────────\n");
        for (self.services, 0..) |service, index| {
            const selected = index == self.selected;
            const pointer: []const u8 = if (selected) "▸" else " ";
            const status: []const u8 = if (service.online) "\x1b[38;5;82mONLINE \x1b[0m" else "\x1b[38;5;214mOFFLINE\x1b[0m";
            if (selected) try buf.writeAll("\x1b[1;38;5;81m");
            try buf.print("  {s} {s:<17} {s}  {d: >3} ms", .{ pointer, service.name, status, service.latency_ms });
            if (selected) try buf.writeAll("\x1b[0m");
            try buf.writeByte('\n');
        }
        try buf.writeAll("\n  MAESTRO MOTION\n");
        try buf.print("  {s} · phase={s} · progress={d:.0}%\n", .{
            current_motion, @tagName(self.transition.phase), self.transition.progress() * 100,
        });
        try buf.writeAll("\n  [↑/k] previous  [↓/j] next  [space/s] toggle service  [r] reset  [q] quit\n");

        var rendered_view = tui.View.init(try buf.toOwnedSlice());
        rendered_view.window_title = "ChappieTUI Maestro Dashboard";
        rendered_view.alt_screen = true;
        return rendered_view;
    }
};

fn bar(ratio: f32) [20]u8 {
    var result: [20]u8 = undefined;
    const filled: usize = @intFromFloat(@round(@as(f32, 20) * ratio));
    for (&result, 0..) |*cell, i| cell.* = if (i < filled) '#' else '-';
    return result;
}

pub fn main() !void {
    var program = tui.Program(Model).init(std.heap.page_allocator, .{});
    defer program.deinit();
    _ = try program.run();
}

test "dashboard progress bars remain bounded" {
    try std.testing.expectEqual(@as(usize, 20), bar(0.5).len);
    try std.testing.expectEqual(@as(usize, 20), bar(1).len);
}
