const std = @import("std");

const IoManager = @import("../global_utils/structs/IoManager.zig");
const DedupFlags = @import("../global_utils/structs/DedupFlags.zig");
const rapidHash = @import("../global_utils/rapidHash.zig");
const Manager = @import("../global_utils/structs/Manager.zig");
const UiStatus = @import("Ux/UiStatus.zig").UiStatus;

pub fn walk(allocator: std.mem.Allocator, io_manager: *IoManager, dedup_flags: DedupFlags, manager: *Manager, ui_status: *UiStatus) !void {
    var handle = std.Io.Dir.cwd();

    var dir = try handle.openDir(io_manager.init.io, dedup_flags.dir_path, .{ .iterate = true });
    defer dir.close(io_manager.init.io);

    var iter = dir.iterate();
    while (try iter.next(io_manager.init.io)) |entry| {
        const entry_full_path = try std.fs.path.join(allocator, &.{ dedup_flags.dir_path, entry.name });
        errdefer allocator.free(entry_full_path);

        // feeds the status thread with the current file name
        ui_status.update(entry_full_path);

        if (entry.kind == .directory and dedup_flags.recursive) {
            const sub_path = try std.fs.path.join(allocator, &.{ dedup_flags.dir_path, entry.name });
            defer allocator.free(sub_path);

            var sub_flags = dedup_flags;
            sub_flags.dir_path = sub_path;

            // passes the UI state down through the recursion
            try walk(allocator, io_manager, sub_flags, manager, ui_status);
            continue;
        }

        if (entry.kind != .file) continue;

        {
            const file_content = dir.readFileAlloc(io_manager.init.io, entry.name, allocator, .unlimited) catch {
                continue;
            };
            defer allocator.free(file_content);

            const file_hash = rapidHash.hash(file_content);
            if (manager.unique_get(file_hash)) |_| {
                try manager.dup_put(file_hash, try allocator.dupe(u8, entry_full_path));
            } else {
                try manager.unique_put(file_hash, try allocator.dupe(u8, entry_full_path));
            }
        }
    }
}
