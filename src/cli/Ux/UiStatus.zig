const std = @import("std");
const IoManager = @import("../../global_utils/structs/IoManager.zig");

pub const UiStatus = struct {
    mutex: std.Io.Mutex = .{ .state = .{ .raw = .unlocked } },
    buf: [256]u8 = [_]u8{0} ** 256,
    len: usize = 0,
    active: bool = true,
    io: std.Io,

    pub fn update(self: *UiStatus, name: []const u8) void {
        self.mutex.lock(self.io) catch {};
        defer self.mutex.unlock(self.io);

        const safe_len = @min(name.len, self.buf.len);
        @memcpy(self.buf[0..safe_len], name[0..safe_len]);
        self.len = safe_len;
    }

    pub fn uiThreadLoop(self: *UiStatus, io_writer: *IoManager) void {
        var local_print_buf: [256]u8 = undefined;

        // 1. Imprime o prefixo UMA ÚNICA VEZ fora do loop
        io_writer.fastPrint(.STDOUT, "[➔] Scanning: ", .{}) catch {};

        while (true) {
            var current_len: usize = 0;
            var should_break = false;

            {
                self.mutex.lock(self.io) catch {};
                defer self.mutex.unlock(self.io);

                if (!self.active) should_break = true;
                current_len = self.len;
                if (current_len > 0) {
                    @memcpy(local_print_buf[0..current_len], self.buf[0..current_len]);
                }
            }

            if (should_break) break;

            if (current_len > 0) {
                const path_slice = local_print_buf[0..current_len];

                const clean_path = if (path_slice.len > 1 and path_slice[path_slice.len - 1] == '/')
                    path_slice[0 .. path_slice.len - 1]
                else
                    path_slice;

                var display_slice = clean_path;
                var found_parts: usize = 0;
                var i = clean_path.len;

                while (i > 0) {
                    i -= 1;
                    if (clean_path[i] == '/') {
                        found_parts += 1;
                        if (found_parts == 2) {
                            display_slice = clean_path[i + 1 ..];
                            break;
                        }
                    }
                }

                // --- SOLUÇÃO PARA O BUG DO SPOTIFY ---
                // Define um limite seguro para o texto não estourar a largura do terminal e quebrar a linha.
                // 60 caracteres é um tamanho excelente para exibir os 2 últimos diretórios sem quebrar o layout.
                const MAX_DISPLAY_LEN = 60;

                if (found_parts >= 2) {
                    // Se o pedaço final ainda for gigante (como o hash do Spotify), trunca ele
                    const final_slice = if (display_slice.len > MAX_DISPLAY_LEN)
                        display_slice[0..MAX_DISPLAY_LEN]
                    else
                        display_slice;

                    io_writer.fastPrint(
                        .STDOUT,
                        "\r\x1B[14C.../{s}\x1B[K",
                        .{final_slice},
                    ) catch {};
                } else {
                    const final_slice = if (clean_path.len > MAX_DISPLAY_LEN)
                        clean_path[0..MAX_DISPLAY_LEN]
                    else
                        clean_path;

                    io_writer.fastPrint(
                        .STDOUT,
                        "\r\x1B[14C{s}\x1B[K",
                        .{final_slice},
                    ) catch {};
                }
            }

            std.Io.sleep(self.io, .fromMilliseconds(30), .real) catch {};
        }
    }
};
