const std = @import("std");
const lipgloss = @import("lipgloss");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var p = lipgloss.Progress.charm();
    _ = p.setWidth(50);

    const help_style = lipgloss.newStyle().foreground(lipgloss.Color.hex("#626262"));
    const help = try help_style.render(allocator, "Press any key to quit");
    defer allocator.free(help);

    var current_percent: f32 = 0.0;
    var target_percent: f32 = 0.0;

    // Generate 120 frames at 40ms intervals (~5 seconds animation)
    for (0..120) |tick| {
        if (tick == 5) {
            target_percent = 0.25;
        } else if (tick == 30) {
            target_percent = 0.50;
        } else if (tick == 55) {
            target_percent = 0.75;
        } else if (tick == 80) {
            target_percent = 1.0;
        }

        if (current_percent < target_percent) {
            current_percent += (target_percent - current_percent) * 0.18 + 0.005;
            if (current_percent >= target_percent) {
                current_percent = target_percent;
            }
        }

        const bar = try p.viewAs(allocator, current_percent);
        defer allocator.free(bar);

        std.debug.print("FRAME_START\n\n  {s}\n\n  {s}\nFRAME_END\n", .{ bar, help });
    }
}
