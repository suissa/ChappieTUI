const std = @import("std");
const tui = @import("tui");

const Model = struct {
    countdown: i32 = 5,

    pub fn init(self: *Model) tui.Cmd {
        _ = self;
        return tui.tick(1000, 0);
    }

    pub fn update(self: *Model, msg: tui.Msg) tui.Cmd {
        switch (msg) {
            .key => |k| {
                if (k.matches("ctrl+c") or k.matches("q")) {
                    return tui.quit();
                }
            },
            .tick => {
                self.countdown -= 1;
                if (self.countdown <= 0) {
                    return tui.quit();
                }
                return tui.tick(1000, 0);
            },
            else => {},
        }
        return tui.none();
    }

    pub fn view(self: *const Model, allocator: std.mem.Allocator) !tui.View {
        var buf = tui.Buffer.init(allocator);
        try buf.print("Hi. This program will exit in {d} seconds.\n\nTo quit sooner press ctrl-c, or press ctrl-z to suspend...\n", .{self.countdown});
        return tui.View.init(try buf.toOwnedSlice());
    }
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const initial_model = Model{};
    var p = tui.Program(Model).init(allocator, initial_model);
    defer p.deinit();

    _ = try p.run();
}
