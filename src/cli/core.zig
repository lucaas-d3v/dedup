const std = @import("std");

const IoManager = @import("../global_utils/structs/IoManager.zig");
const DedupFlags = @import("../global_utils/structs/DedupFlags.zig");
const rapidHash = @import("../global_utils/rapidHash.zig");
const Manager = @import("../global_utils/structs/Manager.zig");

pub fn walk(allocator: std.mem.Allocator, io_manager: *IoManager, dedup_flags: DedupFlags) !void {
    // std.debug.print("{s}\n", .{dedup_flags.dir_path});

    var handle = std.Io.Dir.cwd();

    var dir = try handle.openDir(io_manager.init.io, dedup_flags.dir_path, .{ .iterate = true });
    defer dir.close(io_manager.init.io);

    var manager = Manager.init(allocator);
    defer manager.deinit();

    var iter = dir.iterate();
    try io_manager.fastPrint(.STDOUT, "\n----------------\n", .{});
    while (try iter.next(io_manager.init.io)) |entry| {
        if (entry.kind == .directory and dedup_flags.recursive) {
            try io_manager.fastPrint(.STDOUT, "{s}/\n", .{entry.name});
            if (!dedup_flags.recursive) continue;

            const sub_path = try std.fs.path.join(allocator, &.{ dedup_flags.dir_path, entry.name });
            defer allocator.free(sub_path);

            var sub_flags = dedup_flags;
            sub_flags.dir_path = sub_path;

            try walk(allocator, io_manager, sub_flags);
            continue;
        }

        {
            const file_content = dir.readFileAlloc(io_manager.init.io, entry.name, allocator, .unlimited) catch {
                continue;
            };
            defer allocator.free(file_content);

            const file_hash = rapidHash.hash(file_content);
            try manager.put(file_hash, try allocator.dupe(u8, entry.name));
            // manager.deinit() ja limpa tudo

            try io_manager.fastPrint(.STDOUT, "FILE: {s}\n  Hash: {d}\n", .{ entry.name, file_hash });
        }
    }

    std.debug.print("\n\n==============================\n\t\tRESUMOS\n\n", .{});

    var debug_hash_iterator = manager.iterate();
    while (debug_hash_iterator.next()) |entry| {
        const hash = entry.key_ptr.*; // Pega o valor do u64
        const file_name = entry.value_ptr.*; // Pega a string do nome do arquivo

        std.debug.print("Hash: {d} -> Arquivo: {s}\n", .{ hash, file_name });
    }
}
