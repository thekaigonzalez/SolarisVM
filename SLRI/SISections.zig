//! A section container

// $Id: SISections.zig

const std = @import("std");

const solarisSection = @import("SISection.zig").solarisSection;

const SOLARIS_LIST_SIZE = @import("SIConfig.zig").SOLARIS_LIST_SIZE;

pub const solarisSectionContainer = struct {
    sections: []solarisSection = undefined,
    section_count: usize = 0,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) solarisSectionContainer {
        return solarisSectionContainer{
            .allocator = allocator,
            .sections = allocator.alloc(solarisSection, SOLARIS_LIST_SIZE) catch {
                std.debug.print("solaris: error: failed to allocate section container\n", .{});
                std.process.exit(1);
            },
        };
    }

    pub fn addSection(self: *solarisSectionContainer, section: solarisSection) void {
        self.sections[self.section_count] = section;
        self.section_count += 1;
    }

    pub fn getSection(self: *solarisSectionContainer, index: usize) *solarisSection {
        return &self.sections[index];
    }

    pub fn length(self: *solarisSectionContainer) usize {
        return self.section_count;
    }

    pub fn findSection(self: *solarisSectionContainer, label: i32) ?*solarisSection {
        for (0..self.section_count) |i| {
            if (self.sections[i].label == label) {
                return &self.sections[i];
            }
        }
        return null;
    }
    pub fn deinit(self: *solarisSectionContainer) void {
        self.allocator.free(self.sections);
    }
};
