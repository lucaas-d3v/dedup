const std = @import("std");

const IoManager = @import("../global_utils/IoManager.zig");
const DedupFlags = @import("../global_utils/DedupFlags.zig");

pub fn walk(allocator: std.mem.Allocator, io_manager: *IoManager, dedup_flags: DedupFlags) !void {
    std.debug.print("{s}\n", .{dedup_flags.dir_path});

    var handle = std.Io.Dir.cwd();

    var dir = try handle.openDir(io_manager.init.io, dedup_flags.dir_path, .{ .iterate = true });
    defer dir.close(io_manager.init.io);

    var iter = dir.iterate();
    while (try iter.next(io_manager.init.io)) |entry| {
        try io_manager.fastPrint(.STDOUT, "{s}\n", .{entry.name});
        if (entry.kind == .directory and dedup_flags.recursive) {
            if (!dedup_flags.recursive) continue;

            const sub_path = try std.fs.path.join(allocator, &.{ dedup_flags.dir_path, entry.name });
            defer allocator.free(sub_path);

            var sub_flags = dedup_flags;
            sub_flags.dir_path = sub_path;

            try walk(allocator, io_manager, sub_flags);
        }
    }
}
