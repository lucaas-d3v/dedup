const std = @import("std");

const IoManager = @import("../../global_utils/IoManager.zig");

pub inline fn version(io_manager: *IoManager) !void {
    try io_manager.fastPrint(.STDOUT, "dedup 0.0.1-d3v\n", .{});
}
