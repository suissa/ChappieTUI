//! ChappieTUI terminal component models.
//! These primitives are renderer-agnostic and can be composed in Elm-style Model/update/view flows.

const std = @import("std");
const flex_layout = @import("flex.zig");
pub const flex = flex_layout;
pub const FlexDirection = flex_layout.Direction;
pub const FlexSizing = flex_layout.Sizing;
pub const FlexItem = flex_layout.Item;
pub const FlexPlacement = flex_layout.Placement;
pub const flexLayout = flex_layout.layout;

pub const Badge = struct { label: []const u8, tone: Tone = .neutral };
pub const Text = struct { value: []const u8, tone: Tone = .neutral, bold: bool = false, dim: bool = false };
pub const WidgetState = struct { visible: bool = true, enabled: bool = true, focused: bool = false, hovered: bool = false, dirty: bool = true };
pub const Tone = enum { neutral, primary, success, warning, danger, info };

pub const Button = struct {
    label: []const u8,
    disabled: bool = false,
    focused: bool = false,
    pressed: bool = false,
    pub fn activate(self: *const Button) bool { return !self.disabled; }
};

pub const Card = struct { title: []const u8, body: []const u8 = "", footer: []const u8 = "", padding: u8 = 1 };
pub const Checkbox = struct { label: []const u8, checked: bool = false, disabled: bool = false, pub fn toggle(self: *Checkbox) void { if (!self.disabled) self.checked = !self.checked; } };
pub const Switch = struct { label: []const u8, enabled: bool = false, disabled: bool = false, pub fn toggle(self: *Switch) void { if (!self.disabled) self.enabled = !self.enabled; } };
pub const RadioOption = struct { label: []const u8, value: []const u8, disabled: bool = false };
pub const RadioGroup = struct { options: []const RadioOption, selected: usize = 0, pub fn select(self: *RadioGroup, index: usize) void { if (index < self.options.len and !self.options[index].disabled) self.selected = index; } };
pub const Progress = struct { value: f32 = 0, max: f32 = 100, label: []const u8 = "", pub fn ratio(self: Progress) f32 { if (self.max <= 0) return 0; return @max(0, @min(1, self.value / self.max)); } };
pub const Spinner = struct { frames: []const []const u8 = &.{ "|", "/", "-", "\\" }, frame: usize = 0, pub fn advance(self: *Spinner) void { if (self.frames.len > 0) self.frame = (self.frame + 1) % self.frames.len; } pub fn current(self: Spinner) []const u8 { if (self.frames.len == 0) return ""; return self.frames[self.frame % self.frames.len]; } };
pub const Tabs = struct { labels: []const []const u8, selected: usize = 0, pub fn select(self: *Tabs, index: usize) void { if (index < self.labels.len) self.selected = index; }
    pub fn next(self: *Tabs) void { if (self.labels.len > 0) self.selected = (self.selected + 1) % self.labels.len; } };
pub const Alert = struct { title: []const u8, message: []const u8, tone: Tone = .info, dismissible: bool = true, visible: bool = true, pub fn dismiss(self: *Alert) void { if (self.dismissible) self.visible = false; } };
pub const Toast = struct { message: []const u8, tone: Tone = .info, visible: bool = true, pub fn dismiss(self: *Toast) void { self.visible = false; } };
pub const Modal = struct { title: []const u8, body: []const u8, open: bool = false, pub fn show(self: *Modal) void { self.open = true; }
    pub fn close(self: *Modal) void { self.open = false; } };
pub const AccordionItem = struct { title: []const u8, body: []const u8, expanded: bool = false };
pub const Accordion = struct { items: []AccordionItem, single_open: bool = true, pub fn toggle(self: *Accordion, index: usize) void { if (index >= self.items.len) return; const next = !self.items[index].expanded; if (self.single_open) for (self.items) |*item| { item.expanded = false; }; self.items[index].expanded = next; } };
pub const Slider = struct { value: i32 = 0, min: i32 = 0, max: i32 = 100, step: i32 = 1, pub fn set(self: *Slider, value: i32) void { self.value = @max(self.min, @min(self.max, value)); }
    pub fn increment(self: *Slider) void { self.set(self.value + @max(1, self.step)); }
    pub fn decrement(self: *Slider) void { self.set(self.value - @max(1, self.step)); } };
