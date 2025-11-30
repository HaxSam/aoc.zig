const std = @import("std");
const Allocator = std.mem.Allocator;

const Context = @import("Context.zig");

pub fn ensureSolve(allocator: Allocator, context: *Context) ![]const u8 {
    const year_day = try context.parseYearDay();
    const path = try context.parsePath(allocator);
    defer allocator.free(path);

    const root_dir = &context.root_dir;

    var replace_path: []u8 = try allocator.alloc(u8, path.len);
    defer allocator.free(replace_path);
    const replaced = std.mem.replace(u8, path, "%year%", &year_day.year_str, replace_path);

    var day_file: [year_day.day_str.len + 4]u8 = undefined;
    _ = try std.fmt.bufPrint(&day_file, "{s}.zig", .{year_day.day_str});

    const source_path = try std.fs.path.join(allocator, &.{ replace_path[0 .. replace_path.len - (replaced * 2)], &day_file });

    root_dir.access(source_path, .{}) catch |err| switch (err) {
        error.FileNotFound => {
            const template = @embedFile("template.zig");

            const day_s: usize = if (year_day.day_str[0] == '0') 1 else 0;

            const template_rep_tmp = try std.mem.replaceOwned(u8, allocator, template, "0xC0FE", &year_day.year_str);
            const template_rep = try std.mem.replaceOwned(u8, allocator, template_rep_tmp, "0xBEEF", year_day.day_str[day_s..]);
            defer allocator.free(template_rep);
            allocator.free(template_rep_tmp);

            try root_dir.makePath(std.fs.path.dirname(source_path).?);
            try root_dir.writeFile(.{ .sub_path = source_path, .data = template_rep });
        },
        else => return err,
    };

    return source_path;
}
