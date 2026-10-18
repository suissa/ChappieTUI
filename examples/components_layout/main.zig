const std = @import("std");
const components = @import("components");

/// Small executable example for the layout primitives and viewport-aware widgets.
pub fn main() void {
    const flex_items = [_]components.FlexItem{
        .{ .sizing = .{ .flex = 1 }, .min = 16 },
        .{ .sizing = .{ .flex = 2 }, .min = 16 },
        .{ .sizing = .{ .flex = 1 }, .min = 16 },
    };
    var placements: [3]components.FlexPlacement = undefined;
    components.flexLayout(&flex_items, 80, 2, &placements) catch {
        std.debug.print("Flex layout failed: output buffer too small\n", .{});
        return;
    };

    std.debug.print("ChappieTUI responsive component layout (80 cells)\n", .{});
    for (placements, 0..) |placement, index| {
        std.debug.print("  panel {d}: x={d}, width={d}\n", .{
            index + 1,
            placement.offset,
            placement.size,
        });
    }

    const rows = [_]components.ListItem{
        .{ .label = "API Gateway", .description = "healthy" },
        .{ .label = "Worker Pool", .description = "paused", .disabled = true },
        .{ .label = "Postgres", .description = "healthy" },
        .{ .label = "Event Stream", .description = "degraded" },
        .{ .label = "Cache", .description = "healthy" },
    };
    var list = components.ListView{ .items = &rows };
    list.moveInViewport(2, 3);

    const range = list.visibleRange(3);
    std.debug.print(
        "List viewport: rows {d}..{d}, selected={s}, offset={d}\n",
        .{ range.start, range.end, list.selectedItem().?.label, list.offset },
    );

    var scroll = components.ScrollView{
        .content_height = 40,
        .viewport_height = 8,
    };
    scroll.ensureVisible(21);
    const visible = scroll.visibleRange();
    std.debug.print("Scroll viewport: rows {d}..{d}, max offset={d}\n", .{
        visible.start,
        visible.end,
        scroll.maxOffset(),
    });
}
