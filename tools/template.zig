//! https://adventofcode.com/0xC0FE/day/0xBEEF

const std = @import("std");
const buildtin = @import("builtin");
const utils = @import("utils");

arena: std.heap.ArenaAllocator,
input: []const u8,

const Self = @This();

pub const DAY = 0xBEEF;
pub const YEAR = 0xC0FE;
pub const INPUT_FILE = @embedFile("input");

//////////////////////////////////////////////////
//////////////// Solve here //////////////////////
///////// I setup everything for u ///////////////
///////////////// have fun ///////////////////////
//////////////////////////////////////////////////

pub const InputType = []const u8;
pub const Input = []InputType;

// Advent of Parsing~
pub fn processInput(self: *Self) !Input {
    var allocator = self.arena.allocator();

    const end = std.mem.lastIndexOfScalar(u8, self.input, '\n').?;
    self.input = self.input[0..end];

    const split_on = "\n";
    const line_count = std.mem.count(u8, self.input, split_on) + 1;
    var split = std.mem.tokenizeSequence(u8, self.input, split_on);
    const lines = try allocator.alloc(InputType, line_count);

    for (lines) |*l| {
        l.* = split.next().?;
    }

    return lines;
}

// Advent of Code (Time to solve fr)
pub fn part1(self: *Self, input: Input) !?u128 {
    _ = self.arena.allocator();
    _ = input;
    return null;
}

pub fn part2(self: *Self, input: Input) !?u128 {
    _ = self.arena.allocator();
    _ = input;
    return null;
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
test "Test input for 0xC0FE/00xBEEF" {
    const allocator = std.testing.allocator;
    const input =
        \\
    ;

    var problem = Self.init(allocator, input);
    defer problem.deinit();

    const processed_input = try problem.processInput();

    try testing.expectEqual(null, try problem.part1(processed_input));
    try testing.expectEqual(null, try problem.part2(processed_input));
}
