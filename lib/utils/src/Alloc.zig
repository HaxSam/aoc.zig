const std = @import("std");
const builtin = @import("builtin");

const Allocator = std.mem.Allocator;
const Self = @This();
const native_os = builtin.os.tag;

var debug_allocator: std.heap.DebugAllocator(.{}) = .init;

allocator: Allocator,
is_debug: bool,

pub fn init() Self {
    return gpa: {
        if (native_os == .wasi) break :gpa .{ .allocator = std.heap.wasm_allocator, .is_debug = false };
        break :gpa switch (builtin.mode) {
            .Debug, .ReleaseSafe => .{ .allocator = debug_allocator.allocator(), .is_debug = true },
            .ReleaseFast, .ReleaseSmall => .{ .allocator = std.heap.smp_allocator, .is_debug = false },
        };
    };
}

pub fn deinit(self: *const Self) void {
    if (self.is_debug) {
        _ = debug_allocator.deinit();
    }
}
