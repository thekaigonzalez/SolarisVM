//! Defines a dynamic growable byte list that stores 32-bit integers

// $Id: SLLBytes.zig

const std = @import("std");

const SOLARIS_LIST_SIZE = @import("SIConfig.zig").SOLARIS_LIST_SIZE;

/// ## Bytecode List
///
/// Stores 32-bit integers (strictly)
///
/// To run 8-bit bytecode you can try and convert them to 32-bit integers, do
/// keep in mind that the 32-bit integers are stored in little-endian order.
pub const solarisByteList = struct {
    /// The actual data stored
    data: []i32 = undefined,

    /// The length of the data
    len: usize = 0,

    /// The internal allocator
    allocator: std.mem.Allocator,

    /// Creates a new list of size `25` by default, you can change it in the
    /// `SIConfig.zig` file.
    pub fn new(_allocator: std.mem.Allocator) solarisByteList {
        const bytes_alloc = _allocator.alloc(i32, SOLARIS_LIST_SIZE) catch {
            std.debug.print("solaris: error: failed to allocate bytelist data\n", .{});
            std.process.exit(1);
        };

        @memset(bytes_alloc, 0);

        const byte = solarisByteList{
            .allocator = _allocator,
            .data = bytes_alloc,
        };

        return byte;
    }

    pub fn clear(self: *solarisByteList) void {
        @memset(self.data, 0);
        self.len = 0;
    }

    /// Appends a value to the list
    pub fn append(self: *solarisByteList, value: i32) void {
        if (self.len >= self.data.len) {
            self.data = self.allocator.realloc(self.data, self.data.len * 2) catch {
                std.debug.print("solaris: error: failed to allocate bytelist data\n", .{});
                std.process.exit(1);
            };
        }

        self.data[self.len] = value;
        self.len += 1;
    }

    /// Returns the length of the list
    pub fn length(self: solarisByteList) usize {
        return self.len;
    }

    /// Returns the value at the index, if it's less than the length
    /// Otherwise it'll return null.
    pub fn get(self: solarisByteList, index: usize) ?i32 {
        if (index > self.len - 1) {
            return null;
        }
        return self.data[index];
    }
};
