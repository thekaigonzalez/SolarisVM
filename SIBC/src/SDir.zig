// $Id: SDir.zig

const std = @import("std");
const strList = std.ArrayList([]const u8);

const s_ASMEnvironment = @import("SAsmEnv.zig").s_ASMEnvironment;

/// ## Compiler Compatibility
///
/// Specifies the format the program is designed for.
///
/// For example, if you want to compile for NexFUSE, you would
/// specify `nexfuse` here.
///
/// ```
/// [compat nexfuse]
///
/// <nexfuse-based program>
/// ```
///
/// This function will give an error message if the specified engine
/// is not supported.
pub fn s_compat(env: *s_ASMEnvironment, arg: strList) void {
    if (!std.mem.eql(u8, arg.items[0], env.format)) {
        std.debug.print("sasm: error: program designed for `{s}'\n", .{ arg.items[0] });
        std.debug.print("sasm: engine given; `{s}'\n", .{env.format});
        std.debug.print("sasm: \x1b[35;1mnote:\x1b[0m try recompiling with `--engine={s}'\n", .{arg.items[0]});
        std.os.exit(1);
    }
}
