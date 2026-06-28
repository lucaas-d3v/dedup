const std = @import("std");

const IoManager = @import("../global_utils/IoManager.zig");

pub fn cli(io_manager: *IoManager, args: *std.process.Args.Iterator) !void {
    while (args.next()) |arg| {
        try io_manager.fastPrint(.STDOUT, "{s}\n", .{arg});
    }
}
