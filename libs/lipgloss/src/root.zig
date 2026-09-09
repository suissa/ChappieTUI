const std = @import("std");

pub const color = @import("color.zig");
pub const Color = color.Color;
pub const ColorType = color.ColorType;
pub const AdaptiveColor = color.AdaptiveColor;
pub const CompleteColor = color.CompleteColor;
pub const Profile = color.Profile;

pub const border = @import("border.zig");
pub const Border = border.Border;

pub const position = @import("position.zig");
pub const Position = position.Position;
pub const Align = position.Align;

pub const size = @import("size.zig");
pub const width = size.width;
pub const height = size.height;
pub const stripAnsi = size.stripAnsi;
pub const runeWidth = size.runeWidth;

pub const layout = @import("layout.zig");
pub const joinHorizontal = layout.joinHorizontal;
pub const joinVertical = layout.joinVertical;
pub const place = layout.place;
pub const placeHorizontal = layout.placeHorizontal;
pub const placeVertical = layout.placeVertical;

pub const style = @import("style.zig");
pub const Style = style.Style;

pub const table = @import("table.zig");
pub const Table = table.Table;

pub const tree = @import("tree.zig");
pub const Tree = tree.Tree;
pub const TreeNode = tree.TreeNode;

pub const list = @import("list.zig");
pub const List = list.List;
pub const ListType = list.ListType;

pub const progress = @import("progress.zig");
pub const Progress = progress.Progress;

// Idiomatic Lipgloss helper constructors
pub fn newStyle() Style {
    return Style.init();
}

pub fn hex(s: []const u8) Color {
    return Color.hex(s);
}

pub fn rgb(r: u8, g: u8, b: u8) Color {
    return Color.rgb(r, g, b);
}

pub fn ansi256(code: u8) Color {
    return Color.ansi256(code);
}

pub fn ansi16(code: u8) Color {
    return Color.ansi16(code);
}

test {
    std.testing.refAllDecls(@This());
}
