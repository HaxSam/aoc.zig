//! https://adventofcode.com/2024/day/10

const std = @import("std");
const utils = @import("utils");

arena: std.heap.ArenaAllocator,
input: []const u8,

const Self = @This();

pub const DAY = 10;
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

const Y = @Vector(2, u8){ 1, 0 };
const X = @Vector(2, u8){ 0, 1 };

pub const InputType = struct {
    lines: [][]const u8,
    limit: u8,
    start_pos: []@Vector(2, u8),
};

// Advent of Parsing~
pub fn processInput(self: *Self) !InputType {
    var allocator = self.arena.allocator();

    const line_count = std.mem.count(u8, self.input, "\n");
    var split = std.mem.tokenizeSequence(u8, self.input, "\n");
    const lines = try allocator.alloc([]const u8, line_count);

    var coll = std.ArrayList(u8).init(allocator);
    defer coll.deinit();

    for (lines) |*l| {
        for (split.next().?) |c| {
            try coll.append(try std.fmt.parseInt(u8, &.{c}, 10));
        }
        l.* = try coll.toOwnedSlice();
        coll.clearRetainingCapacity();
    }

    var start_pos = std.ArrayList(@Vector(2, u8)).init(allocator);

    for (lines, 0..) |row, y| {
        for (row, 0..) |col, x| {
            if (col == 0) {
                try start_pos.append(.{ @intCast(y), @intCast(x) });
            }
        }
    }

    return InputType{
        .lines = lines,
        .limit = @intCast(line_count),
        .start_pos = try start_pos.toOwnedSlice(),
    };
}

// Advent of Code (Time to solve fr)
pub fn part1(self: *Self, input: InputType) !?u128 {
    const allocator = self.arena.allocator();

    var result: u16 = 0;

    var search = std.ArrayList(@Vector(2, u8)).init(allocator);
    defer search.deinit();

    for (input.start_pos) |start| {
        try search.append(start);
        defer search.clearRetainingCapacity();

        for (1..9) |step| {
            var old_search = try search.clone();
            defer old_search.deinit();
            search.clearRetainingCapacity();
            for (old_search.items) |lookup| {
                if (lookup[0] > 0 and input.lines[lookup[0] - 1][lookup[1]] == step)
                    try search.append(lookup - Y);
                if (lookup[0] < input.limit - 1 and input.lines[lookup[0] + 1][lookup[1]] == step)
                    try search.append(lookup + Y);
                if (lookup[1] > 0 and input.lines[lookup[0]][lookup[1] - 1] == step)
                    try search.append(lookup - X);
                if (lookup[1] < input.limit - 1 and input.lines[lookup[0]][lookup[1] + 1] == step)
                    try search.append(lookup + X);
            }
        }
        var unique = std.AutoHashMap(@Vector(2, u8), void).init(allocator);
        for (search.items) |lookup| {
            if (lookup[0] > 0 and input.lines[lookup[0] - 1][lookup[1]] == 9)
                unique.put(lookup - Y, {}) catch {};
            if (lookup[0] < input.limit - 1 and input.lines[lookup[0] + 1][lookup[1]] == 9)
                unique.put(lookup + Y, {}) catch {};
            if (lookup[1] > 0 and input.lines[lookup[0]][lookup[1] - 1] == 9)
                unique.put(lookup - X, {}) catch {};
            if (lookup[1] < input.limit - 1 and input.lines[lookup[0]][lookup[1] + 1] == 9)
                unique.put(lookup + X, {}) catch {};
        }

        result += @intCast(unique.count());
    }

    return @intCast(result);
}

pub fn part2(self: *Self, input: InputType) !?u128 {
    const allocator = self.arena.allocator();

    var result = std.ArrayList(@Vector(2, u8)).init(allocator);
    defer result.deinit();

    try result.appendSlice(input.start_pos);

    for (1..10) |step| {
        var old_result = try result.clone();
        defer old_result.deinit();
        result.clearRetainingCapacity();
        for (old_result.items) |lookup| {
            if (lookup[0] > 0 and input.lines[lookup[0] - 1][lookup[1]] == step)
                try result.append(lookup - Y);
            if (lookup[0] < input.limit - 1 and input.lines[lookup[0] + 1][lookup[1]] == step)
                try result.append(lookup + Y);
            if (lookup[1] > 0 and input.lines[lookup[0]][lookup[1] - 1] == step)
                try result.append(lookup - X);
            if (lookup[1] < input.limit - 1 and input.lines[lookup[0]][lookup[1] + 1] == step)
                try result.append(lookup + X);
        }
    }

    return @intCast(result.items.len);
}

test "Test input for 2024/10" {
    const allocator = std.testing.allocator;
    const input =
        \\89010123
        \\78121874
        \\87430965
        \\96549874
        \\45678903
        \\32019012
        \\01329801
        \\10456732
        \\
    ;

    var problem = Self.init(allocator, input);
    defer problem.deinit();

    const processed_input = try problem.processInput();

    try std.testing.expectEqual(36, try problem.part1(processed_input));
    try std.testing.expectEqual(81, try problem.part2(processed_input));
}
