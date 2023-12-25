// $Id: SValue.zig

const std = @import("std");
const mem = std.mem;
const trim = std.mem.trim;

const Allocator = std.mem.Allocator;

/// Types in LR Assembly
pub const s_ValueType = enum {
    number,
    nil,
    none,
};

/// LR Assembly has a very simple type system.
pub const s_Value = struct {
    int: i32 = 0,
    nil: bool = false,

    _type: s_ValueType = s_ValueType.none,

    /// Create a new s_Value, with the type set to nil.
    pub fn initNil() s_Value {
        return s_Value{
            ._type = s_ValueType.nil,
            .nil = true,
        };
    }

    /// Returns `true` if the type is nil,
    ///
    /// This also returns true for absence containers,
    /// or values set to a type of something else, with
    /// a value of nil.
    pub fn isNil(self: s_Value) bool {
        return self._type == s_ValueType.nil or self.nil;
    }

    /// Returns `true` if the type is number.
    pub fn isNumber(self: s_Value) bool {
        return self._type == .number;
    }

    /// Returns the value as a number.
    pub fn asNumber(self: s_Value) i32 {
        return self.int;
    }

    /// Set the type and value to nil.
    pub fn setNil(self: *s_Value) void {
        self.nil = true;
        self._type = .nil;
    }

    /// Sets the type and value.
    ///
    /// NOTE: this does get rid of nil types
    /// if they are set.
    pub fn set(self: *s_Value, comptime T: type, value: T) void {
        if (self.isNil()) {
            self.nil = false;
            self._type = .none;
        }

        switch (T) {
            i32 => {
                self._type = s_ValueType.number;
                self.int = @intCast(value);
            },
            u8 => {
                self._type = s_ValueType.number;
                self.int = value;
            },
            else => {
                @panic("set() not implemented for type " ++ @typeName(T));
            },
        }
    }

    /// Converts a given string to s_Value
    pub fn from(str_normal: []const u8) s_Value {
        const isAlpha = std.ascii.isAlphabetic;

        const str = trim(u8, str_normal, " ");

        if (str.len == 0 or std.mem.eql(u8, str, "nil")) {
            return s_Value.initNil();
        }

        if (isAlpha(str[0]) and str[0] != 'R') {
            var value = s_Value.initNil();
            value.set(u8, str[0]);
            return value;
        } else if (str[0] == 'R') {
            return s_Value{ ._type = s_ValueType.number, .int = std.fmt.parseInt(i32, str[1..], 0) catch {
                @panic("malformed number");
            } };
        }
        else if (str[0] == '\'') { // char literal
            return s_Value{ ._type = s_ValueType.number, .int = @intCast(str[1]) };
        }

        return s_Value{ ._type = s_ValueType.number, .int = std.fmt.parseInt(i32, str, 0) catch {
            @panic("malformed number");
        } };
    }

    /// Returns self._type
    pub fn getType(self: s_Value) s_ValueType {
        return self._type;
    }
};
