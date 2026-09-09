const std = @import("std");
const lipgloss = @import("lipgloss");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // Box styles
    const header_style = lipgloss.newStyle()
        .border(lipgloss.Border.rounded())
        .borderColor(lipgloss.Color.hex("#7D56F4"))
        .foreground(lipgloss.Color.hex("#FAFAFA"))
        .background(lipgloss.Color.hex("#5B21B6"))
        .bold(true)
        .padding(0, 2, 0, 2)
        .width(70)
        .@"align"(.center);

    const sidebar_style = lipgloss.newStyle()
        .border(lipgloss.Border.normal())
        .borderColor(lipgloss.Color.hex("#4B5563"))
        .foreground(lipgloss.Color.hex("#9CA3AF"))
        .padding(1, 1, 1, 1)
        .width(20);

    const main_content_style = lipgloss.newStyle()
        .border(lipgloss.Border.normal())
        .borderColor(lipgloss.Color.hex("#3B82F6"))
        .foreground(lipgloss.Color.hex("#E5E7EB"))
        .padding(1, 2, 1, 2)
        .width(47);

    const footer_style = lipgloss.newStyle()
        .foreground(lipgloss.Color.hex("#6B7280"))
        .padding(0, 1, 0, 1)
        .width(70)
        .@"align"(.center);

    const header = try header_style.render(allocator, "APPLICATION MONITORING DASHBOARD");
    defer allocator.free(header);

    const sidebar = try sidebar_style.render(allocator, "NAVIGATION\n\n• Overview\n• Metrics\n• Logs\n• Alerts\n• Settings");
    defer allocator.free(sidebar);

    const main_content = try main_content_style.render(allocator, "SYSTEM METRICS\n\nCPU Usage:  [████████░░] 80%\nMemory:     [██████░░░░] 60%\nDisk I/O:   [███░░░░░░░] 30%\nNetwork:    1.2 Gbps RX / 450 Mbps TX");
    defer allocator.free(main_content);

    const footer = try footer_style.render(allocator, "Press 'q' to quit • Connected to 12 nodes • All systems operational");
    defer allocator.free(footer);

    // Join sidebar and main content horizontally
    const body = try lipgloss.joinHorizontal(allocator, .top, &.{ sidebar, main_content });
    defer allocator.free(body);

    // Join header, body, and footer vertically
    const dashboard = try lipgloss.joinVertical(allocator, .left, &.{ header, body, footer });
    defer allocator.free(dashboard);

    std.debug.print("{s}\n", .{dashboard});
}
