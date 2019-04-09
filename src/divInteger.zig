const std = @import("std");
const testing = std.testing;
const TypeId = @import("builtin").TypeId;
const TypeInfo = @import("builtin").TypeInfo;

pub fn DivPair(comptime T: type) type {
    return struct {
        quotient: T,
        modulus: T,
    };
}

pub fn signFlag(comptime T: type, val: T) u1 {
    if (@typeId(T) != TypeId.Int) {
        @compileError("signFlag requires an integer type");
    }
    if (@typeInfo(T).Int.is_signed) {
        if (val < 0) {
            return 1; 
        } else {
            return 0;
        }
    } else {
        return 0;
    }
}

pub fn abs(comptime T: type, val: T) T {
    if (@typeId(T) != TypeId.Int) {
        @compileError("abs requires an integer type");
    }
    if (@typeInfo(T).Int.is_signed) {
        if (val < 0) {
            return -val;
        } else {
            return val;
        }
    } else {
        return val;
    }
}

/// flooredDivision is defined as q = floor(a/n)
/// The quotient is always rounded downward, even if it is negative.
pub fn flooredDivision(comptime T: type, dividend: T, divisor: T) DivPair(T) {
    if (@typeId(T) != TypeId.Int) {
        @compileError("flooredDivision requires an integer type");
    }
    const s_divisor = signFlag(T, divisor);
    const abs_divisor = abs(T, divisor);
    var m: T = @rem(abs(T, dividend), abs_divisor);
    var d = dividend;
    if (m != 0 and signFlag(T, dividend) ^ s_divisor != 0) {
        d -= divisor;
        m = abs_divisor - m;
    }
    return DivPair(T){
        .quotient = @divTrunc(d, divisor),
        .modulus = if (s_divisor != 0) -m else m,
    };
}

/// truncatedDivision is defined as q = truncate(a/n). 
/// q will remain zero for -n < a < n.
/// m always has the sign of the divisor.
pub fn truncatedDivision(comptime T: type, dividend: T, divisor: T) DivPair(T) {
    const abs_divisor = abs(T, divisor);
    const q: T = @divTrunc(dividend, abs_divisor);
    const m: T = @rem(dividend, abs_divisor);
    return DivPair(T){
        .quotient = if (signFlag(T, divisor) != 0) -q else q,
        .modulus = m,
    };
}

/// euclideanDivision is defined as: q = floor(a/n), for n > 0; and q = ceil(a/n) for n < 0.
/// The modulus is always 0 <= m < n.
pub fn euclideanDivision(comptime T: type, dividend: T, divisor: T) DivPair(T) {
    const abs_divisor = abs(T, divisor);
    var m: T = @rem(abs(T, dividend), abs_divisor);
    var q: T = @divTrunc(dividend, divisor);
    if (m != 0) {
        if (signFlag(T, dividend) == 1) {
            m = abs_divisor - m;
            if (signFlag(T, divisor) == 1) {
                q += 1;
            } else {
                q -= 1;
            }
        }
    }
    return DivPair(T){
        .quotient = q,
        .modulus = m,
    };
}

test "flooredDivision quick" {
    var di = flooredDivision(i32, 10, 12);
    testing.expectEqual(i32(10), di.modulus);
    testing.expectEqual(i32(0), di.quotient);
    di = flooredDivision(i32, -14, 12);
    testing.expectEqual(i32(10), di.modulus);
    testing.expectEqual(i32(-2), di.quotient);
    di = flooredDivision(i32, -2, 12);
    testing.expectEqual(i32(10), di.modulus);
    testing.expectEqual(i32(-1), di.quotient);
}

