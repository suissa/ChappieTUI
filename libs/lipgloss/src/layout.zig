const std = @import("std");
const Position = @import("position.zig").Position;
const size = @import("size.zig");
const Buffer = @import("buffer.zig").Buffer;

/// Joins multiple multiline blocks horizontally with vertical alignment (top, center, bottom)
pub fn joinHorizontal(allocator: std.mem.Allocator, pos: Position, blocks: []const []const u8) ![]u8 {
    if (blocks.len == 0) return allocator.dupe(u8, "");
    if (blocks.len == 1) return allocator.dupe(u8, blocks[0]);

    // Split each block into lines and measure dimensions
    var block_lines = try allocator.alloc([][]const u8, blocks.len);
    defer {
        for (block_lines) |lines| allocator.free(lines);
        allocator.free(block_lines);
    }

    var block_widths = try allocator.alloc(usize, blocks.len);
    defer allocator.free(block_widths);

    var max_height: usize = 0;

    for (blocks, 0..) |b, b_idx| {
        block_widths[b_idx] = size.width(b);

        var count: usize = 0;
        var it = std.mem.splitScalar(u8, b, '\n');
        while (it.next()) |_| count += 1;

        var lines = try allocator.alloc([]const u8, count);
        var it2 = std.mem.splitScalar(u8, b, '\n');
        var l_idx: usize = 0;
        while (it2.next()) |line| {
            lines[l_idx] = line;
            l_idx += 1;
        }
        block_lines[b_idx] = lines;
        if (lines.len > max_height) max_height = lines.len;
    }

    var out = Buffer.init(allocator);
    errdefer out.deinit();

    // Render row by row across all blocks
    for (0..max_height) |row_idx| {
        for (blocks, 0..) |_, b_idx| {
            const lines = block_lines[b_idx];
            const w = block_widths[b_idx];

            var line_to_draw: ?[]const u8 = null;

            switch (pos) {
                .top, .left, .right => {
                    if (row_idx < lines.len) {
                        line_to_draw = lines[row_idx];
                    }
                },
                .bottom => {
                    const offset = max_height - lines.len;
                    if (row_idx >= offset) {
                        line_to_draw = lines[row_idx - offset];
                    }
                },
                .center => {
                    const top_pad = (max_height - lines.len) / 2;
                    if (row_idx >= top_pad and row_idx < top_pad + lines.len) {
                        line_to_draw = lines[row_idx - top_pad];
                    }
                },
            }

            if (line_to_draw) |l| {
                try out.writeAll(l);
                const cur_w = size.width(l);
                if (cur_w < w) {
                    for (0..(w - cur_w)) |_| try out.writeByte(' ');
                }
            } else {
                for (0..w) |_| try out.writeByte(' ');
            }
        }
        if (row_idx + 1 < max_height) {
            try out.writeByte('\n');
        }
    }

    return out.toOwnedSlice();
}

/// Joins multiple blocks vertically with horizontal alignment (left, center, right)
pub fn joinVertical(allocator: std.mem.Allocator, pos: Position, blocks: []const []const u8) ![]u8 {
    if (blocks.len == 0) return allocator.dupe(u8, "");
    if (blocks.len == 1) return allocator.dupe(u8, blocks[0]);

    var max_width: usize = 0;
    for (blocks) |b| {
        const w = size.width(b);
        if (w > max_width) max_width = w;
    }

    var out = Buffer.init(allocator);
    errdefer out.deinit();

    for (blocks, 0..) |b, b_idx| {
        var it = std.mem.splitScalar(u8, b, '\n');
        var first = true;
        while (it.next()) |line| {
            if (!first or b_idx > 0) try out.writeByte('\n');
            first = false;

            const w = size.width(line);
            switch (pos) {
                .left, .top, .bottom => {
                    try out.writeAll(line);
                    if (w < max_width) {
                        for (0..(max_width - w)) |_| try out.writeByte(' ');
                    }
                },
                .right => {
                    if (w < max_width) {
                        for (0..(max_width - w)) |_| try out.writeByte(' ');
                    }
                    try out.writeAll(line);
                },
                .center => {
                    const pad_left = (max_width - w) / 2;
                    const pad_right = max_width - w - pad_left;
                    for (0..pad_left) |_| try out.writeByte(' ');
                    try out.writeAll(line);
                    for (0..pad_right) |_| try out.writeByte(' ');
                },
            }
        }
    }

    return out.toOwnedSlice();
}

