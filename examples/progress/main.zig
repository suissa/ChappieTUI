const std = @import("std");
const tui = @import("tui");
const lipgloss = @import("lipgloss");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const title_style = lipgloss.newStyle()
        .bold(true)
        .foreground(lipgloss.Color.hex("#FAFAFA"))
        .background(lipgloss.Color.hex("#7D56F4"))
        .padding(0, 2, 0, 2)
        .margin(1, 0, 1, 0);

    const title = try title_style.render(allocator, "Lipgloss Gradient Progress Bars");
    defer allocator.free(title);
    std.debug.print("{s}\n", .{title});

    // 1. Charm Purple-to-Pink (Default Blend)
    std.debug.print("\x1b[1mCharm Purple -> Pink Blend (75%):\x1b[0m\n", .{});
    var p1 = lipgloss.Progress.charm();
    _ = p1.setWidth(50);
    const b1 = try p1.viewAs(allocator, 0.75);
    defer allocator.free(b1);
    std.debug.print("  {s}\n\n", .{b1});

    // 2. Sunset Fire Gradient
    std.debug.print("\x1b[1mSunset Flame Gradient (50%):\x1b[0m\n", .{});
    var p2 = lipgloss.Progress.sunset();
    _ = p2.setWidth(50);
    const b2 = try p2.viewAs(allocator, 0.50);
    defer allocator.free(b2);
    std.debug.print("  {s}\n\n", .{b2});

    // 3. Cyberpunk Cyan -> Blue
    std.debug.print("\x1b[1mCyberpunk Neon Cyan -> Blue (90%):\x1b[0m\n", .{});
    var p3 = lipgloss.Progress.cyberpunk();
    _ = p3.setWidth(50);
    const b3 = try p3.viewAs(allocator, 0.90);
    defer allocator.free(b3);
    std.debug.print("  {s}\n\n", .{b3});

    // 4. Emerald Matrix Green
    std.debug.print("\x1b[1mEmerald Matrix Green (35%):\x1b[0m\n", .{});
    var p4 = lipgloss.Progress.emerald();
    _ = p4.setWidth(50);
    const b4 = try p4.viewAs(allocator, 0.35);
    defer allocator.free(b4);
    std.debug.print("  {s}\n\n", .{b4});

    // 5. Rainbow Violet
    std.debug.print("\x1b[1mNeon Rainbow Violet (100% Complete):\x1b[0m\n", .{});
    var p5 = lipgloss.Progress.rainbow();
    _ = p5.setWidth(50);
    const b5 = try p5.viewAs(allocator, 1.0);
    defer allocator.free(b5);
    std.debug.print("  {s}\n\n", .{b5});
}
