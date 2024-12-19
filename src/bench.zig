const std = @import("std");
const zbench = @import("zbench");
const Solve = @import("solve");

const allocator = std.heap.page_allocator;

var solve: Solve = undefined;
var processed_input: Solve.InputType = undefined;

fn benchParsing(_: std.mem.Allocator) void {
    _ = solve.processInput() catch unreachable;
}

fn benchPart1(_: std.mem.Allocator) void {
    _ = solve.part1(processed_input) catch unreachable;
}

fn benchPart2(_: std.mem.Allocator) void {
    _ = solve.part2(processed_input) catch unreachable;
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    solve = Solve.init(allocator, null);
    defer solve.deinit();
    processed_input = try solve.processInput();
    const part1_result = try solve.part1(processed_input);
    const part2_result = try solve.part2(processed_input);

    try stdout.print("{d}/{d}:\n- Part 1: {?}\n- Part 2: {?} \n", .{
        Solve.YEAR,
        Solve.DAY,
        part1_result,
        part2_result,
    });

    var bench = zbench.Benchmark.init(allocator, .{});
    defer bench.deinit();

    try bench.add("Parse Input", benchParsing, .{
        .track_allocations = false,
    });

    try bench.add("Solve Part1", benchPart1, .{
        .track_allocations = false,
    });

    try bench.add("Solve Part2", benchPart2, .{
        .track_allocations = false,
    });

    try stdout.writeAll("\n");
    try bench.run(stdout);
}