/// Places a text block inside a rectangular viewport of given width and height, aligned according to h_pos and v_pos
pub fn place(
    allocator: std.mem.Allocator,
    target_width: usize,
    target_height: usize,
    h_pos: Position,
    v_pos: Position,
    str: []const u8,
) ![]u8 {
    const cur_w = size.width(str);
    const cur_h = size.height(str);

    const final_w = @max(cur_w, target_width);
    const final_h = @max(cur_h, target_height);

    var count: usize = 0;
    var it_cnt = std.mem.splitScalar(u8, str, '\n');
    while (it_cnt.next()) |_| count += 1;

    var lines = try allocator.alloc([]const u8, count);
    defer allocator.free(lines);

    var it = std.mem.splitScalar(u8, str, '\n');
    var l_idx: usize = 0;
    while (it.next()) |line| {
        lines[l_idx] = line;
        l_idx += 1;
    }

    var out = Buffer.init(allocator);
    errdefer out.deinit();

    const top_offset: usize = switch (v_pos) {
        .top, .left, .right => 0,
        .bottom => if (final_h > lines.len) final_h - lines.len else 0,
        .center => if (final_h > lines.len) (final_h - lines.len) / 2 else 0,
    };

    for (0..final_h) |row| {
        if (row > 0) try out.writeByte('\n');

        if (row >= top_offset and row < top_offset + lines.len) {
            const line = lines[row - top_offset];
            const line_w = size.width(line);

            switch (h_pos) {
                .left, .top, .bottom => {
                    try out.writeAll(line);
                    if (line_w < final_w) {
                        for (0..(final_w - line_w)) |_| try out.writeByte(' ');
                    }
                },
                .right => {
                    if (line_w < final_w) {
                        for (0..(final_w - line_w)) |_| try out.writeByte(' ');
                    }
                    try out.writeAll(line);
                },
                .center => {
                    const pad_l = if (final_w > line_w) (final_w - line_w) / 2 else 0;
                    const pad_r = if (final_w > line_w + pad_l) final_w - line_w - pad_l else 0;
                    for (0..pad_l) |_| try out.writeByte(' ');
                    try out.writeAll(line);
                    for (0..pad_r) |_| try out.writeByte(' ');
                },
            }
        } else {
            for (0..final_w) |_| try out.writeByte(' ');
        }
    }

    return out.toOwnedSlice();
}

pub fn placeHorizontal(allocator: std.mem.Allocator, target_width: usize, pos: Position, str: []const u8) ![]u8 {
    return place(allocator, target_width, size.height(str), pos, .top, str);
}

pub fn placeVertical(allocator: std.mem.Allocator, target_height: usize, pos: Position, str: []const u8) ![]u8 {
    return place(allocator, size.width(str), target_height, .left, pos, str);
}

test "joinHorizontal and joinVertical" {
    const testing = std.testing;
    const a = "AA\nAA";
    const b = "BB\nBB";

    const joined_h = try joinHorizontal(testing.allocator, .top, &.{ a, b });
    defer testing.allocator.free(joined_h);
    try testing.expectEqualStrings("AABB\nAABB", joined_h);

    const joined_v = try joinVertical(testing.allocator, .left, &.{ a, b });
    defer testing.allocator.free(joined_v);
    try testing.expectEqualStrings("AA\nAA\nBB\nBB", joined_v);
}
