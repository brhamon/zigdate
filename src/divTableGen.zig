const warn = std.debug.warn;
const std = @import("std");
const di = @import("divInteger.zig");

/// creates test data
fn generateTable(op: di.divisionOp) void {
    for ([]i32{ 3, -3 }) |divisor| {
        if (divisor > 0) {
            warn("POSITIVE DIVISOR\n");
        } else {
            warn("NEGATIVE DIVISOR\n");
        }
        var dividend: i32 = -10;
        while (dividend <= 10) {
            const q = op(dividend, divisor);
            const dividend2 = divisor * q.quotient + q.modulus;
            // How do you write literal `{` and `}` ?
            warn(".a={}, .n={}, .q={}, .r={},\n", dividend, divisor, q.quotient, q.modulus);
            dividend += 1;
        }
    }
}

pub fn main() void {
    warn("=== TRUNCATED DIVISION ===\n");
    generateTable(di.truncatedDivision);
    warn("=== FLOORED DIVISION ===\n");
    generateTable(di.flooredDivision);
    warn("=== EUCLIDEAN DIVISION ===\n");
    generateTable(di.euclideanDivision);
}
