// $Id: SInstruction.zig

// simple construct for instructions
// contains a name, and arguments
// this is meant for codegen
const std = @import("std");

pub const s_Instruction = struct {
    name: []const u8,
    args: std.ArrayList([]const u8),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, name: []const u8) s_Instruction {
        return s_Instruction{
            .name = name,
            .args = std.ArrayList([]const u8).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn addArgument(self: *s_Instruction, arg: []const u8) void {
        self.args.append(arg) catch {
            @panic("problematic when adding argument - out of memory");
        };
    }

    pub fn deinit(self: *s_Instruction) void {
        self.args.deinit();
    }
};

pub const s_InstructionList = std.ArrayList(s_Instruction);
pub const s_InstructionMap = std.StringHashMap(s_InstructionList);
