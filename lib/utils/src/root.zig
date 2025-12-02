const std = @import("std");
pub const Alloc = @import("Alloc.zig");

pub fn runMain(Solver: type) !void {
    const alloc: Alloc = .init();
    defer alloc.deinit();

    const allocator = alloc.allocator;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var solve = Solver.init(allocator, null);
    defer solve.deinit();

    const processed_input = try solve.processInput();

    if (args.len > 1) {
        if (args[1][0] == '1') {
            try stdout.print("{?}", .{try solve.part1(processed_input)});
        }
        if (args[1][0] == '2') {
            try stdout.print("{?}", .{try solve.part2(processed_input)});
        }
    } else {
        try stdout.print("2025/02:\n- Part 1: {?}\n- Part 2: {?}\n", .{
            try solve.part1(processed_input),
            try solve.part2(processed_input),
        });
    }
    try stdout.flush();
}

pub fn parseInt(comptime T: type, buf: []const u8) !T {
    return std.fmt.parseInt(T, buf, 10);
}

pub fn int2str(allocator: std.mem.Allocator, number: anytype) ![]u8 {
    return std.fmt.allocPrint(allocator, "{d}", .{number});
}
