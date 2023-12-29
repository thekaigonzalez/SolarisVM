//! The AST generation algorithm.
//!
//! Can transform standard LR Assembly into a more computer-readable form.
//!
//! * **Directives**: ✅
//! * **Subroutines**: ✅
//! * **Instructions**: ✅
//!

// $Id: Sast.zig

const std = @import("std");
const ascii = std.ascii;

const mem = std.mem;

const s_TokenCharacters = @import("STokenChar.zig");

const Allocator = std.mem.Allocator;

// sample LR Assembly code
//
// _start:
//    mov R0, 0
//    mov R1, 1
//    mov R2, 2
//    mov R3, 3
//    mov R4, 4
//    mov R5, 5
//    mov R6, 6
//    etc.

// all ASTs look like this:
// ASTNode1
//   id
//   type
//   nodes
// ASTNode2
//   id
//   type
//   nodes
// ASTNode3
//   id
//   type
//   nodes
// ...
// node1 is a subroutine definition, and every node inside of it is a statement call.

/// Node Types define how each node is structured, and how their properties are
/// meant to be accessed.
pub const s_NodeType = enum {
    /// this means the .nodes attribute will contain every ASTNode inside of it,
    /// calls, etc.
    ast_subroutine_header_def,

    /// This means the .nodes attribute will contain parameters, etc.
    ast_instruction_call,

    /// A value
    ast_value,

    /// The root node.
    ast_root,

    /// A directive, these are ignored by codegen
    ///
    /// Allows you to specify a certain engine that
    /// the compiler must follow suite for.
    ///
    /// Example:
    ///
    /// ```asm
    /// [compat <target>]
    /// [compat nexfuse]
    /// [compat mercury]
    /// [compat solaris]
    /// [compat openlud]
    /// [compat std]
    /// [compat any]
    ///
    /// <code here...>
    /// ```
    ast_directive,

    /// A directive parameter
    ast_directive_param,

    /// Keywords
    ///
    /// used for things like `extern`-ing labels
    ///
    /// ```zig
    /// extern abc
    ///
    /// _start:
    ///     jmp abc
    ///
    /// abc:
    ///     mov R0, 0
    /// ```
    ast_keyword,
};

/// Contains 3 fields - `_id`, `_type`, and `_nodes`.
///
/// The `_nodes` field is an array of s_Node, which can be anything
/// from calls to definitions, etc.
pub const s_Node = struct {
    _id: []const u8,
    _type: s_NodeType,
    _nodes: std.ArrayList(s_Node),

    pub fn setId(self: *s_Node, id: []const u8) void {
        self._id = id;
    }

    pub fn setType(self: *s_Node, typee: s_NodeType) void {
        self._type = typee;
    }

    pub fn appendNode(self: *s_Node, node: s_Node) void {
        self._nodes.append(node) catch {
            @panic("error appending node");
        };
    }
};

fn isSymbol(c: u8) bool {
    const symbols = "!@#$%^*()=[]{}|./<>?";

    return std.mem.containsAtLeast(u8, symbols, 1, &[_]u8{c});
}

/// An abstract syntax tree.
///
/// ***NOTE***: allocate this with primarily an Arena Allocator,
/// Any other allocator will cause headaches.
pub const s_AST = struct {
    _root: s_Node = undefined,

    pub fn init(arena_allocator: std.mem.Allocator) s_AST {
        return s_AST{ ._root = s_Node{
            ._nodes = std.ArrayList(s_Node).init(arena_allocator),
            ._id = "root",
            ._type = s_NodeType.ast_root,
        } };
    }

    pub fn nodes(self: s_AST) std.ArrayList(s_Node) {
        return self._root._nodes;
    }
};

