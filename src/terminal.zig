const std = @import("std");
const builtin = @import("builtin");
const is_windows = builtin.os.tag == .windows;

pub const HANDLE = *anyopaque;
pub const BOOL = i32;
pub const DWORD = u32;
pub const SHORT = i16;

pub const STD_INPUT_HANDLE: i32 = -10;
pub const STD_OUTPUT_HANDLE: i32 = -11;
pub const STD_ERROR_HANDLE: i32 = -12;

pub const COORD = extern struct {
    X: SHORT,
    Y: SHORT,
};

pub const SMALL_RECT = extern struct {
    Left: SHORT,
    Top: SHORT,
    Right: SHORT,
    Bottom: SHORT,
};

pub const CONSOLE_SCREEN_BUFFER_INFO = extern struct {
    dwSize: COORD,
    dwCursorPosition: COORD,
    wAttributes: u16,
    srWindow: SMALL_RECT,
    dwMaximumWindowSize: COORD,
};

// Win32 console functions
extern "kernel32" fn GetStdHandle(nStdHandle: i32) callconv(.winapi) ?HANDLE;
extern "kernel32" fn GetConsoleMode(hConsoleHandle: ?HANDLE, lpMode: *DWORD) callconv(.winapi) BOOL;
extern "kernel32" fn SetConsoleMode(hConsoleHandle: ?HANDLE, dwMode: DWORD) callconv(.winapi) BOOL;
extern "kernel32" fn GetConsoleOutputCP() callconv(.winapi) u32;
extern "kernel32" fn SetConsoleOutputCP(wCodePageID: u32) callconv(.winapi) BOOL;
extern "kernel32" fn GetConsoleCP() callconv(.winapi) u32;
extern "kernel32" fn SetConsoleCP(wCodePageID: u32) callconv(.winapi) BOOL;
extern "kernel32" fn GetConsoleScreenBufferInfo(
    hConsoleOutput: ?HANDLE,
    lpConsoleScreenBufferInfo: *CONSOLE_SCREEN_BUFFER_INFO,
) callconv(.winapi) BOOL;
extern "kernel32" fn ReadFile(
    hFile: ?HANDLE,
    lpBuffer: [*]u8,
    nNumberOfBytesToRead: DWORD,
    lpNumberOfBytesRead: ?*DWORD,
    lpOverlapped: ?*anyopaque,
) callconv(.winapi) BOOL;
extern "kernel32" fn WriteFile(
    hFile: ?HANDLE,
    lpBuffer: [*]const u8,
    nNumberOfBytesToWrite: DWORD,
    lpNumberOfBytesWritten: ?*DWORD,
    lpOverlapped: ?*anyopaque,
) callconv(.winapi) BOOL;

pub const TerminalState = struct {
    orig_in_mode: DWORD = 0,
    orig_out_mode: DWORD = 0,
    orig_out_cp: u32 = 0,
    orig_in_cp: u32 = 0,
    in_handle: ?HANDLE = null,
    out_handle: ?HANDLE = null,
    is_raw: bool = false,
    altscreen_active: bool = false,
    cursor_hidden: bool = false,
    orig_termios: ?std.posix.termios = null,
};

