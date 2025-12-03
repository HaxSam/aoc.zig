//! https://adventofcode.com/2025/day/3

const std = @import("std");
const buildtin = @import("builtin");
const utils = @import("utils");

arena: std.heap.ArenaAllocator,
input: []const u8,

const Self = @This();

pub const DAY = 3;
pub const YEAR = 2025;
pub const INPUT_FILE = @embedFile("input");

//////////////////////////////////////////////////
//////////////// Solve here //////////////////////
///////// I setup everything for u ///////////////
///////////////// have fun ///////////////////////
//////////////////////////////////////////////////

pub const Battery = if (buildtin.is_test) [15]u8 else [100]u8;
pub const InputType = []Battery;

// Advent of Parsing~
pub fn processInput(self: *Self) !InputType {
    var allocator = self.arena.allocator();

    const end = std.mem.lastIndexOfScalar(u8, self.input, '\n').?;
    self.input = self.input[0..end];

    const split_on = "\n";
    const line_count = std.mem.count(u8, self.input, split_on) + 1;
    var split = std.mem.tokenizeSequence(u8, self.input, split_on);
    const lines = try allocator.alloc(Battery, line_count);

    for (lines) |*l| {
        for (split.next().?, 0..) |char, i| {
            l[i] = char - 0x30;
        }
    }

    return lines;
}

// Advent of Code (Time to solve fr)
pub fn part1(self: *Self, input: InputType) !?u128 {
    _ = self.arena.allocator();

    var sum: u128 = 0;
    for (input) |put| {
        var largest: u8 = 0;
        var largest_index: usize = 0;
        for (0..put.len - 1) |i| {
            if (put[i] > largest) {
                largest = put[i];
                largest_index = i;
            }
        }
        var second_large: u8 = 0;
        for (largest_index + 1..put.len) |i| {
            if (put[i] > second_large) {
                second_large = put[i];
            }
        }
        sum += largest * 10 + second_large;
    }

    return sum;
}

pub fn part2(self: *Self, input: InputType) !?u128 {
    _ = self.arena.allocator();

    const tens: [12]u64 = comptime blk: {
        var arr: [12]u64 = @splat(0);
        for (0..arr.len) |i| {
            arr[i] = std.math.pow(u64, 10, 11 - i);
        }
        break :blk arr;
    };

    var sum: u128 = 0;
    for (input) |put| {
        var last_index: ?usize = null;
        for (0..12) |s| {
            const last = if (last_index) |l| l + 1 else 0;
            var largest: u8 = 0;
            for (last..put.len - (11 - s)) |i| {
                if (put[i] > largest) {
                    largest = put[i];
                    last_index = i;
                }
            }
            sum += largest * tens[s];
        }
    }

    return sum;
}

//////////////////////////////////////////////////
//////////////////////////////////////////////////
//////////// Setup for the solver ////////////////
//////////////////////////////////////////////////
//////////////////////////////////////////////////

pub fn init(allocator: std.mem.Allocator, input: ?[]const u8) Self {
    return Self{
        .arena = std.heap.ArenaAllocator.init(allocator),
        .input = input orelse INPUT_FILE,
    };
}

pub fn deinit(self: *const Self) void {
    self.arena.deinit();
}

pub fn main() !void {
    try utils.runMain(Self);
}

// Test your solution here
const testing = std.testing;
test "Test input for 2025/03" {
    const allocator = std.testing.allocator;
    const input =
        \\987654321111111
        \\811111111111119
        \\234234234234278
        \\818181911112111
        \\
    ;

    var problem = Self.init(allocator, input);
    defer problem.deinit();

    const processed_input = try problem.processInput();

    try testing.expectEqual(357, try problem.part1(processed_input));
    try testing.expectEqual(3121910778619, try problem.part2(processed_input));
}
