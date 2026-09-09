const std = @import("std");
const builtin = @import("builtin");

const Terminal = @import("terminal.zig").Terminal;
const Renderer = @import("renderer.zig").Renderer;
const Msg = @import("msg.zig").Msg;
const Cmd = @import("cmd.zig").Cmd;
const View = @import("view.zig").View;
const Key = @import("key.zig").Key;
const MouseMsg = @import("mouse.zig").MouseMsg;
const Options = @import("options.zig").Options;
const clipboard = @import("clipboard.zig");
const paste = @import("paste.zig");
const focus = @import("focus.zig");

// Platform time & sleep
extern "kernel32" fn Sleep(dwMilliseconds: u32) callconv(.winapi) void;
extern "kernel32" fn GetTickCount64() callconv(.winapi) u64;

pub fn sleepMs(ms: u32) void {
    if (builtin.os.tag == .windows) {
        Sleep(ms);
    } else {
        const ts: std.posix.timespec = .{
            .sec = @intCast(ms / 1000),
            .nsec = @intCast((ms % 1000) * 1_000_000),
        };
        _ = std.posix.system.nanosleep(&ts, null);
    }
}

pub fn getTimestampMs() i64 {
    if (builtin.os.tag == .windows) {
        return @intCast(GetTickCount64());
    } else {
        var ts: std.posix.timespec = undefined;
        _ = std.posix.system.clock_gettime(.MONOTONIC, &ts);
        return @as(i64, ts.sec) * 1000 + @divTrunc(ts.nsec, 1_000_000);
    }
}

pub const SpinLock = struct {
    locked: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),

    pub fn lock(self: *SpinLock) void {
        while (self.locked.cmpxchgWeak(false, true, .acquire, .monotonic) != null) {
            std.Thread.yield() catch {};
        }
    }

    pub fn unlock(self: *SpinLock) void {
        self.locked.store(false, .release);
    }
};

