// $Id: SAsmEnv.zig

// defines an assembly bytecode-level environment
// this essentially holds all labels for bytecode
const std = @import("std");

const s_32BitByteCode = @import("SByteCode.zig").s_32BitByteCode;
const s_8BitByteCode = @import("SByteCode.zig").s_8BitByteCode;

pub const s_ASMEnvironment = struct {
    /// So say we have a label named `foo`, which
    /// has a simple `mov` instruction that looks like:
    ///
    /// ```
    /// foo:
    ///     mov R1,0
    /// ```
    ///
    /// And that mov R1,0 looks like this in opcode:
    ///
    /// ```
    /// 45    1    0
    /// ^     ^    ^
    /// mov   R1   0
    /// ```
    ///
    /// A label will basically house that entirety of the opcode.
    labels: std.StringHashMap(s_32BitByteCode),

    /// Contains bindings for opcodes, e.g. `mov` and `int`
    opcodes: std.StringHashMap(i32),

    /// If the bytecode format is delimited, meaning that
    /// each instruction must end with a certain delimiter, example:
    ///
    /// A mov instruction in a delimited format would look like
    ///
    /// `45 1 0 <delim>`
    ///
    /// where `<delim>` is the delimiter character for the format
    ///
    /// This can differ, so it should be set separately.
    is_delimited: bool = false,
    delimiter: i32 = -1,

    /// If the bytecode format needs an end instruction, example:
    ///
    /// when a bytecode is completed, the end instruction will signify
    /// that the code has been completed, nothing else to do.
    needs_end: bool = false,
    end: i32 = -1,

    pub fn init(allocator: std.mem.Allocator) s_ASMEnvironment {
        return s_ASMEnvironment{
            .labels = std.StringHashMap(s_32BitByteCode).init(allocator),
            .opcodes = std.StringHashMap(i32).init(allocator),
        };
    }

    pub fn addOpcode(self: *s_ASMEnvironment, opcode: []const u8, value: i32) void {
        self.opcodes.put(opcode, value) catch {
            @panic("problematic when adding opcode - out of memory");
        };
    }

    pub fn addLabelAndReturn(self: *s_ASMEnvironment, label: []const u8) *s_32BitByteCode {
        self.labels.put(label, s_32BitByteCode.init(self.labels.allocator)) catch {
            @panic("problematic when adding label - out of memory");
        };

        return self.labels.getPtr(label).?;
    }

    pub fn getLabel(self: *s_ASMEnvironment, label: []const u8) *s_32BitByteCode {
        if (self.labels.getPtr(label) == null) {
            std.debug.print("label not found: `{s}`\n", .{label});
            @panic("no such label");
        }

        return self.labels.getPtr(label).?;
    }
};
