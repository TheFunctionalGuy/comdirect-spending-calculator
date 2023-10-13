const std = @import("std");
const builtin = @import("builtin");
const mem = std.mem;

const Allocator = mem.Allocator;

pub const debug_mode = switch (builtin.mode) {
    .Debug => true,
    else => false,
};

pub fn readFileToArrayAlloc(allocator: Allocator, path: []const u8) ![]u8 {
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    return try file.readToEndAlloc(allocator, std.math.maxInt(usize));
}

pub fn dropScalar(iterator: *mem.TokenIterator(u8, .scalar), count: usize) void {
    var dropped: usize = 0;

    while (dropped < count) : (dropped += 1) {
        // Find next token
        while (iterator.index < iterator.buffer.len and iterator.buffer[iterator.index] == iterator.delimiter) : (iterator.index += 1) {}

        // Stop on end
        if (iterator.index == iterator.buffer.len) {
            break;
        }

        // Find end
        while (iterator.index < iterator.buffer.len and !(iterator.buffer[iterator.index] == iterator.delimiter)) : (iterator.index += 1) {}
    }
}
