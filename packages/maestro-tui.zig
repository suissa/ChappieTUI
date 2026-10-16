const std = @import("std");

/// Framework-independent animation vocabulary used by TUI widgets and adapters.
pub const Motion = enum {
    slide_in_right, slide_in_left, slide_in_up, slide_in_down,
    slide_out_right, slide_out_left, slide_out_up, slide_out_down,

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

    pub fn axis(self: Motion) Axis {
        return switch (self) {
            .slide_in_right, .slide_in_left, .slide_out_right, .slide_out_left => .horizontal,
            .slide_in_up, .slide_in_down, .slide_out_up, .slide_out_down => .vertical,
        };
    }

    pub fn direction(self: Motion) Direction {
        return switch (self) {
            .slide_in_right, .slide_out_right, .slide_in_down, .slide_out_down => .positive,
            .slide_in_left, .slide_out_left, .slide_in_up, .slide_out_up => .negative,
        };
    }
};

pub const Axis = enum { horizontal, vertical };
pub const Direction = enum { negative, positive };
pub const Phase = enum { idle, delayed, entering, waiting, exiting, finished, cancelled };
pub const Trigger = enum { immediate, on_mount, on_event, on_scroll, on_state_change, after_previous };
pub const Easing = enum { linear, ease_in, ease_out, ease_in_out };

/// One declarative unit of work in a Maestro timeline.
pub const Step = struct {
    motion: Motion,
    duration_ms: u64 = 700,
    delay_ms: u64 = 0,
    wait_after_ms: u64 = 0,
    easing: Easing = .ease_in_out,
};

pub const Options = struct {
    duration_ms: u64 = 700,
    delay_ms: u64 = 0,
    wait_ms: u64 = 0,
    easing: Easing = .ease_in_out,
    reduced_motion: bool = false,
    reverse_on_exit: bool = false,
};

pub const Progress = struct {
    phase: Phase,
    motion: Motion,
    value: f32,
    eased_value: f32,
    elapsed_ms: u64,
    duration_ms: u64,
    offset_x: i32,
    offset_y: i32,
    is_complete: bool,
};

