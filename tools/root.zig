const std = @import("std");

pub const DateTime = @import("Datetime.zig");
pub const generate = @import("generate.zig");
pub const fetch = @import("fetch.zig");
pub const Context = @import("Context.zig");
pub const post = @import("post.zig");
pub const submit = @import("submit.zig");

const ContextAlloc = @import("ContextAlloc.zig");

pub fn main() !void {
    const alloc: ContextAlloc = .init();
    defer alloc.deinit();

    var allocator = alloc.allocator;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var stderr_buffer: [1024]u8 = undefined;
    var stderr_writer = std.fs.File.stderr().writer(&stderr_buffer);
    const stderr = &stderr_writer.interface;

    const args = std.process.argsAlloc(allocator) catch @panic("OOM");
    defer std.process.argsFree(allocator, args);

    var context: Context = .init(args, stdout, stderr);

    const exe = context.parseExe() catch {
        context.small_panic("Coudnt parse exe name\n", .{});
    };

    if (std.mem.eql(u8, exe, "fetch")) {
        const path = fetch.ensureInput(allocator, &context) catch {
            context.small_panic("Coudnt fetch input\n", .{});
        };

        stdout.print("{s}\n", .{path}) catch unreachable;
        stdout.flush() catch unreachable;
        allocator.free(path);
    }

    if (std.mem.eql(u8, exe, "generate")) {
        const path = generate.ensureSolve(allocator, &context) catch {
            context.small_panic("Coudnt generate solve file\n", .{});
        };

        stdout.print("{s}\n", .{path}) catch unreachable;
        stdout.flush() catch unreachable;
        allocator.free(path);
    }

    if (std.mem.eql(u8, exe, "post")) {
        const path = post.postSolution(allocator, &context) catch {
            context.small_panic("Coudnt upload file", .{});
        };

        stdout.print("{s}", .{path}) catch unreachable;
        stdout.flush() catch unreachable;
        allocator.free(path);
    }

    if (std.mem.eql(u8, exe, "submit")) {
        submit.call(allocator, &context) catch {
            context.small_panic("Coudnt submit solve", .{});
        };
    }
}
