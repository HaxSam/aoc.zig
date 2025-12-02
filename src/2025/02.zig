//! https://adventofcode.com/2025/day/2

const std = @import("std");
const buildtin = @import("builtin");
const utils = @import("utils");

arena: std.heap.ArenaAllocator,
input: []const u8,

const Self = @This();

pub const DAY = 2;
pub const YEAR = 2025;
pub const INPUT = @embedFile("input");

//////////////////////////////////////////////////
//////////////// Solve here //////////////////////
///////// I setup everything for u ///////////////
///////////////// have fun ///////////////////////
//////////////////////////////////////////////////

pub const Input = struct {
    l: usize,
    r: usize,
};
pub const InputType = []Input;

// Advent of Parsing~
pub fn processInput(self: *Self) !InputType {
    var allocator = self.arena.allocator();

    const end = std.mem.lastIndexOfScalar(u8, self.input, '\n').?;
    self.input = self.input[0..end];

    const line_count = std.mem.count(u8, self.input, ",") + 1;
    var split = std.mem.tokenizeScalar(u8, self.input, ',');
    const lines = try allocator.alloc(Input, line_count);

    var i: usize = 0;
    while (split.next()) |line| : (i += 1) {
        var nums = std.mem.tokenizeAny(u8, line, "-");

        const l, const r = .{ nums.next(), nums.next() };

        lines[i] = .{
            .l = try utils.parseInt(usize, l.?),
            .r = try utils.parseInt(usize, r.?),
        };
    }

    return lines;
}

// Advent of Code (Time to solve fr)
pub fn part1(self: *Self, input: InputType) !?u128 {
    _ = self.arena.allocator();

    var sum: u128 = 0;
    for (input) |put| {
        for (put.l..put.r + 1) |id| {
            const len: u32 = std.math.log10_int(id) + 1;
            if (@rem(len, 2) != 0) {
                continue;
            }
            const tens: u32 = std.math.pow(u32, 10, @divFloor(len, 2));

            if (@rem(id, tens) == @divFloor(id, tens)) {
                sum += id;
            }
        }
    }

    return sum;
}

pub fn part2(self: *Self, input: InputType) !?u128 {
    _ = self.arena.allocator();

    var sum: u128 = 0;
    for (input) |put| {
        for (put.l..put.r + 1) |id| {
            const len10 = std.math.log10_int(id) + 1;
            out: for (1..@divFloor(len10, 2) + 1) |len| {
                if (@rem(len10, len) != 0) {
                    continue :out;
                }

                const tens = std.math.pow(u64, 10, len);
                var new_id = id;

                const first = @rem(new_id, tens);
                while (new_id != 0) : (new_id = @divFloor(new_id, tens)) {
                    if (first != @rem(new_id, tens)) {
                        continue :out;
                    }
                }

                sum += id;
                break;
            }
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
        .input = input orelse INPUT,
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
test "Test input for 2025/02" {
    const allocator = std.testing.allocator;
    const input =
        \\11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124
        \\
    ;

    var problem = Self.init(allocator, input);
    defer problem.deinit();

    const processed_input = try problem.processInput();

    try testing.expectEqual(1227775554, try problem.part1(processed_input));
    try testing.expectEqual(4174379265, try problem.part2(processed_input));
}
