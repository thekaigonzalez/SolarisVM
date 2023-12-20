//! Defines sections primarily used to store function branches; subroutines
//! and other functions.
//!
//! Contains byte array unfolding functions for the SLRI VM.
//!

// $Id: SISection.zig

const std = @import("std");

const SOLARIS_LIST_SIZE = @import("SIConfig.zig").SOLARIS_LIST_SIZE;

/// ## Sections
///
/// Contains executable data that can be read and written. This is NOT
/// for I/O by any means since that's the registers job.
pub const solarisSection = struct {
    data: []i32 = undefined,
    ptr: usize = 0,
    alloc: std.mem.Allocator,
    label: ?i32 = null,

    pub fn init(allocator: std.mem.Allocator) solarisSection {
        var _section = solarisSection{
            .alloc = allocator,
            .ptr = 0,
        };

        _section.data = allocator.alloc(i32, SOLARIS_LIST_SIZE) catch {
            std.debug.print("solaris: error: failed to allocate section\n", .{});
            std.process.exit(1);
        };

        return _section;
    }

    pub fn setLabel(self: *solarisSection, label: i32) void {
        self.label = label;
    }

    pub fn getLabel(self: *solarisSection) ?i32 {
        return self.label;
    }

    pub fn unload(self: *solarisSection, data: []i32) void {
        if (self.data.len < data.len) {
            self.data = self.alloc.alloc(i32, data.len) catch {
                std.debug.print("solaris: error: failed to allocate section\n", .{});
                std.process.exit(1);
            };
        }

        for (0..data.len) |i| {
        self.data[i] = data[i];
        }
    }
};
