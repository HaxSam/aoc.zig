const std = @import("std");
const Allocator = std.mem.Allocator;

const Context = @import("Context.zig");

pub fn ensureInput(allocator: Allocator, context: *Context) ![]const u8 {
    const year_day = try context.parseYearDay();
    const path = try context.parsePath(allocator);
    defer allocator.free(path);

    var replace_path: []u8 = try allocator.alloc(u8, path.len);
    defer allocator.free(replace_path);
    const replaced = std.mem.replace(u8, path, "%year%", &year_day.year_str, replace_path);

    var day_file: [year_day.day_str.len + 4]u8 = undefined;
    _ = try std.fmt.bufPrint(&day_file, "{s}.txt", .{year_day.day_str});

    const input_path = try std.fs.path.join(allocator, &.{ replace_path[0 .. replace_path.len - (replaced * 2)], &day_file });

    std.fs.cwd().access(input_path, .{}) catch |err| switch (err) {
        error.FileNotFound => {
            const token = try context.parseToken(allocator);
            defer allocator.free(token);
            try fetchInput(allocator, year_day.year, year_day.day, input_path, token);
        },
        else => return err,
    };

    return input_path;
}

fn fetchInput(allocator: Allocator, year: u16, day: u8, input_path: []const u8, token: []const u8) !void {
    const root_dir = std.fs.cwd();

    try root_dir.makePath(std.fs.path.dirname(input_path).?);
    const input_file = try root_dir.createFile(input_path, .{});
    defer input_file.close();

    var input_writer = input_file.writer(&.{});

    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    var url_buf: [128]u8 = undefined;
    const url = try std.fmt.bufPrint(&url_buf, "https://adventofcode.com/{d}/day/{d}/input", .{ year, day });

    var cookie_buf: [1024]u8 = undefined;
    const cookie = try std.fmt.bufPrint(&cookie_buf, "session={s}", .{token});

    const res = try client.fetch(.{
        .location = .{ .url = url },
        .method = .GET,
        .headers = .{ .user_agent = .{ .override = "aoc.zig/0.1.0 developer: haxsam@pm.me" } },
        .extra_headers = &[_]std.http.Header{.{ .name = "Cookie", .value = cookie }},
        .response_writer = &input_writer.interface,
    });
    if (res.status != .ok) return error.HttpError;

    try input_writer.interface.flush();
}
