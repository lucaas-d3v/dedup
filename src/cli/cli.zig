const std = @import("std");

const checker = @import("../global_utils/checker.zig");
const IoManager = @import("../global_utils/structs/IoManager.zig");
const DedupFlags = @import("../global_utils/structs/DedupFlags.zig");
const Manager = @import("../global_utils/structs/Manager.zig");
const UiStatus = @import("Ux/UiStatus.zig").UiStatus;

const help = @import("flags/help.zig").help;
const version = @import("flags/version.zig").version;
const walk = @import("core.zig").walk;

pub fn cli(allocator: std.mem.Allocator, io_manager: *IoManager, args: *std.process.Args.Iterator) !u8 {
    var has_input_file = false;

    var dedup_flags = DedupFlags{
        .recursive = true,
        .dir_path = ".",
        .debug = false,
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

        if (checker.flagsEqual(arg, &.{ "-d", "--debug" })) {
            dedup_flags.debug = true;
            continue;
        }

        if (!has_input_file) {
            has_input_file = true;
            dedup_flags.dir_path = try allocator.dupe(u8, arg);
        }
    }

    try run(allocator, io_manager, dedup_flags);

    if (has_input_file) allocator.free(dedup_flags.dir_path);
    return 0;
}

fn run(allocator: std.mem.Allocator, io_manager: *IoManager, dedup_flags: DedupFlags) !void {
    var manager = Manager.init(allocator);
    defer manager.deinit();

    var ui_status = UiStatus{
        .io = io_manager.init.io,
    };

    // launches the UI thread, passing the necessary references
    const ui_thread = try std.Thread.spawn(.{}, UiStatus.uiThreadLoop, .{ &ui_status, io_manager });

    walk(allocator, io_manager, dedup_flags, &manager, &ui_status) catch |err| {
        // Se der alguma falha no walk, desliga a outra thread antes de estourar o erro
        ui_status.mutex.lock(io_manager.init.io) catch {};
        ui_status.active = false;
        ui_status.mutex.unlock(io_manager.init.io);
        ui_thread.join();
        return err;
    };

    // turns off the active flag and waits for the UI thread to finish
    {
        ui_status.mutex.lock(io_manager.init.io) catch {};
        ui_status.active = false;
        ui_status.mutex.unlock(io_manager.init.io);
    }
    ui_thread.join();

    // clears the last progress line from the terminal so the final table starts off looking clean
    try io_manager.fastPrint(.STDOUT, "\r\x1B[K", .{});

    if (!dedup_flags.debug) {
        try io_manager.stdout.print("Sucesso!\n\n", .{});
        try io_manager.stdout.print("Arquivos processados: {d}.\n", .{manager.unique_map.count()});
        try io_manager.stdout.print("Arquivos duplicados: {d}.\n", .{manager.dup_map.count()});

        try io_manager.stdout.flush();
    } else {
        try io_manager.fastPrint(.STDOUT, "==========================\n\tDebug\n\n", .{});

        try io_manager.fastPrint(.STDOUT, "--------------------------------------------\n\tRESUMOS [ORIGINAL]\n\n", .{});
        var debug_hash_iterator = manager.unique_iterate();
        while (debug_hash_iterator.next()) |entry| {
            const hash = entry.key_ptr.*;
            const file_name = entry.value_ptr.*;
            try io_manager.fastPrint(.STDOUT, "\nHASH: {} -> FILE_PATH: {s}", .{ hash, file_name });
        }
        try io_manager.fastPrint(.STDOUT, "\n", .{});

        try io_manager.fastPrint(.STDOUT, "--------------------------------------------\n\tRESUMOS [DUPLICADOS]\n\n", .{});
        var dup_hash_iterator = manager.dup_iterate();

        while (dup_hash_iterator.next()) |entry| {
            const hash = entry.key_ptr.*;
            const file_list = entry.value_ptr.*;

            try io_manager.fastPrint(.STDOUT, "HASH: {} -> PATHS: ", .{hash});

            if (manager.unique_get(hash)) |original_path| {
                try io_manager.fastPrint(.STDOUT, "\"{s}\"", .{original_path});
            }

            for (file_list.items) |dup_path| {
                try io_manager.fastPrint(.STDOUT, ", \"{s}\"", .{dup_path});
            }

            try io_manager.fastPrint(.STDOUT, "\n", .{});
        }
    }
}
