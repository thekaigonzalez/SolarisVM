//! Contains structure of SLRI bytecode

// $Id: SIControl.zig

const std = @import("std");

const solarisCPU = @import("SICpu.zig").solarisCPU;
const solarisWalker = @import("SIWalker.zig").solarisWalker;
const solarisOpCode = @import("SIOpCode.zig").solarisOpCode;
const solarisByteList = @import("SIGrowable.zig").solarisByteList;
const solarisOpCodeTemplate = @import("SIOpCode.zig").solarisOpCodeTemplate;
const solarisOpHash = @import("SIOpHash.zig").solarisOpHash;
const solarisSection = @import("SISection.zig").solarisSection;

pub const solarisControl = struct {
    cpu: *solarisCPU,
    opHash: *solarisOpHash,

    pub fn init(cpu: *solarisCPU, opHash: *solarisOpHash) solarisControl {
        return solarisControl{
            .cpu = cpu,
            .opHash = opHash,
        };
    }

    pub fn bind(self: *solarisControl, opCode: i32, func: solarisOpCodeTemplate) void {
        self.opHash.put(opCode, solarisOpCode.init(opCode, func));
    }

    pub fn executeBytecode(self: *solarisControl, bytecode: []i32) void {
        var bytes = solarisByteList.new(self.cpu.heap_internal);

        for (0..bytecode.len) |i| {
            bytes.append(bytecode[i]);
        }

        var walker = solarisWalker.start(&bytes);

        var curr = walker.now();

        if (curr == null) {
            std.debug.print("solaris: error: empty bytecode\n", .{});
            std.process.exit(1);
        }

        while (curr != null) {
            if (self.opHash.get(curr.?) != null) {
                var func = self.opHash.get(curr.?);

                if (func == null) {
                    std.debug.print("solaris: error: opcode not found: {d}\n", .{curr.?});
                    std.process.exit(1);
                } else {
                    func.?.execute(self.cpu, &walker);
                }
            }

            curr = walker.next();
        }
    }
};
