const std = @import("std");
pub const Key = @import("key.zig").Key;
pub const MouseMsg = @import("mouse.zig").MouseMsg;

pub const WindowSizeMsg = struct {
    width: u16,
    height: u16,
};

pub const TickMsg = struct {
    time_ms: i64,
    tag: usize = 0,
};

pub const CustomMsg = struct {
    id: usize = 0,
    data: usize = 0,
    ptr: ?*anyopaque = null,
};

pub const FocusMsg = @import("focus.zig").FocusMsg;
pub const BlurMsg = @import("focus.zig").BlurMsg;
pub const PasteMsg = @import("paste.zig").PasteMsg;
pub const ClipboardMsg = @import("clipboard.zig").ClipboardMsg;
pub const ExecMsg = @import("exec.zig").ExecMsg;

pub const Msg = union(enum) {
    key: Key,
    mouse: MouseMsg,
    window_size: WindowSizeMsg,
    tick: TickMsg,
    focus: FocusMsg,
    blur: BlurMsg,
    paste: PasteMsg,
    clipboard: ClipboardMsg,
    exec: ExecMsg,
    custom: CustomMsg,
    quit,
    @"suspend",
    @"resume",
};
