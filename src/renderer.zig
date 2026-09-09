const std = @import("std");
const Buffer = @import("buffer.zig").Buffer;
const Terminal = @import("terminal.zig").Terminal;
const View = @import("view.zig").View;
const Cursor = @import("cursor.zig").Cursor;

pub const Renderer = struct {
    terminal: *Terminal,
    allocator: std.mem.Allocator,
    prev_lines_count: usize = 0,
    altscreen_enabled: bool = false,
    mouse_mode_enabled: bool = false,

    pub fn init(allocator: std.mem.Allocator, terminal: *Terminal) Renderer {
        return .{
            .allocator = allocator,
            .terminal = terminal,
        };
    }

    pub fn render(self: *Renderer, view: View) !void {
        // Handle AltScreen transition
        if (view.alt_screen and !self.altscreen_enabled) {
            self.terminal.enterAltScreen();
            self.altscreen_enabled = true;
            self.prev_lines_count = 0;
        } else if (!view.alt_screen and self.altscreen_enabled) {
            self.terminal.exitAltScreen();
            self.altscreen_enabled = false;
            self.prev_lines_count = 0;
        }

        // Handle Window Title
        if (view.window_title) |title| {
            self.terminal.setWindowTitle(title);
        }

        // Handle Mouse Mode
        if (view.mouse_mode != .none and !self.mouse_mode_enabled) {
            self.terminal.enableMouse(view.mouse_mode == .cell_motion);
            self.mouse_mode_enabled = true;
        } else if (view.mouse_mode == .none and self.mouse_mode_enabled) {
            self.terminal.disableMouse();
            self.mouse_mode_enabled = false;
        }

        var out = Buffer.init(self.allocator);
        defer out.deinit();

        // Begin Synchronized Update & hide cursor while drawing to eliminate flicker
        try out.writeAll("\x1b[?2026h\x1b[?25l");

        if (self.altscreen_enabled) {
            // In altscreen, reposition cursor to top-left (1,1)
            try out.writeAll("\x1b[H");
            try out.writeAll(view.content);
            try out.writeAll("\x1b[J"); // clear to end of screen
        } else {
            // In standard inline mode:
            if (self.prev_lines_count > 0) {
                // Move cursor up to the beginning of the previously rendered block
                try out.print("\x1b[{d}A\r", .{self.prev_lines_count});
                // Clear from cursor to bottom of screen
                try out.writeAll("\x1b[J");
            }

            try out.writeAll(view.content);

            // Ensure content ends with newline if not empty
            if (view.content.len > 0 and view.content[view.content.len - 1] != '\n') {
                try out.writeByte('\n');
            }
        }

        // Count lines in rendered content
        var lines: usize = 0;
        for (view.content) |c| {
            if (c == '\n') lines += 1;
        }
        if (view.content.len > 0 and view.content[view.content.len - 1] != '\n') {
            lines += 1;
        }
        self.prev_lines_count = lines;

        // Render cursor position & style
        if (view.cursor) |c| {
            try c.toAnsi(&out);
        } else {
            // Keep cursor hidden
            try out.writeAll("\x1b[?25l");
        }

        // End Synchronized Update
        try out.writeAll("\x1b[?2026l");

        // Flush all output atomically at once
        self.terminal.writeAll(out.items());
    }

    pub fn clear(self: *Renderer) void {
        if (self.prev_lines_count > 0 and !self.altscreen_enabled) {
            var buf: [64]u8 = undefined;
            const seq = std.fmt.bufPrint(&buf, "\x1b[{d}A\r\x1b[J", .{self.prev_lines_count}) catch return;
            self.terminal.writeAll(seq);
            self.prev_lines_count = 0;
        }
    }
};
