const std = @import("std");

pub const enable_bracketed_paste = "\x1b[?2004h";
pub const disable_bracketed_paste = "\x1b[?2004l";

pub const paste_start = "\x1b[200~";
pub const paste_end = "\x1b[201~";

pub const PasteMsg = struct {
    content: []const u8,
};
