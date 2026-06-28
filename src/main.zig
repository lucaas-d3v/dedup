const std = @import("std");

const IoManager = @import("global_utils/IoManager.zig");

const dedup = @import("cli/cli.zig");

pub fn main(init: std.process.Init) !void {
    // const allocator = init.gpa;

    var stdout_buffer: [2048]u8 = undefined;
    var stderr_buffer: [2048]u8 = undefined;

    var stdout_writer = std.Io.File.stdout().writer(init.io, &stdout_buffer);
    var stderr_writer = std.Io.File.stderr().writer(init.io, &stderr_buffer);

    var io_manager = IoManager{
        .init = init,
        .stdout = &stdout_writer.interface,
        .stderr = &stderr_writer.interface,
    };

    var args = init.minimal.args.iterate();
    _ = args.next(); // skip bin path

    dedup.cli(&io_manager, &args) catch |err| {
        try io_manager.fastPrint(.STDERR, "ERRO: Ocorreu um erro enquanto dedup estava rodando: '{any}'\n", .{err});
    };
}
