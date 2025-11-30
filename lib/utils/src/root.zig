const std = @import("std");
pub const Alloc = @import("Alloc.zig");

pub fn parseInt(comptime T: type, buf: []const u8) !T {
    return std.fmt.parseInt(T, buf, 10);
}

pub fn int2str(allocator: std.mem.Allocator, number: type) ![]u8 {
    return std.fmt.allocPrint(allocator, "{d}", .{number});
}
