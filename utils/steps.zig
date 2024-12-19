const std = @import("std");
const utils = @import("root.zig");

pub const SetupContex = struct {
    const Self = @This();

    b: *std.Build,
    year: u16,
    day: u8,
    step: std.Build.Step,
    pub fn init(b: *std.Build, year: u16, day: u8) *Self {
        const ctx = b.allocator.create(@This()) catch unreachable;
        var day_buf: [8]u8 = undefined;
        ctx.* = .{
            .b = b,
            .year = year,
            .day = day,
            .step = std.Build.Step.init(.{
                .id = .custom,
                .name = b.fmt("Setup {d}|{s}", .{ year, utils.DateTime.twoDigitDay(&day_buf, day) }),
                .owner = b,
                .makeFn = Self.make,
            }),
        };

        return ctx;
    }
    pub fn deinit(self: *Self) void {
        self.b.allocator.destroy(self);
    }
    pub fn make(step: *std.Build.Step, options: std.Progress.Node) anyerror!void {
        _ = options;
        const self: *Self = @fieldParentPtr("step", step);
        _ = try utils.generate.ensureSolve(self.b.allocator, self.year, self.day);
        _ = try utils.fetch.ensureInput(self.b.allocator, self.year, self.day);
    }
};

pub const PostContext = struct {
    const Self = @This();

    b: *std.Build,
    year: u16,
    day: u8,
    step: std.Build.Step,
    pub fn init(b: *std.Build, year: u16, day: u8) *Self {
        const ctx = b.allocator.create(@This()) catch unreachable;
        var day_buf: [8]u8 = undefined;
        ctx.* = .{
            .b = b,
            .year = year,
            .day = day,
            .step = std.Build.Step.init(.{
                .id = .custom,
                .name = b.fmt("Post {d}|{s}", .{ year, utils.DateTime.twoDigitDay(&day_buf, day) }),
                .owner = b,
                .makeFn = Self.make,
            }),
        };

        return ctx;
    }
    pub fn deinit(self: *Self) void {
        self.b.allocator.destroy(self);
    }
    pub fn make(step: *std.Build.Step, options: std.Progress.Node) anyerror!void {
        _ = options;
        const self: *Self = @fieldParentPtr("step", step);
        var day_buf: [8]u8 = undefined;
        try utils.post.postSolution(
            self.b.allocator,
            self.b.fmt("src/{d}/{s}.zig", .{ self.year, utils.DateTime.twoDigitDay(&day_buf, self.day) }),
        );
    }
};
