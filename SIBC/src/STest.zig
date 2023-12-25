// $Id: STest.zig

const std = @import("std");

const assert = std.testing.expect;

const s_Value = @import("SValue.zig").s_Value;

const s_AST = @import("Sast.zig").s_AST;
const s_Node = @import("Sast.zig").s_Node;
const s_NodeType = @import("Sast.zig").s_NodeType;

const s_32BitByteCode = @import("SByteCode.zig").s_32BitByteCode;
const s_writeByteCode = @import("SByteCode.zig").s_write32BitBytecode;

const print_ast = @import("Sast.zig").s_printAST;
const print_ast_pretty = @import("Sast.zig").printASTPretty;

const s_generate = @import("Sast.zig").s_generateASTFromCode;
const s_codegen = @import("SGenerate.zig").s_generateBytecodeFromAST;
const s_ASMEnvironment = @import("SAsmEnv.zig").s_ASMEnvironment;

test "values" {
    var v: s_Value = s_Value.initNil();

    try assert(v.isNil());
    try assert(!v.isNumber());

    v.set(i32, 10.0);

    try assert(!v.isNil());
    try assert(v.isNumber());
    try assert(v.asNumber() == 10.0);

    v.set(u8, 'A');

    try assert(!v.isNil());
    try assert(v.isNumber());
    try assert(v.asNumber() == 65);

    const my_hex = s_Value.from("A");
    const my_reg = s_Value.from("R65");
    const my_char = s_Value.from("0x41");
    const my_num = s_Value.from("65");
    const my_num_wrong = s_Value.from(" 65");

    try assert(my_hex.asNumber() == 65);
    try assert(my_reg.asNumber() == 65);
    try assert(my_char.asNumber() == 65);
    try assert(my_num.asNumber() == 65);
    try assert(my_num_wrong.asNumber() == 65);
}

test "ast" {
    var Arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer Arena.deinit();

    var ast = s_AST.init(Arena.allocator());

    var nodes = ast.nodes();

    try assert(nodes.items.len == 0);

    nodes.append(s_Node{
        ._id = "test",
        ._type = s_NodeType.ast_value,
        ._nodes = std.ArrayList(s_Node).init(Arena.allocator()),
    }) catch |err| switch (err) {
        error.OutOfMemory => {
            @panic("out of memory");
        },
    };

    try assert(nodes.items.len == 1);
    try assert((nodes.items[0]._type == s_NodeType.ast_value));

    // this code should generate an AST where the root only contains
    // one node, a call to mov, with two sub-nodes, R0 and 0, both
    // values.
    const new_ast = s_generate(Arena.allocator(), "\n\n\n\n\n\n\n\n\n\n\n\nabc:\n\tmov abc,ghi,c\n\tint food,0xbar\ndef:\n\tmov abc,ghi,c\n\tint food,0xbar\n");

    std.debug.print("\n", .{});
    print_ast_pretty(new_ast);
    std.debug.print("\n", .{});
}

test "bytecode writer" {
    var Arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer Arena.deinit();

    var byte_code = s_32BitByteCode.init(Arena.allocator());

    try byte_code.append(1);
    try byte_code.append(2);
    try byte_code.append(3);
    try byte_code.append(4);

    try s_writeByteCode(Arena.allocator(), "test", byte_code);

    try assert(byte_code.capacity > 0);
}

test "codegen" {
    var Arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer Arena.deinit();

    const ast = s_generate(Arena.allocator(), "_start:\n\techo a\n");

    var env = s_ASMEnvironment.init(Arena.allocator());

    env.addOpcode("mov", 45);
    env.addOpcode("echo", 40);

    const byte_code = s_codegen(Arena.allocator(), ast, &env);

    std.debug.print("{any}\n", .{byte_code.items});

    try s_writeByteCode(Arena.allocator(), "a.bin", byte_code, false);
}
