const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Core library module
    const mod = b.addModule("tui", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Lipgloss submodule
    const lipgloss_mod = b.addModule("lipgloss", .{
        .root_source_file = b.path("libs/lipgloss/src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Static libraries
    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "tui",
        .root_module = mod,
    });
    b.installArtifact(lib);

    const lipgloss_lib = b.addLibrary(.{
        .linkage = .static,
        .name = "lipgloss",
        .root_module = lipgloss_mod,
    });
    b.installArtifact(lipgloss_lib);

    // Tests
    const tests = b.addTest(.{
        .root_module = mod,
    });
    const run_tests = b.addRunArtifact(tests);

    const lipgloss_tests = b.addTest(.{
        .root_module = lipgloss_mod,
    });
    const run_lipgloss_tests = b.addRunArtifact(lipgloss_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_tests.step);
    test_step.dependOn(&run_lipgloss_tests.step);

    // Examples
    const examples = [_]struct { name: []const u8, path: []const u8, step_name: ?[]const u8 }{
        .{ .name = "tutorial-basics", .path = "examples/basics/main.zig", .step_name = "run-basics" },
        .{ .name = "tutorial-commands", .path = "examples/commands/main.zig", .step_name = "run-commands" },
        .{ .name = "example-simple", .path = "examples/simple/main.zig", .step_name = "run-simple" },
        .{ .name = "example-tabs", .path = "examples/tabs/main.zig", .step_name = "run-tabs" },
        .{ .name = "example-table", .path = "examples/table/main.zig", .step_name = "run-table" },
        .{ .name = "example-dashboard", .path = "examples/dashboard/main.zig", .step_name = "run-dashboard" },
        .{ .name = "example-mouse", .path = "examples/mouse/main.zig", .step_name = "run-mouse" },
        .{ .name = "example-fullscreen", .path = "examples/fullscreen/main.zig", .step_name = "run-fullscreen" },
        .{ .name = "example-spinner", .path = "examples/spinner/main.zig", .step_name = "run-spinner" },
        .{ .name = "example-textinput", .path = "examples/textinput/main.zig", .step_name = "run-textinput" },
        .{ .name = "example-lipgloss-gallery", .path = "examples/lipgloss_gallery/main.zig", .step_name = "run-lipgloss-gallery" },
        .{ .name = "example-lipgloss-table", .path = "examples/lipgloss_table/main.zig", .step_name = "run-lipgloss-table" },
        .{ .name = "example-lipgloss-tree", .path = "examples/lipgloss_tree/main.zig", .step_name = "run-lipgloss-tree" },
        .{ .name = "example-lipgloss-layout", .path = "examples/lipgloss_layout/main.zig", .step_name = "run-lipgloss-layout" },
        .{ .name = "example-progress", .path = "examples/progress/main.zig", .step_name = "run-progress" },
        .{ .name = "example-progress-animated", .path = "examples/progress_animated/main.zig", .step_name = "run-progress-animated" },
        .{ .name = "render-progress-frames", .path = "tools/render_progress_frames.zig", .step_name = null },
    };

    inline for (examples) |ex| {
        const ex_mod = b.createModule(.{
            .root_source_file = b.path(ex.path),
            .target = target,
            .optimize = optimize,
        });
        ex_mod.addImport("tui", mod);
        ex_mod.addImport("lipgloss", lipgloss_mod);

        const exe = b.addExecutable(.{
            .name = ex.name,
            .root_module = ex_mod,
        });
        b.installArtifact(exe);

        if (ex.step_name) |sn| {
            const run_cmd = b.addRunArtifact(exe);
            const run_step = b.step(sn, b.fmt("Run the {s} example", .{ex.name}));
            run_step.dependOn(&run_cmd.step);
        }
    }
}