pub fn lexerError(
    allocator: Allocator,
    code: []const u8,
    lineno: u32,
    charno: u32,
    comptime message: []const u8,
    fmt: anytype,
) void {
    _ = allocator;
    std.debug.print("({d}:{d}) \x1b[31merror:\x1b[0m ", .{ lineno, charno });
    std.debug.print(message, fmt);
    std.debug.print("\n", .{});

    // magenta is \x
    std.debug.print("\x1b[35;1mnote:\x1b[0m in source code:\n", .{});

    // try to print a gcc-style error message
    // with the same line the error occurred on and the line above

    var scal = std.mem.splitScalar(u8, code, '\n');

    var n: i32 = 1;

    while (scal.next()) |line| {
        if (n == lineno) {
            std.debug.print("    {d}   |    {s}\n", .{ n, line });
            std.debug.print("         ", .{});

            std.debug.print(" ", .{});

            for (0..charno) |_| {
                std.debug.print(" ", .{});
            }

            std.debug.print("  \x1b[31m^", .{});

            for (charno..line.len) |_| {
                std.debug.print("~", .{});
            }

            std.debug.print("\x1b[0m\n", .{});
        }
        n += 1;
    }

    std.os.exit(1);
}

pub fn s_generateASTFromCode(allocator: Allocator, code: []const u8) s_AST {
    var ast = s_AST.init(allocator);

    var i: u32 = 0;
    var pc: i32 = 0; // program counter, for keeping track of where we are in the code
    var last_pc: i32 = 0;

    var lineno: u32 = 1;
    var charno: u32 = 0;

    var current_node: *s_Node = &ast._root;
    var last_node: *s_Node = &ast._root;

    var comment = false;

    var buffer = std.ArrayList(u8).init(allocator);

    while (i < code.len) : (i += 1) {
        charno += 1;

        if (code[i] == '\n') {
            lineno += 1;
            charno = 0;
        }

        if (code[i] == s_TokenCharacters.S_TOKEN_COMMENT_START and pc == 1) {
            lexerError(allocator, code, lineno, charno, "inline comments are not allowed", .{});
        }

        if (code[i] == s_TokenCharacters.S_TOKEN_SUBROUTINE_HEADER and pc == 0) {
            current_node = &ast._root;

            const nod = s_Node{
                ._id = buffer.toOwnedSlice() catch {
                    @panic("out of memory");
                },
                ._type = s_NodeType.ast_subroutine_header_def,
                ._nodes = std.ArrayList(s_Node).init(allocator),
            };

            current_node.appendNode(nod);

            current_node = &current_node._nodes.items[current_node._nodes.items.len - 1];
        } else if ((ascii.isWhitespace(code[i]) or code[i] == '\n') and pc == 0 and buffer.items.len > 0) {
            // a instruction call
            const nod = s_Node{
                ._id = buffer.toOwnedSlice() catch {
                    @panic("out of memory");
                },
                ._type = s_NodeType.ast_instruction_call,
                ._nodes = std.ArrayList(s_Node).init(allocator),
            };

            current_node.appendNode(nod);

            if (code[i] != '\n') {
                last_node = current_node;
                current_node = &current_node._nodes.items[current_node._nodes.items.len - 1];

                pc = 1;
            }

            buffer.clearRetainingCapacity();
        } else if ((code[i] == s_TokenCharacters.S_TOKEN_PARAM_SEPARATOR or code[i] == '\n' or i + 1 >= code.len) and pc == 1 and buffer.items.len > 0) {
            if (code[i] == '\n' or i + 1 >= code.len) {
                if (!ascii.isWhitespace(code[i])) {
                    buffer.append(code[i]) catch {
                        @panic("out of memory");
                    };
                }
            }

            const nod = s_Node{
                ._id = buffer.toOwnedSlice() catch {
                    @panic("out of memory");
                },
                ._type = s_NodeType.ast_value,
                ._nodes = std.ArrayList(s_Node).init(allocator),
            };

            current_node.appendNode(nod);

            if (code[i] == '\n' or i + 1 >= code.len) {
                buffer.clearRetainingCapacity();
                pc = 0;
                current_node = last_node;
            }
        } else if (code[i] == s_TokenCharacters.S_TOKEN_DIRECTIVE_START and pc == 0) { // [compat <target>], etc. Directives
            pc = 3;

            buffer.clearRetainingCapacity();
        } else if (ascii.isWhitespace(code[i]) and pc == 3 and buffer.items.len > 0) {
            const nod = s_Node{
                ._id = buffer.toOwnedSlice() catch {
                    @panic("out of memory");
                },
                ._type = s_NodeType.ast_directive,
                ._nodes = std.ArrayList(s_Node).init(allocator),
            };

            current_node.appendNode(nod);

            last_node = current_node;
            current_node = &current_node._nodes.items[current_node._nodes.items.len - 1];

            pc = 4;
        } else if ((ascii.isWhitespace(code[i]) or code[i] == s_TokenCharacters.S_TOKEN_DIRECTIVE_END) and pc == 4 and buffer.items.len > 0) {
            const nod = s_Node{
                ._id = buffer.toOwnedSlice() catch {
                    @panic("out of memory");
                },
                ._type = s_NodeType.ast_value,
                ._nodes = std.ArrayList(s_Node).init(allocator),
            };

            current_node.appendNode(nod);

            buffer.clearRetainingCapacity();

            if (code[i] == s_TokenCharacters.S_TOKEN_DIRECTIVE_END) {
                pc = 0;
                current_node = last_node;
            }
        } else {
            if (code[i] == '\n' and comment) {
                comment = false;
                buffer.clearRetainingCapacity();
                pc = last_pc;
            }

            if (code[i] == s_TokenCharacters.S_TOKEN_COMMENT_START) {
                comment = true;
                last_pc = pc;
                pc = -1;
                buffer.clearRetainingCapacity();
            }

            if (!comment) {
                if (!ascii.isWhitespace(code[i])) {
                    buffer.append(code[i]) catch {
                        @panic("out of memory");
                    };
                }

                if (!ascii.isASCII(code[i])) {
                    lexerError(allocator, code, lineno, charno, "characetr has no valid representation: `{c}'", .{code[i]});
                }

                if (code[i] == s_TokenCharacters.S_TOKEN_COMMENT_START and pc == 1) {
                    lexerError(allocator, code, lineno, charno, "inline comments are not allowed", .{});
                }

                if (ascii.isWhitespace(code[i]) and pc == 1 and buffer.items.len > 0) {
                    lexerError(allocator, code, lineno, charno, "this could be incorrect. Bash-style arguments are not allowed", .{});
                }

                if (isSymbol(code[i])) {
                    lexerError(allocator, code, lineno, charno, "symbols are not allowed in this context, are you missing a \x1b[1m'\x1b[0m ?", .{});
                }
            }
        }
    }

    return ast;
}

