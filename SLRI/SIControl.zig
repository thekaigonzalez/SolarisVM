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
            // comparisons are structured like this:
            // cmp R1,R2
            // (byte-by-byte comparison, makes sure both registers are the same entirely)
            // after comparing, another byte is expected,
            // (je=0xAB, jump equal), which means
            // any instructions until (ENDEQ=0xEF, end equal) are executed.
            // otherwise, (jne=0xAC, jump not equal) is executed.
            // from a low-level perspective (as a note for future developers)
            // this is how a comparison looks from a top-level:

            // cmp R1,R2
            // je
            // ... ; true code
            // eeq
            // jne
            // ... ; false code
            // enq

            if (curr.? == 0xC0) { // cmp
                const reg1 = walker.next();
                const reg2 = walker.next();

                if (reg1 == null or reg2 == null) {
                    std.debug.print("solaris: error: cmp requires 2 registers\n", .{});
                    std.process.exit(1);
                }

                const rega = self.cpu.registerAt(@intCast(reg1.?));
                const regb = self.cpu.registerAt(@intCast(reg2.?));

                var same = true;

                for (0..rega.data.len) |i| {
                    if (rega.data[i] != regb.data[i]) {
                        same = false;
                    }
                }

                if (same) {
                    if (walker.next().? != 0xAB) {
                        std.debug.print("solaris: error: cmp requires je\n", .{});
                        std.process.exit(1);
                    }

                    curr = walker.next();

                    var sub = std.ArrayList(i32).init(self.cpu.heap_internal);

                    while (curr.? != 0xEF) {
                        sub.append(curr.?) catch {
                            std.debug.print("solaris: error: out of memory\n", .{});
                            std.process.exit(1);
                        };
                        curr = walker.next();

                        if (curr == null) {
                            std.debug.print("solaris: error: cmp requires je\n", .{});
                            std.process.exit(1);
                        }
                    }

                    self.executeBytecode(sub.items);

                    if (walker.peek().? != 0xAC) {
                        // ignore
                    } else {
                        curr = walker.next();

                        if (curr == null) {
                            std.debug.print("solaris: error: cmp requires jne\n", .{});
                            std.process.exit(1);
                        }

                        while (curr.? != 0xEF) {
                            curr = walker.next();

                            if (curr == null) {
                                std.debug.print("solaris: error: cmp requires jne\n", .{});
                                std.process.exit(1);
                            }
                        } // note: just ignore everything else
                        // TODO: (maybe?) optimize this lol
                    }
                } else {
                    if (walker.next().? != 0xAB) {
                        std.debug.print("solaris: error: cmp requires je\n", .{});
                        std.process.exit(1);
                    }

                    curr = walker.next();

                    var sub = std.ArrayList(i32).init(self.cpu.heap_internal);

                    while (curr.? != 0xEF) {
                        curr = walker.next(); // ignore true block
                    }

                    if (walker.peek().? != 0xAC) {
                        std.debug.print("solaris: error: cmp requires jne\n", .{});
                        std.process.exit(1);
                    }

                    curr = walker.next();

                    if (curr == null) {
                        std.debug.print("solaris: error: cmp requires endeq\n", .{});
                        std.process.exit(1);
                    }

                    while (curr.? != 0xEF) {
                        sub.append(curr.?) catch {
                            std.debug.print("solaris: error: out of memory\n", .{});
                            std.process.exit(1);
                        };

                        curr = walker.next();

                        if (curr == null) {
                            std.debug.print("solaris: error: no endeq\n", .{});
                            std.process.exit(1);
                        }
                    }

                    self.executeBytecode(sub.items);
                }
            }
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
