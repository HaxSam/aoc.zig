const std = @import("std");
const Context = @import("Context.zig");
const ContextAlloc = @import("ContextAlloc.zig");
const Solve = @import("solve");

const Allocator = std.mem.Allocator;

const Outcome = enum { correct, incorrect, wait, wrong_level };

pub fn call(allocator: Allocator, context: *Context) !void {
    const year_day = try context.parseYearDay();
    const part = try context.parsePart();
    const answer = try context.parseAnswer();
    const token = try context.parseToken(allocator);
    defer allocator.free(token);

    switch (try submitPart(allocator, part, answer, year_day.year, year_day.day, token)) {
        .correct => context.out.print("Part {d}: Correct!\n", .{part}) catch unreachable,
        .incorrect => context.out.print("Part {d}: Incorrect answer\n", .{part}) catch unreachable,
        .wait => context.out.print("Part {d}: Please wait before submitting again\n", .{part}) catch unreachable,
        .wrong_level => context.out.print("Part {d}: Already completed\n", .{part}) catch unreachable,
    }

    context.out.flush() catch unreachable;
}

fn submitPart(allocator: Allocator, part: u8, answer: u128, year: u16, day: u8, token: []const u8) !Outcome {
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    var resp: std.Io.Writer.Allocating = .init(allocator);
    defer resp.deinit();

    var url_buf: [64]u8 = undefined;
    const url = try std.fmt.bufPrint(&url_buf, "https://adventofcode.com/{d}/day/{d}/answer", .{ year, day });
    var cookie_buf: [256]u8 = undefined;
    const cookie = try std.fmt.bufPrint(&cookie_buf, "session={s}", .{token});
    var payload_buf: [128]u8 = undefined;
    const payload = try std.fmt.bufPrint(&payload_buf, "level={d}&answer={d}", .{ part, answer });

    const res = try client.fetch(.{
        .location = .{ .url = url },
        .method = .POST,
        .headers = .{ .user_agent = .{ .override = "aoc.zig/0.1.0 developer: haxsam@pm.me" } },
        .extra_headers = &[_]std.http.Header{
            .{ .name = "Cookie", .value = cookie },
            .{ .name = "Content-Type", .value = "application/x-www-form-urlencoded" },
        },
        .payload = payload,
        .response_writer = &resp.writer,
    });
    if (res.status != .ok) return error.HttpError;

    try resp.writer.flush();

    const html = resp.written();
    if (std.mem.indexOf(u8, html, "That's the right answer") != null) {
        return .correct;
    } else if (std.mem.indexOf(u8, html, "That's not the right answer") != null) {
        return .incorrect;
    } else if (std.mem.indexOf(u8, html, "You gave an answer too recently") != null) {
        return .wait;
    } else if (std.mem.indexOf(u8, html, "You don't seem to be solving the right level") != null) {
        return .wrong_level;
    }
    return error.UnknownResponse;
}

pub fn main() !void {
    const alloc: ContextAlloc = .init();
    defer alloc.deinit();

    const allocator = alloc.allocator;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const args = std.process.argsAlloc(allocator) catch @panic("OOM");
    defer std.process.argsFree(allocator, args);

    var context: Context = .init(args, stdout, stdout);
    const token = try context.parseToken(allocator);

    var solve = Solve.init(allocator, null);
    defer solve.deinit();

    const processed_input = try solve.processInput();
    const part_result: [2]?u128 = .{ try solve.part1(processed_input), try solve.part2(processed_input) };

    for (part_result, 1..) |result, part| {
        if (result) |r| {
            switch (try submitPart(allocator, @intCast(part), r, Solve.YEAR, Solve.DAY, token)) {
                .correct => try stdout.print("Part {d}: Correct!\n", .{part}),
                .incorrect => try stdout.print("Part {d}: Incorrect answer\n", .{part}),
                .wait => try stdout.print("Part {d}: Please wait before submitting again\n", .{part}),
                .wrong_level => try stdout.print("Part {d}: Already completed\n", .{part}),
            }
        }
    }

    try stdout.flush();
}
