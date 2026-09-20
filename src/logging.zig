const std = @import("std");

pub const Logger = struct {
    file: ?std.Io.File = null,
    prefix: []const u8 = "",

    fn io() std.Io {
        var threaded: std.Io.Threaded = .init_single_threaded;
        return threaded.io();
    }

    pub fn init(path: []const u8, prefix: []const u8) !Logger {
        const current_io = io();
        const file = std.Io.Dir.cwd().createFile(current_io, path, .{
            .read = false,
            .truncate = false,
        }) catch return error.AccessDenied;
        return .{ .file = file, .prefix = prefix };
    }

    pub fn deinit(self: *Logger) void {
        if (self.file) |file| {
            file.close(io());
            self.file = null;
        }
    }

    pub fn log(self: *Logger, comptime fmt: []const u8, args: anytype) void {
        const file = self.file orelse return;

        var buf: [1024]u8 = undefined;
        const msg = std.fmt.bufPrint(&buf, "[{s}] " ++ fmt ++ "\n", .{self.prefix} ++ args) catch return;

        const current_io = io();
        const end = file.length(current_io) catch return;
        file.writePositionalAll(current_io, msg, end) catch return;
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
