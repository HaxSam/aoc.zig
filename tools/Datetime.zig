const std = @import("std");
const builtin = @import("builtin");

year: u16,
month: u8,
day: u8,
hour: u8,
minute: u8,
second: u8,
millisecond: u16,

const windows = struct {
    const BOOL = std.os.windows.BOOL;
    const DWORD = std.os.windows.DWORD;
    const LONG = std.os.windows.LONG;
    const SYSTEMTIME = extern struct {
        wYear: u16,
        wMonth: u16,
        wDayOfWeek: u16,
        wDay: u16,
        wHour: u16,
        wMinute: u16,
        wSecond: u16,
        wMilliseconds: u16,
    };
    const TIME_ZONE_INFORMATION = extern struct {
        Bias: LONG,
        StandardName: [32]u16,
        StandardDate: SYSTEMTIME,
        StandardBias: LONG,
        DaylightName: [32]u16,
        DaylightDate: SYSTEMTIME,
        DaylightBias: LONG,
    };
    const INVALID_TIME = @as(DWORD, 0xFFFFFFFF);
    const STANDARD_TIME = 1;
    const DAYLIGHT_TIME = 2;
    extern "kernel32" fn GetTimeZoneInformation(lpTimeZoneInformation: *TIME_ZONE_INFORMATION) callconv(std.os.windows.WINAPI) DWORD;
};

const Posix = struct {
    std: []const u8,
    std_offset: i64,
    pub fn parse(str: []const u8) !Posix {
        if (str.len == 0) return error.InvalidPosix;
        var std_end: usize = 0;
        while (std_end < str.len and !isNum(str[std_end])) : (std_end += 1) {}
        if (std_end == 0) return error.InvalidPosix;
        var offset: i64 = 0;
        var i = std_end;
        var negative = false;
        if (i < str.len and str[i] == '-') {
            negative = true;
            i += 1;
        }
        while (i < str.len and isNum(str[i])) : (i += 1) {
            offset = offset * 10 + (str[i] - '0');
        }
        if (negative) offset = -offset;
        return .{ .std = str[0..std_end], .std_offset = offset * std.time.s_per_hour };
    }
    fn isNum(c: u8) bool {
        return c >= '0' and c <= '9';
    }
};

pub fn now() @This() {
    return nowWithOffset(null);
}

pub fn nowWithOffset(offset_hours: ?i8) @This() {
    const ms = @as(u64, @intCast(@abs(std.time.milliTimestamp())));
    const secs = @divFloor(ms, 1000);
    const msec = @as(u16, @intCast(ms % 1000));
    const epoch_seconds = std.time.epoch.EpochSeconds{ .secs = secs };
    const day = epoch_seconds.getEpochDay();
    const year_day = day.calculateYearDay();
    const month_day = year_day.calculateMonthDay();
    const time = epoch_seconds.getDaySeconds();
    const raw_hour = time.getHoursIntoDay();

    const adjusted_hour: i32 = if (offset_hours) |off|
        @intCast(@mod(@as(i32, raw_hour) + off + 24, 24))
    else switch (builtin.os.tag) {
        .windows => blk: {
            var tz_info: windows.TIME_ZONE_INFORMATION = undefined;
            const result = windows.GetTimeZoneInformation(&tz_info);
            const total_bias = tz_info.Bias + if (result == windows.DAYLIGHT_TIME) tz_info.DaylightBias else 0;
            const hour = @as(i32, raw_hour) + (-@divTrunc(total_bias, 60));
            break :blk @intCast(@mod(hour + 24, 24));
        },
        else => blk: {
            const posix_tz = std.posix.getenv("TZ") orelse "UTC";
            const tz: Posix = Posix.parse(posix_tz) catch .{
                .std = "UTC",
                .std_offset = 0,
            };
            const hour = @as(i32, raw_hour) + @divTrunc(-tz.std_offset, std.time.s_per_hour);
            break :blk @intCast(@mod(hour + 24, 24));
        },
    };

    return .{
        .year = year_day.year,
        .month = month_day.month.numeric(),
        .day = month_day.day_index + 1,
        .hour = @intCast(adjusted_hour),
        .minute = time.getMinutesIntoHour(),
        .second = time.getSecondsIntoMinute(),
        .millisecond = msec,
    };
}

pub fn twoDigitDay(buf: []u8, day: u8) []u8 {
    if (day < 10) {
        return std.fmt.bufPrint(buf, "0{d}", .{day}) catch unreachable;
    } else return std.fmt.bufPrint(buf, "{d}", .{day}) catch unreachable;
}
