const std = @import("std");
const tui = @import("tui");

const url = "https://charm.sh/";

const Model = struct {
    status: u16 = 0,
    err: ?[]const u8 = null,

    pub fn init(self: *Model) tui.Cmd {
        _ = self;
        return tui.Cmd.taskCmd(checkServer);
    }

    pub fn update(self: *Model, msg: tui.Msg) tui.Cmd {
        switch (msg) {
            .custom => |c| {
                if (c.id == 1) {
                    // Status code message
                    self.status = @intCast(c.data);
                    return tui.quit();
                } else if (c.id == 2) {
                    // Error message
                    self.err = "connection error";
                    return tui.quit();
                }
            },
            .key => |k| {
                if (k.matches("ctrl+c") or k.matches("q")) {
                    return tui.quit();
                }
            },
            else => {},
        }
        return tui.none();
    }

    pub fn view(self: *const Model, allocator: std.mem.Allocator) !tui.View {
        var buf = tui.Buffer.init(allocator);

        if (self.err) |e| {
            try buf.print("\nWe had some trouble: {s}\n\n", .{e});
            return tui.View.init(try buf.toOwnedSlice());
        }

        try buf.print("\nChecking {s} ... ", .{url});
        if (self.status > 0) {
            const status_text = switch (self.status) {
                200 => "OK",
                404 => "Not Found",
                500 => "Internal Server Error",
                else => "Unknown",
            };
            try buf.print("{d} {s}!\n\n", .{ self.status, status_text });
        } else {
            try buf.writeAll("\n\n");
        }

        return tui.View.init(try buf.toOwnedSlice());
    }
};

fn checkServer() ?tui.Msg {
    // Simulate network query or fast HTTP check
    tui.program.sleepMs(50);
    return tui.Msg{
        .custom = .{
            .id = 1,
            .data = 200,
        },
    };
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const initial_model = Model{};
    var p = tui.Program(Model).init(allocator, initial_model);
    defer p.deinit();

    _ = try p.run();
}
