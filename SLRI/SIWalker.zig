// $Id: SIWalker.zig

const std = @import("std");

const solarisByteList = @import("SIGrowable.zig").solarisByteList;

/// ## Bytecode Walker
///
/// Walks through the bytecode list given
///
/// Functions:
/// - `start` - sets the pointer to the start of the list, and sets the list to DATA
/// - `next` - increments the pointer and returns the value
/// - `back` - decrements the pointer and returns the value
/// - `peek` - returns the value at the pointer
/// - `length` - returns the length of the list
/// - `reset` - sets the pointer to the start of the list
/// - `set` - sets the value at the pointer
/// - `now` - returns the current value at the pointer
/// - `jump` - increments the pointer by the given value
///
/// Contains just about any abstraction needed for walking the list.
///
/// A majority of the functions return `null` if the pointer is at the end of
/// the list, which is good for ensuring that there's no security vulnerabilities.
pub const solarisWalker = struct {
    data: *solarisByteList,
    ptr: usize = 0,

    /// Sets the pointer to the start of the list
    ///
    /// Also sets `.data` to DATA
    pub fn start(data: *solarisByteList) solarisWalker {
        return solarisWalker{ .data = data, .ptr = 0 };
    }

    /// Returns the current value
    pub fn now(self: *solarisWalker) ?i32 {
        if (self.ptr > self.data.length()) {
            return null;
        }

        return self.data.get(self.ptr);
    }

    /// Increments the pointer and returns the value
    pub fn next(self: *solarisWalker) ?i32 {
        self.ptr += 1;

        if (self.ptr > self.data.length()) {
            return null;
        }

        return self.data.get(self.ptr);
    }

    /// Peeks over to the next value
    pub fn peek(self: *solarisWalker) ?i32 {
        if (self.ptr + 1 >= self.data.length()) {
            return null;
        }

        return self.data.get(self.ptr + 1);
    }

    /// Decrements the pointer by 1
    pub fn back(self: *solarisWalker) ?i32 {
        if (self.ptr == 0) {
            return null;
        }

        self.ptr -= 1;

        return self.data.get(self.ptr);
    }

    /// Returns the length of the list
    pub fn length(self: *solarisWalker) usize {
        return self.data.length();
    }

    /// Resets the pointer, setting it to the start
    pub fn reset(self: *solarisWalker) void {
        self.ptr = 0;
    }

    /// Sets the value at the pointer
    pub fn set(self: *solarisWalker, value: i32) void {
        self.data.data[self.ptr] = value;
    }

    /// Jumps the pointer by the given value
    pub fn jump(self: *solarisWalker, jmplen: i32) void {
        if (jmplen < 0) {
            self.ptr -= @intCast(-jmplen);
        }
        self.ptr += @intCast(jmplen);
    }

    /// Increments the value at the pointer
    ///
    /// NOTE: this function is safe to call when the pointer is at the end of the list
    pub fn increment(self: *solarisWalker) void {
        if (self.ptr > self.data.length()) {
            return;
        } else if (self.ptr == self.data.length()) {
            self.data.data[self.ptr - 1] += 1;
        } else {
            self.data.data[self.ptr] += 1;
        }
    }
};
