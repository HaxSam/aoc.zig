const std = @import("std");
const Solve = @import("solve");
const stdout = std.io.getStdOut;

const Outcome = enum { correct, incorrect, wait, wrong_level };

fn submitPart(part: u8, answer: u128, year: u16, day: u8) !Outcome {
    var client = std.http.Client{ .allocator = std.heap.page_allocator };
    defer client.deinit();

    var resp = std.ArrayList(u8).init(std.heap.page_allocator);
    defer resp.deinit();

    var url_buf: [64]u8 = undefined;
    var token_buf: [256]u8 = undefined;
    var answer_buf: [128]u8 = undefined;

    const res = try client.fetch(.{
        .location = .{
            .url = try std.fmt.bufPrint(
                &url_buf,
                "https://adventofcode.com/{d}/day/{d}/answer",
                .{ year, day },
            ),
        },
        .method = .POST,
        .extra_headers = &[_]std.http.Header{
            .{ .name = "Cookie", .value = try std.fmt.bufPrint(
                &token_buf,
                "session={s}",
                .{@embedFile("token")},
            ) },
            .{ .name = "Content-Type", .value = "application/x-www-form-urlencoded" },
        },
        .payload = try std.fmt.bufPrint(
            &answer_buf,
            "level={d}&answer={d}",
            .{ part, answer },
        ),
        .response_storage = .{ .dynamic = &resp },
    });

    if (res.status != .ok) return error.HttpError;

    const html = resp.items;
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
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var solve = Solve.init(allocator, null);
    defer solve.deinit();

    const processed_input = try solve.processInput();
    const part_result: [2]?u128 = .{ try solve.part1(processed_input), try solve.part2(processed_input) };

    for (part_result, 1..) |result, part| {
        if (result) |r| {
            switch (try submitPart(@intCast(part), r, Solve.YEAR, Solve.DAY)) {
                .correct => try stdout().writer().print("Part {d}: Correct!\n", .{part}),
                .incorrect => try stdout().writer().print("Part {d}: Incorrect answer\n", .{part}),
                .wait => try stdout().writer().print("Part {d}: Please wait before submitting again\n", .{part}),
                .wrong_level => try stdout().writer().print("Part {d}: Already completed\n", .{part}),
            }
        }
    }
}
