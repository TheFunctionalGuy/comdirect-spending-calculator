const std = @import("std");
const util = @import("util");
const mem = std.mem;

const Allocator = std.mem.Allocator;
const StringArrayList = std.ArrayList([]const u8);

allocator: Allocator,
include: StringArrayList,
exclude: StringArrayList,

const Self = @This();

pub fn init(allocator: Allocator, include_path: ?[]const u8, exclude_path: ?[]const u8) !Self {
    return .{
        .allocator = allocator,
        .include = try readFilterFromPathAlloc(allocator, include_path),
        .exclude = try readFilterFromPathAlloc(allocator, exclude_path),
    };
}

pub fn deinit(self: Self) void {
    // Free all elements and then list itself
    for (self.include.items) |filter| {
        self.allocator.free(filter);
    }
    self.include.deinit();

    for (self.exclude.items) |filter| {
        self.allocator.free(filter);
    }
    self.exclude.deinit();
}

fn readFilterFromPathAlloc(allocator: Allocator, file_path: ?[]const u8) !StringArrayList {
    var filters = StringArrayList.init(allocator);

    if (file_path) |path| {
        const file_buf = try util.readFileToArrayAlloc(allocator, path);
        defer allocator.free(file_buf);

        var tokens = mem.tokenizeScalar(u8, file_buf, '\n');

        while (tokens.next()) |filter| {
            var filter_buf = try allocator.alloc(u8, filter.len);
            @memcpy(filter_buf, filter);

            try filters.append(filter_buf);
        }
    }

    return filters;
}
