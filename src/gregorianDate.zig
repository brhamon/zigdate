const warn = std.debug.warn;
const std = @import("std");

/// The earliest year that can be stored in a Date
pub const minYear: i32 = i32(std.math.minInt(i23));

/// The latest year that can be stored in a Date
pub const maxYear: i32 = i32(std.math.maxInt(i23));

/// The earliest month that can be stored in a Date:
/// 1 => January
pub const minMonth: i32 = 1;

/// The latest month that can be stored in a Date:
/// 12 => December
pub const maxMonth: i32 = 12;

/// The earliest day of the month that can be stored in a Date: 1
pub const minDay: i32 = 1;

/// The latest day of the month that can be stored in a Date: 31
pub const maxDay: i32 = 31;

const nbrOfDaysPer400Years: i32 = 146097;
const nbrOfDaysPer100Years: i32 = 36524;
const nbrOfDaysPer4Years: i32 = 1461;
const nbrOfDaysPerYear: i32 = 365;
// 1970-1-1 was 11017 days before 2000-3-1
const unixEpochBeginsOnDay: i32 = -11017;

const dayOffset = []i32{ 0, 31, 61, 92, 122, 153, 184, 214, 245, 275, 306, 337 };

/// The names of the weekdays, in English.
pub const Weekday = enum {
    Monday,
    Tuesday,
    Wednesday,
    Thursday,
    Friday,
    Saturday,
    Sunday,
};

/// The names of the months, in English.
pub const Month = enum {
    January,
    February,
    March,
    April,
    May,
    June,
    July,
    August,
    September,
    October,
    November,
    December,
};

const err = error.RangeError;

const DivPair = struct {
    quotient: i32,
    modulus: i32,
};

/// Floored Division. Assumes divisor > 0.
fn flooredDivision(dividend: i32, comptime divisor: i32) DivPair {
    if (divisor == 0) {
        @compileError("division by zero");
    }
    if (divisor < 0) {
        @compileError("floored division implementation does not allow a negative divisor");
    }
    const m = @rem(switch (dividend < 0) { true => -dividend, false => dividend }, divisor);
    return DivPair{
        .quotient = @divFloor(dividend, divisor),
        .modulus = switch (m != 0 and dividend < 0) { true => divisor - m, false => m },
    };
}

/// A Gregorian date. The size is guaranteed to be 4-bytes, therefore it is
/// inexpensive to pass by value. Construct a Date in one of the following
/// ways:
///   FromYmd -- accepts a Gregorian date in year/month/day format
///   FromCode -- accepts a date code
///   FromCardinal -- accepts a cardinal date
pub const Date = packed struct {
    const Self = @This();

    _day: u5,
    _month: u4,
    _year: i23,

    /// Accessor for year
    pub fn year(self: Self) i32 {
        return @intCast(i32, self._year);
    }

    /// Accessor for month
    pub fn month(self: Self) i32 {
        return @intCast(i32, self._month) + 1;
    }

    /// Accessor for month as a Month (enum)
    pub fn monthEnum(self: Self) Month {
        return @intToEnum(Month, self._month);
    }

    /// Accessor for day of the month
    pub fn day(self: Self) i32 {
        return @intCast(i32, self._day) + 1;
    }

    /// Compare this with another date (the `rhs` or "right hand side"). The result is
    /// less than zero if this date is before the rhs, greater than zero if this date is
    /// after the rhs, or zero if the two dates are the same.
    pub fn compare(self: Self, rhs: Self) i32 {
        return compare2(self, rhs);
    }

    /// Calculate the date code, an integer representing the number of days since the
    /// start of the Unix epoch (1970-1-1). Support for negative results allows us to
    /// map Gregorian dates exactly to 1582-2-24, when it was instituted by
    /// Pope Gregory XIII. Adoption varies by nation, but has been in place worldwide
    /// since 1926.
    pub fn code(self: Self) i32 {
        // We take the approach of starting the year on March 1 so that the leap day falls
        // at the end. To do this we pretend January and February are part of the previous
        // year.
        //
        // Our internal representation will choose as its base date any day which is
        // at the start of the 400-year Gregorian cycle. We have arbitrarily selected
        // 2000-3-1.
        const dr = flooredDivision(self.month() - 3, 12);
        const dr400 = flooredDivision(self.year() + dr.quotient - 2000, 400);
        const dr100 = flooredDivision(dr400.modulus, 100);
        const dr4 = flooredDivision(dr100.modulus, 4);
        return dr400.quotient * nbrOfDaysPer400Years + dr100.quotient * nbrOfDaysPer100Years + dr4.quotient * nbrOfDaysPer4Years + nbrOfDaysPerYear * dr4.modulus + dayOffset[@intCast(usize, dr.modulus)] + self.day() - unixEpochBeginsOnDay - 1;
    }
};

fn isYearInRange(y: i32) bool {
    return minYear <= y and y <= maxYear;
}

fn isMonthInRange(m: i32) bool {
    return minMonth <= m and m <= maxMonth;
}

fn isDayInRange(d: i32) bool {
    return minDay <= d and d <= maxDay;
}

/// Returns an integer representing the day of the week, for the given date code.
/// 0 => Monday, 6 => Sunday
pub fn dayOfWeek(datecode: i32) i32 {
    return flooredDivision(datecode + 3, 7).modulus;
}

