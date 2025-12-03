const std = @import("std");
const utils = @import("tools/root.zig");

const Context = utils.Context;
const steps = utils.steps;
const YearDay = Context.YearDay;

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const date = utils.DateTime.now();
    const year = b.option(u16, "year", "The year to run aoc in") orelse date.year;
    const part = b.option(u8, "part", "Part to run aoc in") orelse 1;

    const utils_mod = b.dependency("utils", .{
        .target = target,
        .optimize = optimize,
    }).module("utils");

    const zbench_mod = b.dependency("zbench", .{
        .target = target,
        .optimize = optimize,
    }).module("zbench");

    const aoc_mod = b.createModule(.{
        .root_source_file = b.path("tools/root.zig"),
        .target = target,
        .optimize = .ReleaseFast,
    });

    const aoc = b.addExecutable(.{
        .name = "aoc",
        .root_module = aoc_mod,
    });
    b.installArtifact(aoc);

    const gen_today_step = b.step("gen", "");
    const test_today_step = b.step("test", "");
    const run_today_step = b.step("run", "");
    const bin_today_step = b.step("bin", "");
    const submit_today_step = b.step("submit", "");
    const bench_today_step = b.step("bench", "");
    const post_today_step = b.step("post", "");

    inline for (1..26) |day| {
        const yearday: YearDay = .init(year, day);
        const src = b.fmt("src/{s}/{s}.zig", .{ yearday.year_str, yearday.day_str });
        const src_dir = src[0..8];

        const input_mod = b.createModule(.{
            .root_source_file = b.path(b.fmt("src/{s}/input/{s}.txt", .{
                yearday.year_str,
                yearday.day_str,
            })),
        });

        const solve_mod = b.createModule(.{
            .root_source_file = b.path(src),
            .target = target,
            .optimize = optimize,
        });
        solve_mod.addImport("utils", utils_mod);
        solve_mod.addImport("input", input_mod);

        const bench_mod = b.createModule(.{
            .root_source_file = b.path("src/bench.zig"),
            .target = target,
            .optimize = .ReleaseFast,
        });
        bench_mod.addImport("zbench", zbench_mod);
        bench_mod.addImport("solve", solve_mod);

        const solve = b.addExecutable(.{
            .name = b.fmt("solve_{s}-{s}-{s}", .{ yearday.year_str, yearday.day_str, if (optimize == .Debug) "debug" else "release" }),
            .root_module = solve_mod,
        });
        const solve_test = b.addTest(.{
            .name = b.fmt("test_{s}-{s}", .{ yearday.year_str, yearday.day_str }),
            .root_module = solve_mod,
        });
        const bench = b.addExecutable(.{
            .name = b.fmt("bench_{s}-{s}", .{ yearday.year_str, yearday.day_str }),
            .root_module = bench_mod,
        });

        const solve_exe = b.addRunArtifact(solve);
        const solve_test_exe = b.addRunArtifact(solve_test);
        const bench_exe = b.addRunArtifact(bench);
        bench_exe.addArg("3");

        const gen: *steps.GenerateContex = .init(b, aoc, yearday, src_dir);
        defer gen.deinit();

        const fetch: *steps.FetchContex = .init(b, aoc, yearday, b.fmt("{s}/input", .{src_dir}));
        defer fetch.deinit();

        const bin = std.Build.Step.InstallArtifact.create(b, solve, .{});

        const submit: *steps.SubmitContex = .init(b, aoc, yearday, part, b.addRunArtifact(solve));
        defer submit.deinit();

        const post: *steps.PostContex = .init(b, aoc, src);
        defer post.deinit();

        const gen_step = b.step(b.fmt("gen:{d}", .{day}), "");
        gen_step.dependOn(&gen.tool.step);
        gen_step.dependOn(&fetch.tool.step);

        const test_step = b.step(b.fmt("test:{d}", .{day}), "");
        test_step.dependOn(&solve_test_exe.step);

        const run_step = b.step(b.fmt("run:{d}", .{day}), "");
        run_step.dependOn(&solve_exe.step);

        const bin_step = b.step(b.fmt("bin:{d}", .{day}), "");
        bin_step.dependOn(&bin.step);

        const submit_step = b.step(b.fmt("submit:{d}", .{day}), "");
        submit_step.dependOn(&submit.tool.step);

        const bench_step = b.step(b.fmt("bench:{d}", .{day}), "");
        bench_step.dependOn(&bench_exe.step);

        const post_step = b.step(b.fmt("post:{d}", .{day}), "");
        post_step.dependOn(&post.tool.step);

        if (day == date.day) {
            gen_today_step.dependOn(gen_step);
            test_today_step.dependOn(test_step);
            run_today_step.dependOn(run_step);
            bin_today_step.dependOn(bin_step);
            submit_today_step.dependOn(submit_step);
            bench_today_step.dependOn(bench_step);
            post_today_step.dependOn(post_step);
        }
    }
}
