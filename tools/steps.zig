const std = @import("std");
const utils = @import("root.zig");

const Step = std.Build.Step;
const Run = Step.Run;

const YearDay = utils.Context.YearDay;

pub const GenerateContex = struct {
    const Self = @This();

    b: *std.Build,
    tool: *Run,

    yearday: YearDay,
    path: ?[]const u8 = null,

    step: Step,

    pub fn init(b: *std.Build, tool: *Step.Compile, yearday: YearDay, path: ?[]const u8) *Self {
        const ctx = b.allocator.create(@This()) catch unreachable;
        ctx.* = .{
            .b = b,
            .tool = b.addRunArtifact(tool),
            .yearday = yearday,
            .path = path,
            .step = Step.init(.{
                .id = .custom,
                .name = b.fmt("generate {s}|{s}", .{ yearday.year_str, yearday.day_str }),
                .owner = b,
                .makeFn = Self.make,
            }),
        };

        ctx.tool.step.dependOn(&ctx.step);

        return ctx;
    }

    pub fn deinit(self: *Self) void {
        self.b.allocator.destroy(self);
    }

    pub fn make(step: *Step, options: Step.MakeOptions) anyerror!void {
        _ = options;
        const self: *Self = @fieldParentPtr("step", step);
        const tool = self.tool;

        tool.addArg("generate");
        tool.addArg(&self.yearday.year_str);
        tool.addArg(&self.yearday.day_str);
        if (self.path) |path| {
            tool.addArg(path);
        }
    }
};

pub const FetchContex = struct {
    const Self = @This();

    b: *std.Build,
    tool: *Run,

    yearday: YearDay,
    path: ?[]const u8 = null,

    step: Step,

    pub fn init(b: *std.Build, tool: *Step.Compile, yearday: YearDay, path: ?[]const u8) *Self {
        const ctx = b.allocator.create(@This()) catch unreachable;
        ctx.* = .{
            .b = b,
            .tool = b.addRunArtifact(tool),
            .yearday = yearday,
            .path = path,
            .step = Step.init(.{
                .id = .custom,
                .name = b.fmt("fetch {s}|{s}", .{ yearday.year_str, yearday.day_str }),
                .owner = b,
                .makeFn = Self.make,
            }),
        };

        ctx.tool.step.dependOn(&ctx.step);

        return ctx;
    }

    pub fn deinit(self: *Self) void {
        self.b.allocator.destroy(self);
    }

    pub fn make(step: *Step, options: Step.MakeOptions) anyerror!void {
        _ = options;
        const self: *Self = @fieldParentPtr("step", step);
        const tool = self.tool;

        tool.addArg("fetch");
        tool.addArg(&self.yearday.year_str);
        tool.addArg(&self.yearday.day_str);
        if (self.path) |path| {
            tool.addArg(path);
        }
    }
};

pub const SubmitContex = struct {
    const Self = @This();

    b: *std.Build,
    tool: *Run,

    yearday: YearDay,
    part: u8,
    solve: std.Build.LazyPath,

    step: Step,

    pub fn init(b: *std.Build, tool: *Step.Compile, yearday: YearDay, part: u8, solution: std.Build.LazyPath) *Self {
        const ctx = b.allocator.create(@This()) catch unreachable;
        ctx.* = .{
            .b = b,
            .tool = b.addRunArtifact(tool),
            .yearday = yearday,
            .part = part,
            .solve = solution,
            .step = Step.init(.{
                .id = .custom,
                .name = b.fmt("submit|{d} {s}|{s}", .{ part, yearday.year_str, yearday.day_str }),
                .owner = b,
                .makeFn = Self.make,
            }),
        };

        ctx.tool.step.dependOn(&ctx.step);
        ctx.step.dependOn(solution.generated.file.step);

        return ctx;
    }

    pub fn deinit(self: *Self) void {
        self.b.allocator.destroy(self);
    }

    pub fn make(step: *Step, options: Step.MakeOptions) anyerror!void {
        _ = options;
        const self: *Self = @fieldParentPtr("step", step);
        const tool = self.tool;

        tool.addArg("submit");
        tool.addArg(&self.yearday.year_str);
        tool.addArg(&self.yearday.day_str);

        tool.addArg(self.b.fmt("{d}", .{self.part}));

        var file_buf: [1024]u8 = undefined;
        const file = std.fs.cwd().readFile(self.solve.generated.file.getPath(), &file_buf) catch @panic("OOM");

        var lines = std.mem.tokenizeSequence(u8, file, "\n");
        _ = lines.next().?;

        const p1 = lines.next().?;
        const p2 = lines.next().?;

        if (self.part < 1 or self.part > 2) {
            @panic("There is no Part 0/3");
        }
        const p = if (self.part == 1) p1 else p2;

        var token = std.mem.splitBackwardsScalar(u8, p, ' ');
        tool.addArg(token.first());
    }
};

pub const PostContex = struct {
    const Self = @This();

    b: *std.Build,
    tool: *Run,

    path: []const u8,

    step: Step,

    pub fn init(b: *std.Build, tool: *Step.Compile, path: []const u8) *Self {
        const ctx = b.allocator.create(@This()) catch unreachable;
        ctx.* = .{
            .b = b,
            .tool = b.addRunArtifact(tool),
            .path = path,
            .step = Step.init(.{
                .id = .custom,
                .name = b.fmt("post {s}", .{path}),
                .owner = b,
                .makeFn = Self.make,
            }),
        };

        ctx.tool.step.dependOn(&ctx.step);

        return ctx;
    }

    pub fn deinit(self: *Self) void {
        self.b.allocator.destroy(self);
    }

    pub fn make(step: *Step, options: Step.MakeOptions) anyerror!void {
        _ = options;
        const self: *Self = @fieldParentPtr("step", step);
        const tool = self.tool;

        tool.addArg("post");
        tool.addArg(self.path);
    }
};
