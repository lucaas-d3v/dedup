const std = @import("std");

const checker = @import("../global_utils/checker.zig");
const IoManager = @import("../global_utils/structs/IoManager.zig");
const DedupFlags = @import("../global_utils/structs/DedupFlags.zig");

const help = @import("flags/help.zig").help;
const version = @import("flags/version.zig").version;
const walk = @import("core.zig").walk;

pub fn cli(allocator: std.mem.Allocator, io_manager: *IoManager, args: *std.process.Args.Iterator) !u8 {
    var has_input_file = false;

    var dedup_flags = DedupFlags{
        .recursive = true,
        .dir_path = ".",
    };

    while (args.next()) |arg| {
        if (checker.flagsEqual(arg, &.{ "-h", "--help" })) {
            try help(io_manager);
            return 0;
        }

        if (checker.flagsEqual(arg, &.{ "-v", "--version" })) {
            try version(io_manager);
            return 0;
        }

        // is recurive for default
        if (checker.flagsEqual(arg, &.{ "-nr", "--no-recursive" })) {
            dedup_flags.recursive = false;
            continue;
        }

        if (!has_input_file) {
            has_input_file = true;
            dedup_flags.dir_path = try allocator.dupe(u8, arg);
        }
    }

    try walk(allocator, io_manager, dedup_flags);
    try io_manager.fastPrint(.STDOUT, "Sucesso\n", .{});

    if (has_input_file) allocator.free(dedup_flags.dir_path);
    return 0;
}
