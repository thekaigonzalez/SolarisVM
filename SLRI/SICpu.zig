//! Contains the SLRI CPU

// $Id: SICpu.zig

const std = @import("std");

const SOLARIS_CPU_MAX_MEMORY = @import("SIConfig.zig").SOLARIS_CPU_MAX_MEMORY;

const solarisRegister = @import("SIRegister.zig").solarisRegister;
const solarisSection = @import("SISection.zig").solarisSection;
const solarisSectionContainer = @import("SISections.zig").solarisSectionContainer;
const solarisStack = @import("SIStack.zig").solarisStack;

pub const solarisCpuState = enum {
    RUNNING,
    SUBROUTINE,
    HALTED,
};

/// Contains sections and registers, manages bytecode states, etc.
pub const solarisCPU = struct {
    memory_occupied: usize = 0,
    memory_max: usize = SOLARIS_CPU_MAX_MEMORY,

    registers: [256]solarisRegister = undefined,

    sections: solarisSectionContainer,

    heap_internal: std.mem.Allocator,

    stack: solarisStack = solarisStack.init(),

    state: solarisCpuState = solarisCpuState.RUNNING,
    
    pub fn init(aloc: std.mem.Allocator) solarisCPU {
        var _cpu = solarisCPU{
            .heap_internal = aloc,
            .sections = solarisSectionContainer.init(aloc),
        };

        for (0..256) |i| {
            _cpu.registers[i] = solarisRegister.init(aloc);
        }

        return _cpu;
    }

    /// NOTE: a majority of functions should push a value to the stack, using
    /// `popeq` to verify the value is correct
    pub fn push(self: *solarisCPU, value: i32) void {
        self.stack.push(value);
    }

    /// Reverse Push
    pub fn rpush(self: *solarisCPU, value: i32) ?void {
        return self.stack.reversePush(value);
    }

    pub fn pop(self: *solarisCPU) ?i32 {
        return self.stack.pop();
    }

    pub fn registerAt(self: *solarisCPU, index: usize) *solarisRegister {
        return &self.registers[index];
    }

    pub fn addSection(self: *solarisCPU, label: i32) ?*solarisSection {
        if (self.sections.section_count >= 256) {
            return null;
        }

        var sec = solarisSection.init(self.heap_internal);

        sec.setLabel(label);

        self.sections.addSection(sec);

        return self.sections.getSection(self.sections.section_count - 1);
    }

    pub fn sectionByLabel(self: *solarisCPU, label: i32) ?*solarisSection {
        return self.sections.findSection(label);
    }

    pub fn free(self: *solarisCPU) void {
        for (0..256) |i| {
            self.registers[i].free();
        }
    }

    pub fn cmalloc(self: *solarisCPU, size: usize, comptime T: type) ?[]T {
        if (self.memory_occupied + size > self.memory_max) {
            return null;
        }

        self.memory_occupied += size;

        return self.heap_internal.alloc(T, size) catch null;
    }

    pub fn getFreeMemory(self: *solarisCPU) usize {
        return self.memory_max - self.memory_occupied;
    }

    pub fn crealloc(self: *solarisCPU, ptr: anytype, size: usize) anyerror![]u8 {
        return self.heap_internal.realloc(ptr, size);
    }

    pub fn cfree(self: *solarisCPU, ptr: anytype) void {
        self.heap_internal.free(ptr);
    }
};
