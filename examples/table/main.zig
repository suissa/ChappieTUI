const std = @import("std");
const tui = @import("tui");

const Row = struct {
    rank: []const u8,
    city: []const u8,
    country: []const u8,
    population: []const u8,
};

const rows = [_]Row{
    .{ .rank = "1", .city = "Tokyo", .country = "Japan", .population = "37,274,000" },
    .{ .rank = "2", .city = "Delhi", .country = "India", .population = "32,065,760" },
    .{ .rank = "3", .city = "Shanghai", .country = "China", .population = "28,516,904" },
    .{ .rank = "4", .city = "Dhaka", .country = "Bangladesh", .population = "22,478,116" },
    .{ .rank = "5", .city = "São Paulo", .country = "Brazil", .population = "22,429,800" },
    .{ .rank = "6", .city = "Mexico City", .country = "Mexico", .population = "22,085,140" },
    .{ .rank = "7", .city = "Cairo", .country = "Egypt", .population = "21,750,020" },
    .{ .rank = "8", .city = "Beijing", .country = "China", .population = "21,333,332" },
};

const Model = struct {
    selected_idx: usize = 0,

    pub fn init(self: *Model) tui.Cmd {
        _ = self;
        return tui.none();
    }

    pub fn update(self: *Model, msg: tui.Msg) tui.Cmd {
        switch (msg) {
            .key => |k| {
                if (k.matches("ctrl+c") or k.matches("q")) {
                    return tui.quit();
                } else if (k.matches("up") or k.matches("k")) {
                    if (self.selected_idx > 0) {
                        self.selected_idx -= 1;
                    }
                } else if (k.matches("down") or k.matches("j")) {
                    if (self.selected_idx < rows.len - 1) {
                        self.selected_idx += 1;
                    }
                }
            },
            else => {},
        }
        return tui.none();
    }

    pub fn view(self: *const Model, allocator: std.mem.Allocator) !tui.View {
        var doc = tui.Buffer.init(allocator);

        // Header
        try doc.writeAll("\x1b[38;5;240m┌──────┬────────────┬────────────┬────────────┐\x1b[0m\n");
        try doc.writeAll("\x1b[38;5;240m│\x1b[0m\x1b[1m Rank \x1b[0m\x1b[38;5;240m│\x1b[0m\x1b[1m City       \x1b[0m\x1b[38;5;240m│\x1b[0m\x1b[1m Country    \x1b[0m\x1b[38;5;240m│\x1b[0m\x1b[1m Population \x1b[0m\x1b[38;5;240m│\x1b[0m\n");
        try doc.writeAll("\x1b[38;5;240m├──────┼────────────┼────────────┼────────────┤\x1b[0m\n");

        // Data rows
        for (rows, 0..) |r, i| {
            const is_selected = (i == self.selected_idx);
            try doc.writeAll("\x1b[38;5;240m│\x1b[0m");

            if (is_selected) {
                // Highlight row (ANSI 57 / purple / reverse)
                try doc.writeAll("\x1b[7;38;5;57m");
                try doc.print(" {s:<4} │ {s:<10} │ {s:<10} │ {s:<10} ", .{ r.rank, r.city, r.country, r.population });
                try doc.writeAll("\x1b[0m");
            } else {
                try doc.print(" {s:<4} \x1b[38;5;240m│\x1b[0m {s:<10} \x1b[38;5;240m│\x1b[0m {s:<10} \x1b[38;5;240m│\x1b[0m {s:<10} ", .{ r.rank, r.city, r.country, r.population });
            }

            try doc.writeAll("\x1b[38;5;240m│\x1b[0m\n");
        }

        // Bottom border
        try doc.writeAll("\x1b[38;5;240m└──────┴────────────┴────────────┴────────────┘\x1b[0m\n");
        try doc.writeAll("  \x1b[38;5;240m↑/k up • ↓/j down • q quit\x1b[0m\n");

        return tui.View.init(try doc.toOwnedSlice());
    }
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const initial_model = Model{};
    var p = tui.Program(Model).init(allocator, initial_model);
    defer p.deinit();

    _ = try p.run();
}
