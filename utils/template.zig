//! https://adventofcode.com/0xC0FE/day/0xBEEF

const std = @import("std");
const buildtin = @import("builtin");
const utils = @import("utils");

arena: std.heap.ArenaAllocator,
input: []const u8,

const Self = @This();

pub const DAY = 0xBEEF;
pub const YEAR = 0xC0FE;
pub const INPUT = @embedFile("input");

pub fn init(allocator: std.mem.Allocator, input: ?[]const u8) Self {
    return Self{
        .arena = std.heap.ArenaAllocator.init(allocator),
        .input = input orelse INPUT,
    };
}

pub fn deinit(self: *const Self) void {
    self.arena.deinit();
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const stdout = std.io.getStdOut().writer();

    var solve = Self.init(allocator, null);
    defer solve.deinit();

    const processed_input = try solve.processInput();
    const part1_result = try solve.part1(processed_input);
    const part2_result = try solve.part2(processed_input);

    try stdout.print("0xC0FE/0xBEEF:\n- Part 1: {?}\n- Part 2: {?} \n", .{
        part1_result,
        part2_result,
    });
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

    const line_count = std.mem.count(u8, INPUT, "\n");
    var split = std.mem.tokenizeSequence(u8, INPUT, "\n");
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

// Test your solution here
const testing = std.testing;
test "Test input for 0xC0FE/0xBEEF" {
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
