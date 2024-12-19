const std = @import("std");
const DateTime = @import("datetime.zig").DateTime;

pub fn existSolve(year: u16, day: u8) !bool {
    const root_dir = std.fs.cwd();
    var path_buf: [128]u8 = undefined;
    var day_buf: [8]u8 = undefined;
    const source_path = try std.fmt.bufPrint(&path_buf, "src/{d}/{s}.zig", .{ year, DateTime.twoDigitDay(&day_buf, day) });

    root_dir.access(source_path, .{}) catch |err| switch (err) {
        error.FileNotFound => return false,
        else => return err,
    };

    return true;
}

pub fn ensureSolve(allocator: std.mem.Allocator, year: u16, day: u8) ![]const u8 {
    const root_dir = std.fs.cwd();
    var day_buf: [8]u8 = undefined;
    const source_path = try std.fmt.allocPrint(allocator, "src/{d}/{s}.zig", .{ year, DateTime.twoDigitDay(&day_buf, day) });

    root_dir.access(source_path, .{}) catch |err| switch (err) {
        error.FileNotFound => {
            const template = @embedFile("template.zig");

            var year_buf: [16]u8 = undefined;

            var template_rep = try std.mem.replaceOwned(u8, allocator, template, "0xC0FE", try std.fmt.bufPrint(&year_buf, "{d}", .{year}));
            template_rep = try std.mem.replaceOwned(u8, allocator, template_rep, "0xBEEF", try std.fmt.bufPrint(&day_buf, "{d}", .{day}));

            var year_dir_buf: [16]u8 = undefined;
            try root_dir.makePath(try std.fmt.bufPrint(&year_dir_buf, "src/{d}", .{year}));
            const file = try root_dir.createFile(source_path, .{});
            try file.writeAll(template_rep);
        },
        else => return err,
    };

    return source_path;
}
