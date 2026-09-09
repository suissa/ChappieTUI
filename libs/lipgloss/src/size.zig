const std = @import("std");

/// Returns the visible column width of a single unicode codepoint on terminal
pub fn runeWidth(cp: u21) usize {
    // Control characters
    if (cp < 32 or (cp >= 0x7F and cp < 0xA0)) return 0;

    // Fast-path ASCII printable
    if (cp < 0x7F) return 1;

    // Zero-width spaces and formatting
    if (cp == 0x200B or cp == 0x200C or cp == 0x200D or cp == 0xFEFF) return 0;

    // Common wide ranges: CJK, Emoji, Fullwidth
    if ((cp >= 0x1100 and cp <= 0x115F) or
        (cp >= 0x2E80 and cp <= 0xA4CF) or
        (cp >= 0xAC00 and cp <= 0xD7A3) or
        (cp >= 0xF900 and cp <= 0xFAFF) or
        (cp >= 0xFE10 and cp <= 0xFE19) or
        (cp >= 0xFE30 and cp <= 0xFE6F) or
        (cp >= 0xFF00 and cp <= 0xFF60) or
        (cp >= 0xFFE0 and cp <= 0xFFE6) or
        (cp >= 0x1F300 and cp <= 0x1F64F) or
        (cp >= 0x1F900 and cp <= 0x1F9FF))
    {
        return 2;
    }

    return 1;
}

/// Computes the visual terminal column width of a string, ignoring ANSI escape sequences.
pub fn width(str: []const u8) usize {
    var max_line_w: usize = 0;
    var cur_line_w: usize = 0;
    var i: usize = 0;

    while (i < str.len) {
        // Handle ANSI escape sequences
        if (str[i] == 0x1B and i + 1 < str.len and str[i + 1] == '[') {
            i += 2;
            while (i < str.len and (str[i] < 0x40 or str[i] > 0x7E)) {
                i += 1;
            }
            if (i < str.len) i += 1;
            continue;
        }

        // OSC sequences
        if (str[i] == 0x1B and i + 1 < str.len and str[i + 1] == ']') {
            i += 2;
            while (i < str.len and str[i] != 0x07 and str[i] != 0x1B) {
                i += 1;
            }
            if (i < str.len and str[i] == 0x07) {
                i += 1;
            } else if (i + 1 < str.len and str[i] == 0x1B and str[i + 1] == '\\') {
                i += 2;
            }
            continue;
        }

        // Line break
        if (str[i] == '\n') {
            if (cur_line_w > max_line_w) max_line_w = cur_line_w;
            cur_line_w = 0;
            i += 1;
            continue;
        }

        // Carriage return
        if (str[i] == '\r') {
            i += 1;
            continue;
        }

        // Tab (align to 4 spaces)
        if (str[i] == '\t') {
            cur_line_w += 4 - (cur_line_w % 4);
            i += 1;
            continue;
        }

        // Decode UTF-8 codepoint
        const cp_len = std.unicode.utf8ByteSequenceLength(str[i]) catch 1;
        if (i + cp_len <= str.len) {
            const cp = std.unicode.utf8Decode(str[i .. i + cp_len]) catch str[i];
            cur_line_w += runeWidth(cp);
            i += cp_len;
        } else {
            cur_line_w += 1;
            i += 1;
        }
    }

    if (cur_line_w > max_line_w) max_line_w = cur_line_w;
    return max_line_w;
}

/// Counts the number of visual lines in the text
pub fn height(str: []const u8) usize {
    if (str.len == 0) return 0;
    var lines: usize = 1;
    for (str) |c| {
        if (c == '\n') lines += 1;
    }
    // If string ends with newline, don't count an empty trailing line
    if (str[str.len - 1] == '\n') {
        lines -= 1;
    }
    return lines;
}

/// Strips all ANSI escape sequences from a string
pub fn stripAnsi(allocator: std.mem.Allocator, str: []const u8) ![]u8 {
    const Buffer = @import("buffer.zig").Buffer;
    var out = Buffer.init(allocator);
    errdefer out.deinit();

    var i: usize = 0;
    while (i < str.len) {
        if (str[i] == 0x1B and i + 1 < str.len and str[i + 1] == '[') {
            i += 2;
            while (i < str.len and (str[i] < 0x40 or str[i] > 0x7E)) {
                i += 1;
            }
            if (i < str.len) i += 1;
            continue;
        }
        try out.writeByte(str[i]);
        i += 1;
    }

    return out.toOwnedSlice();
}

test "ansi-aware width calculation" {
    const testing = std.testing;

    const s1 = "Hello World";
    try testing.expectEqual(@as(usize, 11), width(s1));

    const s2 = "\x1b[31;1mHello\x1b[0m \x1b[32mWorld\x1b[0m";
    try testing.expectEqual(@as(usize, 11), width(s2));

    const s3 = "Line 1\nLine 2 longer";
    try testing.expectEqual(@as(usize, 13), width(s3));
    try testing.expectEqual(@as(usize, 2), height(s3));
}
