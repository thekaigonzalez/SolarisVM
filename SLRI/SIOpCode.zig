//! Contains opcode functions

// $Id: SIOpCode.zig

const std = @import("std");

const solarisCPU = @import("SICpu.zig").solarisCPU;
const solarisWalker = @import("SIWalker.zig").solarisWalker;

// functions can walk through the bytecode to gather needed information.
pub const solarisOpCodeTemplate = *const fn (*solarisCPU, *solarisWalker) void;

pub const solarisOpCode = struct {
    name: i32,
    func: solarisOpCodeTemplate,

    pub fn init(name: i32, func: solarisOpCodeTemplate) solarisOpCode {
        return solarisOpCode{ .name = name, .func = func };
    }

    pub fn execute(self: *solarisOpCode, cpu: *solarisCPU, walker: *solarisWalker) void {
        self.func(cpu, walker);
    }
};
