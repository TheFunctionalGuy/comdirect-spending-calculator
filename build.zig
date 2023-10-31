const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // === zig build (install) ===
    {
        const clap = b.dependency("clap", .{
            .target = target,
            .optimize = optimize,
        });

        const exe_options = b.addOptions();
        exe_options.addOption(bool, "use_gpa", b.option(bool, "use_gpa", "Use GeneralPurposeAllocator (good for debugging)") orelse (optimize == .Debug));

        const exe = b.addExecutable(.{
            .name = "comdirect-spending-calculator",
            .root_source_file = .{ .path = "src/main.zig" },
            .target = target,
            .optimize = optimize,
        });

        exe.addModule("build_options", exe_options.createModule());
        exe.addModule("util", b.createModule(.{ .source_file = .{ .path = "src/util.zig" } }));
        exe.addModule("clap", clap.module("clap"));

        // This declares intent for the executable to be installed into the
        // standard location when the user invokes the "install" step (the default
        // step when running `zig build`).
        b.installArtifact(exe);

        // === zig build run ===
        {
            const run_cmd = b.addRunArtifact(exe);

            run_cmd.step.dependOn(b.getInstallStep());

            // This allows the user to pass arguments to the application in the build
            // command itself, like this: `zig build run -- arg1 arg2 etc`
            if (b.args) |args| {
                run_cmd.addArgs(args);
            }

            const run_step = b.step("run", "Run the app");
            run_step.dependOn(&run_cmd.step);
        }
    }

    // === zig build test ===
    {
        // Creates a step for unit testing. This only builds the test executable
        // but does not run it.
        const unit_tests = b.addTest(.{
            .root_source_file = .{ .path = "src/main.zig" },
            .target = target,
            .optimize = optimize,
        });

        const run_unit_tests = b.addRunArtifact(unit_tests);

        const test_step = b.step("test", "Run unit tests");
        test_step.dependOn(&run_unit_tests.step);
    }

    // === zig build release-artifacts ===
    {
        const targets = [_]std.zig.CrossTarget{
            .{ .cpu_arch = .x86_64, .os_tag = .linux },
            .{ .cpu_arch = .x86_64, .os_tag = .windows },
        };

        const release_artifact_step = b.step("release-artifacts", "Build the release artifacts");

        inline for (targets) |artifact_target| {
            const artifact_optimize = .ReleaseSafe;

            const clap = b.dependency("clap", .{
                .target = artifact_target,
                .optimize = artifact_optimize,
            });

            const exe_options = b.addOptions();
            exe_options.addOption(bool, "use_gpa", false);

            const artifact_exe = b.addExecutable(.{
                .name = "comdirect-spending-calculator",
                .root_source_file = .{ .path = "src/main.zig" },
                .target = artifact_target,
                .optimize = artifact_optimize,
            });

            artifact_exe.strip = true;

            artifact_exe.addModule("build_options", exe_options.createModule());
            artifact_exe.addModule("util", b.createModule(.{ .source_file = .{ .path = "src/util.zig" } }));
            artifact_exe.addModule("clap", clap.module("clap"));

            const install_artifcat_exe = b.addInstallArtifact(artifact_exe, .{
                .dest_dir = .{
                    .override = .{
                        .custom = "release/",
                    },
                },
            });

            release_artifact_step.dependOn(&install_artifcat_exe.step);
        }
    }
}
