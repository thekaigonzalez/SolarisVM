// $Id: test.zig

const std = @import("std");
const solarisList = @import("SIGrowable.zig").solarisByteList;
const solarisWalker = @import("SIWalker.zig").solarisWalker;

const solarisCPU = @import("SICpu.zig").solarisCPU;
const solarisControl = @import("SIControl.zig").solarisControl;
const solarisOpHash = @import("SIOpHash.zig").solarisOpHash;
const solarisOpCode = @import("SIOpCode.zig").solarisOpCode;
const solarisOpCodeTemplate = @import("SIOpCode.zig").solarisOpCodeTemplate;

const solarisRuntime = @import("SIRuntime.zig");

pub fn edge_case() !void {
    var arenaAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arenaAllocator.deinit();

    var growable = solarisList.new(arenaAllocator.allocator());

    // now thats a lot of data!
    for (0..1500) |i| {
        growable.append(@intCast(i));
    }

    var walker = solarisWalker.start(&growable);

    var curr = walker.now();

    while (curr != null) {
        curr = walker.next();
    }
}

pub fn edge_case2() !void {
    var arenaAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arenaAllocator.deinit();

    var cpu = solarisCPU.init(arenaAllocator.allocator());

    var section = cpu.addSection(1);

    var bytes = cpu.cmalloc(2, i32);

    bytes.?[0] = 1;
    bytes.?[1] = 2;

    section.?.unload(bytes.?[0..]);
}

pub fn test_opcode_1(cpu: *solarisCPU, walker: *solarisWalker) void {
    const arg1 = walker.next();

    std.debug.print("test_opcode_1 {any}\n", .{arg1});

    cpu.push(1);
}

pub fn test_opcode_2(cpu: *solarisCPU, walker: *solarisWalker) void {
    _ = cpu;

    const arg1 = walker.next();

    std.debug.print("test_opcode_2 {any}\n", .{arg1});
}

pub fn edge_case3() !void {
    var arenaAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arenaAllocator.deinit();

    var cpu = solarisCPU.init(arenaAllocator.allocator());

    var opHash = solarisOpHash.init(arenaAllocator.allocator());

    opHash.put(solarisOpCode.init(1, test_opcode_1));

    opHash.put(solarisOpCode.init(2, test_opcode_2));

    var bytes = [_]i32{ 1, 2 };

    var control = solarisControl.init(&cpu, &opHash);

    control.executeBytecode(&bytes);
}

pub fn edge_case4() !void {
    var arenaAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arenaAllocator.deinit();

    var cpu = solarisCPU.init(arenaAllocator.allocator());

    var opHash = solarisOpHash.init(arenaAllocator.allocator());

    solarisRuntime.solarisLoadRuntime(&opHash);

    var bytes = [_]i32{
        0xC0, 1, 2, // cmp R1,R2
        
        0xAB, // je
        40, 0x41, // ECHO A
        0xEF, // ENDEQ

        0xAC, // jne
        40, 0x42, // ECHO B
        0xEF, // ENDEQ
        
    };

    var control = solarisControl.init(&cpu, &opHash);

    control.executeBytecode(&bytes);
}

pub fn main() !void {
    try edge_case();
    try edge_case2();
    try edge_case3();
    try edge_case4();
}
