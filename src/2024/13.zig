//! https://adventofcode.com/2024/day/13

const std = @import("std");
const utils = @import("utils");

arena: std.heap.ArenaAllocator,
input: []const u8,

const Self = @This();

pub const DAY = 13;
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
    const Claws = struct {
        a: @Vector(2, i64),
        b: @Vector(2, i64),
        price: @Vector(2, i64),
    };

    claws: []Claws,
};

// Advent of Parsing~
pub fn processInput(self: *Self) !InputType {
    var allocator = self.arena.allocator();

    const line_count = std.mem.count(u8, self.input, "\n\n");
    var split = std.mem.tokenizeSequence(u8, self.input, "\n\n");
    const claws = try allocator.alloc(InputType.Claws, line_count);

    const parseInt = std.fmt.parseInt;
    for (claws) |*claw| {
        const claw_text = split.next().?;
        claw.a = .{ try parseInt(u8, claw_text[12..14], 10), try parseInt(u8, claw_text[18..20], 10) };
        claw.b = .{ try parseInt(u8, claw_text[33..35], 10), try parseInt(u8, claw_text[39..41], 10) };

        const last_comma = std.mem.lastIndexOf(u8, claw_text, ",").?;
        claw.price = .{ try parseInt(u16, claw_text[51..last_comma], 10), try parseInt(u16, claw_text[last_comma + 4 ..], 10) };
    }

    return InputType{
        .claws = claws,
    };
}

// Advent of Code (Time to solve fr)
pub fn part1(self: *Self, input: InputType) !?u128 {
    _ = self.arena.allocator();

    var result: i64 = 0;

    for (input.claws) |claw| {
        const diff = claw.b[0] * claw.a[1] - claw.a[0] * claw.b[1];

        const a_clicks = std.math.divExact(i64, claw.price[1] * claw.b[0] - claw.price[0] * claw.b[1], diff) catch continue;
        const b_clicks = std.math.divExact(i64, claw.price[0] - (a_clicks * claw.a[0]), claw.b[0]) catch continue;

        if (a_clicks >= 100 or b_clicks >= 100 or a_clicks < 0 or b_clicks < 0)
            continue;

        result += a_clicks * 3 + b_clicks;
    }

    return @intCast(result);
}

pub fn part2(self: *Self, input: InputType) !?u128 {
    _ = self.arena.allocator();

    var result: i64 = 0;

    for (input.claws) |claw| {
        const diff = claw.b[0] * claw.a[1] - claw.a[0] * claw.b[1];

        const price = claw.price + @as(@Vector(2, i64), @splat(10000000000000));

        const a_clicks = std.math.divExact(i64, price[1] * claw.b[0] - price[0] * claw.b[1], diff) catch continue;
        const b_clicks = std.math.divExact(i64, price[0] - (a_clicks * claw.a[0]), claw.b[0]) catch continue;

        if (a_clicks < 0 or b_clicks < 0)
            continue;

        result += a_clicks * 3 + b_clicks;
    }

    return @intCast(result);
}

test "Test input for 2024/13" {
    const allocator = std.testing.allocator;
    const input =
        \\Button A: X+94, Y+34
        \\Button B: X+22, Y+67
        \\Prize: X=8400, Y=5400
        \\
        \\Button A: X+26, Y+66
        \\Button B: X+67, Y+21
        \\Prize: X=12748, Y=12176
        \\
        \\Button A: X+17, Y+86
        \\Button B: X+84, Y+37
        \\Prize: X=7870, Y=6450
        \\
        \\Button A: X+69, Y+23
        \\Button B: X+27, Y+71
        \\Prize: X=18641, Y=10279
        \\
        \\
    ;

    var problem = Self.init(allocator, input);
    defer problem.deinit();

    const processed_input = try problem.processInput();

    try std.testing.expectEqual(480, try problem.part1(processed_input));
    try std.testing.expectEqual(null, try problem.part2(processed_input));
}
