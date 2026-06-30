const std = @import("std");
const IdentityContext = @import("../structs/IdentityContext.zig");

const UniqueMapType = std.HashMap(u64, []const u8, IdentityContext, std.hash_map.default_max_load_percentage);
const DupMapType = std.HashMap(u64, std.ArrayList([]const u8), IdentityContext, std.hash_map.default_max_load_percentage);

const Manager = @This();

unique_map: UniqueMapType,
dup_map: DupMapType,
allocator: std.mem.Allocator,

// basics
pub fn init(allocator: std.mem.Allocator) Manager {
    return .{
        .unique_map = UniqueMapType.init(allocator),
        .dup_map = DupMapType.init(allocator),
        .allocator = allocator,
    };
}

pub fn deinit(self: *Manager) void {
    var unique_hash_iterator = self.unique_iterate();
    while (unique_hash_iterator.next()) |entry| {
        self.allocator.free(entry.value_ptr.*);
    }

    var dup_hash_iterator = self.dup_iterate();
    while (dup_hash_iterator.next()) |entry| {
        for (entry.value_ptr.items) |str| {
            self.allocator.free(str);
        }

        entry.value_ptr.deinit(self.allocator);
    }

    self.unique_map.deinit();
    self.dup_map.deinit();
}

// operations

// unique_map
pub fn unique_put(self: *Manager, key: u64, value: []const u8) std.mem.Allocator.Error!void {
    try self.unique_map.put(key, value);
}

pub fn unique_get(self: *Manager, key: u64) ?[]const u8 {
    return self.unique_map.get(key);
}

pub fn unique_iterate(self: *Manager) UniqueMapType.Iterator {
    return self.unique_map.iterator();
}

// dup_map
pub fn dup_put(self: *Manager, key: u64, value: []const u8) std.mem.Allocator.Error!void {
    if (self.dup_map.getPtr(key)) |arr| {
        try arr.append(self.allocator, value);
        return;
    }

    var new_list = std.ArrayList([]const u8).empty;
    try new_list.append(self.allocator, value);
    try self.dup_map.put(key, new_list);
}

pub fn dup_get(self: *Manager, key: u64) ?std.ArrayList([]const u8) {
    return self.dup_map.get(key);
}

pub fn dup_iterate(self: *Manager) DupMapType.Iterator {
    return self.dup_map.iterator();
}
