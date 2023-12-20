//! Contains opcode map
//!
//! Essentially the runtime opcode table

// $Id: SIOpHash.zig

const std = @import("std");

const solarisOpCode = @import("SIOpCode.zig").solarisOpCode;

/// ## Opcode Hashmap
///
/// Contains the runtime opcode table
pub const solarisOpHash = struct {
    map: []solarisOpCode,
    len: usize = 0,
    alloc: std.mem.Allocator,

    pub fn init(memory: std.mem.Allocator) solarisOpHash {
        return solarisOpHash{ .map = memory.alloc(solarisOpCode, 256) catch {
            std.debug.print("solaris: error: failed to allocate register data\n", .{});
            std.process.exit(1);
        }, .len = 0, .alloc = memory };
    }

    pub fn put(self: *solarisOpHash, value: solarisOpCode) void {
        if (self.len >= self.map.len) {
            self.map = self.alloc.realloc(self.map, self.map.len * 2) catch {
                std.debug.print("solaris: error: failed to allocate register data\n", .{});
                std.process.exit(1);
            };
        }
        self.map[self.len] = value;
        self.len += 1;
    }

    pub fn get(self: *solarisOpHash, key: i32) ?solarisOpCode {
        for (0..self.len) |i| {
            if (self.map[i].name == key) {
                return self.map[i];
            }
        }

        return null;
    }
};
