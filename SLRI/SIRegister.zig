//! Defines registers for the SLRI VM
//!
//! Each register is 32-bit, contains a chunk of 256 numbers, and can be
//! accessed through the `solarisRegister` struct.
//!
//! NOTE: Registers are designed for easy I/O, and should be used over sections,
//! which are primarily designed for branching and conditional execution.

// $Id: solarisRegister.zig

const std = @import("std");

const SOLARIS_REGISTER_MAX_DATA = @import("SIConfig.zig").SOLARIS_REGISTER_MAX_DATA;

/// ## Registers
///
/// Contain abstractions for writing and reading data
///
/// It is 100% recommended, although not by the zig language, that you use
/// the provided methods instead of using the `data` field directly.
///
/// Functions:
/// - `push`
/// - `pop`
/// - `set`
/// - `get`
/// - `length`
/// - `clear`
/// - `free`
pub const solarisRegister = struct {
    data: []i32 = undefined,
    ptr: usize = 0,
    alloc: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) solarisRegister {
        var _register = solarisRegister{
            .alloc = allocator,
            .ptr = 0,
        };

        _register.data = allocator.alloc(i32, SOLARIS_REGISTER_MAX_DATA) catch {
            std.debug.print("solaris: error: failed to allocate register data\n", .{});
            std.process.exit(1);
        };

        for (0..SOLARIS_REGISTER_MAX_DATA) |i| {
            _register.data[i] = 0;
        }

        return _register;
    }

    pub fn push(self: *solarisRegister, value: i32) void {
        if (self.ptr >= self.data.len) {
            std.debug.print("solaris: error: register overflow\n", .{});
            std.process.exit(1);
        }
        self.data[self.ptr] = value;
        self.ptr += 1;
    }

    pub fn pop(self: *solarisRegister) i32 {
        if (self.ptr == 0 or self.ptr + 1 > self.data.len) {
            std.debug.print("solaris: error: potential register underflow, can not pop!\n", .{});
            std.process.exit(1);
        }

        self.ptr -= 1;
        self.data[self.ptr + 1] = 0;

        return self.data[self.ptr];
    }

    pub fn set(self: *solarisRegister, index: usize, value: i32) void {
        if (index >= self.data.len) {
            std.debug.print("solaris: error: register index out of bounds\n", .{});
            std.process.exit(1);
        }
        self.data[index] = value;
    }

    pub fn get(self: *solarisRegister, index: usize) i32 {
        if (index >= self.data.len) {
            std.debug.print("solaris: error: register index out of bounds\n", .{});
            std.process.exit(1);
        }
        return self.data[index];
    }

    pub fn length(self: *solarisRegister) usize {
        return self.data.len;
    }

    pub fn clear(self: *solarisRegister) void {
        for (0..self.data.len) |i| {
            self.data[i] = 0;
        }
    }

    pub fn free(self: *solarisRegister) void {
        self.alloc.free(self.data);
        self.data = undefined;
    }

    pub fn deinit(self: *solarisRegister) void {
        self.alloc.free(self.data);
    }
};
