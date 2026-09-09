const std = @import("std");
const tui = @import("tui");
const lipgloss = @import("lipgloss");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const title_style = lipgloss.newStyle()
        .bold(true)
        .foreground(lipgloss.Color.hex("#FFFFFF"))
        .background(lipgloss.Color.hex("#2563EB"))
        .padding(0, 2, 0, 2)
        .margin(1, 0, 1, 0);

    const title = try title_style.render(allocator, "Microservices Status");
    defer allocator.free(title);
    std.debug.print("{s}\n", .{title});

    var t = lipgloss.Table.init(allocator);
    defer t.deinit();

    _ = t.headers(&.{ "SERVICE", "VERSION", "ENVIRONMENT", "UPTIME", "STATUS" });
    _ = t.border(lipgloss.Border.rounded());
    _ = t.borderColor(lipgloss.Color.hex("#4B5563"));

    _ = t.styleHeader(lipgloss.newStyle()
        .bold(true)
        .foreground(lipgloss.Color.hex("#60A5FA")));

    _ = t.styleRows(lipgloss.newStyle()
        .foreground(lipgloss.Color.hex("#D1D5DB")));

    _ = t.styleEvenRows(lipgloss.newStyle()
        .foreground(lipgloss.Color.hex("#93C5FD")));

    _ = try t.row(&.{ "auth-service", "v2.4.1", "Production", "99.98%", "Healthy" });
    _ = try t.row(&.{ "billing-api", "v1.8.0", "Production", "99.95%", "Healthy" });
    _ = try t.row(&.{ "inventory-db", "v3.1.2", "Production", "100.0%", "Healthy" });
    _ = try t.row(&.{ "search-worker", "v0.9.4", "Staging", "98.70%", "Degraded" });
    _ = try t.row(&.{ "gateway", "v4.0.0", "Production", "99.99%", "Healthy" });

    const rendered = try t.render();
    defer allocator.free(rendered);
    std.debug.print("{s}\n", .{rendered});
}
