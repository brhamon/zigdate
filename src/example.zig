const warn = std.debug.warn;
const time = std.os.time;
const std = @import("std");
const date = @import("gregorianDate.zig");

fn today() date.Date {
    // Get UTC and manually adjust to Pacific Daylight Time
    // (For demonstration only -- This is not the correct way to convert to civil time!)
    const now = time.timestamp() - u64(7 * 3600);

    return date.FromCode(@truncate(i32, @intCast(i64, @divFloor(now, u64(86400)))));
}

fn nextElectionDay(t: date.Date) date.Date {
    var eYear = t.year();
    if (@rem(eYear, 2) != 0) {
        eYear += 1;
    }
    const e = date.FromCardinal(date.Nth.First, date.Weekday.Monday, eYear, 11) catch date.max;
    var ec = e.code();
    if (ec + 1 < t.code()) {
        // Election day this year has passed. The next election is 2 years away.
        const e2 = date.FromCardinal(date.Nth.First, date.Weekday.Monday, eYear + 2, 11) catch date.max;
        ec = e2.code();
    }
    // Election day in the U. S. is always on the day *after* the first Monday of November.
    return date.FromCode(ec + 1);
}

pub fn main() void {
    // Note the range error below:
    var my_date = date.FromYmd(2019, 3, 130) catch date.min;
    warn("\nGregorianDate\ntype: {}\nsize: {}\nvalue: {}-{}-{}\n", @typeName(@typeOf(my_date)), @intCast(u32, @sizeOf(@typeOf(my_date))), my_date.year(), my_date.month(), my_date.day());

    var my_date2 = date.FromYmd(2019, 3, 30) catch date.min;
    warn("\nmy_date2: {}-{}-{}\n", my_date2.year(), @tagName(my_date2.monthEnum()), my_date2.day());

    // compare dates without normalizing
    var cmp_res = my_date.compare(my_date2);
    warn("\ncmp_res: {}\n", cmp_res);

    // find the weekday for a given date
    var code: i32 = my_date2.code();
    warn("\nmy_date2.code() = {}\nweekday = {}\n", code, @tagName(date.weekday(code)));

    // what is 90 days after my_date2?
    var my_date3 = date.FromCode(code + 90);
    warn("\nmy_date2 + 90: {}-{}-{}\n", my_date3.year(), my_date3.month(), my_date3.day());

    // Today
    const t = today();
    const tc = t.code();
    warn("Today: {}-{}-{}\n", t.year(), t.month(), t.day());

    const eday = nextElectionDay(t);
    warn("Election day is {}-{}-{}, {} days from today.\n", eday.year(), eday.month(), eday.day(), eday.code() - tc);

    // Convert a date code to Julian Date
    const unix_to_julian_bias: f64 = 2440587.5;
    warn("Today is JD {}.\n", unix_to_julian_bias + @intToFloat(f64, tc));

    // Convert a date code to _Rata Die_
    const rata_die_offset: i32 = 719163;
    warn("Today is rata die {}.\n", rata_die_offset + tc);

    // Convert a date code to Unix time (seconds since 1970-1-1)
    if (tc >= 0) {
        warn("Today began {} seconds after 1970-1-1.\n", @intCast(u64, tc) * u64(86400));
    }
}
