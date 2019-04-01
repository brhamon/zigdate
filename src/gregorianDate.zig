const warn = std.debug.warn;
const std = @import("std");
const di = @import("divInteger.zig");

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
const unixEpochBeginsOnDay: i32 = 135080;

const dayOffset = []i32{ 0, 31, 61, 92, 122, 153, 184, 214, 245, 275, 306, 337, 366 };

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

    /// Compare this with another date (the `rhs` or "right hand side"). The result is less than zero
    /// if this date is before the rhs; greater than zero if this date is after the rhs; and zero
    /// if the two dates are the same.
    pub fn compare(self: Self, rhs: Self) i32 {
        return compare2(self, rhs);
    }

    /// Calculate the date code, an integer representing the number of days between March 1, 1600
    /// and this date -- if the Gregorian calendar had been in use continuously. Note that this
    /// assumption rarely applies to dates prior to about 1750.
    pub fn code(self: Self) i32 {
        // We take the approach of starting the year on March 1 so that leap days fall
        // at the end. To do this we pretend Jan. - Feb. are part of the previous year.
        var bYear: i32 = self.year() - 1600;
        var dr = di.divInteger(self.month() - 3, 12);
        var bYday: i32 = dayOffset[@intCast(usize, dr.modulus)] + self.day() - 1;
        bYear += dr.quotient;

        dr = di.divInteger(bYear, 400);
        bYear = dr.modulus;
        var days: i32 = dr.quotient * nbrOfDaysPer400Years;

        dr = di.divInteger(bYear, 100);
        bYear = dr.modulus;
        days += dr.quotient * nbrOfDaysPer100Years;

        dr = di.divInteger(bYear, 4);
        bYear = dr.modulus;
        days += dr.quotient * nbrOfDaysPer4Years + nbrOfDaysPerYear * bYear + bYday - unixEpochBeginsOnDay;
        return days;
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
    return di.divInteger(datecode + 3, 7).modulus;
}

/// Returns an enumerated value representing the day of the week, for the given
/// date code.
pub fn weekday(datecode: i32) Weekday {
    return @intToEnum(Weekday, @truncate(@TagType(Weekday), @intCast(u32, dayOfWeek(datecode))));
}

/// Construct a Date using a date code. See Date.code for important caveats.
pub fn FromCode(datecode: i32) Date {
    // dateCode has the number of days relative to 1/1/1970, shift this back to 3/1/1600
    var bdc: i32 = datecode + unixEpochBeginsOnDay;
    var dr = di.divInteger(bdc, nbrOfDaysPer400Years);
    bdc = dr.modulus;
    var y: i32 = dr.quotient * 400;
    dr = di.divInteger(bdc, nbrOfDaysPer100Years);
    bdc = dr.modulus;
    y += dr.quotient * 100;
    // put the leap day at the end of 400-year cycle
    if (dr.quotient == 4) {
        y -= 100;
        bdc += nbrOfDaysPer100Years;
    }
    dr = di.divInteger(bdc, nbrOfDaysPer4Years);
    bdc = dr.modulus;
    y += dr.quotient * 4;
    dr = di.divInteger(bdc, nbrOfDaysPerYear);
    bdc = dr.modulus;
    // put the leap day at the end of 4-year cycle
    y += dr.quotient;
    if (dr.quotient == 4) {
        y -= 1;
        bdc += nbrOfDaysPerYear;
    }
    // find the month in the table
    var alpha: usize = 0;
    var beta: usize = 11;
    var gamma: usize = 0;
    while (true) {
        gamma = @divTrunc(alpha + beta, 2);
        var diff: i32 = dayOffset[gamma] - bdc;
        if (diff < 0) {
            var diff2: i32 = dayOffset[gamma + 1] - bdc;
            if (diff2 < 0) {
                alpha = gamma + 1;
            } else if (diff2 == 0) {
                gamma += 1;
                break;
            } else {
                break;
            }
        } else if (diff == 0) {
            break;
        } else {
            beta = gamma;
        }
    }
    if (gamma >= 10) {
        y += 1;
    }
    return Date{
        ._year = @intCast(i23, y + 1600),
        ._month = @intCast(u4, (gamma + 2) % 12),
        ._day = @intCast(u5, bdc - dayOffset[gamma]),
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
