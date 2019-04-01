const warn = std.debug.warn;
const time = std.os.time;
const std = @import("std");
const date = @import("gregorianDate.zig");

fn nextElectionDay() void {
    // Get UTC and manually adjust to Pacific Daylight Time
    // (For demonstration only -- This is not the correct way to convert to civil time!)
    const now = time.timestamp() - u64(7 * 3600);
    const unix_day = @divFloor(now, u64(86400));
    const dc = @truncate(i32, @intCast(i64, unix_day));
    const d = date.FromCode(dc);
    warn("Today: {}-{}-{}\n", d.year(), d.month(), d.day());
    var eYear = d.year();
    if (@rem(eYear, 2) != 0) {
        eYear += 1;
    }
    var eday: date.Date = undefined;
    var count: usize = 10;
    while (count != 0) {
        // The day *after* the first Monday of November in an even-numbered year.
        const e = date.FromCardinal(date.Nth.First, date.Weekday.Monday, eYear, 11) catch date.min;
        const ec = e.code();
        if (ec + 1 >= dc) {
            eday = date.FromCode(ec + 1);
            break;
        }
        eYear += 2;
        count -= 1;
    }
    warn("Election day is {}-{}-{}, {} days from today.\n",
        eday.year(), eday.month(), eday.day(), eday.code() - dc);
}

pub fn main() void {
    // Note the range error below:
    var my_date = date.FromYmd(2019, 3, 130) catch date.min;
    warn("\nGregorianDate\ntype: {}\nsize: {}\nvalue: {}-{}-{}\n",
        @typeName(@typeOf(my_date)), @intCast(u32, @sizeOf(@typeOf(my_date))),
        my_date.year(), my_date.month(), my_date.day());

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

    nextElectionDay();
}
