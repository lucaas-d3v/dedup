const std = @import("std");

const secret0: u64 = 0x2d358dccaa6c78a5;
const secret1: u64 = 0x8bb84b93962eacc9;
const secret2: u64 = 0x4b33a62ed433d4a3;
const default_seed: u64 = 0xbdd89aa982704029;

pub fn hash(buf: []const u8) u64 {
    const len = buf.len;
    // Inicialização da semente misturando o tamanho dos dados
    var current_seed = rapid_mix(default_seed ^ secret0, secret1) ^ len;

    var index: usize = 0;
    // loop principal
    while (index + 96 <= len) {
        // processa de 96 e 96 bytes enquanto houver dados suficientes

        var sub_index: usize = 0;
        // dentro de cada bloco de 96 bytes, processa de 16 em 16 bytes (dois u64)
        while (sub_index < 96) : (sub_index += 16) {
            const pos = index + sub_index;

            // le os 8 bytes do buffer e converte pra u64
            const a = std.mem.readInt(u64, buf[pos..][0..8], .little);
            const b = std.mem.readInt(u64, buf[pos + 8 ..][0..8], .little);

            current_seed = rapid_mix(a ^ secret1, b ^ current_seed);
        }

        index += 96;
    }

    // loop de finalização
    while (index + 8 <= len) {
        // processa as sobras em blocos de 8 bytes
        const a = std.mem.readInt(u64, buf[index..][0..8], .little);
        current_seed = rapid_mix(a ^ secret2, current_seed ^ secret0);
        index += 8;
    }

    // caso sobre entre 1 a 7 bytes
    if (index < len) {
        var leftover: u64 = 0;

        // copia o resto pra um u64 temporário
        @memcpy(std.mem.asBytes(&leftover)[0..(len - index)], buf[index..len]);

        current_seed = rapid_mix(leftover ^ secret0, current_seed ^ secret1);
    }

    return rapid_mix(current_seed ^ secret0, secret2);
}

inline fn rapid_mix(a: u64, b: u64) u64 {
    // Multiplica dois u64 gerando um u128
    const r: u128 = @as(u128, a) * b;

    // Pega nos 64 bits inferiores
    const low: u64 = @truncate(r);

    // Desloca 'r' para pegar nos 64 bits superiores
    const high: u64 = @truncate(r >> 64);

    return low ^ high;
}

test "teste de RapidHashing" {
    const test1 = hash("string 1");
    const test2 = hash("string 1");

    const test3 = hash("string 1");
    const test4 = hash("string 2");

    std.log.debug("CASO 1:\n  {d} e {d} são {s}\n", .{ test1, test2, if (test1 == test2) "iguais" else "diferentes" });
    std.log.debug("CASO 2:\n  {d} e {d} são {s}\n", .{ test3, test4, if (test3 == test4) "iguais" else "diferentes" });
}