test "flooredDivision full" {
    const TestDivIntegerElem = struct {
        N: i32,
        D: i32,
        Q: i32,
        M: i32,
    };
    const testData = []TestDivIntegerElem{
        TestDivIntegerElem{ .N = 180, .D = 131, .Q = 1, .M = 49 },
        TestDivIntegerElem{ .N = -180, .D = 131, .Q = -2, .M = 82 },
        TestDivIntegerElem{ .N = 180, .D = -131, .Q = -2, .M = -82 },
        TestDivIntegerElem{ .N = -180, .D = -131, .Q = 1, .M = -49 },
        TestDivIntegerElem{ .N = 180, .D = 31, .Q = 5, .M = 25 },
        TestDivIntegerElem{ .N = -180, .D = 31, .Q = -6, .M = 6 },
        TestDivIntegerElem{ .N = 180, .D = -31, .Q = -6, .M = -6 },
        TestDivIntegerElem{ .N = -180, .D = -31, .Q = 5, .M = -25 },
        TestDivIntegerElem{ .N = 18, .D = 3, .Q = 6, .M = 0 },
        TestDivIntegerElem{ .N = -18, .D = 3, .Q = -6, .M = 0 },
        TestDivIntegerElem{ .N = 18, .D = -3, .Q = -6, .M = 0 },
        TestDivIntegerElem{ .N = -18, .D = -3, .Q = 6, .M = 0 },
        TestDivIntegerElem{ .N = 0, .D = -3, .Q = 0, .M = 0 },
        TestDivIntegerElem{ .N = 0, .D = -3, .Q = 0, .M = 0 },
    };
    for (testData) |elem| {
        const di = flooredDivision(i32, elem.N, elem.D);
        testing.expectEqual(elem.Q, di.quotient);
        testing.expectEqual(elem.M, di.modulus);
    }
}

