//! Utility functions to load 32-bit and 8-bit bytecode files and return them
//! as a byte list

// $Id: SIDumpFile.zig

const std = @import("std");

// we're gonna use the standard file stuff

const SOLARIS_MAX_BYTECODE = @import("SIConfig.zig").SOLARIS_MAX_BYTECODE;

const solarisByteList = @import("SIGrowable.zig").solarisByteList;

pub fn solarisLoadBytecode(allocator: std.mem.Allocator, fileName: []const u8) ?solarisByteList {
    var file = std.fs.cwd().openFile(fileName, .{}) catch return null;
    defer file.close();

    var bytecode = solarisByteList.new(allocator);

    const size: u64 = @intCast(4);
    _ = size;
    const endP: usize = file.getEndPos() catch return null;
    const filesize = endP / @sizeOf(i32);

    for (0..filesize) |_| {
        // we are infallible.
        // no errors in this god damn house. (lol)
        const byte = file.reader().readInt(i32, std.builtin.Endian.little) catch 0;

        bytecode.append(byte);
    }

    return bytecode;
}
