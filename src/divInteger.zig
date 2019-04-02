const std = @import("std");
const T = std.testing;

pub const DivPair = struct {
    quotient: i32,
    modulus: i32,
};

pub const divisionOp = fn (dividend: i32, divisor: i32) DivPair;

pub fn signFlag(val: i32) u1 {
    if (val < 0) {
        return 1;
    } else {
        return 0;
    }
}

pub fn abs(val: i32) i32 {
    if (val < 0) {
        return -val;
    } else {
        return val;
    }
}

/// flooredDivision is defined as q = floor(a/n)
/// The quotient is always rounded downward, even if it is negative.
pub fn flooredDivision(dividend: i32, divisor: i32) DivPair {
    const s_divisor = signFlag(divisor);
    const abs_divisor = abs(divisor);
    var m: i32 = @rem(abs(dividend), abs_divisor);
    var d = dividend;
    if (m != 0 and signFlag(dividend) ^ s_divisor != 0) {
        d -= divisor;
        m = abs_divisor - m;
    }
    return DivPair{
        .quotient = @divTrunc(d, divisor),
        .modulus = switch (s_divisor) {
            1 => -m,
            0 => m,
        },
    };
}

/// truncatedDivision is defined as q = truncate(a/n). 
/// q will remain zero for -n < a < n.
/// m always has the sign of the divisor.
pub fn truncatedDivision(dividend: i32, divisor: i32) DivPair {
    const abs_divisor = abs(divisor);
    const s_dividend = signFlag(dividend);
    const abs_dividend = abs(dividend);
    const q: i32 = @divTrunc(abs_dividend, abs_divisor);
    const m: i32 = @rem(abs_dividend, abs_divisor);
    return DivPair{
        .quotient = switch (signFlag(divisor) ^ s_dividend) {
            1 => -q,
            0 => q,
        },
        .modulus = switch (s_dividend) {
            1 => -m,
            0 => m,
        },
    };
}

/// euclideanDivision is defined as: q = floor(a/n), for n > 0; and q = ceil(a/n) for n < 0.
/// The modulus is always 0 <= m < n.
pub fn euclideanDivision(dividend: i32, divisor: i32) DivPair {
    const abs_divisor = abs(divisor);
    var m: i32 = @rem(abs(dividend), abs_divisor);
    var q: i32 = @divTrunc(dividend, divisor);
    if (m != 0) {
        if (signFlag(dividend) == 1) {
            m = abs_divisor - m;
            if (signFlag(divisor) == 1) {
                q += 1;
            } else {
                q -= 1;
            }
        }
    }
    return DivPair{
        .quotient = q,
        .modulus = m,
    };
}

test "flooredDivision quick" {
    var di = flooredDivision(10, 12);
    T.expectEqual(i32(10), di.modulus);
    T.expectEqual(i32(0), di.quotient);
    di = flooredDivision(-14, 12);
    T.expectEqual(i32(10), di.modulus);
    T.expectEqual(i32(-2), di.quotient);
    di = flooredDivision(-2, 12);
    T.expectEqual(i32(10), di.modulus);
    T.expectEqual(i32(-1), di.quotient);
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
        const di = flooredDivision(elem.N, elem.D);
        T.expectEqual(elem.Q, di.quotient);
        T.expectEqual(elem.M, di.modulus);
    }
}

