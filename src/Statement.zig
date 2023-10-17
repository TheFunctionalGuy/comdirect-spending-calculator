const std = @import("std");
const util = @import("util");
const mem = std.mem;

const Filters = @import("Filters.zig");
const Allocator = mem.Allocator;
const EntryArrayList = std.ArrayList(Entry);

const Entry = struct {
    value: i64,
    description: []const u8,
};

allocator: Allocator,
entries: EntryArrayList,

const Self = @This();

pub fn init(allocator: Allocator, path: []const u8) !Self {
    var entries = EntryArrayList.init(allocator);

    // Fill entries
    const file_buf = try util.readFileToArrayAlloc(allocator, path);
    defer allocator.free(file_buf);

    var lines = mem.tokenizeScalar(u8, file_buf, '\n');

    // Remove header
    util.dropScalar(&lines, 5);

    while (lines.next()) |line| {
        // Stop on empty line
        if (line.len == 1) {
            break;
        }

        var tokens = mem.tokenizeScalar(u8, line, ';');
        util.dropScalar(&tokens, 3);

        const description_token = tokens.next().?;
        const description = try allocator.alloc(u8, description_token.len - 2);
        @memcpy(description, description_token[1 .. description_token.len - 1]);

        // Extract value
        const value_token = tokens.next().?;
        var value_string = try allocator.alloc(u8, value_token.len - 3);
        defer allocator.free(value_string);

        // Copy the token into the value string by overwriting the comma and stripping unneeded chars
        mem.copyBackwards(u8, value_string, value_token[1 .. value_token.len - 4]);
        value_string[value_string.len - 2] = value_token[value_token.len - 3];
        value_string[value_string.len - 1] = value_token[value_token.len - 2];

        const value = try std.fmt.parseInt(i64, value_string, 10);

        try entries.append(.{
            .value = value,
            .description = description,
        });
    }

    return .{
        .allocator = allocator,
        .entries = entries,
    };
}

pub fn deinit(self: Self) void {
    for (self.entries.items) |item| {
        self.allocator.free(item.description);
    }
    self.entries.deinit();
}

pub fn getFilteredSum(self: Self, filters: Filters) i64 {
    var sum: i64 = 0.0;

    for (self.entries.items) |entry| {
        var selected = false;

        // Look for includes
        for (filters.include) |include_filter| {
            if (mem.startsWith(u8, entry.description, include_filter)) {
                selected = true;
                break;
            }
        }

        // Look for excludes
        for (filters.exclude) |exclude_filter| {
            if (mem.startsWith(u8, entry.description, exclude_filter)) {
                selected = false;
                break;
            }
        }

        if (selected) {
            sum += entry.value;
        }
    }

    return sum;
}
