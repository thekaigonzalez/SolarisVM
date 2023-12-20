//! Contains values for the SLRI.

// $Id: SIConfig.zig

/// The standard list size, do note however
/// there's no capacity because this value is multiplied by
/// two whenever it's needed to grow/expand to fit all of the data
/// 
/// The default value is `256`.
pub const SOLARIS_LIST_SIZE: usize = 256;

/// The maximum amount of bytecode that seems safe for SLRI
/// 
/// The default value is `65536`. Changing this value to `-1` will cancel
/// it out, disabling the max amount of bytecode that a file can run.
pub const SOLARIS_MAX_BYTECODE: usize = 65536;

/// Defines the maximum amount of JMP cycles that the CPU
/// can stand.
/// 
/// What that means is code like this:
/// 
/// ```asm
/// a:
///   jmp b
/// b:
///   jmp a
/// ```
/// 
/// can only execute 512 CPU recycles.
/// 
/// The default value is `512`.
/// 
/// Changing this value to `-1` will cancel it out, disabling the maximum
/// amount of CPU cycles for recursive decision-making
pub const SOLARIS_MAX_JMP: usize = 512;

/// The default RAM for the SLRI
/// 
/// All CPU functions are only limited to this much user space,
/// preventing overflows as well, stopping any access when memory
/// runs out.
/// 
/// The default value is `512`, however
/// this may change in the future.
pub const SOLARIS_RAM: comptime_int = 512;

/// The maximum amount of information that a register can store.
/// 
/// The default value is `256`.
pub const SOLARIS_REGISTER_MAX_DATA: comptime_int = 256;

/// The CPU memory space.
/// 
/// Any CPU memory calls will be limited to this much space, 
/// 
/// The default value is `4096` -- changing this value to `-1` will
/// allow it to be an unlimited amount of memory.
pub const SOLARIS_CPU_MAX_MEMORY: usize = 4096;

/// The max registers that a CPU can have
/// 
/// The default value is `32`.
pub const SOLARIS_CPU_MAX_REGISTERS: usize = 32;
