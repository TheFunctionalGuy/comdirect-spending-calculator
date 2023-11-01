const std = @import("std");
const build_options = @import("build_options");
const util = @import("util");
const clap = @import("clap");

const mem = std.mem;

const Filters = @import("Filters.zig");
const Statement = @import("Statement.zig");

const Allocator = mem.Allocator;

// Define clap parameters and parsers
const PARAMS = clap.parseParamsComptime(
    \\-h, --help               Display this help and exit
    \\-i, --include <FILE>...  Optional filters which specify which values to take into account
    \\-e, --exclude <FILE>...  Optional filters which specify which values NOT to take into account after applying the including filter
    \\-v, --verbose            Show additional verbose output
    \\--version                Display version and exit
    \\<FILE>                   First statement
    \\<FILE>                   Second statement
    \\
);
const PARSERS = .{
    .FILE = clap.parsers.string,
};

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const stderr = std.io.getStdErr().writer();

    // Warn about debug mode
    if (util.debug_mode) {
        try stderr.print("Warning: This is a DEBUG build!\n", .{});
    }

    // Parse parameters and handle errors
    var diag = clap.Diagnostic{};

    var res = clap.parse(clap.Help, &PARAMS, PARSERS, .{
        .diagnostic = &diag,
    }) catch |err| {
        diag.report(stderr, err) catch {};
        return;
    };
    defer res.deinit();

    // -h, --help
    if (res.args.help != 0) {
        return clap.help(stderr, clap.Help, &PARAMS, .{});
    }
    // --version
    if (res.args.version != 0) {
        try stdout.writeAll(build_options.version_string ++ "\n");
        return;
    }
    // Too few or too much positionals
    if (res.positionals.len < 1 or res.positionals.len > 2) {
        try stderr.writeAll("Please provide one or two statements!\n");
        return clap.help(stderr, clap.Help, &PARAMS, .{});
    }

    // Get allocator
    var allocator_state = if (build_options.use_gpa)
        std.heap.GeneralPurposeAllocator(.{}){}
    else
        std.heap.ArenaAllocator.init(std.heap.page_allocator);

    defer {
        if (build_options.use_gpa)
            std.debug.assert(allocator_state.deinit() == .ok)
        else
            allocator_state.deinit();
    }

    const allocator = allocator_state.allocator();

    // Read filters
    const filters = try Filters.init(allocator, res.args.include, res.args.exclude);
    defer filters.deinit();
    std.log.debug("\n{}\n", .{filters});

    // Read statements
    const first_statement_path = res.positionals[0];

    var first_statement = try Statement.init(allocator, first_statement_path);
    defer first_statement.deinit();

    if (res.args.verbose != 0) {
        try stdout.print("{s}:\n", .{first_statement_path});
    }
    const first_sum = try first_statement.getFilteredSum(filters, res.args.verbose != 0);

    const second_sum = blk: {
        if (res.positionals.len > 1) {
            const second_statement_path = res.positionals[1];

            var second_statement = try Statement.init(allocator, second_statement_path);
            defer second_statement.deinit();

            if (res.args.verbose != 0) {
                try stdout.print("{s}:\n", .{second_statement_path});
            }
            const second_sum = try second_statement.getFilteredSum(filters, res.args.verbose != 0);

            break :blk second_sum;
        } else {
            break :blk 0;
        }
    };

    // Convert cents to euros and extract non-negative cents
    const diff_2: f64 = @as(f64, @floatFromInt(first_sum - second_sum)) / 100.0;

    if (res.positionals.len > 1) {
        try stdout.print("Difference: {d:.02} Euro\n", .{diff_2});
    } else {
        if (diff_2 >= 0.0) {
            try stdout.print("Earnings: {d:.02} Euro\n", .{diff_2});
        } else {
            try stdout.print("Expenses: {d:.02} Euro\n", .{diff_2});
        }
    }
}
