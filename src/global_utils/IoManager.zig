const std = @import("std");

pub const IoManager = @This();

init: std.process.Init,
stderr: *std.Io.Writer,
stdout: *std.Io.Writer,

pub fn fastPrint(self: *IoManager, writer: enum { STDOUT, STDERR }, comptime fmt: []const u8, args: anytype) !void {
    switch (writer) {
        .STDOUT => {
            try self.stdout.print(fmt, args);
            try self.stdout.flush();
        },
        .STDERR => {
            try self.stderr.print(fmt, args);
            try self.stderr.flush();
        },
    }
}
