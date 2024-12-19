const std = @import("std");
const utils = @import("utils/root.zig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const date = utils.DateTime.now();
    const year = b.option(u16, "year", "The year to run the day in") orelse date.year;
    const current_day = date.day;

    const utils_mod = b.dependency("utils", .{
        .target = target,
        .optimize = optimize,
    }).module("utils");
    const zbench_mod = b.dependency("zbench", .{
        .target = target,
        .optimize = optimize,
    }).module("zbench");

    const create_current_step = b.step("create", "Setup current day");
    const run_current_step = b.step("run", "Run current day");
    const test_current_step = b.step("test", "Test current day");
    const bench_current_step = b.step("bench", "Benchmark current day");
    const submit_current_step = b.step("submit", "Submit current day");
    const post_current_step = b.step("post", "Post current day");

    inline for (1..26) |day| {
        var day_buf: [8]u8 = undefined;
        const day_string = utils.DateTime.twoDigitDay(&day_buf, day);
        if (try utils.generate.existSolve(year, day)) {
            const input_mod = b.addModule(b.fmt("input_{d}-{s}", .{ year, day_string }), .{
                .root_source_file = b.path(try utils.fetch.ensureInput(b.allocator, year, day)),
            });
            const source_file = b.path(try utils.generate.ensureSolve(b.allocator, year, day));

            const solve = b.addExecutable(.{
                .name = b.fmt("solve_{d}-{s}", .{ year, day_string }),
                .root_source_file = source_file,
                .target = target,
                .optimize = optimize,
            });
            solve.root_module.addImport("utils", utils_mod);
            solve.root_module.addImport("input", input_mod);
            const run_solve = b.addRunArtifact(solve);

            const solve_mod = b.addModule(b.fmt("{d}-{s}", .{ year, day_string }), .{
                .root_source_file = source_file,
            });
            solve_mod.addImport("utils", utils_mod);
            solve_mod.addImport("input", input_mod);

            const solve_test = b.addTest(.{
                .name = b.fmt("test_{d}-{s}", .{ year, day_string }),
                .root_source_file = source_file,
                .target = target,
                .optimize = optimize,
            });
            solve_test.root_module.addImport("utils", utils_mod);
            solve_test.root_module.addImport("input", input_mod);
            const run_test = b.addRunArtifact(solve_test);

            const bench = b.addExecutable(.{
                .name = b.fmt("bench_{d}-{s}", .{ year, day_string }),
                .root_source_file = b.path("src/bench.zig"),
                .target = target,
                .optimize = .ReleaseFast,
            });
            bench.root_module.addImport("zbench", zbench_mod);
            bench.root_module.addImport("solve", solve_mod);
            const run_bench = b.addRunArtifact(bench);

            const submit = b.addExecutable(.{
                .name = b.fmt("submit_{d}-{s}", .{ year, day_string }),
                .root_source_file = b.path("src/submit.zig"),
                .target = target,
                .optimize = .ReleaseFast,
            });
            submit.root_module.addImport("solve", solve_mod);
            submit.root_module.addAnonymousImport("token", .{
                .root_source_file = b.path(".session"),
            });
            const run_submit = b.addRunArtifact(submit);

            const ctx = utils.steps.PostContext.init(b, year, day);
            defer ctx.deinit();

            const run_step = b.step(b.fmt("run:{d}", .{day}), b.fmt("Run day {s}", .{day_string}));
            run_step.dependOn(&run_solve.step);
            const test_step = b.step(b.fmt("test:{d}", .{day}), b.fmt("Test day {s}", .{day_string}));
            test_step.dependOn(&run_test.step);
            const bench_step = b.step(b.fmt("bench:{d}", .{day}), b.fmt("Bench day {s}", .{day_string}));
            bench_step.dependOn(&run_bench.step);
            const submit_step = b.step(b.fmt("submit:{d}", .{day}), b.fmt("Submit day {s}", .{day_string}));
            submit_step.dependOn(&run_submit.step);
            const post_step = b.step(b.fmt("post:{d}", .{day}), b.fmt("Post day {s}", .{day_string}));
            post_step.dependOn(&ctx.step);

            if (current_day == day) {
                run_current_step.dependOn(&run_solve.step);
                test_current_step.dependOn(&run_test.step);
                bench_current_step.dependOn(&run_bench.step);
                submit_current_step.dependOn(&run_submit.step);
                post_current_step.dependOn(&ctx.step);
            }
        } else {
            const create_step = b.step(b.fmt("create:{d}", .{day}), b.fmt("Setup day {s}", .{day_string}));
            const ctx = utils.steps.SetupContex.init(b, year, day);
            defer ctx.deinit();
            create_step.dependOn(&ctx.step);

            if (current_day == day) {
                create_current_step.dependOn(&ctx.step);
            }
        }
    }
}
