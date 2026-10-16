const std = @import("std");

/// Motion vocabulary mirrors Animate.css slideIn/slideOut directions.
pub const Motion = enum {
    slide_in_right,
    slide_in_left,
    slide_in_up,
    slide_in_down,
    slide_out_right,
    slide_out_left,
    slide_out_up,
    slide_out_down,

    pub fn isEntering(self: Motion) bool {
        return switch (self) {
            .slide_in_right, .slide_in_left, .slide_in_up, .slide_in_down => true,
            else => false,
        };
    }

    pub fn name(self: Motion) []const u8 {
        return switch (self) {
            .slide_in_right => "slideInRight",
            .slide_in_left => "slideInLeft",
            .slide_in_up => "slideInUp",
            .slide_in_down => "slideInDown",
            .slide_out_right => "slideOutRight",
            .slide_out_left => "slideOutLeft",
            .slide_out_up => "slideOutUp",
            .slide_out_down => "slideOutDown",
        };
    }

    pub fn opposite(self: Motion) Motion {
        return switch (self) {
            .slide_in_right => .slide_out_right,
            .slide_in_left => .slide_out_left,
            .slide_in_up => .slide_out_up,
            .slide_in_down => .slide_out_down,
            .slide_out_right => .slide_in_right,
            .slide_out_left => .slide_in_left,
            .slide_out_up => .slide_in_up,
            .slide_out_down => .slide_in_down,
        };
    }
};

pub const Phase = enum { idle, entering, waiting, exiting, finished };

pub const Orchestrator = struct {
    motion: Motion = .slide_in_right,
    phase: Phase = .idle,
    duration_ms: u64 = 700,
    elapsed_ms: u64 = 0,
    wait_ms: u64 = 0,
    wait_elapsed_ms: u64 = 0,

    pub fn start(self: *Orchestrator, motion: Motion, duration_ms: u64) void {
        self.motion = motion;
        self.phase = .entering;
        self.duration_ms = @max(duration_ms, 1);
        self.elapsed_ms = 0;
        self.wait_elapsed_ms = 0;
    }

    pub fn startSequence(self: *Orchestrator, motion: Motion, duration_ms: u64, wait_ms: u64) void {
        self.start(motion, duration_ms);
        self.wait_ms = wait_ms;
    }

    /// Advances the canonical behavior lifecycle by elapsed milliseconds.
    pub fn advance(self: *Orchestrator, delta_ms: u64) void {
        switch (self.phase) {
            .idle, .finished => return,
            .entering => {
                self.elapsed_ms = @min(self.elapsed_ms +| delta_ms, self.duration_ms);
                if (self.elapsed_ms >= self.duration_ms) {
                    if (self.wait_ms > 0) {
                        self.phase = .waiting;
                        self.wait_elapsed_ms = 0;
                    } else if (self.motion.isEntering()) {
                        self.phase = .finished;
                    } else {
                        self.phase = .finished;
                    }
                }
            },
            .waiting => {
                self.wait_elapsed_ms = @min(self.wait_elapsed_ms +| delta_ms, self.wait_ms);
                if (self.wait_elapsed_ms >= self.wait_ms) {
                    self.motion = self.motion.opposite();
                    self.phase = .exiting;
                    self.elapsed_ms = 0;
                }
            },
            .exiting => {
                self.elapsed_ms = @min(self.elapsed_ms +| delta_ms, self.duration_ms);
                if (self.elapsed_ms >= self.duration_ms) self.phase = .finished;
            },
        }
    }

    /// Scroll can scrub a motion deterministically instead of waiting for a timer.
    pub fn scrub(self: *Orchestrator, progress: f32) void {
        const clamped = std.math.clamp(progress, 0.0, 1.0);
        self.elapsed_ms = @intFromFloat(@as(f64, @floatFromInt(self.duration_ms)) * @as(f64, clamped));
        self.phase = if (clamped >= 1.0) .finished else .entering;
    }

    pub fn progress(self: Orchestrator) f32 {
        if (self.phase == .waiting) return 1.0;
        if (self.phase == .finished) return 1.0;
        return @as(f32, @floatFromInt(self.elapsed_ms)) / @as(f32, @floatFromInt(@max(self.duration_ms, 1)));
    }

    /// Signed displacement in terminal cells for a slide motion.
    pub fn offset(self: Orchestrator, width: usize, height: usize) struct { x: i32, y: i32 } {
        const p = self.progress();
        const entering = self.motion.isEntering();
        const amount = if (entering) 1.0 - p else p;
        const sign: f32 = switch (self.motion) {
            .slide_in_right, .slide_out_right => 1.0,
            .slide_in_left, .slide_out_left => -1.0,
            .slide_in_down, .slide_out_down => 1.0,
            .slide_in_up, .slide_out_up => -1.0,
        };
        return switch (self.motion) {
            .slide_in_right, .slide_out_right, .slide_in_left, .slide_out_left => .{
                .x = @intFromFloat(sign * amount * @as(f32, @floatFromInt(width))),
                .y = 0,
            },
            .slide_in_down, .slide_out_down, .slide_in_up, .slide_out_up => .{
                .x = 0,
                .y = @intFromFloat(sign * amount * @as(f32, @floatFromInt(height))),
            },
        };
    }
};

test "slide motions expose expected names and opposites" {
    try std.testing.expectEqualStrings("slideInRight", Motion.slide_in_right.name());
    try std.testing.expectEqual(Motion.slide_out_right, Motion.slide_in_right.opposite());
    try std.testing.expect(Motion.slide_out_left.isEntering() == false);
}

test "orchestrator progresses through enter wait exit" {
    var motion = Orchestrator{};
    motion.startSequence(.slide_in_left, 100, 50);
    motion.advance(100);
    try std.testing.expectEqual(Phase.waiting, motion.phase);
    motion.advance(50);
    try std.testing.expectEqual(Phase.exiting, motion.phase);
    motion.advance(100);
    try std.testing.expectEqual(Phase.finished, motion.phase);
}
