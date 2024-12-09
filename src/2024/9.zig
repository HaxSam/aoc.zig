//! https://adventofcode.com/2024/day/9

const std = @import("std");
const utils = @import("utils");

arena: std.heap.ArenaAllocator,
input: []const u8,

const Self = @This();

pub const DAY = 9;
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
    file_length: []u8,
    free_space: []u8,
};

// Advent of Parsing~
pub fn processInput(self: *Self) !InputType {
    var allocator = self.arena.allocator();

    const file_length = try allocator.alloc(u8, (self.input.len + 1) / 2);
    errdefer allocator.free(file_length);
    const free_space = try allocator.alloc(u8, (self.input.len - 1) / 2);
    errdefer allocator.free(free_space);

    var f_idx: u16 = 0;
    var s_idx: u16 = 0;
    for (self.input, 0..) |c, i| {
        if (i % 2 == 0) {
            file_length[f_idx] = try std.fmt.parseInt(u8, &[_]u8{c}, 10);
            f_idx += 1;
        } else {
            free_space[s_idx] = try std.fmt.parseInt(u8, &[_]u8{c}, 10);
            s_idx += 1;
        }
    }

    return InputType{
        .file_length = file_length,
        .free_space = free_space,
    };
}

// Advent of Code (Time to solve fr)
pub fn part1(self: *Self, input: InputType) !?u128 {
    _ = self.arena.allocator();

    var index: u32 = 0;
    var f_idx: u16 = 0;
    var f_end: u16 = @as(u16, @intCast(input.file_length.len)) - 1;
    var f_end_count = input.file_length[f_end];
    var s_idx: u16 = 0;
    var result: u64 = 0;

    while (f_idx <= f_end) {
        const f = input.file_length[f_idx];
        for (index..index + f) |idx| result += f_idx * idx;
        index += f;
        f_idx += 1;

        if (f_idx == f_end) {
            break;
        }

        const s = input.free_space[s_idx];
        for (index..index + s) |idx| {
            if (f_end_count == 0) {
                f_end -= 1;
                f_end_count = input.file_length[f_end];
            }
            result += f_end * idx;
            f_end_count -= 1;
        }
        index += s;
        s_idx += 1;
    }
    for (index..index + f_end_count) |idx| result += f_idx * idx;

    return result;
}

pub fn part2(self: *Self, input: InputType) !?u128 {
    const allocator = self.arena.allocator();

    var index: u32 = 0;
    var f_idx: u16 = 0;
    var f_end: u16 = @as(u16, @intCast(input.file_length.len)) - 1;
    var f_end_count = input.file_length[f_end];
    var f_skip = std.AutoHashMap(u16, void).init(allocator);
    defer f_skip.deinit();
    var s_idx: u16 = 0;
    var result: u64 = 0;

    while (f_idx < f_end) {
        const f = input.file_length[f_idx];
        f_skip.get(f_idx) orelse {
            for (index..index + f) |idx| {
                result += f_idx * idx;
            }
        };
        index += f;

        f_idx += 1;

        var s = input.free_space[s_idx];
        while (s != 0) {
            while (f_skip.get(f_end)) |_| {
                f_end -= 1;
                f_end_count = input.file_length[f_end];
            }
            var f_end_tmp = f_end;
            var f_end_count_tmp = f_end_count;
            while (f_end_tmp >= f_idx) : (f_end_tmp -= 1) {
                f_skip.get(f_end_tmp) orelse {
                    f_end_count_tmp = input.file_length[f_end_tmp];
                };
                if (f_end_count_tmp <= s)
                    break;
            }
            if (f_end_tmp < f_idx) {
                index += s;
                break;
            }

            f_skip.put(f_end_tmp, {}) catch {};
            if (f_end_tmp == f_end) {
                f_end -= 1;
                f_end_count = input.file_length[f_end];
            }

            for (index..index + f_end_count_tmp) |idx| {
                result += f_end_tmp * idx;
            }

            index += f_end_count_tmp;
            s -= f_end_count_tmp;
        }
        s_idx += 1;
    }
    if (f_end == f_idx) {
        for (index..index + f_end_count) |idx| {
            result += f_idx * idx;
        }
    }

    return result;
}

test "Test input for 2024/9" {
    const allocator = std.testing.allocator;
    const input =
        \\706218196
    ;

    var problem = Self.init(allocator, input);
    defer problem.deinit();

    const processed_input = try problem.processInput();

    //try std.testing.expectEqual(60, try problem.part1(processed_input));
    try std.testing.expectEqual(568, try problem.part2(processed_input));
}
