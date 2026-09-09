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

    const title = try title_style.render(allocator, "Lipgloss in Zig 0.16 Gallery");
    defer allocator.free(title);
    std.debug.print("{s}\n", .{title});

    const rounded_box = lipgloss.newStyle()
        .border(lipgloss.Border.rounded())
        .borderColor(lipgloss.Color.hex("#04B575"))
        .foreground(lipgloss.Color.hex("#04B575"))
        .bold(true)
        .padding(1, 2, 1, 2)
        .width(28)
        .@"align"(.center);

    const double_box = lipgloss.newStyle()
        .border(lipgloss.Border.double())
        .borderColor(lipgloss.Color.hex("#FF5F87"))
        .foreground(lipgloss.Color.hex("#FF5F87"))
        .bold(true)
        .padding(1, 2, 1, 2)
        .width(28)
        .@"align"(.center);

    const thick_box = lipgloss.newStyle()
        .border(lipgloss.Border.thick())
        .borderColor(lipgloss.Color.hex("#3B82F6"))
        .foreground(lipgloss.Color.hex("#3B82F6"))
        .bold(true)
        .padding(1, 2, 1, 2)
        .width(28)
        .@"align"(.center);

    const card1 = try rounded_box.render(allocator, "Rounded Border\nStatus: Active");
    defer allocator.free(card1);

    const card2 = try double_box.render(allocator, "Double Border\nStatus: Running");
    defer allocator.free(card2);

    const card3 = try thick_box.render(allocator, "Thick Border\nStatus: Ready");
    defer allocator.free(card3);

    const row = try lipgloss.joinHorizontal(allocator, .top, &.{ card1, card2, card3 });
    defer allocator.free(row);
    std.debug.print("{s}\n", .{row});

    std.debug.print("\x1b[1mFeatures Highlight:\x1b[0m\n", .{});
    var feat_list = lipgloss.List.init(allocator);
    defer feat_list.deinit();
    _ = feat_list.typeOf(.bullet);
    _ = feat_list.styleBullet(lipgloss.newStyle().foreground(lipgloss.Color.hex("#7D56F4")).bold(true));
    _ = feat_list.styleItem(lipgloss.newStyle().foreground(lipgloss.Color.hex("#CCCCCC")));
    _ = try feat_list.item("Zero allocations on style construction (fluent immutable API)");
    _ = try feat_list.item("Full ANSI & TrueColor hex downsampling support");
    _ = try feat_list.item("Flexible layouts: Horizontal & Vertical joining with alignment");
    _ = try feat_list.item("Data Tables, Lists, and Tree components included");

    const list_rendered = try feat_list.render();
    defer allocator.free(list_rendered);
    std.debug.print("{s}\n", .{list_rendered});
}