/// Canonical runtime: adapters render state but do not own timing or orchestration.
pub const Maestro = struct {
    motion: Motion = .slide_in_right,
    phase: Phase = .idle,
    duration_ms: u64 = 700,
    delay_ms: u64 = 0,
    wait_ms: u64 = 0,
    elapsed_ms: u64 = 0,
    delay_elapsed_ms: u64 = 0,
    wait_elapsed_ms: u64 = 0,
    easing: Easing = .ease_in_out,
    reduced_motion: bool = false,
    reverse_on_exit: bool = false,

    steps: []const Step = &.{},
    step_index: usize = 0,
    sequence_active: bool = false,
    loop_sequence: bool = false,
    completed_cycles: u64 = 0,

    pub fn start(self: *Maestro, motion: Motion, duration_ms: u64) void {
        self.configure(motion, .{
            .duration_ms = duration_ms,
            .reduced_motion = self.reduced_motion,
            .easing = self.easing,
            .reverse_on_exit = self.reverse_on_exit,
        });
    }

    pub fn configure(self: *Maestro, motion: Motion, options: Options) void {
        self.motion = motion;
        self.duration_ms = @max(options.duration_ms, 1);
        self.delay_ms = options.delay_ms;
        self.wait_ms = options.wait_ms;
        self.easing = options.easing;
        self.reduced_motion = options.reduced_motion;
        self.reverse_on_exit = options.reverse_on_exit;
        self.elapsed_ms = 0;
        self.delay_elapsed_ms = 0;
        self.wait_elapsed_ms = 0;
        self.steps = &.{};
        self.step_index = 0;
        self.sequence_active = false;
        self.loop_sequence = false;
        self.completed_cycles = 0;

        if (self.reduced_motion) {
            self.elapsed_ms = self.duration_ms;
            self.phase = if (self.delay_ms > 0) .delayed else .finished;
        } else {
            self.phase = if (self.delay_ms > 0) .delayed else .entering;
        }
    }

    /// Run an enter -> wait -> opposite-direction exit lifecycle.
    pub fn startSequence(self: *Maestro, motion: Motion, duration_ms: u64, wait_ms: u64) void {
        self.configure(motion, .{
            .duration_ms = duration_ms,
            .wait_ms = wait_ms,
            .reduced_motion = self.reduced_motion,
            .easing = self.easing,
            .reverse_on_exit = true,
        });
    }

    /// The caller-owned steps slice must outlive the sequence.
    pub fn play(self: *Maestro, steps: []const Step, loop: bool) void {
        self.steps = steps;
        self.step_index = 0;
        self.loop_sequence = loop;
        self.sequence_active = steps.len > 0;
        self.completed_cycles = 0;
        if (steps.len == 0) {
            self.phase = .finished;
            return;
        }
        self.loadStep(steps[0]);
    }

    pub fn replay(self: *Maestro) void {
        if (self.steps.len > 0) {
            self.step_index = 0;
            self.completed_cycles = 0;
            self.sequence_active = true;
            self.loadStep(self.steps[0]);
        } else {
            self.elapsed_ms = 0;
            self.delay_elapsed_ms = 0;
            self.wait_elapsed_ms = 0;
            self.phase = if (self.delay_ms > 0 and !self.reduced_motion) .delayed else if (self.reduced_motion) .finished else .entering;
        }
    }

    pub fn reset(self: *Maestro) void {
        self.phase = .idle;
        self.elapsed_ms = 0;
        self.delay_elapsed_ms = 0;
        self.wait_elapsed_ms = 0;
        self.step_index = 0;
        self.sequence_active = false;
        self.steps = &.{};
        self.completed_cycles = 0;
    }

    pub fn cancel(self: *Maestro) void {
        self.phase = .cancelled;
        self.sequence_active = false;
    }

    pub fn setReducedMotion(self: *Maestro, enabled: bool) void {
        self.reduced_motion = enabled;
        if (enabled and self.phase != .idle and self.phase != .cancelled) {
            self.elapsed_ms = self.duration_ms;
            self.delay_elapsed_ms = self.delay_ms;
            self.wait_elapsed_ms = self.wait_ms;
            self.phase = .finished;
            self.sequence_active = false;
        }
    }

    /// Advances the state machine and carries excess time across phase boundaries.
    pub fn advance(self: *Maestro, delta_ms: u64) void {
        if (self.reduced_motion) {
            if (self.phase != .idle and self.phase != .cancelled) {
                self.phase = .finished;
                self.sequence_active = false;
            }
            return;
        }

        var remaining = delta_ms;
        var transitions: usize = 0;
        while (transitions < 16) : (transitions += 1) {
            switch (self.phase) {
                .idle, .finished, .cancelled => return,
                .delayed => {
                    const needed = self.delay_ms -| self.delay_elapsed_ms;
                    const consumed = @min(remaining, needed);
                    self.delay_elapsed_ms += consumed;
                    remaining -= consumed;
                    if (self.delay_elapsed_ms < self.delay_ms) return;
                    self.phase = .entering;
                    if (remaining == 0) return;
                },
                .entering => {
                    const needed = self.duration_ms -| self.elapsed_ms;
                    const consumed = @min(remaining, needed);
                    self.elapsed_ms += consumed;
                    remaining -= consumed;
                    if (self.elapsed_ms < self.duration_ms) return;
                    if (self.wait_ms > 0) {
                        self.phase = .waiting;
                        self.wait_elapsed_ms = 0;
                    } else if (self.reverse_on_exit) {
                        self.motion = self.motion.opposite();
                        self.phase = .exiting;
                        self.elapsed_ms = 0;
                    } else {
                        self.finishStep();
                    }
                    if (remaining == 0) return;
                },
                .waiting => {
                    const needed = self.wait_ms -| self.wait_elapsed_ms;
                    const consumed = @min(remaining, needed);
                    self.wait_elapsed_ms += consumed;
                    remaining -= consumed;
                    if (self.wait_elapsed_ms < self.wait_ms) return;
                    if (self.reverse_on_exit) {
                        self.motion = self.motion.opposite();
                        self.phase = .exiting;
                        self.elapsed_ms = 0;
                    } else {
                        self.finishStep();
                    }
                    if (remaining == 0) return;
                },
                .exiting => {
                    const needed = self.duration_ms -| self.elapsed_ms;
                    const consumed = @min(remaining, needed);
                    self.elapsed_ms += consumed;
                    remaining -= consumed;
                    if (self.elapsed_ms < self.duration_ms) return;
                    self.finishStep();
                    if (remaining == 0) return;
                },
            }
        }
    }

    /// Drive the timeline from a normalized scroll position.
    pub fn scrub(self: *Maestro, progress_value: f32) void {
        const clamped = std.math.clamp(progress_value, 0.0, 1.0);
        self.sequence_active = false;
        self.delay_ms = 0;
        self.elapsed_ms = @intFromFloat(@as(f64, @floatFromInt(self.duration_ms)) * @as(f64, clamped));
        self.phase = if (clamped >= 1.0) .finished else .entering;
    }

    pub fn progress(self: Maestro) f32 {
        if (self.phase == .waiting or self.phase == .finished) return 1.0;
        if (self.phase == .idle or self.phase == .delayed or self.phase == .cancelled) return 0.0;
        return std.math.clamp(
            @as(f32, @floatFromInt(self.elapsed_ms)) / @as(f32, @floatFromInt(@max(self.duration_ms, 1))),
            0.0,
            1.0,
        );
    }

    pub fn easedProgress(self: Maestro) f32 {
        const p = self.progress();
        return switch (self.easing) {
            .linear => p,
            .ease_in => p * p,
            .ease_out => 1.0 - ((1.0 - p) * (1.0 - p)),
            .ease_in_out => if (p < 0.5) 2.0 * p * p else 1.0 - std.math.pow(f32, -2.0 * p + 2.0, 2.0) / 2.0,
        };
    }

    /// Signed displacement in terminal cells; rendering is left to the adapter.
    pub fn offset(self: Maestro, width: usize, height: usize) struct { x: i32, y: i32 } {
        const p = self.easedProgress();
        const amount = if (self.motion.isEntering()) 1.0 - p else p;
        const sign: f32 = if (self.motion.direction() == .positive) 1.0 else -1.0;
        return switch (self.motion.axis()) {
            .horizontal => .{
                .x = @intFromFloat(sign * amount * @as(f32, @floatFromInt(width))),
                .y = 0,
            },
            .vertical => .{
                .x = 0,
                .y = @intFromFloat(sign * amount * @as(f32, @floatFromInt(height))),
            },
        };
    }

    pub fn snapshot(self: Maestro, width: usize, height: usize) Progress {
        const displacement = self.offset(width, height);
        return .{
            .phase = self.phase,
            .motion = self.motion,
            .value = self.progress(),
            .eased_value = self.easedProgress(),
            .elapsed_ms = self.elapsed_ms,
            .duration_ms = self.duration_ms,
            .offset_x = displacement.x,
            .offset_y = displacement.y,
            .is_complete = self.phase == .finished or self.phase == .cancelled,
        };
    }

    fn loadStep(self: *Maestro, step: Step) void {
        self.motion = step.motion;
        self.duration_ms = @max(step.duration_ms, 1);
        self.delay_ms = step.delay_ms;
        self.wait_ms = step.wait_after_ms;
        self.easing = step.easing;
        self.reverse_on_exit = false;
        self.elapsed_ms = 0;
        self.delay_elapsed_ms = 0;
        self.wait_elapsed_ms = 0;
        self.phase = if (self.reduced_motion) .finished else if (step.delay_ms > 0) .delayed else .entering;
        if (self.reduced_motion) self.finishStep();
    }

    fn finishStep(self: *Maestro) void {
        if (self.sequence_active and self.steps.len > 0) {
            self.step_index += 1;
            if (self.step_index < self.steps.len) {
                self.loadStep(self.steps[self.step_index]);
                return;
            }
            self.completed_cycles += 1;
            if (self.loop_sequence) {
                self.step_index = 0;
                self.loadStep(self.steps[0]);
                return;
            }
            self.sequence_active = false;
        }
        self.phase = .finished;
    }
};

