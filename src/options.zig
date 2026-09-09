const std = @import("std");
const Msg = @import("msg.zig").Msg;
const mouse = @import("mouse.zig");

pub const Options = struct {
    alt_screen: bool = false,
    mouse_mode: mouse.MouseMode = .none,
    fps: u32 = 60,
    disable_renderer: bool = false,
    window_title: ?[]const u8 = null,
    filter: ?*const fn (msg: Msg) ?Msg = null,
    report_focus: bool = false,
    bracketed_paste: bool = false,
    catch_panics: bool = true,

    pub fn withAltScreen(self: Options) Options {
        var opt = self;
        opt.alt_screen = true;
        return opt;
    }

    pub fn withMouseCellMotion(self: Options) Options {
        var opt = self;
        opt.mouse_mode = .cell_motion;
        return opt;
    }

    pub fn withMouseAllMotion(self: Options) Options {
        var opt = self;
        opt.mouse_mode = .all_motion;
        return opt;
    }

    pub fn withFPS(self: Options, target_fps: u32) Options {
        var opt = self;
        opt.fps = std.math.clamp(target_fps, 1, 120);
        return opt;
    }

    pub fn withoutRenderer(self: Options) Options {
        var opt = self;
        opt.disable_renderer = true;
        return opt;
    }

    pub fn withWindowTitle(self: Options, title: []const u8) Options {
        var opt = self;
        opt.window_title = title;
        return opt;
    }

    pub fn withFilter(self: Options, filter_fn: *const fn (msg: Msg) ?Msg) Options {
        var opt = self;
        opt.filter = filter_fn;
        return opt;
    }

    pub fn withReportFocus(self: Options) Options {
        var opt = self;
        opt.report_focus = true;
        return opt;
    }

    pub fn withBracketedPaste(self: Options) Options {
        var opt = self;
        opt.bracketed_paste = true;
        return opt;
    }
};
