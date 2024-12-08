//! https://adventofcode.com/2024/day/8

const std = @import("std");
const utils = @import("utils");

arena: std.heap.ArenaAllocator,
input: []const u8,

const Self = @This();

pub const DAY = 8;
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
    radio: std.AutoHashMap(u8, std.ArrayList(@Vector(2, i16))),
    limit: i16,
};

// Advent of Parsing~
pub fn processInput(self: *Self) !InputType {
    const allocator = self.arena.allocator();

    const line_count = std.mem.count(u8, self.input, "\n");
    var split = std.mem.tokenizeSequence(u8, self.input, "\n");

    var radio = std.AutoHashMap(u8, std.ArrayList(@Vector(2, i16))).init(allocator);

    for (0..line_count) |i| {
        for (split.next().?, 0..) |c, j| {
            if (c == '.')
                continue;
            var r = try radio.getOrPut(c);
            if (!r.found_existing)
                r.value_ptr.* = std.ArrayList(@Vector(2, i16)).init(allocator);
            try r.value_ptr.append(.{ @intCast(i), @intCast(j) });
        }
    }

    return InputType{
        .radio = radio,
        .limit = @intCast(line_count),
    };
}

// Advent of Code (Time to solve fr)
pub fn part1(self: *Self, input: InputType) !?u128 {
    const allocator = self.arena.allocator();

    var antinodes = std.AutoHashMap(@Vector(2, i16), void).init(allocator);
    defer antinodes.deinit();

    var iter = input.radio.valueIterator();
    const limit1: @Vector(2, i16) = @splat(0);
    const limit2: @Vector(2, i16) = @splat(input.limit);

    while (iter.next()) |radio| {
        for (radio.items, 1..) |antenna1, i| {
            for (radio.items[i..]) |antenna2| {
                const diff = antenna2 - antenna1;
                const antinode1 = antenna1 - diff;
                const antinode2 = antenna2 + diff;

                if (@reduce(.And, antinode1 >= limit1) and @reduce(.And, antinode1 < limit2))
                    antinodes.put(antinode1, {}) catch {};
                if (@reduce(.And, antinode2 >= limit1) and @reduce(.And, antinode2 < limit2))
                    antinodes.put(antinode2, {}) catch {};
            }
        }
    }

    return @intCast(antinodes.count());
}

pub fn part2(self: *Self, input: InputType) !?u128 {
    const allocator = self.arena.allocator();

    var antinodes = std.AutoHashMap(@Vector(2, i16), void).init(allocator);
    defer antinodes.deinit();

    var iter = input.radio.valueIterator();
    const limit1: @Vector(2, i16) = @splat(0);
    const limit2: @Vector(2, i16) = @splat(input.limit);

    while (iter.next()) |radio| {
        for (radio.items, 1..) |antenna1, i| {
            antinodes.put(antenna1, {}) catch {};
            for (radio.items[i..]) |antenna2| {
                const diff = antenna2 - antenna1;
                var antinode1 = antenna1 - diff;
                var antinode2 = antenna2 + diff;
                antinodes.put(antenna2, {}) catch {};

                while (@reduce(.And, antinode1 >= limit1) and @reduce(.And, antinode1 < limit2)) {
                    antinodes.put(antinode1, {}) catch {};
                    antinode1 -= diff;
                }
                while (@reduce(.And, antinode2 >= limit1) and @reduce(.And, antinode2 < limit2)) {
                    antinodes.put(antinode2, {}) catch {};
                    antinode2 += diff;
                }
            }
        }
    }

    return @intCast(antinodes.count());
}

test "Test input for 2024/8" {
    const allocator = std.testing.allocator;
    const input =
        \\............
        \\........0...
        \\.....0......
        \\.......0....
        \\....0.......
        \\......A.....
        \\............
        \\............
        \\........A...
        \\.........A..
        \\............
        \\............
        \\
    ;

    var problem = Self.init(allocator, input);
    defer problem.deinit();

    const processed_input = try problem.processInput();

    try std.testing.expectEqual(14, try problem.part1(processed_input));
    try std.testing.expectEqual(34, try problem.part2(processed_input));
}
