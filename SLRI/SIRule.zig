//! Contains the SLRI rules
//! Most of these are redundant, however, but good to have.

// $Id: SIRule.zig

const std = @import("std");

pub const solarisRule = struct {
    gosub: i32 = 15, // GOSUB instruction
    sub: i32 = 10, // SUB instruction
    endsub: i32 = 0x42, // ENDSUB instruction

    pub fn init() solarisRule {
        return solarisRule{};
    }
};
