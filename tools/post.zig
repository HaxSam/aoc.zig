const std = @import("std");
const Allocator = std.mem.Allocator;

const Context = @import("Context.zig");

pub fn postSolution(allocator: Allocator, context: *Context) ![]const u8 {
    const path = try context.parsePath(allocator);
    defer allocator.free(path);

    const solve_file = try context.root_dir.openFile(path, .{});
    defer solve_file.close();
    var solve_reader = solve_file.reader(&.{});

    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    var payload = std.Io.Writer.Allocating.init(allocator);
    defer payload.deinit();
    const payload_writer = &payload.writer;

    _ = try payload_writer.write("--ziggi\r\n");
    _ = try payload_writer.write("Content-Disposition: form-data; name=\"file\"; filename=\"-\"\r\n\r\n");
    _ = try payload_writer.sendFile(&solve_reader, .unlimited);
    _ = try payload_writer.write("--ziggi--\r\n");

    var resp = std.Io.Writer.Allocating.init(allocator);
    defer resp.deinit();

    const res = try client.fetch(.{
        .location = .{ .url = "https://zigbin.io/" },
        .method = .POST,
        .redirect_behavior = .unhandled,
        .headers = .{ .content_type = .{ .override = "multipart/form-data; boundary=ziggi" } },
        .payload = payload.written(),
        .response_writer = &resp.writer,
    });
    if (res.status != .ok) return error.HttpError;

    try resp.writer.flush();

    return try allocator.dupe(u8, resp.written());
}
