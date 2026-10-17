//! Constraint-based Flex layout primitives for terminal components.
//! Layout is computed in terminal cells and does not allocate memory.

const std = @import("std");

pub const Direction = enum { horizontal, vertical };

pub const Sizing = union(enum) {
    fixed: usize,
    intrinsic: usize,
    flex: u32,
};

pub const Item = struct {
    sizing: Sizing,
    min: usize = 0,
    max: usize = std.math.maxInt(usize),
};

pub const Placement = struct {
    offset: usize = 0,
    size: usize = 0,
};

pub const LayoutError = error{OutputTooSmall};

fn clampSize(value: usize, item: Item) usize {
    return @min(item.max, @max(item.min, value));
}

/// Computes item offsets and sizes within `available` terminal cells.
/// Fixed and intrinsic items take their clamped base size; flexible items
/// share remaining cells by weight, respecting min/max constraints.
/// If fixed content exceeds the available area, positions remain valid and
/// flexible items collapse toward their minimum sizes.
pub fn layout(
    items: []const Item,
    available: usize,
    gap: usize,
    output: []Placement,
) LayoutError!void {
    if (output.len < items.len) return error.OutputTooSmall;
    if (items.len == 0) return;

    const gap_count = items.len - 1;
    const multiplied = @mulWithOverflow(gap, gap_count);
    const total_gap = if (multiplied[1] != 0) available else @min(available, multiplied[0]);
    const usable = available - total_gap;

    var used: usize = 0;
    for (items, 0..) |item, index| {
        const base = switch (item.sizing) {
            .fixed => |size| clampSize(size, item),
            .intrinsic => |size| clampSize(size, item),
            .flex => clampSize(item.min, item),
        };
        output[index] = .{ .offset = 0, .size = base };
        used +|= base;
    }

    var remaining = usable -| used;
    // Re-distribute leftover space until all flexible items hit max or no
    // additional cell can be assigned. The fallback guarantees progress when
    // weighted integer division rounds every share down to zero.
    while (remaining > 0) {
        var total_weight: u64 = 0;
        for (items, 0..) |item, index| {
            switch (item.sizing) {
                .flex => |weight| {
                    if (output[index].size < item.max) total_weight += @max(1, weight);
                },
                else => {},
            }
        }
        if (total_weight == 0) break;

        const before = remaining;
        const round_remaining = remaining;
        for (items, 0..) |item, index| {
            const flex_weight: u32 = switch (item.sizing) {
                .flex => |weight| weight,
                else => continue,
            };
            if (output[index].size >= item.max) continue;
            const weight: u64 = @max(1, flex_weight);
            const share: usize = @intCast((@as(u64, @intCast(round_remaining)) * weight) / total_weight);
            if (share == 0) continue;
            const room = item.max - output[index].size;
            const added = @min(room, @min(share, remaining));
            output[index].size += added;
            remaining -= added;
            if (remaining == 0) break;
        }

        if (remaining == before) {
            for (items, 0..) |item, index| {
                const is_flex = switch (item.sizing) {
                    .flex => true,
                    else => false,
                };
                if (!is_flex or output[index].size >= item.max) continue;
                output[index].size += 1;
                remaining -= 1;
                if (remaining == 0) break;
            }
        }
    }

    var offset: usize = 0;
    for (output[0..items.len]) |*placement| {
        placement.offset = offset;
        offset +|= placement.size;
        offset +|= gap;
    }
}

test "flex distributes remaining cells by weight" {
    const items = [_]Item{
        .{ .sizing = .{ .fixed = 4 } },
        .{ .sizing = .{ .flex = 1 } },
        .{ .sizing = .{ .flex = 2 } },
    };
    var output: [3]Placement = undefined;
    try layout(&items, 16, 1, &output);
    try std.testing.expectEqual(@as(usize, 0), output[0].offset);
    try std.testing.expectEqual(@as(usize, 4), output[0].size);
    try std.testing.expectEqual(@as(usize, 4), output[1].size);
    try std.testing.expectEqual(@as(usize, 6), output[2].size);
    try std.testing.expectEqual(@as(usize, 10), output[2].offset);
}

test "flex respects minimum and maximum constraints" {
    const items = [_]Item{
        .{ .sizing = .{ .flex = 1 }, .min = 3, .max = 4 },
        .{ .sizing = .{ .flex = 1 }, .min = 2, .max = 20 },
    };
    var output: [2]Placement = undefined;
    try layout(&items, 12, 0, &output);
    try std.testing.expectEqual(@as(usize, 4), output[0].size);
    try std.testing.expectEqual(@as(usize, 8), output[1].size);
}

test "layout validates output capacity and handles empty input" {
    const items = [_]Item{.{ .sizing = .{ .fixed = 2 } }};
    var empty: [0]Placement = .{};
    try std.testing.expectError(error.OutputTooSmall, layout(&items, 2, 0, &empty));
    try layout(&.{}, 0, 0, &empty);
}

test "fixed overflow collapses flexible items without invalid offsets" {
    const items = [_]Item{
        .{ .sizing = .{ .fixed = 8 } },
        .{ .sizing = .{ .flex = 1 }, .min = 1 },
    };
    var output: [2]Placement = undefined;
    try layout(&items, 5, 0, &output);
    try std.testing.expectEqual(@as(usize, 8), output[0].size);
    try std.testing.expectEqual(@as(usize, 1), output[1].size);
    try std.testing.expectEqual(@as(usize, 8), output[1].offset);
}
