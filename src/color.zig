const std = @import("std");
const builtin = @import("builtin");

pub const Profile = enum {
    ascii,
    ansi,
    ansi256,
    truecolor,

    pub fn detect() Profile {
        if (builtin.os.tag == .windows or builtin.os.tag == .macos) {
            // Modern Windows and macOS terminals support 24-bit TrueColor.
            return .truecolor;
        }

        // Environment access became explicit in Zig 0.16. Keep this zero-context
        // helper conservative and portable; callers that need environment-aware
        // detection can provide that policy at the application boundary.
        return .ansi256;
    }
};

test "color profile detect" {
    const p = Profile.detect();
    _ = p;
}