/// Backwards-compatible name for the original TUI motion API.
pub const Orchestrator = Maestro;

/// A group can be played sequentially; parallel groups can be composed by the adapter.
pub const Group = struct {
    steps: []const Step,
    loop: bool = false,
};

test "all slide motions have names and inverse motions" {
    inline for (std.meta.tags(Motion)) |motion| {
        try std.testing.expect(motion.name().len > 0);
        try std.testing.expectEqual(motion, motion.opposite().opposite());
    }
    try std.testing.expectEqualStrings("slideInRight", Motion.slide_in_right.name());
    try std.testing.expectEqual(Axis.horizontal, Motion.slide_out_left.axis());
    try std.testing.expectEqual(Direction.negative, Motion.slide_in_up.direction());
}

test "enter wait exit lifecycle consumes elapsed time" {
    var maestro = Maestro{};
    maestro.startSequence(.slide_in_left, 100, 50);
    maestro.advance(100);
    try std.testing.expectEqual(Phase.waiting, maestro.phase);
    maestro.advance(50);
    try std.testing.expectEqual(Phase.exiting, maestro.phase);
    maestro.advance(100);
    try std.testing.expectEqual(Phase.finished, maestro.phase);
}

test "sequence advances and replays" {
    const steps = [_]Step{
        .{ .motion = .slide_in_right, .duration_ms = 20 },
        .{ .motion = .slide_out_down, .duration_ms = 30 },
    };
    var maestro = Maestro{};
    maestro.play(&steps, false);
    maestro.advance(20);
    try std.testing.expectEqual(Motion.slide_out_down, maestro.motion);
    maestro.advance(30);
    try std.testing.expectEqual(Phase.finished, maestro.phase);
    maestro.replay();
    try std.testing.expectEqual(Motion.slide_in_right, maestro.motion);
    try std.testing.expectEqual(Phase.entering, maestro.phase);
}

test "reduced motion completes without animated displacement" {
    var maestro = Maestro{};
    maestro.configure(.slide_in_right, .{ .duration_ms = 500, .reduced_motion = true });
    try std.testing.expectEqual(Phase.finished, maestro.phase);
    try std.testing.expectEqual(@as(f32, 1.0), maestro.progress());
}

test "scroll scrub clamps progress" {
    var maestro = Maestro{};
    maestro.start(.slide_in_up, 100);
    maestro.scrub(1.5);
    try std.testing.expectEqual(Phase.finished, maestro.phase);
    try std.testing.expectEqual(@as(f32, 1.0), maestro.progress());
}