const IdtIdx = enum(usize) {
    A,
    N,
    Q,
    R,
};
const truncatedTable = []const [@memberCount(IdtIdx)]i32 {
    []i32{ -10, 3, -3, -1, },
    []i32{ -9, 3, -3, 0, },
    []i32{ -8, 3, -2, -2, },
    []i32{ -7, 3, -2, -1, },
    []i32{ -6, 3, -2, 0, },
    []i32{ -5, 3, -1, -2, },
    []i32{ -4, 3, -1, -1, },
    []i32{ -3, 3, -1, 0, },
    []i32{ -2, 3, 0, -2, },
    []i32{ -1, 3, 0, -1, },
    []i32{ 0, 3, 0, 0, },
    []i32{ 1, 3, 0, 1, },
    []i32{ 2, 3, 0, 2, },
    []i32{ 3, 3, 1, 0, },
    []i32{ 4, 3, 1, 1, },
    []i32{ 5, 3, 1, 2, },
    []i32{ 6, 3, 2, 0, },
    []i32{ 7, 3, 2, 1, },
    []i32{ 8, 3, 2, 2, },
    []i32{ 9, 3, 3, 0, },
    []i32{ 10, 3, 3, 1, },
    []i32{ -10, -3, 3, -1, },
    []i32{ -9, -3, 3, 0, },
    []i32{ -8, -3, 2, -2, },
    []i32{ -7, -3, 2, -1, },
    []i32{ -6, -3, 2, 0, },
    []i32{ -5, -3, 1, -2, },
    []i32{ -4, -3, 1, -1, },
    []i32{ -3, -3, 1, 0, },
    []i32{ -2, -3, 0, -2, },
    []i32{ -1, -3, 0, -1, },
    []i32{ 0, -3, 0, 0, },
    []i32{ 1, -3, 0, 1, },
    []i32{ 2, -3, 0, 2, },
    []i32{ 3, -3, -1, 0, },
    []i32{ 4, -3, -1, 1, },
    []i32{ 5, -3, -1, 2, },
    []i32{ 6, -3, -2, 0, },
    []i32{ 7, -3, -2, 1, },
    []i32{ 8, -3, -2, 2, },
    []i32{ 9, -3, -3, 0, },
    []i32{ 10, -3, -3, 1, },
};
const flooredTable = []const [@memberCount(IdtIdx)]i32 {
    []i32{ -10, 3, -4, 2, },
    []i32{ -9, 3, -3, 0, },
    []i32{ -8, 3, -3, 1, },
    []i32{ -7, 3, -3, 2, },
    []i32{ -6, 3, -2, 0, },
    []i32{ -5, 3, -2, 1, },
    []i32{ -4, 3, -2, 2, },
    []i32{ -3, 3, -1, 0, },
    []i32{ -2, 3, -1, 1, },
    []i32{ -1, 3, -1, 2, },
    []i32{ 0, 3, 0, 0, },
    []i32{ 1, 3, 0, 1, },
    []i32{ 2, 3, 0, 2, },
    []i32{ 3, 3, 1, 0, },
    []i32{ 4, 3, 1, 1, },
    []i32{ 5, 3, 1, 2, },
    []i32{ 6, 3, 2, 0, },
    []i32{ 7, 3, 2, 1, },
    []i32{ 8, 3, 2, 2, },
    []i32{ 9, 3, 3, 0, },
    []i32{ 10, 3, 3, 1, },
    []i32{ -10, -3, 3, -1, },
    []i32{ -9, -3, 3, 0, },
    []i32{ -8, -3, 2, -2, },
    []i32{ -7, -3, 2, -1, },
    []i32{ -6, -3, 2, 0, },
    []i32{ -5, -3, 1, -2, },
    []i32{ -4, -3, 1, -1, },
    []i32{ -3, -3, 1, 0, },
    []i32{ -2, -3, 0, -2, },
    []i32{ -1, -3, 0, -1, },
    []i32{ 0, -3, 0, 0, },
    []i32{ 1, -3, -1, -2, },
    []i32{ 2, -3, -1, -1, },
    []i32{ 3, -3, -1, 0, },
    []i32{ 4, -3, -2, -2, },
    []i32{ 5, -3, -2, -1, },
    []i32{ 6, -3, -2, 0, },
    []i32{ 7, -3, -3, -2, },
    []i32{ 8, -3, -3, -1, },
    []i32{ 9, -3, -3, 0, },
    []i32{ 10, -3, -4, -2, },
};
const euclideanTable = []const [@memberCount(IdtIdx)]i32 {
    []i32{ -10, 3, -4, 2, },
    []i32{ -9, 3, -3, 0, },
    []i32{ -8, 3, -3, 1, },
    []i32{ -7, 3, -3, 2, },
    []i32{ -6, 3, -2, 0, },
    []i32{ -5, 3, -2, 1, },
    []i32{ -4, 3, -2, 2, },
    []i32{ -3, 3, -1, 0, },
    []i32{ -2, 3, -1, 1, },
    []i32{ -1, 3, -1, 2, },
    []i32{ 0, 3, 0, 0, },
    []i32{ 1, 3, 0, 1, },
    []i32{ 2, 3, 0, 2, },
    []i32{ 3, 3, 1, 0, },
    []i32{ 4, 3, 1, 1, },
    []i32{ 5, 3, 1, 2, },
    []i32{ 6, 3, 2, 0, },
    []i32{ 7, 3, 2, 1, },
    []i32{ 8, 3, 2, 2, },
    []i32{ 9, 3, 3, 0, },
    []i32{ 10, 3, 3, 1, },
    []i32{ -10, -3, 4, 2, },
    []i32{ -9, -3, 3, 0, },
    []i32{ -8, -3, 3, 1, },
    []i32{ -7, -3, 3, 2, },
    []i32{ -6, -3, 2, 0, },
    []i32{ -5, -3, 2, 1, },
    []i32{ -4, -3, 2, 2, },
    []i32{ -3, -3, 1, 0, },
    []i32{ -2, -3, 1, 1, },
    []i32{ -1, -3, 1, 2, },
    []i32{ 0, -3, 0, 0, },
    []i32{ 1, -3, 0, 1, },
    []i32{ 2, -3, 0, 2, },
    []i32{ 3, -3, -1, 0, },
    []i32{ 4, -3, -1, 1, },
    []i32{ 5, -3, -1, 2, },
    []i32{ 6, -3, -2, 0, },
    []i32{ 7, -3, -2, 1, },
    []i32{ 8, -3, -2, 2, },
    []i32{ 9, -3, -3, 0, },
    []i32{ 10, -3, -3, 1, },
};

const divisionOp = fn (type, i32, i32) DivPair(i32);

fn run(comptime op: divisionOp, comptime table: []const [@memberCount(IdtIdx)]i32) void {
    for (table) |testcase| {
        const pair = op(i32, testcase[@enumToInt(IdtIdx.A)], testcase[@enumToInt(IdtIdx.N)]);
        const a2 = testcase[@enumToInt(IdtIdx.N)] * pair.quotient + pair.modulus;
        testing.expectEqual(testcase[@enumToInt(IdtIdx.A)], a2);
        testing.expectEqual(testcase[@enumToInt(IdtIdx.Q)], pair.quotient);
        testing.expectEqual(testcase[@enumToInt(IdtIdx.R)], pair.modulus);
    }
}

test "integer division" {
    const Pair = struct {
        op: divisionOp,
        table: []const [@memberCount(IdtIdx)]i32,
    };
    const runs = []Pair{
        Pair{ .op=flooredDivision, .table=flooredTable, },
        Pair{ .op=truncatedDivision, .table=truncatedTable, },
        Pair{ .op=euclideanDivision, .table=euclideanTable, },
    };
    inline for (runs) |pass| {
        run(pass.op, pass.table);
    }
}
