// $Id: SByteCode.zig

// ima zig fiend, so i used all zig constructs

// codegen
const std = @import("std");

const Allocator = std.mem.Allocator;

pub const s_32BitByteCode = std.ArrayList(i32);
pub const s_8BitByteCode = std.ArrayList(i8);

/// Writes a 32BitBytecode array to a file
pub fn s_write32BitBytecode(allocator: Allocator, filename: []const u8, byte_code: s_32BitByteCode, fake_8bit: bool) !void {
    _ = allocator;
    var file = try std.fs.cwd().createFile(filename, .{});
    defer file.close();

    var writer = file.writer();

    for (byte_code.items) |item| {
        if (!fake_8bit) {
            try writer.writeInt(i32, item, .little);
        } else {
            try writer.writeInt(i8, @intCast(item), .little);
        }
    }
}
