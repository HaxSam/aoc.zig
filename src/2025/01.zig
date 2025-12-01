//! https://adventofcode.com/2025/day/1

const std = @import("std");
const buildtin = @import("builtin");
const utils = @import("utils");

arena: std.heap.ArenaAllocator,
input: []const u8,

const Self = @This();

pub const DAY = 1;
pub const YEAR = 2025;
pub const INPUT = @embedFile("input");

//////////////////////////////////////////////////
//////////////// Solve here //////////////////////
///////// I setup everything for u ///////////////
///////////////// have fun ///////////////////////
//////////////////////////////////////////////////

pub const InputType = []const i64;

// Advent of Parsing~
pub fn processInput(self: *Self) !InputType {
    var allocator = self.arena.allocator();

    const line_count = std.mem.count(u8, self.input, "\n");
    var split = std.mem.tokenizeSequence(u8, self.input, "\n");
    const lines = try allocator.alloc(i64, line_count);

    for (lines) |*l| {
        const line = split.next().?;
        l.* = try utils.parseInt(i64, line[1..]);
        if (line[0] == 'L') {
            l.* *= -1;
        }
    }

    return lines;
}

// Advent of Code (Time to solve fr)
pub fn part1(self: *Self, input: InputType) !?u128 {
    _ = self.arena.allocator();

    var dial: i64 = 50;
    var count_zeros: u128 = 0;
    for (input) |dial_move| {
        dial = @rem(dial + dial_move, 100);
        if (dial == 0) {
            count_zeros += 1;
        }
    }

    return count_zeros;
}

pub fn part2(self: *Self, input: InputType) !?u128 {
    _ = self.arena.allocator();

    var dial: i64 = 50;
    var count_zeros: u128 = 0;
    for (input) |dial_move| {
        count_zeros += @divFloor(@abs(dial_move), 100);
        const mod_dial_move = @rem(dial_move, 100);

        const new_dial_pos = dial + mod_dial_move;
        if (new_dial_pos >= 100 or (new_dial_pos < 0 and dial != 0) or new_dial_pos == 0) {
            count_zeros += 1;
        }

        dial = @mod(new_dial_pos, 100);
    }

    return count_zeros;
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

    try stdout.print("2025/01:\n- Part 1: {?}\n- Part 2: {?}\n", .{
        part1_result,
        part2_result,
    });
    try stdout.flush();
}

// Test your solution here
const testing = std.testing;
test "Test input for 2025/01" {
    const allocator = std.testing.allocator;
    const input =
        \\L68
        \\L30
        \\R48
        \\L5
        \\R60
        \\L55
        \\L1
        \\L99
        \\R14
        \\L82
        \\
    ;

    var problem = Self.init(allocator, input);
    defer problem.deinit();

    const processed_input = try problem.processInput();

    try testing.expectEqual(3, try problem.part1(processed_input));
    try testing.expectEqual(6, try problem.part2(processed_input));
}
