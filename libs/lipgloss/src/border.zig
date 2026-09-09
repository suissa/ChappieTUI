const std = @import("std");

pub const Border = struct {
    top: []const u8 = "─",
    bottom: []const u8 = "─",
    left: []const u8 = "│",
    right: []const u8 = "│",
    top_left: []const u8 = "┌",
    top_right: []const u8 = "┐",
    bottom_left: []const u8 = "└",
    bottom_right: []const u8 = "┘",

    middle_left: []const u8 = "├",
    middle_right: []const u8 = "┤",
    middle: []const u8 = "┼",
    middle_top: []const u8 = "┬",
    middle_bottom: []const u8 = "┴",

    pub fn normal() Border {
        return .{
            .top = "─",
            .bottom = "─",
            .left = "│",
            .right = "│",
            .top_left = "┌",
            .top_right = "┐",
            .bottom_left = "└",
            .bottom_right = "┘",
            .middle_left = "├",
            .middle_right = "┤",
            .middle = "┼",
            .middle_top = "┬",
            .middle_bottom = "┴",
        };
    }

    pub fn rounded() Border {
        return .{
            .top = "─",
            .bottom = "─",
            .left = "│",
            .right = "│",
            .top_left = "╭",
            .top_right = "╮",
            .bottom_left = "╰",
            .bottom_right = "╯",
            .middle_left = "├",
            .middle_right = "┤",
            .middle = "┼",
            .middle_top = "┬",
            .middle_bottom = "┴",
        };
    }

    pub fn thick() Border {
        return .{
            .top = "━",
            .bottom = "━",
            .left = "┃",
            .right = "┃",
            .top_left = "┏",
            .top_right = "┓",
            .bottom_left = "┗",
            .bottom_right = "┛",
            .middle_left = "┣",
            .middle_right = "┫",
            .middle = "╋",
            .middle_top = "┳",
            .middle_bottom = "┻",
        };
    }

    pub fn double() Border {
        return .{
            .top = "═",
            .bottom = "═",
            .left = "║",
            .right = "║",
            .top_left = "╔",
            .top_right = "╗",
            .bottom_left = "╚",
            .bottom_right = "╝",
            .middle_left = "╠",
            .middle_right = "╣",
            .middle = "╬",
            .middle_top = "╦",
            .middle_bottom = "╩",
        };
    }

    pub fn block() Border {
        return .{
            .top = "█",
            .bottom = "█",
            .left = "█",
            .right = "█",
            .top_left = "█",
            .top_right = "█",
            .bottom_left = "█",
            .bottom_right = "█",
            .middle_left = "█",
            .middle_right = "█",
            .middle = "█",
            .middle_top = "█",
            .middle_bottom = "█",
        };
    }

    pub fn outerHalfBlock() Border {
        return .{
            .top = "▀",
            .bottom = "▄",
            .left = "▌",
            .right = "▐",
            .top_left = "▛",
            .top_right = "▜",
            .bottom_left = "▙",
            .bottom_right = "▟",
        };
    }

    pub fn innerHalfBlock() Border {
        return .{
            .top = "▄",
            .bottom = "▀",
            .left = "▐",
            .right = "▌",
            .top_left = "▗",
            .top_right = "▖",
            .bottom_left = "▝",
            .bottom_right = "▘",
        };
    }

    pub fn hidden() Border {
        return .{
            .top = " ",
            .bottom = " ",
            .left = " ",
            .right = " ",
            .top_left = " ",
            .top_right = " ",
            .bottom_left = " ",
            .bottom_right = " ",
            .middle_left = " ",
            .middle_right = " ",
            .middle = " ",
            .middle_top = " ",
            .middle_bottom = " ",
        };
    }
};

test "border presets" {
    const b = Border.rounded();
    try std.testing.expectEqualStrings("╭", b.top_left);
    try std.testing.expectEqualStrings("╯", b.bottom_right);
}
