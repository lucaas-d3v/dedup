const std = @import("std");

pub inline fn cmdEqual(potential_cmd: []const u8, expected_cmd: []const u8) bool {
    return std.mem.eql(u8, potential_cmd, expected_cmd);
}

pub inline fn flagsEqual(potential_flag: []const u8, expected_flags: []const []const u8) bool {
    for (expected_flags) |e_flag| {
        if (std.mem.eql(u8, potential_flag, e_flag)) return true;
    }

    return false;
}
