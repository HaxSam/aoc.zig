const std = @import("std");

pub fn postSolution(allocator: std.mem.Allocator, solve_path: []const u8) !void {
    const solve_file = try std.fs.cwd().openFile(solve_path, .{});
    defer solve_file.close();
    const solve = try solve_file.readToEndAlloc(allocator, try solve_file.getEndPos());
    defer allocator.free(solve);

    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    var server_header_buffer: [16 * 1024]u8 = undefined;
    var req = try client.open(.POST, try std.Uri.parse("https://zigbin.io/"), .{
        .server_header_buffer = &server_header_buffer,
        .redirect_behavior = .unhandled,
        .headers = .{ .content_type = .{ .override = "multipart/form-data; boundary=ziggi" } },
    });
    defer req.deinit();

    req.transfer_encoding = .{ .chunked = {} };

    try req.send();

    try req.writeAll("--ziggi\r\n");
    try req.writeAll("Content-Disposition: form-data; name=\"file\"; filename=\"-\"\r\n\r\n");
    try req.writeAll(solve);
    try req.writeAll("--ziggi--\r\n");

    try req.finish();
    try req.wait();

    var resp = std.ArrayList(u8).init(allocator);
    defer resp.deinit();

    try req.reader().readAllArrayList(&resp, 64);

    std.debug.print("Got posted to: {s}", .{resp.items});
}
