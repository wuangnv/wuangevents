namespace QuanLySuKienWuangEvents.Models;

// Lịch sự kiện dùng giờ Việt Nam; các mốc hệ thống lưu UTC rồi đổi khi hiển thị.
public static class VietnamTime
{
    public static readonly TimeZoneInfo Zone = ResolveZone();

    public static DateTime Now => TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, Zone);
    public static DateTime Today => Now.Date;

    public static DateTime FromUtc(DateTime value)
    {
        var utc = value.Kind == DateTimeKind.Utc
            ? value
            : DateTime.SpecifyKind(value, DateTimeKind.Utc);
        return TimeZoneInfo.ConvertTimeFromUtc(utc, Zone);
    }

    public static DateTime? FromUtc(DateTime? value) =>
        value.HasValue ? FromUtc(value.Value) : null;

    public static DateTime ToUtc(DateTime value)
    {
        var vietnamLocal = DateTime.SpecifyKind(value, DateTimeKind.Unspecified);
        return TimeZoneInfo.ConvertTimeToUtc(vietnamLocal, Zone);
    }

    private static TimeZoneInfo ResolveZone()
    {
        try { return TimeZoneInfo.FindSystemTimeZoneById("SE Asia Standard Time"); }
        catch (TimeZoneNotFoundException)
        {
            return TimeZoneInfo.FindSystemTimeZoneById("Asia/Ho_Chi_Minh");
        }
    }
}