pub fn s_printAST(ast: s_AST) void {
    std.debug.print("(ast root node name - {s})\n", .{ast._root._id});
    for (0..ast.nodes().items.len) |i| {
        printNode(ast.nodes().items[i]);
    }
}

fn printNode(node: s_Node) void {
    std.debug.print("(node name - {s})\n", .{node._id});
    std.debug.print("id: {s}\n", .{node._id});
    std.debug.print("type: {s}\n", .{@tagName(node._type)});

    std.debug.print("(begin sub-nodes)\n", .{});
    for (0..node._nodes.items.len) |i| {
        printNode(node._nodes.items[i]);
    }
    std.debug.print("(end sub-nodes)\n", .{});
}

pub fn printASTPretty(ast: s_AST) void {
    for (0..ast.nodes().items.len) |i| {
        printNodePretty(ast.nodes().items[i]);
    }
}

fn printNodePretty(node: s_Node) void {
    switch (node._type) {
        .ast_subroutine_header_def => {
            std.debug.print("\n{s}:\n", .{node._id});

            for (0..node._nodes.items.len) |i| {
                printNodePretty(node._nodes.items[i]);
            }
        },
        .ast_instruction_call => {
            std.debug.print("\n  {s} ", .{node._id});
            for (0..node._nodes.items.len) |i| {
                printNodePretty(node._nodes.items[i]);
            }
        },
        .ast_value => {
            std.debug.print("{s} ", .{node._id});
        },
        else => {},
    }
}
