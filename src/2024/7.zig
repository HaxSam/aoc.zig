//! https://adventofcode.com/2024/day/7

const std = @import("std");
const utils = @import("utils");

arena: std.heap.ArenaAllocator,
input: []const u8,

const Self = @This();

pub const DAY = 7;
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
    const Calibration = struct {
        result: u64,
        components: []u16,
    };

    lines: []Calibration,
};

// Advent of Parsing~
pub fn processInput(self: *Self) !InputType {
    var allocator = self.arena.allocator();

    const line_count = std.mem.count(u8, self.input, "\n");
    const lines = try allocator.alloc(InputType.Calibration, line_count);
    var split = std.mem.tokenizeSequence(u8, self.input, "\n");

    for (lines) |*line| {
        var numbers = std.mem.tokenizeSequence(u8, split.next().?, " ");
        var res = numbers.next().?;
        const result = try std.fmt.parseInt(u64, res[0 .. res.len - 1], 10);
        var components = std.ArrayList(u16).init(allocator);
        while (numbers.next()) |num| {
            try components.append(try std.fmt.parseInt(u16, num, 10));
        }
        line.* = .{
            .result = result,
            .components = try components.toOwnedSlice(),
        };
    }

    return InputType{
        .lines = lines,
    };
}

// Advent of Code (Time to solve fr)
pub fn part1(self: *Self, input: InputType) !?u128 {
    const allocator = self.arena.allocator();

    var count: u64 = 0;
    for (input.lines) |line| {
        var results = std.ArrayList(u64).init(allocator);
        defer results.deinit();

        try results.append(line.components[0]);

        const add_to_count: u64 = search: for (line.components[1..], 2..) |item, i| {
            var oldResults = try results.clone();
            defer oldResults.deinit();
            results.clearRetainingCapacity();
            for (oldResults.items) |result| {
                const add = result + item;
                const mul = result * item;

                if (i == line.components.len and (add == line.result or mul == line.result))
                    break :search line.result;

                try results.append(add);
                try results.append(mul);
            }
        } else 0;

        count += add_to_count;
    }

    return count;
}

pub fn part2(self: *Self, input: InputType) !?u128 {
    const allocator = self.arena.allocator();

    var count: u64 = 0;
    for (input.lines) |line| {
        var results = std.ArrayList(u64).init(allocator);
        defer results.deinit();

        try results.append(line.components[0]);

        const add_to_count: u64 = search: for (line.components[1..], 2..) |item, i| {
            var oldResults = try results.clone();
            defer oldResults.deinit();
            results.clearRetainingCapacity();
            for (oldResults.items) |result| {
                const add = result + item;
                const mul = result * item;
                const cob = result * std.math.pow(u64, 10, std.math.log10_int(item) + 1) + item;

                if (i == line.components.len and (add == line.result or mul == line.result or cob == line.result))
                    break :search line.result;

                try results.append(add);
                try results.append(mul);
                try results.append(cob);
            }
        } else 0;

        count += add_to_count;
    }

    return count;
}

test "Test input for 2024/7" {
    const allocator = std.testing.allocator;
    const input =
        \\190: 10 19
        \\3267: 81 40 27
        \\83: 17 5
        \\156: 15 6
        \\7290: 6 8 6 15
        \\161011: 16 10 13
        \\192: 17 8 14
        \\21037: 9 7 18 13
        \\292: 11 6 16 20
        \\
    ;

    var problem = Self.init(allocator, input);
    defer problem.deinit();

    const processed_input = try problem.processInput();

    try std.testing.expectEqual(3749, try problem.part1(processed_input));
    try std.testing.expectEqual(11387, try problem.part2(processed_input));
}
