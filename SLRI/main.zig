// $Id: main.zig

const std = @import("std");
const zappyArgumentParser = @import("argparse.zig").zappyArgumentParser;

const solarisCPU = @import("SICpu.zig").solarisCPU;
const solarisControl = @import("SIControl.zig").solarisControl;
const solarisOpHash = @import("SIOpHash.zig").solarisOpHash;
const solarisOpCode = @import("SIOpCode.zig").solarisOpCode;
const solarisOpCodeTemplate = @import("SIOpCode.zig").solarisOpCodeTemplate;
const solarisLoadBytecode = @import("SIDumpFile.zig").solarisLoadBytecode;

const solarisRuntime = @import("SIRuntime.zig");

pub fn main() !void {
    // You can use your favorite allocator
    var arena_allocator =
        std.heap.ArenaAllocator.init(std.heap.page_allocator);

    // just make sure you don't forget to deinit!
    defer arena_allocator.deinit();

    // Get the arguments
    const args =
        try std.process.argsAlloc(arena_allocator.allocator());

    // Create the argument parser
    var argparser =
        zappyArgumentParser.create(arena_allocator.allocator());
    defer argparser.deinit(); // it has it's own deinit() function, try it!

    // For required arguments, how should the argument parser handle them?
    argparser.for_required_arguments(.prompt);

    // sets the program details
    argparser.details("solrun [-Nd] [--no-runtime --dump] filename", "The Solaris VM Interface", "solrun");

    // flags have a bunch of different abstractions and methods, try some!
    var noruntime = try argparser.add_flag('N', "no-runtime", .boolean, "Skips the initial runtime loading phase. Creates a minimal runtime environment.");
    noruntime.default_value("false");
    var dump = try argparser.add_flag('d', "dump", .boolean, "Dumps a 32-bit file as bytes. Similar to LunarRED's bytedump program.");
    dump.default_value("false");
    var help = try argparser.add_flag('h', "help", .boolean, "Displays this help text and exits.");
    help.default_value("false");

    try argparser.parse_args(args[1..]);

    if (help.convert(bool)) {
        const src =
            \\Usage: solrun [options...] [--no-runtime --dump] filename
            \\
            \\  The Solaris VM Interface
            \\
            \\Options:
            \\  -N                 Skips the initial runtime loading phase (also --no-runtime)
            \\  -d                 Dumps a 32-bit file as bytes. Similar to LunarRED's bytedump program (also --dump)
            \\  -h                 Displays this help text and exits (aliases: --help)
            \\
            \\Unless `-d' is specified, there MUST be a filename given.
            \\
            \\Loads little-endian 32-bit files with 8-bit generation being a WIP,
            \\however 8-bit bytecode formats are slowly being phased out due to lack
            \\of sizeability, etc.
            \\
        ;
        std.debug.print("{s}", .{src});
        std.process.exit(0);
    }

    if (argparser.get_positionals() != 1) {
        std.debug.print("Usage: {s}\n", .{argparser.usage});
        std.process.exit(1);
    }

    const filename = argparser.get_positional(0);

    var arenaAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arenaAllocator.deinit();

    var cpu = solarisCPU.init(arenaAllocator.allocator());

    var opHash = solarisOpHash.init(arenaAllocator.allocator());

    const byteFile = solarisLoadBytecode(arenaAllocator.allocator(), filename);

    if (byteFile == null) {
        std.debug.print("solrun: could not load file: `{s}'\n", .{filename});
        std.process.exit(1);
    }

    if (dump.convert(bool)) {
        for (0..byteFile.?.length()) |i| {
            std.debug.print("{?d} ", .{byteFile.?.get(i)});
        }

        std.debug.print("\nsolrun: bytes dumped: {d}\n", .{byteFile.?.data.len});
        std.process.exit(0);
    }

    if (!noruntime.convert(bool)) {
        solarisRuntime.solarisLoadRuntime(&opHash);
    }

    var control = solarisControl.init(&cpu, &opHash);

    control.executeBytecode(byteFile.?.data);

    // free the arguments
    std.process.argsFree(arena_allocator.allocator(), args);
}
