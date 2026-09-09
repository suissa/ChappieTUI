const std = @import("std");

pub const Position = enum {
    top,
    bottom,
    center,
    left,
    right,

    pub const Top = Position.top;
    pub const Bottom = Position.bottom;
    pub const Center = Position.center;
    pub const Left = Position.left;
    pub const Right = Position.right;
};

pub const Align = enum {
    left,
    center,
    right,
};