pub const Pagination = struct { page: usize = 0, page_count: usize = 1, pub fn next(self: *Pagination) void { if (self.page + 1 < self.page_count) self.page += 1; }
    pub fn previous(self: *Pagination) void { if (self.page > 0) self.page -= 1; } };
pub const Breadcrumb = struct { items: []const []const u8, current: usize = 0 };
pub const MenuItem = struct { label: []const u8, enabled: bool = true };
pub const Menu = struct { items: []const MenuItem, selected: usize = 0, pub fn move(self: *Menu, delta: isize) void { if (self.items.len == 0) return; const len: isize = @intCast(self.items.len); self.selected = @intCast(@mod(@as(isize, @intCast(self.selected)) + delta, len)); } };
pub const Navbar = struct { title: []const u8, links: []const []const u8, active: usize = 0 };
pub const Sidebar = struct { items: []const []const u8, selected: usize = 0, collapsed: bool = false };
pub const StatusBar = struct { left: []const u8 = "", center: []const u8 = "", right: []const u8 = "" };
pub const ItemRange = struct { start: usize, end: usize };

pub const ScrollView = struct {
    offset: usize = 0,
    content_height: usize = 0,
    viewport_height: usize = 0,

    pub fn maxOffset(self: ScrollView) usize {
        return self.content_height -| self.viewport_height;
    }

    pub fn scrollTo(self: *ScrollView, offset: usize) void {
        self.offset = @min(offset, self.maxOffset());
    }

    pub fn scroll(self: *ScrollView, delta: isize) void {
        const current = @min(self.offset, self.maxOffset());
        if (delta >= 0) {
            self.scrollTo(current +| @as(usize, @intCast(delta)));
        } else {
            // Avoid negating minInt(isize), which would overflow.
            const amount: usize = @as(usize, @intCast(-(delta + 1))) + 1;
            self.scrollTo(current -| amount);
        }
    }

    pub fn visibleRange(self: ScrollView) ItemRange {
        const start = @min(self.offset, self.content_height);
        return .{ .start = start, .end = @min(self.content_height, start +| self.viewport_height) };
    }

    pub fn ensureVisible(self: *ScrollView, index: usize) void {
        if (self.viewport_height == 0 or index >= self.content_height) return;
        if (index < self.offset) {
            self.scrollTo(index);
        } else if (index >= self.offset +| self.viewport_height) {
            self.scrollTo(index - self.viewport_height + 1);
        }
    }
};
pub const SplitView = struct { ratio: f32 = 0.5, min_ratio: f32 = 0.15, max_ratio: f32 = 0.85, pub fn setRatio(self: *SplitView, value: f32) void { self.ratio = @max(self.min_ratio, @min(self.max_ratio, value)); } };
pub const Grid = struct { columns: usize = 1, rows: usize = 1, pub fn cellCount(self: Grid) usize { return self.columns * self.rows; } };
pub const TreeNode = struct { label: []const u8, children: []const TreeNode = &.{}, expanded: bool = false };
pub const TextInput = struct { value: []const u8 = "", placeholder: []const u8 = "", cursor: usize = 0, focused: bool = false };
pub const TextArea = struct { value: []const u8 = "", cursor_row: usize = 0, cursor_col: usize = 0, rows: usize = 4, focused: bool = false };
pub const Tooltip = struct { text: []const u8, visible: bool = false };
pub const Skeleton = struct { width: usize = 12, height: usize = 1, shimmer_frame: usize = 0, pub fn advance(self: *Skeleton) void { self.shimmer_frame +%= 1; } };
pub const Separator = struct { vertical: bool = false, glyph: []const u8 = "─" };
pub const Image = struct { alt: []const u8, source: []const u8 = "", width: usize = 0, height: usize = 0 };
pub const Border = struct { style: BorderStyle = .single };
pub const BorderStyle = enum { none, single, double, rounded, thick };
pub const ListItem = struct { label: []const u8, description: []const u8 = "", disabled: bool = false };
pub const ListView = struct {
    items: []const ListItem,
    selected: usize = 0,
    offset: usize = 0,

    pub fn visibleRange(self: ListView, viewport_height: usize) ItemRange {
        const start = @min(self.offset, self.items.len);
        return .{ .start = start, .end = @min(self.items.len, start +| viewport_height) };
    }

    pub fn selectedItem(self: ListView) ?ListItem {
        if (self.items.len == 0 or self.selected >= self.items.len) return null;
        return self.items[self.selected];
    }

    pub fn move(self: *ListView, delta: isize) void {
        self.moveInViewport(delta, 0);
    }

    pub fn moveInViewport(self: *ListView, delta: isize, viewport_height: usize) void {
        if (self.items.len == 0) return;
        self.selected = @min(self.selected, self.items.len - 1);

        const direction: isize = if (delta < 0) -1 else 1;
        var remaining: usize = if (delta < 0)
            @intCast(-(delta + 1)) + 1
        else
            @intCast(delta);
        if (remaining == 0) return;

        while (remaining > 0) {
            var next = self.selected;
            var found = false;
            while (true) {
                if (direction < 0) {
                    if (next == 0) break;
                    next -= 1;
                } else {
                    if (next + 1 >= self.items.len) break;
                    next += 1;
                }
                if (!self.items[next].disabled) {
                    found = true;
                    break;
                }
            }
            if (!found) break;
            self.selected = next;
            remaining -= 1;
        }

        if (viewport_height > 0) {
            if (self.selected < self.offset) {
                self.offset = self.selected;
            } else if (self.selected >= self.offset +| viewport_height) {
                self.offset = self.selected - viewport_height + 1;
            }
            self.offset = @min(self.offset, self.items.len -| viewport_height);
        }
    }
};
pub const TableColumn = struct { title: []const u8, width: usize = 12 };
pub const Table = struct { columns: []const TableColumn, rows: []const []const []const u8, selected: usize = 0 };
pub const TooltipPlacement = enum { top, right, bottom, left };
pub const InputField = TextInput;
pub const TextAreaWidget = TextArea;
pub const List = ListView;
pub const Statusbar = StatusBar;
pub const Scroll = ScrollView;
pub const Split = SplitView;

