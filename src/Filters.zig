const std = @import("std");
const util = @import("util");
const mem = std.mem;

const Allocator = std.mem.Allocator;
const StringArrayList = std.ArrayList([]const u8);

allocator: Allocator,
include: StringArrayList,
exclude: StringArrayList,

const Self = @This();

pub fn init(allocator: Allocator, include_paths: []const []const u8, exclude_paths: []const []const u8) !Self {
    return .{
        .allocator = allocator,
        .include = try readFilterFromPathAlloc(allocator, include_paths),
        .exclude = try readFilterFromPathAlloc(allocator, exclude_paths),
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

pub fn format(self: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    if (fmt.len != 0) {
        std.fmt.invalidFmtError(fmt, self);
    }
    _ = options;

    // Print including filters
    try writer.writeAll("Including filters");
    if (self.include.items.len == 0) {
        try writer.writeAll(" are empty!\n");
    } else {
        try writer.writeAll(":\n");

        for (self.include.items) |filter| {
            try writer.print("{s}\n", .{filter});
        }
    }

    // Print excluding filters
    try writer.writeAll("Excluding filters");
    if (self.exclude.items.len == 0) {
        try writer.writeAll(" are empty!\n");
    } else {
        try writer.writeAll(":\n");

        for (self.exclude.items) |filter| {
            try writer.print("{s}\n", .{filter});
        }
    }
}

fn readFilterFromPathAlloc(allocator: Allocator, file_paths: []const []const u8) !StringArrayList {
    var filters = StringArrayList.init(allocator);

    for (file_paths) |path| {
        const file_buf = try util.readFileToArrayAlloc(allocator, path);
        defer allocator.free(file_buf);

        var tokens = mem.tokenizeScalar(u8, file_buf, '\n');

        while (tokens.next()) |filter| {
            // Skip empty lines
            if (filter.len == 1) {
                continue;
            }
            // Skip comment lines
            if (filter.len >= 2 and mem.eql(u8, filter[0..2], "//")) {
                continue;
            }

            var filter_buf = try allocator.alloc(u8, filter.len);
            @memcpy(filter_buf, filter);

            try filters.append(filter_buf);
        }
    }

    return filters;
}
