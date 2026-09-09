const std = @import("std");
const builtin = @import("builtin");
const Msg = @import("msg.zig").Msg;

pub const ExecMsg = struct {
    exit_code: u32 = 0,
    err: ?[]const u8 = null,
};

// Win32 declarations for external process execution
extern "kernel32" fn CreateProcessW(
    lpApplicationName: ?[*:0]const u16,
    lpCommandLine: ?[*:0]u16,
    lpProcessAttributes: ?*anyopaque,
    lpThreadAttributes: ?*anyopaque,
    bInheritHandles: i32,
    dwCreationFlags: u32,
    lpEnvironment: ?*anyopaque,
    lpCurrentDirectory: ?[*:0]const u16,
    lpStartupInfo: *STARTUPINFOW,
    lpProcessInformation: *PROCESS_INFORMATION,
) callconv(.winapi) i32;

extern "kernel32" fn WaitForSingleObject(hHandle: ?*anyopaque, dwMilliseconds: u32) callconv(.winapi) u32;
extern "kernel32" fn GetExitCodeProcess(hProcess: ?*anyopaque, lpExitCode: *u32) callconv(.winapi) i32;
extern "kernel32" fn CloseHandle(hObject: ?*anyopaque) callconv(.winapi) i32;

const STARTUPINFOW = extern struct {
    cb: u32 = @sizeOf(STARTUPINFOW),
    lpReserved: ?[*:0]u16 = null,
    lpDesktop: ?[*:0]u16 = null,
    lpTitle: ?[*:0]u16 = null,
    dwX: u32 = 0,
    dwY: u32 = 0,
    dwXSize: u32 = 0,
    dwYSize: u32 = 0,
    dwXCountChars: u32 = 0,
    dwYCountChars: u32 = 0,
    dwFillAttribute: u32 = 0,
    dwFlags: u32 = 0,
    wShowWindow: u16 = 0,
    cbReserved2: u16 = 0,
    lpReserved2: ?*u8 = null,
    hStdInput: ?*anyopaque = null,
    hStdOutput: ?*anyopaque = null,
    hStdError: ?*anyopaque = null,
};

const PROCESS_INFORMATION = extern struct {
    hProcess: ?*anyopaque = null,
    hThread: ?*anyopaque = null,
    dwProcessId: u32 = 0,
    dwThreadId: u32 = 0,
};

pub const ExecCmd = struct {
    argv: []const []const u8,
    on_done: ?*const fn (exit_code: u32) ?Msg = null,

    pub fn run(self: ExecCmd, allocator: std.mem.Allocator) ?Msg {
        if (self.argv.len == 0) return null;

        var exit_code: u32 = 0;
        var err_name: ?[]const u8 = null;

        if (builtin.os.tag == .windows) {
            var cmd_buf: [1024]u8 = undefined;
            var pos: usize = 0;
            for (self.argv, 0..) |arg, i| {
                if (i > 0 and pos < cmd_buf.len) {
                    cmd_buf[pos] = ' ';
                    pos += 1;
                }
                const end = @min(pos + arg.len, cmd_buf.len);
                @memcpy(cmd_buf[pos..end], arg[0 .. end - pos]);
                pos = end;
            }

            var cmd_w: [1024:0]u16 = undefined;
            const len = std.unicode.utf8ToUtf16Le(&cmd_w, cmd_buf[0..pos]) catch {
                return Msg{ .exec = .{ .exit_code = 1, .err = "Utf8ConversionFailed" } };
            };
            cmd_w[len] = 0;

            var si: STARTUPINFOW = .{};
            var pi: PROCESS_INFORMATION = .{};

            const res = CreateProcessW(
                null,
                &cmd_w,
                null,
                null,
                1, // inherit handles
                0,
                null,
                null,
                &si,
                &pi,
            );

            if (res != 0) {
                const INFINITE: u32 = 0xFFFFFFFF;
                _ = WaitForSingleObject(pi.hProcess, INFINITE);
                var code: u32 = 0;
                _ = GetExitCodeProcess(pi.hProcess, &code);
                _ = CloseHandle(pi.hProcess);
                _ = CloseHandle(pi.hThread);
                exit_code = code;
            } else {
                exit_code = 1;
                err_name = "CreateProcessFailed";
            }
        } else {
            // POSIX fork & exec
            const rc = std.posix.system.fork();
            if (rc < 0) {
                return Msg{ .exec = .{ .exit_code = 1, .err = "ForkFailed" } };
            }
            if (rc == 0) {
                var c_argv = allocator.alloc(?[*:0]const u8, self.argv.len + 1) catch std.posix.system.exit(1);
                for (self.argv, 0..) |arg, i| {
                    const arg_z = allocator.dupeZ(u8, arg) catch std.posix.system.exit(1);
                    c_argv[i] = arg_z.ptr;
                }
                c_argv[self.argv.len] = null;

                const empty_env: [1:null]?[*:0]const u8 = .{null};
                _ = std.posix.system.execve(c_argv[0].?, @ptrCast(c_argv.ptr), &empty_env);
                std.posix.system.exit(127);
            } else {
                if (builtin.os.tag == .macos or builtin.os.tag == .freebsd or builtin.os.tag == .openbsd) {
                    var status: c_int = 0;
                    _ = std.posix.system.waitpid(@intCast(rc), &status, 0);
                    exit_code = @intCast(@max(0, status));
                } else {
                    var status: u32 = 0;
                    _ = std.posix.system.waitpid(@intCast(rc), &status, 0);
                    exit_code = status;
                }
            }
        }

        if (self.on_done) |cb| {
            return cb(exit_code);
        }

        return Msg{
            .exec = .{
                .exit_code = exit_code,
                .err = err_name,
            },
        };
    }
};
