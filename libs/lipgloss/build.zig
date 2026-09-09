const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Submodule lipgloss
    const lipgloss_mod = b.addModule("lipgloss", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Static library
    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "lipgloss",
        .root_module = lipgloss_mod,
    });
    b.installArtifact(lib);

    // Tests
    const tests = b.addTest(.{
        .root_module = lipgloss_mod,
    });
    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run lipgloss unit tests");
    test_step.dependOn(&run_tests.step);

    // Examples
    const examples = [_]struct { name: []const u8, path: []const u8, step: []const u8 }{
        .{ .name = "gallery", .path = "examples/gallery.zig", .step = "run-gallery" },
        .{ .name = "table", .path = "examples/table.zig", .step = "run-table" },
        .{ .name = "tree", .path = "examples/tree.zig", .step = "run-tree" },
        .{ .name = "layout", .path = "examples/layout.zig", .step = "run-layout" },
    };

    inline for (examples) |ex| {
        const ex_mod = b.createModule(.{
            .root_source_file = b.path(ex.path),
            .target = target,
            .optimize = optimize,
        });
        ex_mod.addImport("lipgloss", lipgloss_mod);

        const exe = b.addExecutable(.{
            .name = ex.name,
            .root_module = ex_mod,
        });
        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        const run_step = b.step(ex.step, b.fmt("Run the {s} example", .{ex.name}));
        run_step.dependOn(&run_cmd.step);
    }
}
