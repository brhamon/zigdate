const std = @import("std");
const builtin = @import("builtin");
const T = std.testing;
const date = @import("gregorianDate.zig");
const warn = std.debug.warn;

test "Date coarse range check" {
    const R = enum {
        inRange,
        outOfRange,
    };
    const RangeCheckElem = struct {
        y: i32,
        m: i32,
        d: i32,
        dflt: @typeOf(date.min),
        exp: R,
        val: i32,
    };
    const rangeCheckTable = []RangeCheckElem{
        RangeCheckElem{ .y = 2019, .m = 3, .d = 130, .dflt = date.min, .exp = R.outOfRange, .val = undefined },
        RangeCheckElem{ .y = 2019, .m = 3, .d = 1, .dflt = date.min, .exp = R.inRange, .val = 1033792 },
        RangeCheckElem{ .y = 2019, .m = 0, .d = 12, .dflt = date.min, .exp = R.outOfRange, .val = undefined },
        RangeCheckElem{ .y = 2019, .m = -1, .d = 4, .dflt = date.min, .exp = R.outOfRange, .val = undefined },
        RangeCheckElem{ .y = 2019, .m = 1, .d = 7, .dflt = date.min, .exp = R.inRange, .val = 1033734 },
        RangeCheckElem{ .y = 2019, .m = 12, .d = 29, .dflt = date.min, .exp = R.inRange, .val = 1034108 },
        RangeCheckElem{ .y = 2019, .m = 12, .d = 31, .dflt = date.min, .exp = R.inRange, .val = 1034110 },
        RangeCheckElem{ .y = 2019, .m = 12, .d = 32, .dflt = date.min, .exp = R.outOfRange, .val = undefined },
        RangeCheckElem{ .y = 2019, .m = 13, .d = 1, .dflt = date.min, .exp = R.outOfRange, .val = undefined },
        RangeCheckElem{ .y = 2020, .m = 2, .d = 29, .dflt = date.min, .exp = R.inRange, .val = 1034300 },
        RangeCheckElem{ .y = 2020, .m = 2, .d = 30, .dflt = date.min, .exp = R.inRange, .val = 1034301 },
        RangeCheckElem{ .y = 2020, .m = 2, .d = 31, .dflt = date.min, .exp = R.inRange, .val = 1034302 },
        RangeCheckElem{ .y = 2020, .m = 2, .d = 32, .dflt = date.min, .exp = R.outOfRange, .val = undefined },
        RangeCheckElem{ .y = date.maxYear, .m = 1, .d = 1, .dflt = date.min, .exp = R.inRange, .val = 2147483136 },
        RangeCheckElem{ .y = date.maxYear, .m = 12, .d = 31, .dflt = date.min, .exp = R.inRange, .val = 2147483518 },
        RangeCheckElem{ .y = date.maxYear, .m = 12, .d = 32, .dflt = date.min, .exp = R.outOfRange, .val = undefined },
        RangeCheckElem{ .y = date.maxYear + 1, .m = 1, .d = 1, .dflt = date.min, .exp = R.outOfRange, .val = undefined },
        RangeCheckElem{ .y = date.minYear, .m = 1, .d = 1, .dflt = date.max, .exp = R.inRange, .val = -2147483648 },
        RangeCheckElem{ .y = date.minYear - 1, .m = 12, .d = 31, .dflt = date.max, .exp = R.outOfRange, .val = undefined },
    };

    var my_date = date.min;
    var count: usize = 0;
    for (rangeCheckTable) |elem| {
        my_date = date.FromYmd(elem.y, elem.m, elem.d) catch elem.dflt;
        T.expectEqual(elem.exp, switch (my_date.compare(elem.dflt) == 0) {
            false => R.inRange,
            true => R.outOfRange,
        });
        if (elem.exp == R.inRange) {
            T.expectEqual(elem.val, @bitCast(i32, my_date));
        }
        count += 1;
    }
}

