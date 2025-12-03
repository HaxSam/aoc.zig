const std = @import("std");

const Allocator = std.mem.Allocator;
const Writer = std.Io.Writer;
const fs = std.fs;

const Self = @This();

pub const Error = error{
    InvalidArgs,
};

pub const YearDay = struct {
    year_str: [4]u8 = undefined,
    day_str: [2]u8 = undefined,
    year: u16,
    day: u8,

    pub fn init(year: u16, day: u8) YearDay {
        var ret: YearDay = .{ .year = year, .day = day };

        _ = std.fmt.printInt(&ret.year_str, year, 10, .lower, .{});
        _ = std.fmt.printInt(&ret.day_str, day, 10, .lower, .{ .width = 2, .fill = '0' });

        return ret;
    }
};

args: []const [:0]const u8,
root_dir: fs.Dir = fs.cwd(),
out: *Writer = undefined,
err: *Writer = undefined,

pub fn init(args: []const [:0]const u8, out: *Writer, err: *Writer) Self {
    return .{
        .args = args,
        .out = out,
        .err = err,
    };
}

pub fn parseInt(self: *Self, comptime T: type) (std.fmt.ParseIntError || Error)!T {
    if (self.args.len < 1) {
        return error.InvalidArgs;
    }

    const part_str = self.args[0];
    const part = try std.fmt.parseInt(T, part_str, 10);

    self.args = self.args[1..];
    return part;
}

pub fn parseExe(self: *Self) Error![]const u8 {
    if (self.args.len < 1) {
        return error.InvalidArgs;
    }

    const exe = b: {
        const name = fs.path.basename(self.args[0]);
        if (!std.mem.eql(u8, name, "aoc")) {
            self.args = self.args[1..];
            break :b name;
        }
        if (self.args.len < 2) {
            return Error.InvalidArgs;
        }
        const arg1 = self.args[1];
        self.args = self.args[2..];
        break :b arg1;
    };

    return exe;
}

pub fn parseYearDay(self: *Self) !YearDay {
    const year = try self.parseInt(u16);
    const day = try self.parseInt(u8);

    return YearDay.init(year, day);
}

pub fn parsePath(self: *Self, allocator: Allocator) std.fs.Dir.RealPathError![]const u8 {
    const path = b: {
        if (self.args.len == 0) {
            break :b self.root_dir.realpathAlloc(allocator, ".") catch |err| switch (err) {
                error.OutOfMemory => @panic("OOM"),
                else => |e| return e,
            };
        }
        const p = allocator.dupe(u8, self.args[0]) catch @panic("OOM");
        self.args = self.args[1..];
        break :b p;
    };

    return path;
}

pub fn parseToken(self: *Self, allocator: Allocator) ![]const u8 {
    var env = try std.process.getEnvMap(allocator);
    defer env.deinit();

    if (env.get("AOC_SESSION")) |token| {
        return allocator.dupe(u8, token) catch @panic("OOM");
    } else {
        return try self.root_dir.readFileAlloc(allocator, ".session", 1024);
    }
}

pub fn parsePart(self: *Self) !u8 {
    return try self.parseInt(u8);
}

pub fn parseAnswer(self: *Self) !u128 {
    return try self.parseInt(u128);
}

pub fn small_panic(self: *Self, comptime format: []const u8, args: anytype) noreturn {
    self.err.print(format, args) catch unreachable;
    self.err.flush() catch unreachable;
    std.process.exit(1);
}
