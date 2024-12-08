const std = @import("std");

fn findHighestEntry(comptime T: type, root_dir: std.fs.Dir, dir_path: []const u8, kind: std.fs.File.Kind) !T {
    var max: ?T = null;

    const dir = try root_dir.openDir(dir_path, .{ .iterate = true });
    var iter = dir.iterate();
    while (try iter.next()) |entry| {
        if (entry.kind != kind) continue;

        const parsed = try std.fmt.parseInt(T, std.fs.path.stem(entry.name), 10);
        if (max == null or parsed > max.?)
            max = parsed;
    }

    return max orelse std.fs.File.OpenError.FileNotFound;
}

fn ensureSource(allocator: std.mem.Allocator, root_dir: std.fs.Dir, year: u16, day: u8) ![]const u8 {
    const path = try std.fmt.allocPrint(allocator, "src/{d}/{d}.zig", .{ year, day });

    root_dir.access(path, .{}) catch |err| switch (err) {
        error.FileNotFound => {
            const template_file = try root_dir.openFile("template.zig", .{});
            var template = try template_file.readToEndAlloc(allocator, try template_file.getEndPos());

            template = try std.mem.replaceOwned(u8, allocator, template, "0xC0FE", try std.fmt.allocPrint(allocator, "{d}", .{year}));
            template = try std.mem.replaceOwned(u8, allocator, template, "0xBEEF", try std.fmt.allocPrint(allocator, "{d}", .{day}));

            try root_dir.makePath(try std.fmt.allocPrint(allocator, "src/{d}", .{year}));
            const file = try root_dir.createFile(path, .{});
            try file.writeAll(template);
        },
        else => return err,
    };

    return path;
}

fn ensureInput(allocator: std.mem.Allocator, root_dir: std.fs.Dir, year: u16, day: u8) !void {
    const path = try std.fmt.allocPrint(allocator, "src/{d}/input/{d}.txt", .{ year, day });
    root_dir.access(path, .{}) catch |err| switch (err) {
        error.FileNotFound => {
            const token_file = root_dir.openFile(".session", .{}) catch std.debug.panic("Root directory does not contain a .session file", .{});
            defer token_file.close();
            const token = try token_file.reader().readAllAlloc(allocator, try token_file.getEndPos());

            var client = std.http.Client{ .allocator = allocator };
            defer client.deinit();

            var response = std.ArrayList(u8).init(allocator);
            defer response.deinit();

            const res = try client.fetch(.{
                .location = .{
                    .url = try std.fmt.allocPrint(
                        allocator,
                        "https://adventofcode.com/{d}/day/{d}/input",
                        .{ year, day },
                    ),
                },
                .method = .GET,
                .extra_headers = &[_]std.http.Header{
                    .{
                        .name = "Cookie",
                        .value = try std.fmt.allocPrint(
                            allocator,
                            "session={s}",
                            .{token},
                        ),
                    },
                },
                .response_storage = .{ .dynamic = &response },
            });

            if (res.status != .ok)
                return error.FailedToFetchInputFile;

            // Save to disk
            const dir = try std.fs.cwd().makeOpenPath(
                std.fs.path.dirname(path).?,
                .{},
            );
            const file = try dir.createFile(std.fs.path.basename(path), .{});
            defer file.close();
            try file.writeAll(response.items);
        },
        else => return err,
    };
}

pub fn build(b: *std.Build) !void {
    const root_dir = try std.fs.openDirAbsolute(b.path(".").getPath(b), .{});

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const year = b.option(u16, "year", "The year to run the day in") orelse findHighestEntry(u16, root_dir, "src", std.fs.File.Kind.directory) catch {
        try b.default_step.addError("Could't detect year, please provide one to complete initialization logic", .{});
        return;
    };
    const day = b.option(u8, "day", "The day to run") orelse findHighestEntry(u8, root_dir, try std.fmt.allocPrint(b.allocator, "src/{d}", .{year}), std.fs.File.Kind.file) catch {
        try b.default_step.addError("Could't detect day, please provide one to complete initialization logic", .{});
        return;
    };

    const solve_source_file = b.path(try ensureSource(b.allocator, root_dir, year, day));
    try ensureInput(b.allocator, root_dir, year, day);

    const utils = b.addModule("utils", .{
        .root_source_file = b.path("src/utils/root.zig"),
    });

    const solve = b.addModule("problem", .{
        .root_source_file = solve_source_file,
    });
    solve.addImport("utils", utils);

    const zbench_module = b.dependency("zbench", .{
        .target = target,
        .optimize = optimize,
    }).module("zbench");

    const exe = b.addExecutable(.{
        .name = "aoc.zig",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("problem", solve);
    exe.root_module.addImport("zbench", zbench_module);

    const unit_test = b.addTest(.{
        .root_source_file = solve_source_file,
        .target = target,
        .optimize = optimize,
    });
    unit_test.root_module.addImport("utils", utils);

    const create_step = b.step("create", "Check for compilation errors");
    create_step.dependOn(&exe.step);

    const run_test = b.addRunArtifact(unit_test);
    const test_step = b.step("test", "Run tests for the day");
    test_step.dependOn(&run_test.step);

    const run_exe = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the day");
    run_step.dependOn(&run_exe.step);
}
