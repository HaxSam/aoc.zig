//! https://adventofcode.com/0xC0FE/day/0xBEEF

const std = @import("std");
const utils = @import("utils");

arena: std.heap.ArenaAllocator,
input: []const u8,

const Self = @This();

pub const DAY = 0xBEEF;
pub const YEAR = 0xC0FE;

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
    var split = std.mem.tokenizeSequence(u8, self.input, "\n");
    const lines = try allocator.alloc([]const u8, line_count);

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

test "Test input for 0xC0FE/0xBEEF" {
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
