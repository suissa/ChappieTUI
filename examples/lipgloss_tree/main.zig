const std = @import("std");
const tui = @import("tui");
const lipgloss = @import("lipgloss");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const title_style = lipgloss.newStyle()
        .bold(true)
        .foreground(lipgloss.Color.hex("#FFFFFF"))
        .background(lipgloss.Color.hex("#059669"))
        .padding(0, 2, 0, 2)
        .margin(1, 0, 1, 0);

    const title = try title_style.render(allocator, "Project File Tree");
    defer allocator.free(title);
    std.debug.print("{s}\n", .{title});

    var tr = lipgloss.Tree.init(allocator, "MyTUI.zigTUI");
    defer tr.deinit();

    _ = tr.branchColor(lipgloss.Color.hex("#6EE7B7"));
    _ = tr.root().setStyle(lipgloss.newStyle().bold(true).foreground(lipgloss.Color.hex("#34D399")));

    var src_node = lipgloss.TreeNode.init(allocator, "src");
    _ = src_node.setStyle(lipgloss.newStyle().bold(true).foreground(lipgloss.Color.hex("#60A5FA")));
    _ = try src_node.child(lipgloss.TreeNode.init(allocator, "root.zig"));
    _ = try src_node.child(lipgloss.TreeNode.init(allocator, "program.zig"));
    _ = try src_node.child(lipgloss.TreeNode.init(allocator, "view.zig"));
    _ = try src_node.child(lipgloss.TreeNode.init(allocator, "renderer.zig"));
    _ = try tr.root().child(src_node);

    var libs_node = lipgloss.TreeNode.init(allocator, "libs/lipgloss");
    _ = libs_node.setStyle(lipgloss.newStyle().bold(true).foreground(lipgloss.Color.hex("#A78BFA")));

    var lip_src = lipgloss.TreeNode.init(allocator, "src");
    _ = lip_src.setStyle(lipgloss.newStyle().foreground(lipgloss.Color.hex("#C4B5FD")));
    _ = try lip_src.child(lipgloss.TreeNode.init(allocator, "style.zig"));
    _ = try lip_src.child(lipgloss.TreeNode.init(allocator, "color.zig"));
    _ = try lip_src.child(lipgloss.TreeNode.init(allocator, "table.zig"));
    _ = try lip_src.child(lipgloss.TreeNode.init(allocator, "tree.zig"));
    _ = try lip_src.child(lipgloss.TreeNode.init(allocator, "layout.zig"));
    _ = try libs_node.child(lip_src);

    _ = try libs_node.child(lipgloss.TreeNode.init(allocator, "build.zig.zon"));
    _ = try tr.root().child(libs_node);

    _ = try tr.root().child(lipgloss.TreeNode.init(allocator, "build.zig"));

    const rendered = try tr.render();
    defer allocator.free(rendered);
    std.debug.print("{s}\n", .{rendered});
}
