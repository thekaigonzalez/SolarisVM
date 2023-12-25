// $Id: main.zig

// main entry point
const std = @import("std");

const argparse = @import("argparse.zig");

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

pub fn panic(message: []const u8, stack_trace: ?*std.builtin.StackTrace, _: ?usize) noreturn {
    _ = stack_trace;
    std.debug.print("\x1b[31;1merror:\x1b[0m {s}\n", .{message});
    std.os.exit(1);
}

pub fn main() !void {
    // You can use your favorite allocator
    var arena_allocator =
        std.heap.ArenaAllocator.init(std.heap.page_allocator);

    // just make sure you don't forget to deinit!
    defer arena_allocator.deinit();

    // Get the arguments
    const args =
        try std.process.argsAlloc(arena_allocator.allocator());

    var argparser =
        argparse.zappyArgumentParser.create(arena_allocator.allocator());
    defer argparser.deinit(); // it has it's own deinit() function, try it!

    argparser.details("sasm [-hm] filename(s)...", "Bytecode compiler", "sibc");
    argparser.for_required_arguments(.message);

    var help = argparser.add_flag('h', "help", .boolean, "show this help message and exit") catch {
        @panic("out of memory");
    };

    var arch = argparser.add_flag('m', "arch", .no_compound, "specifies the architecture to compile for.") catch {
        @panic("out of memory");
    };
    arch.default_value("32");

    var engine = argparser.add_flag('E', "engine", .number, "specifies the engine to compile for.") catch {
        @panic("out of memory");
    };

    var output = argparser.add_flag('o', "output", .string, "specifies the output filename.") catch {
        @panic("out of memory");
    };
    output.default_value("a.bin");

    argparser.parse_args(args[1..]) catch {
        @panic("failed to parse command line arguments");
    };

    if (help.convert(bool) or argparser.get_positionals() == 0) {
        const src =
            \\usage: sasm [options...] filename(s)
            \\
            \\The SOLARIS INTERMEDIATE BYTECODE COMPILER
            \\
            \\Options:
            \\
            \\        -h            show this help message and exit (also --help)
            \\        -m            specifies the architecture to compile for,
            \\                       Note that this function performs "pseudo-architecture"
            \\                       emulation, which means that it will take 32-bit bytecode
            \\                       and write it as 8-bit, this does not, however, take into
            \\                       account the specific restrictions of the specified target,
            \\                       such as the maximum number of bytes per instruction, the max
            \\                       amount of register data, usages, and instructions.
            \\
            \\                       to directly specify the engine to compile for use --engine.
            \\                       this is primarily meant to be used in conjunction with --engine.
            \\
            \\
            \\        -E <engine>    specifies the engine to compile for.
            \\                       Supports:
            \\                          OpenLUD
            \\                          NexFUSE
            \\                          Solaris
            \\                          MercuryPIC
        ;
        std.debug.print("{s}\n", .{src});
        std.process.exit(0);
    }
    // Separate memory spaces for each process
    var TokenArena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer TokenArena.deinit();

    var EnvironmentArena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer EnvironmentArena.deinit();

    var ByteCodeArena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer ByteCodeArena.deinit();

    const filename = argparser.get_positional(0);

    const source = std.fs.cwd().readFileAlloc(TokenArena.allocator(), filename, std.math.maxInt(usize)) catch {
        std.debug.print("note: file not found: `{s}'\n", .{filename});
        std.process.exit(0);
    };

    const ast = s_generate(TokenArena.allocator(), source);

    var env = s_ASMEnvironment.init(EnvironmentArena.allocator());

    const engineName = engine.convert([]const u8);

    env.addOpcode("echo", 40);
    env.addOpcode("mov", 41);
    env.addOpcode("each", 42);
    env.addOpcode("reset", 43);
    env.addOpcode("clear", 44);
    env.addOpcode("put", 45);
    env.addOpcode("get", 46);

    if (std.mem.eql(u8, engineName, "OpenLUD")) {
        env.is_delimited = true;
        env.delimiter = 0;
        env.needs_end = true;
        env.end = 12;
    } else if (std.mem.eql(u8, engineName, "NexFUSE")) {
        env.is_delimited = true;
        env.delimiter = 0;

        env.needs_end = true;
        env.end = 22;
    } else if (std.mem.eql(u8, engineName, "Solaris")) {
        // solaris needs nothing special
    } 

    else if (std.mem.eql(u8, engineName, "MercuryPIC")) {
        env.is_delimited = true;
        env.delimiter = 0xAF;

        env.needs_end = true;
        env.end = 22;
    }
    
    else {
        @panic("unsupported engine specified, available options: OpenLUD, NexFUSE, Solaris, MercuryPIC");
    }

    const byte_code = s_codegen(ByteCodeArena.allocator(), ast, &env);

    if (arch.convert(i32) == 32) {
        try s_writeByteCode(ByteCodeArena.allocator(), output.convert([]const u8), byte_code, false);
    } else if (arch.convert(i32) == 8) {
        try s_writeByteCode(ByteCodeArena.allocator(), output.convert([]const u8), byte_code, true);
    } else {
        @panic("unsupported architecture");
    }
}
