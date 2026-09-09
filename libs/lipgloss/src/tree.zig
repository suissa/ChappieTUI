const std = @import("std");
const Style = @import("style.zig").Style;
const Color = @import("color.zig").Color;
const Buffer = @import("buffer.zig").Buffer;

pub const TreeNode = struct {
    allocator: std.mem.Allocator,
    label: []const u8,
    children: std.ArrayList(TreeNode) = .empty,
    style: ?Style = null,

    pub fn init(allocator: std.mem.Allocator, label: []const u8) TreeNode {
        return .{
            .allocator = allocator,
            .label = label,
            .children = .empty,
        };
    }

    pub fn deinit(self: *TreeNode) void {
        for (self.children.items) |*ch| {
            ch.deinit();
        }
        self.children.deinit(self.allocator);
    }

    pub fn child(self: *TreeNode, node: TreeNode) !*TreeNode {
        try self.children.append(self.allocator, node);
        return self;
    }

    pub fn setStyle(self: *TreeNode, s: Style) *TreeNode {
        self.style = s;
        return self;
    }
};

pub const Tree = struct {
    allocator: std.mem.Allocator,
    root_node: TreeNode,
    branch_color: Color = Color.ansi256(245),

    pub fn init(allocator: std.mem.Allocator, root_label: []const u8) Tree {
        return .{
            .allocator = allocator,
            .root_node = TreeNode.init(allocator, root_label),
        };
    }

    pub fn deinit(self: *Tree) void {
        self.root_node.deinit();
    }

    pub fn root(self: *Tree) *TreeNode {
        return &self.root_node;
    }

    pub fn branchColor(self: *Tree, c: Color) *Tree {
        self.branch_color = c;
        return self;
    }

    pub fn render(self: *Tree) ![]u8 {
        var out = Buffer.init(self.allocator);
        defer out.deinit();

        try self.renderNode(&out, &self.root_node, "", true, true);
        return out.toOwnedSlice();
    }

    fn renderNode(
        self: *Tree,
        out: *Buffer,
        node: *const TreeNode,
        prefix: []const u8,
        is_last: bool,
        is_root: bool,
    ) !void {
        const reset = "\x1b[0m";

        if (!is_root) {
            try self.branch_color.writeAnsi(out, false);
            try out.writeAll(prefix);
            if (is_last) {
                try out.writeAll("└── ");
            } else {
                try out.writeAll("├── ");
            }
            try out.writeAll(reset);
        }

        if (node.style) |s| {
            if (s.is_bold) try out.writeAll("\x1b[1m");
            try s.fg.writeAnsi(out, false);
            try s.bg.writeAnsi(out, true);
            try out.writeAll(node.label);
            try out.writeAll(reset);
        } else {
            try out.writeAll(node.label);
        }
        try out.writeByte('\n');

        var new_prefix = Buffer.init(self.allocator);
        defer new_prefix.deinit();

        if (!is_root) {
            try new_prefix.writeAll(prefix);
            if (is_last) {
                try new_prefix.writeAll("    ");
            } else {
                try new_prefix.writeAll("│   ");
            }
        }

        const count = node.children.items.len;
        for (node.children.items, 0..) |*c, idx| {
            const last = (idx + 1 == count);
            try self.renderNode(out, c, new_prefix.items(), last, false);
        }
    }
};

test "tree rendering" {
    const testing = std.testing;
    var tr = Tree.init(testing.allocator, "Root Project");
    defer tr.deinit();

    var c1 = TreeNode.init(testing.allocator, "src");
    _ = try c1.child(TreeNode.init(testing.allocator, "main.zig"));
    _ = try tr.root().child(c1);

    const res = try tr.render();
    defer testing.allocator.free(res);

    try testing.expect(res.len > 0);
    try testing.expect(std.mem.indexOf(u8, res, "Root Project") != null);
    try testing.expect(std.mem.indexOf(u8, res, "main.zig") != null);
}
