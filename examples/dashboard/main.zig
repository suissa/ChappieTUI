const std = @import("std");
const tui = @import("tui");

const Service = struct {
    name: []const u8,
    port: []const u8,
    latency_ms: u32,
    online: bool,
    uptime_pct: []const u8,
};

const LogEntry = struct {
    time: []const u8,
    level: []const u8,
    message: []const u8,
};

const Model = struct {
    tick_count: u64 = 0,
    uptime_sec: u64 = 142,
    cpu_pct: u32 = 42,
    ram_pct: u32 = 58,
    net_in_kb: u32 = 18400,
    net_out_kb: u32 = 4200,

    selected_service: usize = 0,
    services: [6]Service = .{
        .{ .name = "API Gateway", .port = "8080", .latency_ms = 4, .online = true, .uptime_pct = "99.98%" },
        .{ .name = "Postgres DB", .port = "5432", .latency_ms = 1, .online = true, .uptime_pct = "99.99%" },
        .{ .name = "Redis Cache", .port = "6379", .latency_ms = 1, .online = true, .uptime_pct = "100.0%" },
        .{ .name = "Auth Service", .port = "4000", .latency_ms = 14, .online = true, .uptime_pct = "99.85%" },
        .{ .name = "Worker Pool", .port = "9000", .latency_ms = 0, .online = false, .uptime_pct = "98.20%" },
        .{ .name = "Storage S3", .port = "9002", .latency_ms = 28, .online = true, .uptime_pct = "99.95%" },
    },

    logs: [4]LogEntry = .{
        .{ .time = "09:25:01", .level = "INFO", .message = "Gateway health check OK: all 6 endpoints responsive" },
        .{ .time = "09:25:04", .level = "WARN", .message = "Worker pool scaled down: 2 idle executors evicted" },
        .{ .time = "09:25:08", .level = "OK  ", .message = "Postgres auto-vacuum completed: 1,420 rows cleaned" },
        .{ .time = "09:25:12", .level = "INFO", .message = "Redis hit-ratio 99.4% in 15m monitoring window" },
    },

    pub fn init(self: *Model) tui.Cmd {
        _ = self;
        return tui.tick(1000, 0);
    }

    pub fn update(self: *Model, msg: tui.Msg) tui.Cmd {
        switch (msg) {
            .key => |k| {
                if (k.matches("ctrl+c") or k.matches("q")) {
                    return tui.quit();
                } else if (k.matches("up") or k.matches("k")) {
                    if (self.selected_service > 0) {
                        self.selected_service -= 1;
                    }
                } else if (k.matches("down") or k.matches("j")) {
                    if (self.selected_service < self.services.len - 1) {
                        self.selected_service += 1;
                    }
                } else if (k.matches("space") or k.matches("s") or k.matches("enter")) {
                    self.services[self.selected_service].online = !self.services[self.selected_service].online;
                } else if (k.matches("r")) {
                    self.cpu_pct = 35;
                    self.ram_pct = 50;
                    self.uptime_sec = 0;
                }
            },
            .tick => {
                self.tick_count += 1;
                self.uptime_sec += 1;

                // Dynamic oscillation
                const cpu_delta: i32 = @as(i32, @intCast(self.tick_count % 7)) - 3;
                const new_cpu = @as(i32, @intCast(self.cpu_pct)) + cpu_delta;
                self.cpu_pct = @intCast(std.math.clamp(new_cpu, 15, 95));

                const ram_delta: i32 = if (self.tick_count % 3 == 0) 1 else -1;
                const new_ram = @as(i32, @intCast(self.ram_pct)) + ram_delta;
                self.ram_pct = @intCast(std.math.clamp(new_ram, 40, 85));

                self.net_in_kb = 15000 + @as(u32, @intCast((self.tick_count * 137) % 8000));
                self.net_out_kb = 3500 + @as(u32, @intCast((self.tick_count * 79) % 2500));

                return tui.tick(1000, 0);
            },
            else => {},
        }
        return tui.none();
    }

    pub fn view(self: *const Model, allocator: std.mem.Allocator) !tui.View {
        var buf = tui.Buffer.init(allocator);

        // Box Width = 74 inner columns, exactly 76 total terminal columns
        // Top border
        try buf.writeAll("\x1b[38;5;69m╭──────────────────────────────────────────────────────────────────────────╮\x1b[0m\n");

        // Header Row (74 cols inner)
        try buf.print("\x1b[38;5;69m│\x1b[0m \x1b[1;38;5;81mTUI.zig SYSTEM DASHBOARD (Zig v0.16)\x1b[0m       \x1b[38;5;245mUptime: {d:0>2}m {d:0>2}s | Multi-OS\x1b[0m \x1b[38;5;69m│\x1b[0m\n", .{
            self.uptime_sec / 60,
            self.uptime_sec % 60,
        });
        try buf.writeAll("\x1b[38;5;69m├────────────────────────┬────────────────────────┬────────────────────────┤\x1b[0m\n");

        // KPI Metric Cards Row (24 + 24 + 24 = 72 + 2 separators = 74 inner cols)
        var cpu_bar: [10]u8 = undefined;
        renderBar(&cpu_bar, self.cpu_pct);
        var ram_bar: [10]u8 = undefined;
        renderBar(&ram_bar, self.ram_pct);

        try buf.writeAll("\x1b[38;5;69m│\x1b[0m \x1b[1mCPU CORE\x1b[0m               \x1b[38;5;69m│\x1b[0m \x1b[1mRAM MEMORY\x1b[0m             \x1b[38;5;69m│\x1b[0m \x1b[1mNETWORK TRAFFIC\x1b[0m        \x1b[38;5;69m│\x1b[0m\n");
        try buf.print("\x1b[38;5;69m│\x1b[0m [{s}] \x1b[38;5;48m{d: >2}%\x1b[0m        \x1b[38;5;69m│\x1b[0m [{s}] \x1b[38;5;178m{d: >2}%\x1b[0m        \x1b[38;5;69m│\x1b[0m IN  \x1b[38;5;45m{d: >5}.2 MB/s\x1b[0m       \x1b[38;5;69m│\x1b[0m\n", .{
            cpu_bar,
            self.cpu_pct,
            ram_bar,
            self.ram_pct,
            self.net_in_kb / 1000,
        });
        try buf.print("\x1b[38;5;69m│\x1b[0m \x1b[38;5;245mLoad: 1.45 1.62 1.80\x1b[0m   \x1b[38;5;69m│\x1b[0m \x1b[38;5;245m19.8 GB / 32.0 GB\x1b[0m      \x1b[38;5;69m│\x1b[0m OUT \x1b[38;5;141m{d: >5}.1 MB/s\x1b[0m       \x1b[38;5;69m│\x1b[0m\n", .{
            self.net_out_kb / 1000,
        });

        // Services Table Header
        try buf.writeAll("\x1b[38;5;69m├────────────────────────┴────────────────────────┴────────────────────────┤\x1b[0m\n");
        try buf.writeAll("\x1b[38;5;69m│\x1b[0m \x1b[1;38;5;250mSTATUS   SERVICE             PORT    LATENCY   UPTIME    ACTIONS         \x1b[0m \x1b[38;5;69m│\x1b[0m\n");
        try buf.writeAll("\x1b[38;5;69m├──────────────────────────────────────────────────────────────────────────┤\x1b[0m\n");

        // Services Rows (74 cols inner)
        for (self.services, 0..) |s, i| {
            const is_selected = (i == self.selected_service);
            const cursor_str: []const u8 = if (is_selected) ">" else " ";
            const status_str: []const u8 = if (s.online) "Active" else "Paused";

            try buf.writeAll("\x1b[38;5;69m│\x1b[0m ");
            if (is_selected) {
                try buf.writeAll("\x1b[7;38;5;69m");
            }

            try buf.print("{s} {s:<7} {s:<18} {s:<7} {d: >3}ms     {s:<8} [Toggle:s] ", .{
                cursor_str,
                status_str,
                s.name,
                s.port,
                s.latency_ms,
                s.uptime_pct,
            });

            if (is_selected) {
                try buf.writeAll("\x1b[0m");
            }

            try buf.writeAll(" \x1b[38;5;69m│\x1b[0m\n");
        }

        // Live Event Log Section (74 cols inner)
        try buf.writeAll("\x1b[38;5;69m├──────────────────────────────────────────────────────────────────────────┤\x1b[0m\n");
        try buf.writeAll("\x1b[38;5;69m│\x1b[0m \x1b[1;38;5;250mLIVE EVENT LOGS                                                          \x1b[0m \x1b[38;5;69m│\x1b[0m\n");

        for (self.logs) |log| {
            const lvl_color: []const u8 = if (std.mem.startsWith(u8, log.level, "INFO"))
                "\x1b[38;5;69m"
            else if (std.mem.startsWith(u8, log.level, "WARN"))
                "\x1b[38;5;214m"
            else
                "\x1b[38;5;82m";

            try buf.print("\x1b[38;5;69m│\x1b[0m \x1b[38;5;244m[{s}]\x1b[0m {s}[{s}]\x1b[0m \x1b[38;5;253m{s:<54}\x1b[0m \x1b[38;5;69m│\x1b[0m\n", .{
                log.time,
                lvl_color,
                log.level,
                log.message,
            });
        }

        // Bottom Controls Footer
        try buf.writeAll("\x1b[38;5;69m╰──────────────────────────────────────────────────────────────────────────╯\x1b[0m\n");
        try buf.writeAll("  \x1b[1;38;5;245mUP/DOWN/j/k:\x1b[0m Move   \x1b[1;38;5;245mSpace/s:\x1b[0m Toggle Service   \x1b[1;38;5;245mr:\x1b[0m Reset   \x1b[1;38;5;245mq:\x1b[0m Quit\n");

        var v = tui.View.init(try buf.toOwnedSlice());
        v.window_title = "TUI.zig System Dashboard - Zig v0.16";
        v.alt_screen = true; // Use alternate screen buffer for clean fullscreen rendering
        return v;
    }
};

fn renderBar(buf: *[10]u8, pct: u32) void {
    const filled: usize = (pct * 10) / 100;
    for (0..10) |i| {
        if (i < filled) {
            buf[i] = '#';
        } else {
            buf[i] = '-';
        }
    }
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const initial_model = Model{};
    var p = tui.Program(Model).init(allocator, initial_model);
    defer p.deinit();

    _ = try p.run();
}
