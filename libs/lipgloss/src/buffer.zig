const std = @import("std");

pub const Buffer = struct {
    list: std.ArrayList(u8) = .empty,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Buffer {
        return .{
            .allocator = allocator,
            .list = .empty,
        };
    }

    pub fn deinit(self: *Buffer) void {
        self.list.deinit(self.allocator);
    }

    pub fn writeByte(self: *Buffer, b: u8) !void {
        try self.list.append(self.allocator, b);
    }

    pub fn writeAll(self: *Buffer, s: []const u8) !void {
        try self.list.appendSlice(self.allocator, s);
    }

    pub fn print(self: *Buffer, comptime fmt: []const u8, args: anytype) !void {
        var buf: [256]u8 = undefined;
        if (std.fmt.bufPrint(&buf, fmt, args)) |s| {
            try self.list.appendSlice(self.allocator, s);
        } else |_| {
            const formatted = try std.fmt.allocPrint(self.allocator, fmt, args);
            defer self.allocator.free(formatted);
            try self.list.appendSlice(self.allocator, formatted);
        }
    }

    pub fn toOwnedSlice(self: *Buffer) ![]u8 {
        return self.list.toOwnedSlice(self.allocator);
    }

    pub fn popTrailingNewline(self: *Buffer) void {
        if (self.list.items.len > 0 and self.list.items[self.list.items.len - 1] == '\n') {
            self.list.items.len -= 1;
        }
    }

    pub fn items(self: *const Buffer) []const u8 {
        return self.list.items;
    }
};
