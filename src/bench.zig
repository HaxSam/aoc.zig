const std = @import("std");
const zbench = @import("zbench");
const Solve = @import("solve");

const allocator = std.heap.page_allocator;

var solve: Solve = undefined;
var processed_input: Solve.InputType = undefined;

fn setup() void {
    solve = Solve.init(allocator, null);
    processed_input = solve.processInput() catch @panic("cant process input");
}

fn cleanup() void {
    solve.deinit();
}

fn benchParsing(_: std.mem.Allocator) void {
    _ = std.mem.doNotOptimizeAway(solve.processInput() catch unreachable);
}

fn benchPart1(_: std.mem.Allocator) void {
    _ = std.mem.doNotOptimizeAway(solve.part1(processed_input) catch unreachable);
}

fn benchPart2(_: std.mem.Allocator) void {
    _ = std.mem.doNotOptimizeAway(solve.part2(processed_input) catch unreachable);
}

pub fn main() !void {
    try Solve.main();

    var bench = zbench.Benchmark.init(allocator, .{
        .hooks = .{
            .before_all = setup,
            .after_all = cleanup,
        },
        .track_allocations = false,
    });
    defer bench.deinit();

    try bench.add("Parse Input", benchParsing, .{});

    try bench.add("Solve Part1", benchPart1, .{});

    try bench.add("Solve Part2", benchPart2, .{});

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try bench.run(stdout);
    try stdout.flush();
}