test "integer division" {
    const IdtElem = struct {
        a: i32,
        n: i32,
        q: i32,
        r: i32,
    };
    const IdtPass = struct {
        op: divisionOp,
        table: []const IdtElem,
    };
    const idtTable = []IdtPass{
        IdtPass{
            .op = truncatedDivision,
            .table = []IdtElem{
                IdtElem{
                    .a = -10,
                    .n = 3,
                    .q = -3,
                    .r = -1,
                },
                IdtElem{
                    .a = -9,
                    .n = 3,
                    .q = -3,
                    .r = 0,
                },
                IdtElem{
                    .a = -8,
                    .n = 3,
                    .q = -2,
                    .r = -2,
                },
                IdtElem{
                    .a = -7,
                    .n = 3,
                    .q = -2,
                    .r = -1,
                },
                IdtElem{
                    .a = -6,
                    .n = 3,
                    .q = -2,
                    .r = 0,
                },
                IdtElem{
                    .a = -5,
                    .n = 3,
                    .q = -1,
                    .r = -2,
                },
                IdtElem{
                    .a = -4,
                    .n = 3,
                    .q = -1,
                    .r = -1,
                },
                IdtElem{
                    .a = -3,
                    .n = 3,
                    .q = -1,
                    .r = 0,
                },
                IdtElem{
                    .a = -2,
                    .n = 3,
                    .q = 0,
                    .r = -2,
                },
                IdtElem{
                    .a = -1,
                    .n = 3,
                    .q = 0,
                    .r = -1,
                },
                IdtElem{
                    .a = 0,
                    .n = 3,
                    .q = 0,
                    .r = 0,
                },
                IdtElem{
                    .a = 1,
                    .n = 3,
                    .q = 0,
                    .r = 1,
                },
                IdtElem{
                    .a = 2,
                    .n = 3,
                    .q = 0,
                    .r = 2,
                },
                IdtElem{
                    .a = 3,
                    .n = 3,
                    .q = 1,
                    .r = 0,
                },
                IdtElem{
                    .a = 4,
                    .n = 3,
                    .q = 1,
                    .r = 1,
                },
                IdtElem{
                    .a = 5,
                    .n = 3,
                    .q = 1,
                    .r = 2,
                },
                IdtElem{
                    .a = 6,
                    .n = 3,
                    .q = 2,
                    .r = 0,
                },
                IdtElem{
                    .a = 7,
                    .n = 3,
                    .q = 2,
                    .r = 1,
                },
                IdtElem{
                    .a = 8,
                    .n = 3,
                    .q = 2,
                    .r = 2,
                },
                IdtElem{
                    .a = 9,
                    .n = 3,
                    .q = 3,
                    .r = 0,
                },
                IdtElem{
                    .a = 10,
                    .n = 3,
                    .q = 3,
                    .r = 1,
                },
                IdtElem{
                    .a = -10,
                    .n = -3,
                    .q = 3,
                    .r = -1,
                },
                IdtElem{
                    .a = -9,
                    .n = -3,
                    .q = 3,
                    .r = 0,
                },
                IdtElem{
                    .a = -8,
                    .n = -3,
                    .q = 2,
                    .r = -2,
                },
                IdtElem{
                    .a = -7,
                    .n = -3,
                    .q = 2,
                    .r = -1,
                },
                IdtElem{
                    .a = -6,
                    .n = -3,
                    .q = 2,
                    .r = 0,
                },
                IdtElem{
                    .a = -5,
                    .n = -3,
                    .q = 1,
                    .r = -2,
                },
                IdtElem{
                    .a = -4,
                    .n = -3,
                    .q = 1,
                    .r = -1,
                },
                IdtElem{
                    .a = -3,
                    .n = -3,
                    .q = 1,
                    .r = 0,
                },
                IdtElem{
                    .a = -2,
                    .n = -3,
                    .q = 0,
                    .r = -2,
                },
                IdtElem{
                    .a = -1,
                    .n = -3,
                    .q = 0,
                    .r = -1,
                },
                IdtElem{
                    .a = 0,
                    .n = -3,
                    .q = 0,
                    .r = 0,
                },
                IdtElem{
                    .a = 1,
                    .n = -3,
                    .q = 0,
                    .r = 1,
                },
                IdtElem{
                    .a = 2,
                    .n = -3,
                    .q = 0,
                    .r = 2,
                },
                IdtElem{
                    .a = 3,
                    .n = -3,
                    .q = -1,
                    .r = 0,
                },
                IdtElem{
                    .a = 4,
                    .n = -3,
                    .q = -1,
                    .r = 1,
                },
                IdtElem{
                    .a = 5,
                    .n = -3,
                    .q = -1,
                    .r = 2,
                },
                IdtElem{
                    .a = 6,
                    .n = -3,
                    .q = -2,
                    .r = 0,
                },
                IdtElem{
                    .a = 7,
                    .n = -3,
                    .q = -2,
                    .r = 1,
                },
                IdtElem{
                    .a = 8,
                    .n = -3,
                    .q = -2,
                    .r = 2,
                },
                IdtElem{
                    .a = 9,
                    .n = -3,
                    .q = -3,
                    .r = 0,
                },
                IdtElem{
                    .a = 10,
                    .n = -3,
                    .q = -3,
                    .r = 1,
                },
            },
        },
        IdtPass{
            .op = flooredDivision,
            .table = []IdtElem{
                IdtElem{
                    .a = -10,
                    .n = 3,
                    .q = -4,
                    .r = 2,
                },
                IdtElem{
                    .a = -9,
                    .n = 3,
                    .q = -3,
                    .r = 0,
                },
                IdtElem{
                    .a = -8,
                    .n = 3,
                    .q = -3,
                    .r = 1,
                },
                IdtElem{
                    .a = -7,
                    .n = 3,
                    .q = -3,
                    .r = 2,
                },
                IdtElem{
                    .a = -6,
                    .n = 3,
                    .q = -2,
                    .r = 0,
                },
                IdtElem{
                    .a = -5,
                    .n = 3,
                    .q = -2,
                    .r = 1,
                },
                IdtElem{
                    .a = -4,
                    .n = 3,
                    .q = -2,
                    .r = 2,
                },
                IdtElem{
                    .a = -3,
                    .n = 3,
                    .q = -1,
                    .r = 0,
                },
                IdtElem{
                    .a = -2,
                    .n = 3,
                    .q = -1,
                    .r = 1,
                },
                IdtElem{
                    .a = -1,
                    .n = 3,
                    .q = -1,
                    .r = 2,
                },
                IdtElem{
                    .a = 0,
                    .n = 3,
                    .q = 0,
                    .r = 0,
                },
                IdtElem{
                    .a = 1,
                    .n = 3,
                    .q = 0,
                    .r = 1,
                },
                IdtElem{
                    .a = 2,
                    .n = 3,
                    .q = 0,
                    .r = 2,
                },
                IdtElem{
                    .a = 3,
                    .n = 3,
                    .q = 1,
                    .r = 0,
                },
                IdtElem{
                    .a = 4,
                    .n = 3,
                    .q = 1,
                    .r = 1,
                },
                IdtElem{
                    .a = 5,
                    .n = 3,
                    .q = 1,
                    .r = 2,
                },
                IdtElem{
                    .a = 6,
                    .n = 3,
                    .q = 2,
                    .r = 0,
                },
                IdtElem{
                    .a = 7,
                    .n = 3,
                    .q = 2,
                    .r = 1,
                },
                IdtElem{
                    .a = 8,
                    .n = 3,
                    .q = 2,
                    .r = 2,
                },
                IdtElem{
                    .a = 9,
                    .n = 3,
                    .q = 3,
                    .r = 0,
                },
                IdtElem{
                    .a = 10,
                    .n = 3,
                    .q = 3,
                    .r = 1,
                },
                IdtElem{
                    .a = -10,
                    .n = -3,
                    .q = 3,
                    .r = -1,
                },
                IdtElem{
                    .a = -9,
                    .n = -3,
                    .q = 3,
                    .r = 0,
                },
                IdtElem{
                    .a = -8,
                    .n = -3,
                    .q = 2,
                    .r = -2,
                },
                IdtElem{
                    .a = -7,
                    .n = -3,
                    .q = 2,
                    .r = -1,
                },
                IdtElem{
                    .a = -6,
                    .n = -3,
                    .q = 2,
                    .r = 0,
                },
                IdtElem{
                    .a = -5,
                    .n = -3,
                    .q = 1,
                    .r = -2,
                },
                IdtElem{
                    .a = -4,
                    .n = -3,
                    .q = 1,
                    .r = -1,
                },
                IdtElem{
                    .a = -3,
                    .n = -3,
                    .q = 1,
                    .r = 0,
                },
                IdtElem{
                    .a = -2,
                    .n = -3,
                    .q = 0,
                    .r = -2,
                },
                IdtElem{
                    .a = -1,
                    .n = -3,
                    .q = 0,
                    .r = -1,
                },
                IdtElem{
                    .a = 0,
                    .n = -3,
                    .q = 0,
                    .r = 0,
                },
                IdtElem{
                    .a = 1,
                    .n = -3,
                    .q = -1,
                    .r = -2,
                },
                IdtElem{
                    .a = 2,
                    .n = -3,
                    .q = -1,
                    .r = -1,
                },
                IdtElem{
                    .a = 3,
                    .n = -3,
                    .q = -1,
                    .r = 0,
                },
                IdtElem{
                    .a = 4,
                    .n = -3,
                    .q = -2,
                    .r = -2,
                },
                IdtElem{
                    .a = 5,
                    .n = -3,
                    .q = -2,
                    .r = -1,
                },
                IdtElem{
                    .a = 6,
                    .n = -3,
                    .q = -2,
                    .r = 0,
                },
                IdtElem{
                    .a = 7,
                    .n = -3,
                    .q = -3,
                    .r = -2,
                },
                IdtElem{
                    .a = 8,
                    .n = -3,
                    .q = -3,
                    .r = -1,
                },
                IdtElem{
                    .a = 9,
                    .n = -3,
                    .q = -3,
                    .r = 0,
                },
                IdtElem{
                    .a = 10,
                    .n = -3,
                    .q = -4,
                    .r = -2,
                },
            },
        },
        IdtPass{
            .op = euclideanDivision,
            .table = []IdtElem{
                IdtElem{
                    .a = -10,
                    .n = 3,
                    .q = -4,
                    .r = 2,
                },
                IdtElem{
                    .a = -9,
                    .n = 3,
                    .q = -3,
                    .r = 0,
                },
                IdtElem{
                    .a = -8,
                    .n = 3,
                    .q = -3,
                    .r = 1,
                },
                IdtElem{
                    .a = -7,
                    .n = 3,
                    .q = -3,
                    .r = 2,
                },
                IdtElem{
                    .a = -6,
                    .n = 3,
                    .q = -2,
                    .r = 0,
                },
                IdtElem{
                    .a = -5,
                    .n = 3,
                    .q = -2,
                    .r = 1,
                },
                IdtElem{
                    .a = -4,
                    .n = 3,
                    .q = -2,
                    .r = 2,
                },
                IdtElem{
                    .a = -3,
                    .n = 3,
                    .q = -1,
                    .r = 0,
                },
                IdtElem{
                    .a = -2,
                    .n = 3,
                    .q = -1,
                    .r = 1,
                },
                IdtElem{
                    .a = -1,
                    .n = 3,
                    .q = -1,
                    .r = 2,
                },
                IdtElem{
                    .a = 0,
                    .n = 3,
                    .q = 0,
                    .r = 0,
                },
                IdtElem{
                    .a = 1,
                    .n = 3,
                    .q = 0,
                    .r = 1,
                },
                IdtElem{
                    .a = 2,
                    .n = 3,
                    .q = 0,
                    .r = 2,
                },
                IdtElem{
                    .a = 3,
                    .n = 3,
                    .q = 1,
                    .r = 0,
                },
                IdtElem{
                    .a = 4,
                    .n = 3,
                    .q = 1,
                    .r = 1,
                },
                IdtElem{
                    .a = 5,
                    .n = 3,
                    .q = 1,
                    .r = 2,
                },
                IdtElem{
                    .a = 6,
                    .n = 3,
                    .q = 2,
                    .r = 0,
                },
                IdtElem{
                    .a = 7,
                    .n = 3,
                    .q = 2,
                    .r = 1,
                },
                IdtElem{
                    .a = 8,
                    .n = 3,
                    .q = 2,
                    .r = 2,
                },
                IdtElem{
                    .a = 9,
                    .n = 3,
                    .q = 3,
                    .r = 0,
                },
                IdtElem{
                    .a = 10,
                    .n = 3,
                    .q = 3,
                    .r = 1,
                },
                IdtElem{
                    .a = -10,
                    .n = -3,
                    .q = 4,
                    .r = 2,
                },
                IdtElem{
                    .a = -9,
                    .n = -3,
                    .q = 3,
                    .r = 0,
                },
                IdtElem{
                    .a = -8,
                    .n = -3,
                    .q = 3,
                    .r = 1,
                },
                IdtElem{
                    .a = -7,
                    .n = -3,
                    .q = 3,
                    .r = 2,
                },
                IdtElem{
                    .a = -6,
                    .n = -3,
                    .q = 2,
                    .r = 0,
                },
                IdtElem{
                    .a = -5,
                    .n = -3,
                    .q = 2,
                    .r = 1,
                },
                IdtElem{
                    .a = -4,
                    .n = -3,
                    .q = 2,
                    .r = 2,
                },
                IdtElem{
                    .a = -3,
                    .n = -3,
                    .q = 1,
                    .r = 0,
                },
                IdtElem{
                    .a = -2,
                    .n = -3,
                    .q = 1,
                    .r = 1,
                },
                IdtElem{
                    .a = -1,
                    .n = -3,
                    .q = 1,
                    .r = 2,
                },
                IdtElem{
                    .a = 0,
                    .n = -3,
                    .q = 0,
                    .r = 0,
                },
                IdtElem{
                    .a = 1,
                    .n = -3,
                    .q = 0,
                    .r = 1,
                },
                IdtElem{
                    .a = 2,
                    .n = -3,
                    .q = 0,
                    .r = 2,
                },
                IdtElem{
                    .a = 3,
                    .n = -3,
                    .q = -1,
                    .r = 0,
                },
                IdtElem{
                    .a = 4,
                    .n = -3,
                    .q = -1,
                    .r = 1,
                },
                IdtElem{
                    .a = 5,
                    .n = -3,
                    .q = -1,
                    .r = 2,
                },
                IdtElem{
                    .a = 6,
                    .n = -3,
                    .q = -2,
                    .r = 0,
                },
                IdtElem{
                    .a = 7,
                    .n = -3,
                    .q = -2,
                    .r = 1,
                },
                IdtElem{
                    .a = 8,
                    .n = -3,
                    .q = -2,
                    .r = 2,
                },
                IdtElem{
                    .a = 9,
                    .n = -3,
                    .q = -3,
                    .r = 0,
                },
                IdtElem{
                    .a = 10,
                    .n = -3,
                    .q = -3,
                    .r = 1,
                },
            },
        },
    };
    for (idtTable) |pass| {
        for (pass.table) |testcase| {
            const pair = pass.op(testcase.a, testcase.n);
            const a2 = testcase.n * pair.quotient + pair.modulus;
            T.expectEqual(testcase.a, a2);
            T.expectEqual(testcase.q, pair.quotient);
            T.expectEqual(testcase.r, pair.modulus);
        }
    }
}
