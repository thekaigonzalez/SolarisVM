// $Id: SGenerate.zig

// generates bytecode from an AST
const std = @import("std");

const Allocator = std.mem.Allocator;

const s_AST = @import("Sast.zig").s_AST;

const s_32BitByteCode = @import("SByteCode.zig").s_32BitByteCode;
const s_writeByteCode = @import("SByteCode.zig").s_write32BitBytecode;

const s_ASMEnvironment = @import("SAsmEnv.zig").s_ASMEnvironment;

const s_Value = @import("SValue.zig").s_Value;

const s_InstructionList = @import("SInstruction.zig").s_InstructionList;
const s_InstructionMap = @import("SInstruction.zig").s_InstructionMap;
const s_Instruction = @import("SInstruction.zig").s_Instruction;


pub fn s_generateBytecodeFromAST(allocator: Allocator, ast: s_AST, env: *s_ASMEnvironment) s_32BitByteCode {
    @compileLog("this function is deprecated, please use IR APIs instead.");

    var bc = s_32BitByteCode.init(allocator);
    var tc = s_32BitByteCode.init(allocator);

    var gen = &bc;

    const in_subroutine = false;
    _ = in_subroutine;

    for (ast.nodes().items) |node| {
        switch (node._type) {
            .ast_subroutine_header_def => {
                // TODO: deprecate start
                const start = false;

                gen = &tc;
                tc.clearRetainingCapacity();

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

                        for (0..labl.items.len) |j| {
                            gen.append(labl.items[j]) catch {
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
                            if (n._type == .ast_value) {
                                // append the rest as values
                                const gen_num = s_Value.from(n._id).asNumber();

                                gen.append(gen_num) catch {
                                    @panic("out of memory");
                                };
                            }
                        }
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
            },
            .ast_directive => {
                var as_str = std.ArrayList([]const u8).init(allocator);
                defer as_str.deinit();

                for (node._nodes.items) |n| {
                    as_str.append(n._id) catch {
                        @panic("out of memory");
                    };
                }

                const func = env.getDirective(node._id);
                func(env, as_str);
            },
            else => {
                @panic("unexpected node type in AST"); // todo: make this a new error
            },
        }
    }

    bc.appendSlice(env.getLabel("_start").items[0..]) catch {
        @panic("out of memory");
    };

    if (env.needs_end) {
        bc.append(env.end) catch {
            @panic("out of memory");
        };
    }

    return bc;
}

pub fn s_generateInstructionsFromAST(allocator: Allocator, ast: s_AST, env: *s_ASMEnvironment) s_InstructionMap {
    var ins_map = s_InstructionMap.init(allocator);

    for (ast.nodes().items) |node| {
        switch (node._type) {
            .ast_subroutine_header_def => {
                var gen = s_InstructionList.init(allocator);

                for (node._nodes.items) |sub_node| {
                    var ins = s_Instruction.init(allocator, sub_node._id);

                    for (sub_node._nodes.items) |n| {
                        if (n._type == .ast_value) {
                            ins.addArgument(n._id);
                        }
                    }

                    gen.append(ins) catch {
                        @panic("out of memory");
                    };
                }

                ins_map.put(node._id, gen) catch {
                    @panic("out of memory");
                };
            },
            .ast_directive => {
                var as_str = std.ArrayList([]const u8).init(allocator);
                defer as_str.deinit();

                for (node._nodes.items) |n| {
                    as_str.append(n._id) catch {
                        @panic("out of memory");
                    };
                }

                const func = env.getDirective(node._id);
                func(env, as_str);
            },
            else => {
                @panic("unexpected node type in AST"); // todo: make this a new error
            },
        }
    }

    return ins_map;
}

pub fn s_byteCodeFromInstructions(allocator: Allocator, ins_map: s_InstructionMap, env: *s_ASMEnvironment, start: bool) s_32BitByteCode {
    _ = start;
    var kiter = ins_map.keyIterator();
    var bc = s_32BitByteCode.init(allocator);
    var n = kiter.next();

    while (n) |key| {
        const ins = ins_map.get(key.*).?;

        if (std.mem.eql(u8, key.*, "_start")) {
            do_instructions(allocator, ins, env, &bc, ins_map);
        }

        n = kiter.next();
    }

    if (env.needs_end) {
        // handle end-cases for LLVMs like NexFUSE, OpenLUD
        bc.append(env.end) catch {
            @panic("out of memory");
        };
    }

    return bc;
}

fn do_instructions(allocator: Allocator, inst: s_InstructionList, env: *s_ASMEnvironment, bc: *s_32BitByteCode, ins_map: s_InstructionMap) void {
    for (inst.items) |ins| {
        // .name
        // .args
        // ins - s_Instruction

        if (std.mem.eql(u8, ins.name, "jmp")) {
            // move to the label
            const label = ins_map.get(ins.args.items[0]);

            if (label == null) {
                std.debug.print("label not found: {s}\n", .{ins.args.items[0]});
                @panic("label not found");
            }

            do_instructions(allocator, label.?, env, bc, ins_map);
            return;
        }

        const opcode = env.opcodes.get(ins.name) orelse {
            std.debug.print("opcode not found: `{s}'\n", .{ins.name});
            @panic("opcode error");
        };

        bc.append(opcode) catch {
            @panic("out of memory");
        };

        for (ins.args.items) |arg| {
            const arg_num = s_Value.from(arg).asNumber();

            bc.append(arg_num) catch {
                @panic("out of memory");
            };

            if (env.is_delimited) {
                bc.append(env.delimiter) catch {
                    @panic("out of memory");
                };
            }
        }
    }
}
