const std = @import("std");
const zbench = @import("zbench");
const Problem = @import("problem");

const allocator = std.heap.page_allocator;
const input = @embedFile(std.fmt.comptimePrint("{d}/input/{d}.txt", .{ Problem.YEAR, Problem.DAY }));

var problem: Problem = undefined;
var processed_input: Problem.InputType = undefined;

fn benchParsing(_: std.mem.Allocator) void {
    _ = problem.processInput() catch unreachable;
}

fn benchPart1(_: std.mem.Allocator) void {
    _ = problem.part1(processed_input) catch unreachable;
}

fn benchPart2(_: std.mem.Allocator) void {
    _ = problem.part2(processed_input) catch unreachable;
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    problem = Problem.init(allocator, input);
    defer problem.deinit();

    processed_input = try problem.processInput();
    const part1_result = try problem.part1(processed_input);
    const part2_result = try problem.part2(processed_input);

    try stdout.print("{d}/{d}:\n- Part 1: {?}\n- Part 2: {?} \n", .{
        Problem.YEAR,
        Problem.DAY,
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
