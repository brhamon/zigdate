const std = @import("std");
const T = std.testing;

const DivInteger = struct {
    quotient: i32,
    modulus: i32,
};

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

pub fn divInteger(dividend: i32, divisor: i32) DivInteger {
    const s_divisor = signFlag(divisor);
    const abs_divisor = abs(divisor);
    var m: i32 = @rem(abs(dividend), abs_divisor);
    var d = dividend;
    if (m != 0 and signFlag(dividend) ^ s_divisor != 0) {
        d -= divisor;
        m = abs_divisor - m;
    }
    return DivInteger{
        .quotient = @divTrunc(d, divisor),
        .modulus = switch (s_divisor) {
            1 => -m,
            0 => m,
        },
    };
}

test "divInteger quick" {
    var di = divInteger(10, 12);
    T.expectEqual(i32(10), di.modulus);
    T.expectEqual(i32(0), di.quotient);
    di = divInteger(-14, 12);
    T.expectEqual(i32(10), di.modulus);
    T.expectEqual(i32(-2), di.quotient);
    di = divInteger(-2, 12);
    T.expectEqual(i32(10), di.modulus);
    T.expectEqual(i32(-1), di.quotient);
}

test "divInteger full" {
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
        const di = divInteger(elem.N, elem.D);
        T.expectEqual(elem.Q, di.quotient);
        T.expectEqual(elem.M, di.modulus);
    }
}
