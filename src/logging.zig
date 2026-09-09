const std = @import("std");
const builtin = @import("builtin");

// Win32 API
extern "kernel32" fn CreateFileW(
    lpFileName: [*:0]const u16,
    dwDesiredAccess: u32,
    dwShareMode: u32,
    lpSecurityAttributes: ?*anyopaque,
    dwCreationDisposition: u32,
    dwFlagsAndAttributes: u32,
    hTemplateFile: ?*anyopaque,
) callconv(.winapi) ?*anyopaque;

extern "kernel32" fn CloseHandle(hObject: ?*anyopaque) callconv(.winapi) i32;
extern "kernel32" fn WriteFile(
    hFile: ?*anyopaque,
    lpBuffer: [*]const u8,
    nNumberOfBytesToWrite: u32,
    lpNumberOfBytesWritten: ?*u32,
    lpOverlapped: ?*anyopaque,
) callconv(.winapi) i32;
extern "kernel32" fn SetFilePointer(
    hFile: ?*anyopaque,
    lDistanceToMove: i32,
    lpDistanceToMoveHigh: ?*i32,
    dwMoveMethod: u32,
) callconv(.winapi) u32;

pub const Logger = struct {
    handle: ?*anyopaque = null,
    fd: i32 = -1,
    prefix: []const u8 = "",

    pub fn init(path: []const u8, prefix: []const u8) !Logger {
        if (builtin.os.tag == .windows) {
            var path_w: [260:0]u16 = undefined;
            const len = try std.unicode.utf8ToUtf16Le(&path_w, path);
            path_w[len] = 0;
            const GENERIC_WRITE: u32 = 0x40000000;
            const FILE_SHARE_READ: u32 = 0x00000001;
            const OPEN_ALWAYS: u32 = 4;
            const FILE_ATTRIBUTE_NORMAL: u32 = 0x80;

            const h = CreateFileW(
                &path_w,
                GENERIC_WRITE,
                FILE_SHARE_READ,
                null,
                OPEN_ALWAYS,
                FILE_ATTRIBUTE_NORMAL,
                null,
            );
            if (h == null or @intFromPtr(h) == ~@as(usize, 0)) return error.AccessDenied;
            _ = SetFilePointer(h, 0, null, 2); // FILE_END
            return .{ .handle = h, .prefix = prefix };
        } else {
            const fd_val = std.posix.open(path, .{ .ACCMODE = .WRONLY, .CREAT = true, .APPEND = true }, 0o644) catch return error.AccessDenied;
            return .{ .fd = fd_val, .prefix = prefix };
        }
    }

    pub fn deinit(self: *Logger) void {
        if (builtin.os.tag == .windows) {
            if (self.handle) |h| {
                _ = CloseHandle(h);
                self.handle = null;
            }
        } else {
            if (self.fd >= 0) {
                std.posix.close(self.fd);
                self.fd = -1;
            }
        }
    }

    pub fn log(self: *Logger, comptime fmt: []const u8, args: anytype) void {
        var buf: [1024]u8 = undefined;
        const msg = std.fmt.bufPrint(&buf, "[{s}] " ++ fmt ++ "\n", .{self.prefix} ++ args) catch return;

        if (builtin.os.tag == .windows) {
            if (self.handle) |h| {
                var written: u32 = 0;
                _ = WriteFile(h, msg.ptr, @intCast(msg.len), &written, null);
            }
        } else {
            if (self.fd >= 0) {
                _ = std.posix.system.write(self.fd, msg.ptr, msg.len);
            }
        }
    }
};

var global_logger: ?Logger = null;

pub fn logToFile(path: []const u8, prefix: []const u8) !void {
    if (global_logger) |*l| {
        l.deinit();
    }
    global_logger = try Logger.init(path, prefix);
}

pub fn log(comptime fmt: []const u8, args: anytype) void {
    if (global_logger) |*l| {
        l.log(fmt, args);
    }
}
