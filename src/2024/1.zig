//! https://adventofcode.com/2024/day/1

const std = @import("std");
const utils = @import("utils");

arena: std.heap.ArenaAllocator,
input: []const u8,

const Self = @This();

pub const DAY = 1;
pub const YEAR = 2024;

pub fn init(allocator: std.mem.Allocator, input: []const u8) Self {
    return Self{
        .arena = std.heap.ArenaAllocator.init(allocator),
        .input = input,
    };
}

pub fn deinit(self: *const Self) void {
    self.arena.deinit();
}

//////////////////////////////////////////////////
//////////////// Solve here //////////////////////
////////// I setup everyting for u ///////////////
///////////////// have fun ///////////////////////
//////////////////////////////////////////////////

pub const InputType = struct {
    left: []u32,
    right: []u32,
};

// Advent of Parsing~
pub fn processInput(self: *Self) !InputType {
    var allocator = self.arena.allocator();

    var lines = std.mem.tokenizeSequence(u8, self.input, "\n");
    const line_count = std.mem.count(u8, self.input, "\n");

    const left = try allocator.alloc(u32, line_count);
    errdefer allocator.free(left);
    const right = try allocator.alloc(u32, line_count);
    errdefer allocator.free(right);

    for (left, right) |*lef, *rig| {
        var line = std.mem.tokenizeSequence(u8, lines.next().?, " ");
        lef.* = try std.fmt.parseInt(u32, line.next().?, 10);
        rig.* = try std.fmt.parseInt(u32, line.next().?, 10);
    }

    return InputType{
        .left = left,
        .right = right,
    };
}

// Advent of Code (Time to solve fr)
pub fn part1(self: *Self, input: InputType) !?u128 {
    _ = self.arena.allocator();

    std.mem.sort(u32, input.left, {}, comptime std.sort.asc(u32));
    std.mem.sort(u32, input.right, {}, comptime std.sort.asc(u32));

    var sum: u64 = 0;
    for (input.left, input.right) |l, r| {
        sum += @abs(@as(i64, l) - @as(i64, r));
    }

    return sum;
}

pub fn part2(self: *Self, input: InputType) !?u128 {
    _ = self.arena.allocator();
    var sum: usize = 0;

    for (input.left) |n| {
        sum += n * std.mem.count(u32, input.right, &[_]u32{n});
    }

    return sum;
}

test "Test input for 2024/1" {
    const allocator = std.testing.allocator;
    const input =
        \\3   4
        \\4   3
        \\2   5
        \\1   3
        \\3   9
        \\3   3
        \\
    ;

    var problem = Self.init(allocator, input);
    defer problem.deinit();

    const processed_input = try problem.processInput();

    try std.testing.expectEqual(11, try problem.part1(processed_input));
    try std.testing.expectEqual(31, try problem.part2(processed_input));
}
