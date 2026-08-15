using Ganss.Xss;

namespace QuanLySuKienWuangEvents.Models;

// Chỉ cho phép các thẻ định dạng cơ bản trong nội dung do ban tổ chức nhập.
public static class SafeHtml
{
    private static readonly HtmlSanitizer Sanitizer = TaoBoLoc();

    public static string Sanitize(string? html) => Sanitizer.Sanitize(html ?? "");

    private static HtmlSanitizer TaoBoLoc()
    {
        var sanitizer = new HtmlSanitizer();
        sanitizer.AllowedTags.Clear();
        sanitizer.AllowedTags.UnionWith(
            ["p", "br", "strong", "b", "em", "i", "u", "ul", "ol", "li", "h2", "h3", "h4", "blockquote", "a"]);
        sanitizer.AllowedAttributes.Clear();
        sanitizer.AllowedAttributes.UnionWith(["href", "title"]);
        sanitizer.AllowedSchemes.Clear();
        sanitizer.AllowedSchemes.UnionWith(["http", "https", "mailto"]);
        return sanitizer;
    }
}
