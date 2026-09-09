const std = @import("std");

pub const program = @import("program.zig");
pub const Program = program.Program;

pub const options = @import("options.zig");
pub const Options = options.Options;

pub const buffer = @import("buffer.zig");
pub const Buffer = buffer.Buffer;

pub const terminal = @import("terminal.zig");
pub const Terminal = terminal.Terminal;

pub const renderer = @import("renderer.zig");
pub const Renderer = renderer.Renderer;

pub const view = @import("view.zig");
pub const View = view.View;

pub const cursor = @import("cursor.zig");
pub const Cursor = cursor.Cursor;
pub const CursorStyle = cursor.CursorStyle;

pub const msg = @import("msg.zig");
pub const Msg = msg.Msg;
pub const WindowSizeMsg = msg.WindowSizeMsg;
pub const TickMsg = msg.TickMsg;
pub const CustomMsg = msg.CustomMsg;
pub const FocusMsg = msg.FocusMsg;
pub const BlurMsg = msg.BlurMsg;
pub const PasteMsg = msg.PasteMsg;
pub const ClipboardMsg = msg.ClipboardMsg;
pub const ExecMsg = msg.ExecMsg;

pub const key = @import("key.zig");
pub const Key = key.Key;
pub const KeyCode = key.KeyCode;

pub const mouse = @import("mouse.zig");
pub const MouseMsg = mouse.MouseMsg;
pub const MouseButton = mouse.MouseButton;
pub const MouseAction = mouse.MouseAction;
pub const MouseMode = mouse.MouseMode;

pub const cmd = @import("cmd.zig");
pub const Cmd = cmd.Cmd;
pub const TaskFn = cmd.TaskFn;

pub const style = @import("style.zig");
pub const Style = style.Style;
pub const Color = style.Color;
pub const Border = style.Border;
pub const Align = style.Align;

pub const clipboard = @import("clipboard.zig");
pub const ClipboardSelection = clipboard.ClipboardSelection;

pub const paste = @import("paste.zig");
pub const focus = @import("focus.zig");

pub const color = @import("color.zig");
pub const Profile = color.Profile;

pub const logging = @import("logging.zig");
pub const Logger = logging.Logger;
pub const logToFile = logging.logToFile;
pub const log = logging.log;

pub const exec = @import("exec.zig");
pub const ExecCmd = exec.ExecCmd;

// Helper constructors matching Bubble Tea idioms
pub fn quit() Cmd {
    return Cmd.quitCmd();
}

pub fn tick(duration_ms: u64, tag: usize) Cmd {
    return Cmd.tickCmd(duration_ms, tag);
}

pub fn every(interval_ms: u64, tag: usize) Cmd {
    return Cmd.everyCmd(interval_ms, tag);
}

pub fn none() Cmd {
    return Cmd.noneCmd();
}

pub fn batch(cmds: []const Cmd) Cmd {
    return Cmd.batchCmd(cmds);
}

pub fn sequence(cmds: []const Cmd) Cmd {
    return Cmd.sequenceCmd(cmds);
}

pub fn enterAltScreen() Cmd {
    return Cmd.enterAltScreen();
}

pub fn exitAltScreen() Cmd {
    return Cmd.exitAltScreen();
}

pub fn hideCursor() Cmd {
    return Cmd.hideCursor();
}

pub fn showCursor() Cmd {
    return Cmd.showCursor();
}

pub fn setCursor(x: u16, y: u16, c_style: CursorStyle) Cmd {
    return Cmd.setCursor(x, y, c_style);
}

pub fn enableMouse(cell_motion: bool) Cmd {
    return Cmd.enableMouse(cell_motion);
}

pub fn disableMouse() Cmd {
    return Cmd.disableMouse();
}

pub fn setWindowTitle(title: []const u8) Cmd {
    return Cmd.setWindowTitle(title);
}

pub fn setClipboard(text: []const u8) Cmd {
    return Cmd.setClipboard(text);
}

pub fn readClipboard() Cmd {
    return Cmd.readClipboard();
}

pub fn println(text: []const u8) Cmd {
    return Cmd.println(text);
}

pub fn execProcess(argv: []const []const u8, on_done: ?*const fn (exit_code: u32) ?Msg) Cmd {
    return Cmd.execProcess(argv, on_done);
}

test {
    std.testing.refAllDecls(@This());
}