test "interactive component state transitions" {
    var checkbox = Checkbox{ .label = "enabled" };
    checkbox.toggle();
    try @import("std").testing.expect(checkbox.checked);

    var tabs = Tabs{ .labels = &.{ "overview", "events" } };
    tabs.next();
    try @import("std").testing.expectEqual(@as(usize, 1), tabs.selected);

    var slider = Slider{ .value = 98, .max = 100, .step = 5 };
    slider.increment();
    try @import("std").testing.expectEqual(@as(i32, 100), slider.value);

    var modal = Modal{ .title = "Confirm", .body = "Proceed?" };
    modal.show();
    try @import("std").testing.expect(modal.open);
}


test "scroll view clamps offsets and computes visible range" {
    var scroll_view = ScrollView{ .content_height = 20, .viewport_height = 5 };
    scroll_view.scroll(3);
    try std.testing.expectEqual(@as(usize, 3), scroll_view.offset);
    try std.testing.expectEqual(ItemRange{ .start = 3, .end = 8 }, scroll_view.visibleRange());
    scroll_view.scroll(-99);
    try std.testing.expectEqual(@as(usize, 0), scroll_view.offset);
    scroll_view.scrollTo(99);
    try std.testing.expectEqual(@as(usize, 15), scroll_view.offset);
    scroll_view.ensureVisible(2);
    try std.testing.expectEqual(@as(usize, 2), scroll_view.offset);
}

test "list view skips disabled items and keeps selection visible" {
    const items = [_]ListItem{
        .{ .label = "first" },
        .{ .label = "disabled", .disabled = true },
        .{ .label = "third" },
        .{ .label = "fourth" },
    };
    var list = ListView{ .items = &items };
    list.moveInViewport(1, 2);
    try std.testing.expectEqual(@as(usize, 2), list.selected);
    try std.testing.expectEqual(@as(usize, 1), list.offset);
    try std.testing.expectEqual(ItemRange{ .start = 1, .end = 3 }, list.visibleRange(2));
    try std.testing.expectEqualStrings("third", list.selectedItem().?.label);
    list.moveInViewport(99, 2);
    try std.testing.expectEqual(@as(usize, 3), list.selected);
    list.moveInViewport(-99, 2);
    try std.testing.expectEqual(@as(usize, 0), list.selected);
}