pub fn Program(comptime ModelType: type) type {
    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        model: ModelType,
        terminal: Terminal,
        renderer: Renderer,
        options: Options,
        running: std.atomic.Value(bool),
        queue_lock: SpinLock = .{},
        msg_queue: std.ArrayList(Msg) = .empty,
        input_thread: ?std.Thread = null,
        last_width: u16 = 0,
        last_height: u16 = 0,

        pub fn init(allocator: std.mem.Allocator, initial_model: ModelType) Self {
            return initWithOptions(allocator, initial_model, .{});
        }

        pub fn initWithOptions(allocator: std.mem.Allocator, initial_model: ModelType, options: Options) Self {
            var term = Terminal.init();
            return .{
                .allocator = allocator,
                .model = initial_model,
                .terminal = term,
                .renderer = Renderer.init(allocator, &term),
                .options = options,
                .running = std.atomic.Value(bool).init(false),
                .msg_queue = .empty,
            };
        }

        pub fn deinit(self: *Self) void {
            self.msg_queue.deinit(self.allocator);
        }

        pub fn send(self: *Self, msg: Msg) void {
            self.pushMsg(msg);
        }

        pub fn pushMsg(self: *Self, msg: Msg) void {
            var processed_msg = msg;
            if (self.options.filter) |filter_fn| {
                if (filter_fn(msg)) |filtered| {
                    processed_msg = filtered;
                } else {
                    return; // Ignored by filter
                }
            }

            self.queue_lock.lock();
            defer self.queue_lock.unlock();
            self.msg_queue.append(self.allocator, processed_msg) catch {};
        }

        pub fn popMsg(self: *Self) ?Msg {
            self.queue_lock.lock();
            defer self.queue_lock.unlock();
            if (self.msg_queue.items.len == 0) return null;
            return self.msg_queue.orderedRemove(0);
        }

        pub fn quit(self: *Self) void {
            self.pushMsg(.quit);
        }

        pub fn run(self: *Self) !ModelType {
            self.terminal.enableRawMode();
            defer self.terminal.restore();

            // Configure terminal based on options
            if (self.options.alt_screen) {
                self.terminal.enterAltScreen();
                self.renderer.altscreen_enabled = true;
            }

            if (self.options.mouse_mode != .none) {
                self.terminal.enableMouse(self.options.mouse_mode == .cell_motion);
                self.renderer.mouse_mode_enabled = true;
            }

            if (self.options.window_title) |title| {
                self.terminal.setWindowTitle(title);
            }

            if (self.options.report_focus) {
                self.terminal.writeAll(focus.enable_focus_reporting);
            }

            if (self.options.bracketed_paste) {
                self.terminal.writeAll(paste.enable_bracketed_paste);
            }

            self.running.store(true, .release);

            // Send initial WindowSizeMsg
            const sz = self.terminal.getWindowSize();
            self.last_width = sz.width;
            self.last_height = sz.height;
            self.pushMsg(.{ .window_size = .{ .width = sz.width, .height = sz.height } });

            // Start background input reader thread
            self.input_thread = try std.Thread.spawn(.{}, inputReaderWorker, .{self});

            // Execute initial model command
            const init_cmd = self.model.init();
            self.handleCmd(init_cmd);

            // Initial render
            if (!self.options.disable_renderer) {
                const initial_view = try self.model.view(self.allocator);
                try self.renderer.render(initial_view);
            }

            const frame_delay_ms: u32 = @intCast(1000 / self.options.fps);

            // Main event loop
            while (self.running.load(.acquire)) {
                var had_msg = false;

                while (self.popMsg()) |msg| {
                    had_msg = true;
                    switch (msg) {
                        .quit => {
                            self.running.store(false, .release);
                            break;
                        },
                        else => {
                            const cmd = self.model.update(msg);
                            self.handleCmd(cmd);

                            if (!self.running.load(.acquire)) break;

                            if (!self.options.disable_renderer) {
                                const v = try self.model.view(self.allocator);
                                try self.renderer.render(v);
                            }
                        },
                    }
                }

                if (!self.running.load(.acquire)) break;

                // Check for window resize
                const cur_sz = self.terminal.getWindowSize();
                if (cur_sz.width != self.last_width or cur_sz.height != self.last_height) {
                    self.last_width = cur_sz.width;
                    self.last_height = cur_sz.height;
                    self.pushMsg(.{ .window_size = .{ .width = cur_sz.width, .height = cur_sz.height } });
                }

                if (!had_msg) {
                    sleepMs(frame_delay_ms);
                }
            }

            if (self.options.bracketed_paste) {
                self.terminal.writeAll(paste.disable_bracketed_paste);
            }
            if (self.options.report_focus) {
                self.terminal.writeAll(focus.disable_focus_reporting);
            }

            if (!self.options.disable_renderer) {
                self.renderer.clear();
            }

            return self.model;
        }

        fn handleCmd(self: *Self, cmd: Cmd) void {
            switch (cmd) {
                .none => {},
                .quit => {
                    self.pushMsg(.quit);
                },
                .tick => |t| {
                    _ = std.Thread.spawn(.{}, timerWorker, .{ self, t.duration_ms, t.tag, false }) catch {};
                },
                .every => |e| {
                    _ = std.Thread.spawn(.{}, timerWorker, .{ self, e.interval_ms, e.tag, false }) catch {};
                },
                .task => |func| {
                    _ = std.Thread.spawn(.{}, taskWorker, .{ self, func }) catch {};
                },
                .batch => |cmds| {
                    for (cmds) |c| {
                        self.handleCmd(c);
                    }
                },
                .sequence => |cmds| {
                    for (cmds) |c| {
                        self.handleCmd(c);
                    }
                },
                .enter_alt_screen => {
                    self.terminal.enterAltScreen();
                    self.renderer.altscreen_enabled = true;
                },
                .exit_alt_screen => {
                    self.terminal.exitAltScreen();
                    self.renderer.altscreen_enabled = false;
                },
                .hide_cursor => {
                    self.terminal.hideCursor();
                },
                .show_cursor => {
                    self.terminal.showCursor();
                },
                .set_cursor => |sc| {
                    var buf: [32]u8 = undefined;
                    const seq = std.fmt.bufPrint(&buf, "\x1b[{d};{d}H", .{ sc.y + 1, sc.x + 1 }) catch return;
                    self.terminal.writeAll(seq);
                },
                .enable_mouse => |cell_motion| {
                    self.terminal.enableMouse(cell_motion);
                    self.renderer.mouse_mode_enabled = true;
                },
                .disable_mouse => {
                    self.terminal.disableMouse();
                    self.renderer.mouse_mode_enabled = false;
                },
                .set_window_title => |title| {
                    self.terminal.setWindowTitle(title);
                },
                .set_clipboard => |text| {
                    const formatted = clipboard.formatSetClipboard(self.allocator, text, .clipboard) catch return;
                    defer self.allocator.free(formatted);
                    self.terminal.writeAll(formatted);
                },
                .read_clipboard => {
                    const formatted = clipboard.formatReadClipboard(self.allocator, .clipboard) catch return;
                    defer self.allocator.free(formatted);
                    self.terminal.writeAll(formatted);
                },
                .print_line => |text| {
                    self.terminal.writeAll(text);
                    self.terminal.writeAll("\n");
                },
                .exec => |exec_cmd| {
                    // Suspend terminal
                    self.terminal.restore();
                    const result_msg = exec_cmd.run(self.allocator);
                    // Resume terminal
                    self.terminal.enableRawMode();
                    if (self.renderer.altscreen_enabled) {
                        self.terminal.enterAltScreen();
                    }
                    if (result_msg) |rm| {
                        self.pushMsg(rm);
                    }
                },
            }
        }

        fn inputReaderWorker(self: *Self) void {
            var buf: [512]u8 = undefined;
            while (self.running.load(.acquire)) {
                const n = self.terminal.readInput(&buf);
                if (n > 0) {
                    var offset: usize = 0;
                    while (offset < n) {
                        const slice = buf[offset..n];

                        // Focus reporting (\x1b[I = focus, \x1b[O = blur)
                        if (std.mem.startsWith(u8, slice, "\x1b[I")) {
                            self.pushMsg(.{ .focus = .{} });
                            offset += 3;
                            continue;
                        } else if (std.mem.startsWith(u8, slice, "\x1b[O")) {
                            self.pushMsg(.{ .blur = .{} });
                            offset += 3;
                            continue;
                        }

                        // Bracketed paste detection
                        if (std.mem.startsWith(u8, slice, paste.paste_start)) {
                            if (std.mem.indexOf(u8, slice, paste.paste_end)) |end_idx| {
                                const pasted_content = slice[paste.paste_start.len..end_idx];
                                const duped = self.allocator.dupe(u8, pasted_content) catch "";
                                self.pushMsg(.{ .paste = .{ .content = duped } });
                                offset += end_idx + paste.paste_end.len;
                                continue;
                            }
                        }

                        // Try parsing mouse sequence
                        if (MouseMsg.parseSGR(slice)) |m| {
                            self.pushMsg(.{ .mouse = m.msg });
                            offset += m.consumed;
                            continue;
                        }

                        // Try parsing key sequence
                        if (Key.parse(slice)) |k| {
                            self.pushMsg(.{ .key = k.key });
                            offset += k.consumed;
                            continue;
                        }

                        offset += 1;
                    }
                } else {
                    sleepMs(10);
                }
            }
        }

        fn timerWorker(self: *Self, duration_ms: u64, tag: usize, repeat: bool) void {
            _ = repeat;
            sleepMs(@intCast(duration_ms));
            if (self.running.load(.acquire)) {
                self.pushMsg(.{ .tick = .{ .time_ms = getTimestampMs(), .tag = tag } });
            }
        }

        fn taskWorker(self: *Self, func: *const fn () ?Msg) void {
            if (func()) |msg| {
                if (self.running.load(.acquire)) {
                    self.pushMsg(msg);
                }
            }
        }
    };
}
