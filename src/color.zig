const std = @import("std");
const builtin = @import("builtin");

pub const Profile = enum {
    ascii,
    ansi,
    ansi256,
    truecolor,

    pub fn detect() Profile {
        if (builtin.os.tag == .windows) {
            // Modern Windows 10/11 console supports 24-bit TrueColor
            return .truecolor;
        }

        // On POSIX check COLORTERM and TERM
        if (std.posix.getenv("COLORTERM")) |ct| {
            if (std.mem.eql(u8, ct, "truecolor") or std.mem.eql(u8, ct, "24bit")) {
                return .truecolor;
            }
        }

        if (std.posix.getenv("TERM")) |term| {
            if (std.mem.indexOf(u8, term, "256color") != null) {
                return .ansi256;
            }
            if (std.mem.eql(u8, term, "dumb")) {
                return .ascii;
            }
            return .ansi;
        }

        return .ansi256;
    }
};

test "color profile detect" {
    const p = Profile.detect();
    _ = p;
}