pub const Terminal = struct {
    state: TerminalState = .{},

    pub fn init() Terminal {
        var term = Terminal{};
        if (is_windows) {
            term.state.in_handle = GetStdHandle(STD_INPUT_HANDLE);
            term.state.out_handle = GetStdHandle(STD_OUTPUT_HANDLE);
            if (term.state.in_handle) |hIn| {
                _ = GetConsoleMode(hIn, &term.state.orig_in_mode);
            }
            if (term.state.out_handle) |hOut| {
                _ = GetConsoleMode(hOut, &term.state.orig_out_mode);
            }
            term.state.orig_out_cp = GetConsoleOutputCP();
            term.state.orig_in_cp = GetConsoleCP();
        }
        return term;
    }

    pub fn enableRawMode(self: *Terminal) void {
        if (self.state.is_raw) return;

        if (is_windows) {
            // Force UTF-8 (Code Page 65001) for crisp Unicode box drawing
            _ = SetConsoleOutputCP(65001);
            _ = SetConsoleCP(65001);

            if (self.state.out_handle) |hOut| {
                // ENABLE_PROCESSED_OUTPUT (0x1) | ENABLE_WRAP_AT_EOL_OUTPUT (0x2) | ENABLE_VIRTUAL_TERMINAL_PROCESSING (0x4)
                const out_mode: DWORD = self.state.orig_out_mode | 0x0001 | 0x0002 | 0x0004;
                _ = SetConsoleMode(hOut, out_mode);
            }
            if (self.state.in_handle) |hIn| {
                // ENABLE_VIRTUAL_TERMINAL_INPUT (0x0200) | ENABLE_WINDOW_INPUT (0x0008)
                const in_mode: DWORD = 0x0200 | 0x0008;
                _ = SetConsoleMode(hIn, in_mode);
            }
        } else {
            // POSIX raw mode
            self.state.orig_termios = std.posix.tcgetattr(0) catch null;
            if (self.state.orig_termios) |orig| {
                var raw = orig;
                raw.iflag.IGNBRK = false;
                raw.iflag.BRKINT = false;
                raw.iflag.PARMRK = false;
                raw.iflag.ISTRIP = false;
                raw.iflag.INLCR = false;
                raw.iflag.IGNCR = false;
                raw.iflag.ICRNL = false;
                raw.iflag.IXON = false;
                raw.oflag.OPOST = false;
                raw.lflag.ECHO = false;
                raw.lflag.ECHONL = false;
                raw.lflag.ICANON = false;
                raw.lflag.ISIG = false;
                raw.lflag.IEXTEN = false;
                raw.cflag.CSIZE = .CS8;
                raw.cflag.PARENB = false;
                raw.cc[@intFromEnum(std.posix.V.MIN)] = 1;
                raw.cc[@intFromEnum(std.posix.V.TIME)] = 0;
                std.posix.tcsetattr(0, .NOW, raw) catch {};
            }
        }
        self.state.is_raw = true;
    }

    pub fn restore(self: *Terminal) void {
        if (self.state.altscreen_active) {
            self.exitAltScreen();
        }
        if (self.state.cursor_hidden) {
            self.showCursor();
        }
        self.disableMouse();

        if (is_windows and self.state.is_raw) {
            if (self.state.orig_out_cp != 0) {
                _ = SetConsoleOutputCP(self.state.orig_out_cp);
            }
            if (self.state.orig_in_cp != 0) {
                _ = SetConsoleCP(self.state.orig_in_cp);
            }
            if (self.state.in_handle) |hIn| {
                _ = SetConsoleMode(hIn, self.state.orig_in_mode);
            }
            if (self.state.out_handle) |hOut| {
                _ = SetConsoleMode(hOut, self.state.orig_out_mode);
            }
        } else if (!is_windows and self.state.is_raw) {
            if (self.state.orig_termios) |orig| {
                std.posix.tcsetattr(0, .NOW, orig) catch {};
            }
        }
        self.state.is_raw = false;
    }

    pub fn enterAltScreen(self: *Terminal) void {
        self.writeAll("\x1b[?1049h\x1b[H");
        self.state.altscreen_active = true;
    }

    pub fn exitAltScreen(self: *Terminal) void {
        self.writeAll("\x1b[?1049l");
        self.state.altscreen_active = false;
    }

    pub fn hideCursor(self: *Terminal) void {
        self.writeAll("\x1b[?25l");
        self.state.cursor_hidden = true;
    }

    pub fn showCursor(self: *Terminal) void {
        self.writeAll("\x1b[?25h");
        self.state.cursor_hidden = false;
    }

    pub fn clearScreen(self: *Terminal) void {
        self.writeAll("\x1b[2J\x1b[H");
    }

    pub fn setWindowTitle(self: *Terminal, title: []const u8) void {
        var buf: [256]u8 = undefined;
        const msg = std.fmt.bufPrint(&buf, "\x1b]0;{s}\x07", .{title}) catch return;
        self.writeAll(msg);
    }

    pub fn enableMouse(self: *Terminal, cell_motion: bool) void {
        if (cell_motion) {
            self.writeAll("\x1b[?1000h\x1b[?1002h\x1b[?1006h");
        } else {
            self.writeAll("\x1b[?1000h\x1b[?1003h\x1b[?1006h");
        }
    }

    pub fn disableMouse(self: *Terminal) void {
        self.writeAll("\x1b[?1000l\x1b[?1002l\x1b[?1003l\x1b[?1006l");
    }

    pub fn getWindowSize(self: *Terminal) struct { width: u16, height: u16 } {
        if (is_windows) {
            if (self.state.out_handle) |hOut| {
                var csbi: CONSOLE_SCREEN_BUFFER_INFO = undefined;
                if (GetConsoleScreenBufferInfo(hOut, &csbi) != 0) {
                    const w = csbi.srWindow.Right - csbi.srWindow.Left + 1;
                    const h = csbi.srWindow.Bottom - csbi.srWindow.Top + 1;
                    if (w > 0 and h > 0) {
                        return .{ .width = @intCast(w), .height = @intCast(h) };
                    }
                }
            }
        }
        return .{ .width = 80, .height = 24 };
    }

    pub fn writeAll(self: *Terminal, data: []const u8) void {
        if (data.len == 0) return;
        if (is_windows) {
            if (self.state.out_handle) |hOut| {
                var written: DWORD = 0;
                _ = WriteFile(hOut, data.ptr, @intCast(data.len), &written, null);
                return;
            }
        } else {
            _ = std.posix.system.write(1, data.ptr, data.len);
            return;
        }
        std.debug.print("{s}", .{data});
    }

    pub fn readInput(self: *Terminal, buffer: []u8) usize {
        if (buffer.len == 0) return 0;
        if (is_windows) {
            if (self.state.in_handle) |hIn| {
                var read_bytes: DWORD = 0;
                if (ReadFile(hIn, buffer.ptr, @intCast(buffer.len), &read_bytes, null) != 0) {
                    return @intCast(read_bytes);
                }
            }
        } else {
            const rc = std.posix.system.read(0, buffer.ptr, buffer.len);
            const signed_rc: isize = @bitCast(rc);
            if (signed_rc > 0) return @intCast(signed_rc);
        }
        return 0;
    }
};
