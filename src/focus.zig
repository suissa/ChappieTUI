const std = @import("std");

pub const enable_focus_reporting = "\x1b[?1004h";
pub const disable_focus_reporting = "\x1b[?1004l";

pub const FocusMsg = struct {};
pub const BlurMsg = struct {};
