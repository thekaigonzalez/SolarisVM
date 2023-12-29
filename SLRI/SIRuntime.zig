//! Runtime
//!
//! Standard I/O functions
//!
//! keep in mind, all standard functions are sub-safe, meaning
//! that they are easily integrated into subroutines.

// $Id: SIRuntime.zig

const std = @import("std");

const solarisOpCode = @import("SIOpCode.zig").solarisOpCode;
const solarisOpHash = @import("SIOpHash.zig").solarisOpHash;
const solarisWalker = @import("SIWalker.zig").solarisWalker;
const solarisCPU = @import("SICpu.zig").solarisCPU;

pub const solarisECHOInstruction = 40;
/// ## Solaris ECHO Instruction
///
/// Takes in 1 byte and tries to print it out in the most accurate way possible,
/// whether it's a character or a number.
///
/// ### Return Codes
/// * `0` - Success
/// * `1` - Error in parameters
pub fn solarisRTECHO(cpu: *solarisCPU, walker: *solarisWalker) void {
    const byte = walker.next();

    if (cpu.state == .SUBROUTINE) return;

    if (byte == null) {
        cpu.push(1);
        return;
    }

    if (byte.? < 256 and byte.? >= 0) {
        const cha: u8 = @intCast(byte.?);
        std.debug.print("{c}", .{cha});
    } else {
        std.debug.print("{d}", .{byte.?});
    }

    cpu.push(0); // return code
}

pub const solarisMOVInstruction = 41;
/// ## Solaris MOV Instruction
///
/// Takes in 1 byte and moves it to the top of the stack
///
/// **NOTE** this is unlike the other bytecode formats I've made in the past
/// where MOV intakes a register AND value, this one just takes in a value
/// And pushes it to the top of the stack
///
/// ### Return Codes
/// * `0` - Success
/// * `1` - Error in parameters
/// * `2` - Stack overflow
pub fn solarisRTMOV(cpu: *solarisCPU, walker: *solarisWalker) void {
    const byte = walker.next();

    if (cpu.state == .SUBROUTINE) return;

    if (byte == null) {
        cpu.push(1);
        return;
    }

    if (cpu.rpush(byte.?) == null) {
        cpu.push(2);
    }
}

pub const solarisEACHInstruction = 42;
/// ## Solaris EACH Instruction
///
/// prints out each value in given register, if no register is given, or the
/// parameter is -1, it will print out every byte in the stack instead.
///
/// ### Return Codes
/// * `0` - Success
pub fn solarisRTEACH(cpu: *solarisCPU, walker: *solarisWalker) void {
    const byte = walker.next();

    if (cpu.state == .SUBROUTINE) return;

    if (byte == null or byte.? == -1) {
        for (0..cpu.stack.data.items.len) |i| {
            if (cpu.stack.data.items[i] < 256) {
                const cha: u8 = @intCast(cpu.stack.data.items[i]);

                std.debug.print("{c}", .{cha});
            } else {
                std.debug.print("{d}\n", .{cpu.stack.data.items[i]});
            }
        }
    } else {
        const register = cpu.registerAt(@intCast(byte.?));

        for (0..register.data.len) |i| {
            if (register.data[i] < 256 and register.data[i] >= 0) {
                const cha: u8 = @intCast(register.get(i));

                std.debug.print("{c}", .{cha});
            } else {
                std.debug.print("{d}\n", .{register.get(i)});
            }
        }
    }
}

pub const solarisPUTInstruction = 43;
/// ## Solaris PUT Instruction
///
/// Takes in 3 parameters - a register, byte, and position
/// and puts the byte into the register at the position
///
/// ### Return Codes
/// * `0` - Success
/// * `1` - Error in parameters
/// * `6` - Invalid position
pub fn solarisRTPUT(cpu: *solarisCPU, walker: *solarisWalker) void {
    const reg_num = walker.next();
    const byte = walker.next();
    const position = walker.next();

    if (cpu.state == .SUBROUTINE) return;

    if (byte == null or reg_num == null or position == null) {
        cpu.push(1);
        return;
    }

    const register = cpu.registerAt(@intCast(byte.?));

    if (position.? < 0 or position.? >= register.data.len) {
        cpu.push(6);
    }

    register.set(position.?, byte.?);

    cpu.push(0);
}

pub const solarisGETInstruction = 44;
/// ## Solaris GET Instruction
///
/// Takes in 3 parameters - a register, byte, and position
/// and gets the byte from the register at the position and pushes it to the top of the stack
///
/// ### Return Codes
/// * `0` - Success
/// * `1` - Error in parameters
/// * `6` - Invalid position
pub fn solarisRTGET(cpu: *solarisCPU, walker: *solarisWalker) void {
    const reg_num = walker.next();
    const byte = walker.next();
    const position = walker.next();

    if (cpu.state == .SUBROUTINE) return;

    if (byte == null or reg_num == null or position == null) {
        cpu.push(1);
        return;
    }

    const register = cpu.registerAt(@intCast(byte.?));

    if (position.? < 0 or position.? >= register.data.len) {
        cpu.push(6);
    }

    cpu.push(register.get(position.?));

    cpu.push(0);
}

