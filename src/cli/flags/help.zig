const std = @import("std");

const IoManager = @import("../../global_utils/IoManager.zig");

pub inline fn help(io_manager: *IoManager) !void {
    try io_manager.stdout.print("Use: dedup [flags] <path>\n", .{});

    try io_manager.stdout.flush();
}