test "Calendrical Calculations test points" {
    const rata_die_offset: i32 = 719163;
    const unix_to_julian_bias: f64 = 2440587.5;
    const CalCalElem = struct {
        rd: i32,
        dw: date.Weekday,
        jd: f64,
        gy: i32,
        gm: i32,
        gd: i32,
    };
    // The set of reference points from Calendrical Calculations, Appendix C, Table 1 (part 1)
    const appendix_c = []CalCalElem{
        CalCalElem{ .rd = -214193, .dw = date.Weekday.Sunday, .jd = 1507231.5, .gy = -586, .gm = 7, .gd = 24 },
        CalCalElem{ .rd = -61387, .dw = date.Weekday.Wednesday, .jd = 1660037.5, .gy = -168, .gm = 12, .gd = 5 },
        CalCalElem{ .rd = 25469, .dw = date.Weekday.Wednesday, .jd = 1746893.5, .gy = 70, .gm = 9, .gd = 24 },
        CalCalElem{ .rd = 49217, .dw = date.Weekday.Sunday, .jd = 1770641.5, .gy = 135, .gm = 10, .gd = 2 },
        CalCalElem{ .rd = 171307, .dw = date.Weekday.Wednesday, .jd = 1892731.5, .gy = 470, .gm = 1, .gd = 8 },
        CalCalElem{ .rd = 210155, .dw = date.Weekday.Monday, .jd = 1931579.5, .gy = 576, .gm = 5, .gd = 20 },
        CalCalElem{ .rd = 253427, .dw = date.Weekday.Saturday, .jd = 1974851.5, .gy = 694, .gm = 11, .gd = 10 },
        CalCalElem{ .rd = 369740, .dw = date.Weekday.Sunday, .jd = 2091164.5, .gy = 1013, .gm = 4, .gd = 25 },
        CalCalElem{ .rd = 400085, .dw = date.Weekday.Sunday, .jd = 2121509.5, .gy = 1096, .gm = 5, .gd = 24 },
        CalCalElem{ .rd = 434355, .dw = date.Weekday.Friday, .jd = 2155779.5, .gy = 1190, .gm = 3, .gd = 23 },
        CalCalElem{ .rd = 452605, .dw = date.Weekday.Saturday, .jd = 2174029.5, .gy = 1240, .gm = 3, .gd = 10 },
        CalCalElem{ .rd = 470160, .dw = date.Weekday.Friday, .jd = 2191584.5, .gy = 1288, .gm = 4, .gd = 2 },
        CalCalElem{ .rd = 473837, .dw = date.Weekday.Sunday, .jd = 2195261.5, .gy = 1298, .gm = 4, .gd = 27 },
        CalCalElem{ .rd = 507850, .dw = date.Weekday.Sunday, .jd = 2229274.5, .gy = 1391, .gm = 6, .gd = 12 },
        CalCalElem{ .rd = 524156, .dw = date.Weekday.Wednesday, .jd = 2245580.5, .gy = 1436, .gm = 2, .gd = 3 },
        CalCalElem{ .rd = 544676, .dw = date.Weekday.Saturday, .jd = 2266100.5, .gy = 1492, .gm = 4, .gd = 9 },
        CalCalElem{ .rd = 567118, .dw = date.Weekday.Saturday, .jd = 2288542.5, .gy = 1553, .gm = 9, .gd = 19 },
        CalCalElem{ .rd = 569477, .dw = date.Weekday.Saturday, .jd = 2290901.5, .gy = 1560, .gm = 3, .gd = 5 },
        CalCalElem{ .rd = 601716, .dw = date.Weekday.Wednesday, .jd = 2323140.5, .gy = 1648, .gm = 6, .gd = 10 },
        CalCalElem{ .rd = 613424, .dw = date.Weekday.Sunday, .jd = 2334848.5, .gy = 1680, .gm = 6, .gd = 30 },
        CalCalElem{ .rd = 626596, .dw = date.Weekday.Friday, .jd = 2348020.5, .gy = 1716, .gm = 7, .gd = 24 },
        CalCalElem{ .rd = 645554, .dw = date.Weekday.Sunday, .jd = 2366978.5, .gy = 1768, .gm = 6, .gd = 19 },
        CalCalElem{ .rd = 664224, .dw = date.Weekday.Monday, .jd = 2385648.5, .gy = 1819, .gm = 8, .gd = 2 },
        CalCalElem{ .rd = 671401, .dw = date.Weekday.Wednesday, .jd = 2392825.5, .gy = 1839, .gm = 3, .gd = 27 },
        CalCalElem{ .rd = 694799, .dw = date.Weekday.Sunday, .jd = 2416223.5, .gy = 1903, .gm = 4, .gd = 19 },
        CalCalElem{ .rd = 704424, .dw = date.Weekday.Sunday, .jd = 2425848.5, .gy = 1929, .gm = 8, .gd = 25 },
        CalCalElem{ .rd = 708842, .dw = date.Weekday.Monday, .jd = 2430266.5, .gy = 1941, .gm = 9, .gd = 29 },
        CalCalElem{ .rd = 709409, .dw = date.Weekday.Monday, .jd = 2430833.5, .gy = 1943, .gm = 4, .gd = 19 },
        CalCalElem{ .rd = 709580, .dw = date.Weekday.Thursday, .jd = 2431004.5, .gy = 1943, .gm = 10, .gd = 7 },
        CalCalElem{ .rd = 727274, .dw = date.Weekday.Tuesday, .jd = 2448698.5, .gy = 1992, .gm = 3, .gd = 17 },
        CalCalElem{ .rd = 728714, .dw = date.Weekday.Sunday, .jd = 2450138.5, .gy = 1996, .gm = 2, .gd = 25 },
        CalCalElem{ .rd = 744313, .dw = date.Weekday.Wednesday, .jd = 2465737.5, .gy = 2038, .gm = 11, .gd = 10 },
        CalCalElem{ .rd = 764652, .dw = date.Weekday.Sunday, .jd = 2486076.5, .gy = 2094, .gm = 7, .gd = 18 },
    };

    for (appendix_c) |elem| {
        const d = try date.FromYmd(elem.gy, elem.gm, elem.gd);
        const dc: i32 = d.code();
        T.expectEqual(elem.rd, dc + rata_die_offset);
        T.expectEqual(elem.dw, date.weekday(dc));
        const f = date.FromCode(dc);
        T.expectEqual(elem.gy, f.year());
        T.expectEqual(elem.gm, f.month());
        T.expectEqual(elem.gd, f.day());
        const jd: f64 = unix_to_julian_bias + @intToFloat(f64, dc);
        T.expectEqual(elem.jd, jd);
    }
}

test "cardinal dates" {
    const CdElem = struct {
        nth: date.Nth,
        wkdy: date.Weekday,
        y: i32,
        m: i32,
        exp: i32,
    };
    const cd_data = []CdElem{
        CdElem{ .nth = date.Nth.First, .wkdy = date.Weekday.Monday, .y = 2019, .m = 4, .exp = 1 },
        CdElem{ .nth = date.Nth.Second, .wkdy = date.Weekday.Friday, .y = 2019, .m = 9, .exp = 13 },
        CdElem{ .nth = date.Nth.Last, .wkdy = date.Weekday.Tuesday, .y = 1992, .m = 7, .exp = 28 },
    };
    for (cd_data) |elem| {
        const d = try date.FromCardinal(elem.nth, elem.wkdy, elem.y, elem.m);
        T.expectEqual(elem.exp, d.day());
    }
}