/// Returns an enumerated value representing the day of the week, for the given
/// date code.
pub fn weekday(datecode: i32) Weekday {
    return @intToEnum(Weekday, @truncate(@TagType(Weekday), @intCast(u32, dayOfWeek(datecode))));
}

pub fn findDayOffsetIdx(bdc: i32) usize {
    // find the month in the table
    var gamma: usize = 0;
    inline for (dayOffset) |ofs| {
        if (bdc < ofs) {
            gamma -= 1;
            break;
        } else if (bdc == ofs or gamma == 11) {
            break;
        }
        gamma += 1;
    }
    return gamma;
}

/// Construct a Date using a date code. This constructor requires more computation than
/// the other two, so prefer the others if possible.
pub fn FromCode(datecode: i32) Date {
    // dateCode has the number of days relative to 1/1/1970, shift this ahead to 3/1/2000
    const dr400 = flooredDivision(datecode + unixEpochBeginsOnDay, nbrOfDaysPer400Years);
    var dr100 = flooredDivision(dr400.modulus, nbrOfDaysPer100Years);
    // put the leap day at the end of 400-year cycle
    if (dr100.quotient == 4) {
        dr100.quotient -= 1;
        dr100.modulus += nbrOfDaysPer100Years;
    }
    const dr4 = flooredDivision(dr100.modulus, nbrOfDaysPer4Years);
    var dr1 = flooredDivision(dr4.modulus, nbrOfDaysPerYear);
    // put the leap day at the end of 4-year cycle
    if (dr1.quotient == 4) {
        dr1.quotient -= 1;
        dr1.modulus += nbrOfDaysPerYear;
    }
    const gamma = findDayOffsetIdx(dr1.modulus);
    if (gamma >= 10) {
        dr1.quotient += 1;
    }
    return Date{
        ._year = @intCast(i23, dr400.quotient * 400 + dr100.quotient * 100 + dr4.quotient * 4 + dr1.quotient + 2000),
        ._month = @intCast(u4, (gamma + 2) % 12),
        ._day = @intCast(u5, dr1.modulus - dayOffset[gamma]),
    };
}

/// Compare two dates, the `lhs` ("left hand side") and `rhs` ("right hand side").
/// Returns an integer that is less than zero if `lhs` is before `rhs`,
/// greater than zero if `lhs` is after `rhs`, and zero if they both refer to the
/// same date.
pub fn compare2(lhs: Date, rhs: Date) i32 {
    var res: i64 = @intCast(i64, @bitCast(i32, lhs)) - @bitCast(i32, rhs);
    if (res < 0) {
        return -1;
    } else if (res > 0) {
        return 1;
    } else {
        return 0;
    }
}

/// Construct a Date from its Gregorian year, month, and day. This will fail
/// if any of the inputs are out of range. Note that the range checking only
/// assures that the values can be stored in the internal data structure
/// without losing information. It does allow setting to values which would
/// not be possible in the Gregorian calendar. For example: FromYmd(2000, 2, 30)
/// is perfectly acceptable, even though February 2000 only had 29 days.
/// However, FromYmd(2000, 1, 32) will be rejected.
pub fn FromYmd(y: i32, m: i32, d: i32) !Date {
    if (isYearInRange(y) and isMonthInRange(m) and isDayInRange(d)) {
        return Date{
            ._year = @intCast(i23, y),
            ._month = @intCast(u4, m - 1),
            ._day = @intCast(u5, d - 1),
        };
    } else {
        return err;
    }
}

/// The earliest date which can be represented.
pub const min = comptime Date{ ._year = minYear, ._month = minMonth - 1, ._day = minDay - 1 };

/// The latest date which can be represented.
pub const max = comptime Date{ ._year = maxYear, ._month = maxMonth - 1, ._day = maxDay - 1 };

/// An enumeration of the cardinal values 1 through 5, to be used as an input
/// to cardinal date methods.
pub const Nth = enum {
    First,
    Second,
    Third,
    Fourth,
    Last,
};

/// Return the date code where year and month are known, and you want to select a
/// specific occurrence of a given weekday. For example, the Second Tuesday in November 2020.
/// This function may fail, if the year or month inputs are out of range.
pub fn cardinalCode(nth: Nth, wkdy: Weekday, y: i32, m: i32) !i32 {
    const d = try FromYmd(y, m, 1);
    var dc: i32 = d.code();
    const dow1st = dayOfWeek(dc);
    var wkdy2: i32 = @enumToInt(wkdy);
    if (wkdy2 < dow1st) {
        wkdy2 += 7;
    }
    dc += wkdy2 - dow1st + 7 * @intCast(i32, @enumToInt(nth));
    if (nth == Nth.Last) {
        // check that the fifth week is actually in the same month
        const d2 = FromCode(dc);
        if (d2.month() != m) {
            dc -= 7;
        }
    }
    return dc;
}

/// Construct a Date, when year and month are known, and you want to select a
/// specific occurrence of a given weekday. For example, the Second Tuesday in November 2020.
/// This function may fail, if the year or month inputs are out of range.
pub fn FromCardinal(nth: Nth, wkdy: Weekday, y: i32, m: i32) !Date {
    var dc = try cardinalCode(nth, wkdy, y, m);
    return FromCode(dc);
}
