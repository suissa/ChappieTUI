const std = @import("std");
pub const Msg = @import("msg.zig").Msg;
pub const ExecCmd = @import("exec.zig").ExecCmd;
pub const CursorStyle = @import("cursor.zig").CursorStyle;

pub const TaskFn = *const fn () ?Msg;

pub const Cmd = union(enum) {
    none,
    quit,
    tick: struct { duration_ms: u64, tag: usize = 0 },
    every: struct { interval_ms: u64, tag: usize = 0 },
    task: TaskFn,
    batch: []const Cmd,
    sequence: []const Cmd,
    enter_alt_screen,
    exit_alt_screen,
    hide_cursor,
    show_cursor,
    set_cursor: struct { x: u16, y: u16, style: CursorStyle = .default },
    enable_mouse: bool, // true = cell_motion, false = all_motion
    disable_mouse,
    set_window_title: []const u8,
    set_clipboard: []const u8,
    read_clipboard,
    exec: ExecCmd,
    print_line: []const u8,

    pub fn noneCmd() Cmd {
        return .none;
    }

    pub fn quitCmd() Cmd {
        return .quit;
    }

    pub fn tickCmd(duration_ms: u64, tag: usize) Cmd {
        return .{ .tick = .{ .duration_ms = duration_ms, .tag = tag } };
    }

    pub fn everyCmd(interval_ms: u64, tag: usize) Cmd {
        return .{ .every = .{ .interval_ms = interval_ms, .tag = tag } };
    }

    pub fn taskCmd(func: TaskFn) Cmd {
        return .{ .task = func };
    }

    pub fn batchCmd(cmds: []const Cmd) Cmd {
        return .{ .batch = cmds };
    }

    pub fn sequenceCmd(cmds: []const Cmd) Cmd {
        return .{ .sequence = cmds };
    }

    pub fn enterAltScreen() Cmd {
        return .enter_alt_screen;
    }

    pub fn exitAltScreen() Cmd {
        return .exit_alt_screen;
    }

    pub fn hideCursor() Cmd {
        return .hide_cursor;
    }

    pub fn showCursor() Cmd {
        return .show_cursor;
    }

    pub fn setCursor(x: u16, y: u16, style: CursorStyle) Cmd {
        return .{ .set_cursor = .{ .x = x, .y = y, .style = style } };
    }

    pub fn enableMouse(cell_motion: bool) Cmd {
        return .{ .enable_mouse = cell_motion };
    }

    pub fn disableMouse() Cmd {
        return .disable_mouse;
    }

    pub fn setWindowTitle(title: []const u8) Cmd {
        return .{ .set_window_title = title };
    }

    pub fn setClipboard(text: []const u8) Cmd {
        return .{ .set_clipboard = text };
    }

    pub fn readClipboard() Cmd {
        return .read_clipboard;
    }

    pub fn execProcess(argv: []const []const u8, on_done: ?*const fn (exit_code: u32) ?Msg) Cmd {
        return .{ .exec = .{ .argv = argv, .on_done = on_done } };
    }

    pub fn println(text: []const u8) Cmd {
        return .{ .print_line = text };
    }
};
