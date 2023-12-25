// $Id: SGenerate.zig

// generates bytecode from an AST
const std = @import("std");

const Allocator = std.mem.Allocator;

const s_AST = @import("Sast.zig").s_AST;

const s_32BitByteCode = @import("SByteCode.zig").s_32BitByteCode;
const s_writeByteCode = @import("SByteCode.zig").s_write32BitBytecode;

const s_ASMEnvironment = @import("SAsmEnv.zig").s_ASMEnvironment;

const s_Value = @import("SValue.zig").s_Value;

pub fn s_generateBytecodeFromAST(allocator: Allocator, ast: s_AST, env: *s_ASMEnvironment) s_32BitByteCode {
    var bc = s_32BitByteCode.init(allocator);
    var tc = s_32BitByteCode.init(allocator);

    var gen = &bc;

    const in_subroutine = false;
    _ = in_subroutine;

    for (ast.nodes().items) |node| {
        switch (node._type) {
            .ast_subroutine_header_def => {
                var start = false;

                // check if it's not a start label, beacuse that's
                // a special case where we just write the code
                // directly to the target
                if (!std.mem.eql(u8, node._id, "_start")) {
                    // then we're in the temporary generator
                    gen = &tc;
                    tc.clearRetainingCapacity();
                } else {
                    start = true;
                    gen = &bc;
                }

                for (node._nodes.items) |sub_node| {
                    // id is the name of the instruction
                    const nam = sub_node._id;

                    var jmp = false;

                    if (std.mem.eql(u8, nam, "jmp")) {
                        jmp = true;
                        const id = sub_node._nodes.items[0]._id;

                        // handle jmp code, basically unload
                        // an entire label's bytecode onto the frame
                        const labl = env.getLabel(id);

                        for (0..labl.items.len) |i| {
                            gen.append(labl.items[i]) catch {
                                @panic("out of memory");
                            };
                        }
                    }

                    if (!jmp) {
                        gen.*.append(env.opcodes.get(nam) orelse {
                            @panic("no such opcode");
                        }) catch {
                            @panic("out of memory");
                        };

                        for (sub_node._nodes.items) |n| {
                            // append the rest as values
                            const gen_num = s_Value.from(n._id).asNumber();

                            gen.append(gen_num) catch {
                                @panic("out of memory");
                            };
                        }

                        if (env.is_delimited) {
                            gen.append(env.delimiter) catch {
                                @panic("out of memory");
                            };
                        }
                    }

                    if (!start) {
                        var labl = env.addLabelAndReturn(node._id);

                        for (0..gen.items.len) |i| {
                            labl.append(gen.items[i]) catch {
                                @panic("out of memory");
                            };
                        }
                    }
                }
            },
            else => {
                @panic("unexpected node type in AST"); // todo: make this a new error
            },
        }
    }

    if (env.needs_end) {
        bc.append(env.end) catch {
            @panic("out of memory");
        };
    }

    return bc;
}
