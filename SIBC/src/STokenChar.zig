// $Id: STokenChar.zig

const std = @import("std");

/// `_start:`
pub const S_TOKEN_SUBROUTINE_HEADER: u8 = ':';

/// `mov a,b`
pub const S_TOKEN_PARAM_SEPARATOR: u8 = ',';

/// `; <comment>`
pub const S_TOKEN_COMMENT_START: u8 = ';';

/// `[<directive> <args...>]`
pub const S_TOKEN_DIRECTIVE_START: u8 = '[';
pub const S_TOKEN_DIRECTIVE_END: u8 = ']';