pub const solarisPOPEQInstruction = 50;
/// ## Solaris POPEQ Instruction
///
/// Pops 1 byte from the top of the stack and checks it against the second byte,
/// if true, it pushes 1 to the top of the stack, otherwise it pushes 0
///
/// This is probably one of the most important instructions in the program, because
/// it's able to check if the stack value is equal to another value.
///
/// ### Return Codes
/// * `1` - Equal
/// * `0` - Not Equal
/// * `2` - Error in parameters
/// * `3` - Stack underflow
///
/// ### Supported
/// As of now, this instruction is fully supported and maintained.
pub fn solarisRTPOPEQ(cpu: *solarisCPU, walker: *solarisWalker) void {
    const toOtherByte = walker.next();

    const comparedByte = cpu.pop();

    if (cpu.state == .SUBROUTINE) return;

    if (toOtherByte == null) {
        cpu.push(2);
        return;
    }

    if (comparedByte == null) {
        cpu.push(3);
        return;
    }

    if (toOtherByte == comparedByte) {
        cpu.push(1);
    } else {
        cpu.push(0);
    }
}

pub const solarisPUSHQInstruction = 61;
/// ## Solaris PUSHQ Instruction
///
/// Takes in 1 byte and pushes it to the last value in the stack
///
/// ### Return Codes
/// * `0` - Success
/// * `1` - Error in parameters
/// * `2` - Stack overflow
pub fn solarisRTPUSHQ(cpu: *solarisCPU, walker: *solarisWalker) void {
    const byte = walker.next();

    if (cpu.state == .SUBROUTINE) return;

    if (byte == null) {
        cpu.push(1);
        return;
    }

    cpu.push(byte.?);

    return;
}

pub const solarisPOPTOPInstruction = 62;
/// ## Solaris POPTOP Instruction
///
/// Pops 1 byte from the top of the stack and pushes it to the last value in the
/// stack, essentially a reordering instruction
///
/// ### Return Codes
/// * `0` - Success
/// * `1` - Error in parameters
/// * `2` - Stack underflow
pub fn solarisRTPOPTOP(cpu: *solarisCPU, walker: *solarisWalker) void {
    _ = walker;

    if (cpu.state == .SUBROUTINE) return;

    const byte = cpu.pop();

    if (byte == null) {
        cpu.push(1);
        return;
    }

    cpu.push(byte.?);

    return;
}

pub const solarisPOPTOInstruction = 63;
/// ## Solaris POPTO Instruction
///
/// Pops 1 byte from the top of the stack and pushes it into the given register
///
/// `m := r[r.len] = w1 | r.len + 1`
///
/// ### Return Codes
/// * `0` - Success
/// * `1` - Error in parameters
/// * `2` - Stack underflow
pub fn solarisRTPOPTO(cpu: *solarisCPU, walker: *solarisWalker) void {
    const byte = cpu.pop();
    const reg = walker.next();

    if (cpu.state == .SUBROUTINE) return;

    if (byte == null or reg == null) {
        cpu.push(1);
        return;
    }

    cpu.registerAt(@intCast(reg.?)).push(byte.?);

    return;
}

pub const solarisRCLInstruction = 64;
/// ## Solaris RCL instruction
///
/// Prints the entirety of a register as numbers,
/// if they're not 0
///
/// ### Return Codes
/// * `0` - Success
pub fn solarisRCL(cpu: *solarisCPU, walker: *solarisWalker) void {
    const reg = walker.next();

    if (reg == null) {
        return;
    }

    const r = cpu.registerAt(@intCast(reg.?));

    for (0..r.data.len) |i| {
        if (r.data[i] == 0) {
            continue;
        }
        std.debug.print("{d}\n", .{r.data[i]});
    }

    cpu.push(0);
}

pub const solarisADDInstruction = 65;
/// ## Solaris ADD instruction
///
/// Adds the top 2 values in the stack
///
/// ### Return Codes
/// * `0` - Success
/// * `1` - Error in parameters
/// * `2` - Stack underflow
pub fn solarisADD(cpu: *solarisCPU, walker: *solarisWalker) void {
    _ = walker;
    const b = cpu.pop().?;
    const a = cpu.pop().?;

    cpu.push(a + b);
}

pub const solarisMOVQInstruction = 66;
/// ## Solaris MOVQ Instruction
///
/// Moves a value to specified register
///
/// ### Return Codes
///
/// * `0` - Success
/// * `1` - Error in parameters
pub fn solarisMOVQ(cpu: *solarisCPU, walker: *solarisWalker) void {
    const reg = walker.next();
    const val = walker.next();

    if (reg == null or val == null) {
        cpu.push(1);
        return;
    }

    cpu.registerAt(@intCast(reg.?)).push(val.?);
    cpu.push(0);
}

/// Load the runtime (every instruction)
pub fn solarisLoadRuntime(hash: *solarisOpHash) void {
    hash.put(solarisOpCode.init(solarisECHOInstruction, solarisRTECHO));
    hash.put(solarisOpCode.init(solarisMOVInstruction, solarisRTMOV));
    hash.put(solarisOpCode.init(solarisEACHInstruction, solarisRTEACH));

    hash.put(solarisOpCode.init(solarisPOPEQInstruction, solarisRTPOPEQ));
    hash.put(solarisOpCode.init(solarisPUSHQInstruction, solarisRTPUSHQ));
    hash.put(solarisOpCode.init(solarisPOPTOPInstruction, solarisRTPOPTOP));
    hash.put(solarisOpCode.init(solarisPOPTOInstruction, solarisRTPOPTO));
    hash.put(solarisOpCode.init(solarisRCLInstruction, solarisRCL));
    hash.put(solarisOpCode.init(solarisADDInstruction, solarisADD));
    hash.put(solarisOpCode.init(solarisMOVQInstruction, solarisMOVQ));
}
