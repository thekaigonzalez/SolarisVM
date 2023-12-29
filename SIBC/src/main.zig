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

const s_codegen_new = @import("SGenerate.zig").s_generateInstructionsFromAST;
const s_codegen2 = @import("SGenerate.zig").s_byteCodeFromInstructions;

const s_ASMEnvironment = @import("SAsmEnv.zig").s_ASMEnvironment;

const s_compat = @import("SDir.zig").s_compat;

pub fn panic(message: []const u8, stack_trace: ?*std.builtin.StackTrace, _: ?usize) noreturn {
    _ = stack_trace;
    std.debug.print("\x1b[31;1minternal error:\x1b[0m {s}\n", .{message});
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

    var classic = argparser.add_flag('c', "classic", .boolean, "use the classic codegen.") catch {
        @panic("out of memory");
    };
    classic.default_value("false");

    const irgen = argparser.add_flag('i', "ir", .boolean, "generates an intermediate representation of the program.") catch {
        @panic("out of memory");
    };

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
            \\        -o <filename>  specifies the output filename.
            \\        -i             Generates a top-down represation of the program in a Markdown-formatted file.
            \\        -c             specifies classic code generation
            \\                          Modern compiler features will handle all 32-bit instructions
            \\                          and subroutines, specifying this flag will generate subroutine
            \\                          calls and definitions instead, which can bloat file size
            \\                          and can be less efficient for certain targets.
            \\
            \\  --engine <engine>    specifies the engine to compile for.
            \\                       Supports:
            \\                          OpenLUD
            \\                          NexFUSE
            \\                          Solaris
            \\                          MercuryPIC
            \\
            \\for 8-bit codegen, pseudo-8bit emulation is performed, essentially
            \\replacing all 32-bit instructions with 8-bit equivalents/truncating each 32-bit
            \\value.
            \\
            \\for 32-bit codegen, no emulation is performed, and the bytecode is written as-is.
            \\
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

    var engineName = engine.convert([]const u8);

    if (std.mem.eql(u8, engineName, "")) {
        engineName = "nexfuse";
    }

    env.addOpcode("echo", 40);
    env.addOpcode("mov", 41);
    env.addOpcode("each", 42);
    env.addOpcode("reset", 43);
    env.addOpcode("clear", 44);
    env.addOpcode("put", 45);
    env.addOpcode("get", 46);

    env.addOpcode("in", 50);

    env.addOpcode("popeq", 61);
    env.addOpcode("pushq", 61);
    env.addOpcode("popto", 63);
    env.addOpcode("rcl", 64);
    env.addOpcode("add", 65);
    env.addOpcode("movq", 66);
    env.addOpcode("db", 67);

    env.addOpcode("je", 0xAB);
    env.addOpcode("eeq", 0xEF);
    env.addOpcode("jne", 0xAC);

    env.addDirective("compat", s_compat);

    env.format = std.ascii.allocLowerString(TokenArena.allocator(), engineName) catch {
        @panic("out of memory");
    };

    if (std.mem.eql(u8, env.format, "openlud")) {
        env.is_delimited = true;
        env.delimiter = 0;
        env.needs_end = true;
        env.end = 12;
    } else if (std.mem.eql(u8, env.format, "nexfuse")) {
        env.is_delimited = true;
        env.needs_end = true;

        env.delimiter = 0;
        env.end = 22;
    } else if (std.mem.eql(u8, env.format, "solaris")) {
        // solaris needs nothing special
    } else if (std.mem.eql(u8, env.format, "mercurypic")) {
        env.is_delimited = true;
        env.delimiter = 0xAF;

        env.needs_end = true;
        env.end = 22;
    } else {
        std.debug.print("sasm: \x1b[35;1mnote:\x1b[0m choosing bytecode engine `{s}'", .{"NexFUSE"});
        engineName = "nexfuse";
    }

    if (classic.convert(bool)) {
        // nexfuse-based codegen here
        env.addOpcode("cmp", 51);

        const bytecode = s_codegen(ByteCodeArena.allocator(), ast, &env);

        if (irgen.convert(bool) == true) {
            @panic("irgen can not be used in classic mode (-c)");
        }

        s_writeByteCode(ByteCodeArena.allocator(), output.convert([]const u8), bytecode, (arch.convert(i32) == 8)) catch {
            @panic("failed to write bytecode");
        };
    } else {
        // essentially generate an IR (Intermediate Representation)
        // Each file is structured as a HashMap:
        // ("_start") => a list of instructions
        // so on and so forth
        // this new codegen actually implements and fixes recursion, etc.
        // this also introduces output for low-level representations of
        // source code.
        // but that's for a new day.
        const ir = s_codegen_new(ByteCodeArena.allocator(), ast, &env);

        env.addOpcode("cmp", 0xC0);

        if (irgen.convert(bool) == true) {
            var key_iterator = ir.keyIterator();

            std.debug.print("<!-- Intermediate Representation of `{s}` -->\n", .{filename});
            while (key_iterator.next()) |key| {
                std.debug.print("## {s}\n", .{key.*});

                const lbl = ir.get(key.*).?;

                for (lbl.items) |item| {
                    // item is an instruction
                    std.debug.print("* `{s}`\n", .{item.name});
                    for (item.args.items) |arg| {
                        std.debug.print("  * `{s}`\n", .{arg});
                    }
                }
            }
            std.process.exit(0);
        }

        // generate the bytecode from the IR
        const byte_code = s_codegen2(ByteCodeArena.allocator(), ir, &env, true);

        // write the bytecode
        if (arch.convert(i32) == 32) {
            s_writeByteCode(ByteCodeArena.allocator(), output.convert([]const u8), byte_code, false) catch {
                @panic("could not write bytecode to output dest.");
            };
        } else if (arch.convert(i32) == 8) {
            // perform pseudo-8bit actions (hence fake_8bit set to true)
            s_writeByteCode(ByteCodeArena.allocator(), output.convert([]const u8), byte_code, true) catch {
                @panic("out of memory or could not write bytecode to output dest.");
            };
        } else {
            @panic("unsupported architecture");
        }
    }
}
