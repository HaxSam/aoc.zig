//! https://adventofcode.com/2024/day/11

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

    try stdout.print("{d}/{d}:\n- Part 1: {?}\n- Part 2: {?} \n", .{
        YEAR,
        DAY,
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
    stones: []const u64,
};

// Advent of Parsing~
pub fn processInput(self: *Self) !InputType {
    var allocator = self.arena.allocator();

    const stones_count = std.mem.count(u8, self.input, " ");
    const stones = try allocator.alloc(u64, stones_count + 1);
    var stone = std.mem.tokenizeSequence(u8, self.input, " ");

    for (stones) |*s| {
        s.* = try std.fmt.parseInt(u64, stone.next().?, 10);
    }

    return InputType{
        .stones = stones,
    };
}

// Advent of Code (Time to solve fr)
pub fn part1(self: *Self, input: InputType) !?u128 {
    const allocator = self.arena.allocator();

    var result = std.ArrayList(u64).init(allocator);
    defer result.deinit();

    try result.appendSlice(input.stones);

    for (0..25) |_| {
        const old_result = try result.clone();
        defer old_result.deinit();
        result.clearRetainingCapacity();
        for (old_result.items) |stone| {
            if (stone == 0) {
                try result.append(1);
                continue;
            }
            const tens = std.math.log10_int(stone) + 1;
            if (tens % 2 == 1) {
                try result.append(stone * 2024);
            } else {
                const shift = std.math.pow(u64, 10, tens / 2);
                try result.append(stone / shift);
                try result.append(stone % shift);
            }
        }
    }

    return @intCast(result.items.len);
}

pub fn part2(self: *Self, input: InputType) !?u128 {
    const allocator = self.arena.allocator();

    var result = std.AutoHashMap(u64, u64).init(allocator);
    defer result.deinit();

    for (input.stones) |stone| {
        const stone_cache = try result.getOrPutValue(stone, 0);
        stone_cache.value_ptr.* += 1;
    }

    var result_v: u64 = 0;

    for (0..74) |_| {
        var old_result = try result.clone();
        defer old_result.deinit();
        result.clearRetainingCapacity();
        var iter = old_result.iterator();
        while (iter.next()) |stone| {
            if (stone.key_ptr.* == 0) {
                const stone_cache = try result.getOrPutValue(1, 0);
                stone_cache.value_ptr.* += stone.value_ptr.*;
                continue;
            }
            const tens = std.math.log10_int(stone.key_ptr.*) + 1;
            if (tens % 2 == 1) {
                const stone_cache = try result.getOrPutValue(stone.key_ptr.* * 2024, 0);
                stone_cache.value_ptr.* += stone.value_ptr.*;
            } else {
                const shift = std.math.pow(u64, 10, tens / 2);

                const stone_cache1 = try result.getOrPutValue(stone.key_ptr.* / shift, 0);
                stone_cache1.value_ptr.* += stone.value_ptr.*;
                const stone_cache2 = try result.getOrPutValue(stone.key_ptr.* % shift, 0);
                stone_cache2.value_ptr.* += stone.value_ptr.*;
            }
        }
    }

    var iter = result.iterator();
    while (iter.next()) |stone| {
        if (stone.key_ptr.* == 0) {
            result_v += stone.value_ptr.*;
            continue;
        }
        const tens = std.math.log10_int(stone.key_ptr.*) + 1;
        if (tens % 2 == 1) {
            result_v += stone.value_ptr.*;
        } else {
            result_v += stone.value_ptr.* * 2;
        }
    }

    return result_v;
}

test "Test input for 2024/11" {
    const allocator = std.testing.allocator;
    const input =
        \\125 17
    ;

    var problem = Self.init(allocator, input);
    defer problem.deinit();

    const processed_input = try problem.processInput();

    try std.testing.expectEqual(55312, try problem.part1(processed_input));
    try std.testing.expectEqual(null, try problem.part2(processed_input));
}
