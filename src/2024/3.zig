//! https://adventofcode.com/2024/day/3

const std = @import("std");
const utils = @import("utils");

arena: std.heap.ArenaAllocator,
input: []const u8,

const Self = @This();

pub const DAY = 3;
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
    lines: [][]const u8,
};

// Advent of Parsing~
pub fn processInput(self: *Self) !InputType {
    var allocator = self.arena.allocator();

    const line_count = std.mem.count(u8, self.input, "\n");
    const lines = try allocator.alloc([]const u8, line_count);
    var split = std.mem.tokenizeSequence(u8, self.input, "\n");

    for (lines) |*l| {
        l.* = split.next().?;
    }

    return InputType{
        .lines = lines,
    };
}

// Advent of Code (Time to solve fr)
pub fn part1(self: *Self, input: InputType) !?u128 {
    _ = self.arena.allocator();
    _ = input;
    return null;
}

pub fn part2(self: *Self, input: InputType) !?u128 {
    _ = self.arena.allocator();
    _ = input;
    return null;
}

test "Test input for 2024/3" {
    const allocator = std.testing.allocator;
    const input =
        \\
    ;

    var problem = Self.init(allocator, input);
    defer problem.deinit();

    const processed_input = try problem.processInput();

    try std.testing.expectEqual(null, try problem.part1(processed_input));
    try std.testing.expectEqual(null, try problem.part2(processed_input));
}
