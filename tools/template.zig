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

//////////////////////////////////////////////////
//////////////// Solve here //////////////////////
///////// I setup everything for u ///////////////
///////////////// have fun ///////////////////////
//////////////////////////////////////////////////

pub const Input = []const u8;
pub const InputType = []Input;

// Advent of Parsing~
pub fn processInput(self: *Self) !InputType {
    var allocator = self.arena.allocator();

    const line_count = std.mem.count(u8, self.input, "\n");
    var split = std.mem.tokenizeSequence(u8, self.input, "\n");
    const lines = try allocator.alloc(Input, line_count);

    for (lines) |*l| {
        l.* = split.next().?;
    }

    return lines;
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

//////////////////////////////////////////////////
//////////////////////////////////////////////////
//////////// Setup for the solver ////////////////
//////////////////////////////////////////////////
//////////////////////////////////////////////////

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
    const alloc: utils.Alloc = .init();
    defer alloc.deinit();

    const allocator = alloc.allocator;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var solve = Self.init(allocator, null);
    defer solve.deinit();

    const processed_input = try solve.processInput();
    const part1_result = try solve.part1(processed_input);
    const part2_result = try solve.part2(processed_input);

    try stdout.print("0xC0FE/00xBEEF:\n- Part 1: {?}\n- Part 2: {?}\n", .{
        part1_result,
        part2_result,
    });
    try stdout.flush();
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
