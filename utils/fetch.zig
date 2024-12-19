const std = @import("std");

pub fn ensureInput(allocator: std.mem.Allocator, year: u32, day: u32) ![]const u8 {
    const input_path = try std.fmt.allocPrint(allocator, "src/{d}/input/{d}.txt", .{ year, day });

    std.fs.cwd().access(input_path, .{}) catch |err| switch (err) {
        error.FileNotFound => try fetchInput(allocator, year, day, input_path),
        else => return err,
    };

    return input_path;
}

fn fetchInput(allocator: std.mem.Allocator, year: u32, day: u32, input_path: []const u8) !void {
    var token_buf: [1024]u8 = undefined;
    const token = try std.fs.cwd().readFile(".session", &token_buf);

    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    var url_buf: [128]u8 = undefined;
    const url = try std.fmt.bufPrint(&url_buf, "https://adventofcode.com/{d}/day/{d}/input", .{ year, day });

    var cookie_buf: [1024]u8 = undefined;
    const cookie = try std.fmt.bufPrint(&cookie_buf, "session={s}", .{token});

    var resp = std.ArrayList(u8).init(allocator);
    defer resp.deinit();

    const res = try client.fetch(.{
        .location = .{ .url = url },
        .method = .GET,
        .extra_headers = &[_]std.http.Header{.{ .name = "Cookie", .value = cookie }},
        .response_storage = .{ .dynamic = &resp },
    });
    if (res.status != .ok) return error.HttpError;

    try std.fs.cwd().makePath(input_path[0..std.mem.lastIndexOf(u8, input_path, "/").?]);
    try std.fs.cwd().writeFile(.{ .sub_path = input_path, .data = resp.items });
}
