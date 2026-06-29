const std = @import("std");
const IdentityContext = @import("../structs/IdentityContext.zig");
const MapType = std.HashMap(u64, []const u8, IdentityContext, std.hash_map.default_max_load_percentage);

const Manager = @This();

vtable: std.HashMap(u64, []const u8, IdentityContext, std.hash_map.default_max_load_percentage),
allocator: std.mem.Allocator,

pub fn init(allocator: std.mem.Allocator) Manager {
    return .{
        .vtable = std.HashMap(u64, []const u8, IdentityContext, std.hash_map.default_max_load_percentage).init(allocator),
        .allocator = allocator,
    };
}

pub fn deinit(self: *Manager) void {
    var debug_hash_iterator = self.iterate();
    while (debug_hash_iterator.next()) |entry| {
        self.allocator.free(entry.value_ptr.*);
    }

    self.vtable.deinit();
}

pub fn put(self: *Manager, key: u64, value: []const u8) std.mem.Allocator.Error!void {
    try self.vtable.put(key, value);
}

pub fn get(self: *Manager, key: u64) ?[]const u8 {
    return self.vtable.get(key);
}

pub fn iterate(self: *Manager) MapType.Iterator {
    return self.vtable.iterator();
}
