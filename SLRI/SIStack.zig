//! Contains the SLRI stack
//!
//! A simple list of integers that can pop, etc.

// $Id: SIStack.zig

const std = @import("std");

pub const solarisStack = struct {
    data: std.ArrayList(i32) = std.ArrayList(i32).init(std.heap.page_allocator),

    pub fn init() solarisStack {
        return solarisStack{};
    }

    pub fn push(self: *solarisStack, value: i32) void {
        self.data.append(value) catch {
            std.debug.print("solaris: error: failed to push value to stack\n", .{});
            std.process.exit(1);
        };
    }

    pub fn reversePush(self: *solarisStack, value: i32) ?void {
        return self.data.insert(0, value) catch null;
    }

    pub fn pop(self: *solarisStack) ?i32 {
        return self.data.popOrNull();
    }

    pub fn length(self: *solarisStack) usize {
        return self.data.items.len;
    }

    pub fn items(self: *solarisStack) []i32 {
        return self.data.items;
    }
};
