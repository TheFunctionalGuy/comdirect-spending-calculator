const std = @import("std");
const util = @import("util");

const mem = std.mem;

const Allocator = std.mem.Allocator;
const StringArrayList = std.ArrayList([]const u8);

allocator: Allocator,
include: []const []const u8,
exclude: []const []const u8,

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
    for (self.include) |filter| {
        self.allocator.free(filter);
    }
    self.allocator.free(self.include);

    for (self.exclude) |filter| {
        self.allocator.free(filter);
    }
    self.allocator.free(self.exclude);
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

fn readFilterFromPathAlloc(allocator: Allocator, file_paths: []const []const u8) ![]const []const u8 {
    var filters = StringArrayList.init(allocator);
    defer filters.deinit();

    var path_queue = std.SegmentedList([]const u8, 0){};
    defer path_queue.deinit(allocator);

    try path_queue.appendSlice(allocator, file_paths);
    var paths = path_queue.constIterator(0);

    // Keep track of files which have been parsed already
    var parsed_paths = std.StringHashMap(void).init(allocator);
    defer parsed_paths.deinit();

    while (paths.next()) |path| {
        // Skip files that have been parsed already
        if (parsed_paths.contains(path.*)) {
            continue;
        }

        const file_buf = try util.readFileToArrayAlloc(allocator, path.*);
        defer allocator.free(file_buf);

        const containing_directory = std.fs.path.dirname(path.*);

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
            // Handle filter imports
            if (filter.len > 1 and filter[0] == '@') {
                const uncombined_paths = [_][]const u8{ containing_directory.?, filter[1..] };
                try path_queue.append(allocator, try std.fs.path.join(allocator, &uncombined_paths));
                continue;
            }

            var filter_buf = try allocator.alloc(u8, filter.len);
            @memcpy(filter_buf, filter);

            try filters.append(filter_buf);
        }

        try parsed_paths.put(path.*, {});
    }

    // Free paths that were imported via @
    var added_paths = path_queue.constIterator(file_paths.len);
    while (added_paths.next()) |path| {
        allocator.free(path.*);
    }

    return filters.toOwnedSlice();
}
