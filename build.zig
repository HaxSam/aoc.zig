const std = @import("std");
const utils = @import("tools/root.zig");

const Context = utils.Context;
const YearDay = Context.YearDay;

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const date = utils.DateTime.now();
    const year = b.option(u16, "year", "The year to run aoc in") orelse date.year;

    const utils_mod = b.dependency("utils", .{
        .target = target,
        .optimize = optimize,
    }).module("utils");

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
    const submit_today_step = b.step("submit", "");
    const post_today_step = b.step("post", "");

    inline for (1..26) |day| {
        const yearday: YearDay = .init(year, day);
        const src = b.fmt("src/{s}/{s}.zig", .{ yearday.year_str, yearday.day_str });

        const steps: StepBuilder = .init(b, aoc, yearday, src);

        const input_mod = b.createModule(.{ .root_source_file = b.path(b.fmt("src/{s}/input/{s}.txt", .{ yearday.year_str, yearday.day_str })) });

        const solve_mod = b.createModule(.{
            .root_source_file = b.path(src),
            .target = target,
            .optimize = optimize,
        });
        solve_mod.addImport("utils", utils_mod);
        solve_mod.addImport("input", input_mod);

        const solve = b.addExecutable(.{
            .name = b.fmt("solve: {s}|{s}", .{ yearday.year_str, yearday.day_str }),
            .root_module = solve_mod,
        });
        const solve_test = b.addTest(.{
            .name = b.fmt("test: {s}|{s}", .{ yearday.year_str, yearday.day_str }),
            .root_module = solve_mod,
        });

        const solve_exe = b.addRunArtifact(solve);
        const solve_test_exe = b.addRunArtifact(solve_test);

        const submit_mod = b.createModule(.{
            .root_source_file = b.path("tools/submit.zig"),
            .target = target,
            .optimize = .ReleaseFast,
        });
        submit_mod.addImport("solve", solve_mod);

        const submit = b.addExecutable(.{
            .name = b.fmt("submit: {s}|{s}", .{ yearday.year_str, yearday.day_str }),
            .root_module = submit_mod,
        });
        const submit_exe = b.addRunArtifact(submit);

        const gen_step = b.step(b.fmt("gen:{d}", .{day}), "");
        gen_step.dependOn(steps.fetch_step);
        gen_step.dependOn(steps.generate_step);

        const test_step = b.step(b.fmt("test:{d}", .{day}), "");
        test_step.dependOn(&solve_test_exe.step);

        const run_step = b.step(b.fmt("run:{d}", .{day}), "");
        run_step.dependOn(&solve_exe.step);

        const submit_step = b.step(b.fmt("submit:{d}", .{day}), "");
        submit_step.dependOn(&submit_exe.step);

        const post_step = b.step(b.fmt("post:{d}", .{day}), "");
        post_step.dependOn(steps.post_step);

        if (day == date.day) {
            gen_today_step.dependOn(gen_step);
            test_today_step.dependOn(test_step);
            run_today_step.dependOn(run_step);
            submit_today_step.dependOn(submit_step);
            post_today_step.dependOn(post_step);
        }
    }
}

const StepBuilder = struct {
    const Step = std.Build.Step;
    const Compile = Step.Compile;
    const Run = Step.Run;
    const Self = @This();

    fetch_step: *Step,
    generate_step: *Step,
    post_step: *Step,

    pub fn init(b: *std.Build, aoc: *Compile, yearday: YearDay, path: []const u8) Self {
        return .{
            .fetch_step = fetch(b.addRunArtifact(aoc), yearday, b.fmt("{s}/input", .{path[0..8]})),
            .generate_step = generate(b.addRunArtifact(aoc), yearday, path[0..8]),
            .post_step = post(b.addRunArtifact(aoc), path),
        };
    }

    fn fetch(tool: *Run, yearday: YearDay, path: ?[]const u8) *Step {
        tool.addArg("fetch");
        tool.addArg(&yearday.year_str);
        tool.addArg(&yearday.day_str);
        if (path) |p| {
            tool.addArg(p);
        }
        return &tool.step;
    }

    fn generate(tool: *Run, yearday: YearDay, path: ?[]const u8) *Step {
        tool.addArg("generate");
        tool.addArg(&yearday.year_str);
        tool.addArg(&yearday.day_str);
        if (path) |p| {
            tool.addArg(p);
        }
        return &tool.step;
    }

    fn post(tool: *Run, path: []const u8) *Step {
        tool.addArg("post");
        tool.addArg(path);
        return &tool.step;
    }
};
