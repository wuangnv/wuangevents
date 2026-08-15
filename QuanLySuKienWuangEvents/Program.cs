using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authentication.Google;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.Extensions.FileProviders;
using QuanLySuKienWuangEvents.Models;
using System.Globalization;
using System.Security.Claims;
using System.Threading.RateLimiting;

var vietnameseCulture = CultureInfo.GetCultureInfo("vi-VN");
CultureInfo.DefaultThreadCurrentCulture = vietnameseCulture;
CultureInfo.DefaultThreadCurrentUICulture = vietnameseCulture;

// Điểm bắt đầu của ứng dụng. Builder đọc appsettings, biến môi trường
// và chuẩn bị nơi đăng ký các dịch vụ dùng bằng dependency injection.
var builder = WebApplication.CreateBuilder(args);

// Đọc DefaultConnection từ appsettings và lưu vào Db.cs để Controller dùng chung.
string connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? throw new InvalidOperationException("Thiếu ConnectionStrings:DefaultConnection.");
Db.Init(connectionString);

// Đăng ký MVC: cho phép dùng Controller và Razor View.
builder.Services.AddControllersWithViews(options =>
    options.Filters.Add(new AutoValidateAntiforgeryTokenAttribute()));
builder.Services.AddHttpClient();
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.AddFixedWindowLimiter("auth", limiter =>
    {
        limiter.PermitLimit = 10;
        limiter.Window = TimeSpan.FromMinutes(1);
        limiter.QueueLimit = 0;
        limiter.QueueProcessingOrder = QueueProcessingOrder.OldestFirst;
    });
});

// Session giữ bản nháp chọn vé/ghế; đóng trang trước khi bấm thanh toán sẽ không tạo đơn.
builder.Services.AddDistributedMemoryCache();
builder.Services.AddSession(options =>
{
    options.IdleTimeout = TimeSpan.FromMinutes(30);
    options.Cookie.HttpOnly = true;
    options.Cookie.IsEssential = true;
    options.Cookie.Name = "WuangEvents.Checkout";
    options.Cookie.SameSite = SameSiteMode.Lax;
    options.Cookie.SecurePolicy = CookieSecurePolicy.SameAsRequest;
});

// Scoped: trong mỗi HTTP request tạo một EmailService và dùng lại nó
// cho các Controller cần gửi mail trong chính request đó.
builder.Services.AddScoped<QuanLySuKienWuangEvents.Services.EmailService>();

// Google dùng cookie tạm để nhận hồ sơ; AccountController đổi sang cookie chính của website.
const string googleExternalCookie = "GoogleExternal";
string? configuredGoogleClientId = builder.Configuration["Authentication:Google:ClientId"];
string? configuredGoogleClientSecret = builder.Configuration["Authentication:Google:ClientSecret"];
string googleClientId = string.IsNullOrWhiteSpace(configuredGoogleClientId)
    ? "not-configured"
    : configuredGoogleClientId;
string googleClientSecret = string.IsNullOrWhiteSpace(configuredGoogleClientSecret)
    ? "not-configured"
    : configuredGoogleClientSecret;

builder.Services.AddAuthentication(options =>
    {
        options.DefaultAuthenticateScheme = CookieAuthenticationDefaults.AuthenticationScheme;
        options.DefaultSignInScheme = CookieAuthenticationDefaults.AuthenticationScheme;
        options.DefaultChallengeScheme = CookieAuthenticationDefaults.AuthenticationScheme;
    })
    .AddCookie(options =>
    {
        // Chưa đăng nhập -> chuyển tới LoginPath.
        options.LoginPath = "/Account/DangNhap";
        options.LogoutPath = "/Account/DangXuat";
        // Đăng nhập rồi nhưng thiếu role -> chuyển tới AccessDeniedPath.
        options.AccessDeniedPath = "/Account/DangNhap";
        // Tên cookie lưu trong browser.
        options.Cookie.Name = "WuangEvents.Student";
        options.Cookie.HttpOnly = true;
        options.Cookie.SameSite = SameSiteMode.Lax;
        options.Cookie.SecurePolicy = CookieSecurePolicy.SameAsRequest;
        options.ExpireTimeSpan = TimeSpan.FromHours(8);
        options.SlidingExpiration = true;
        options.Events.OnValidatePrincipal = async context =>
        {
            const string validationKey = "last-security-validation-utc";
            if (context.Properties.Items.TryGetValue(validationKey, out string? lastText)
                && DateTimeOffset.TryParse(lastText, CultureInfo.InvariantCulture,
                    DateTimeStyles.RoundtripKind, out DateTimeOffset lastValidation)
                && DateTimeOffset.UtcNow - lastValidation < TimeSpan.FromMinutes(5))
                return;

            ClaimsPrincipal? principal = context.Principal;
            string? idText = principal?.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!Guid.TryParse(idText, out Guid userId))
            {
                context.RejectPrincipal();
                await context.HttpContext.SignOutAsync(context.Scheme.Name);
                return;
            }

            var user = await Db.LayDonLe<NguoiDung>(
                "SELECT * FROM NguoiDung WHERE Id = @userId", new { userId });
            string expectedRole = user?.VaiTro switch
            {
                3 => "Quản trị viên",
                1 => "Ban tổ chức",
                2 => "Nhân viên soát vé",
                _ => "Người mua"
            };
            if (user == null || user.TrangThai == 0 || principal == null || !principal.IsInRole(expectedRole))
            {
                context.RejectPrincipal();
                await context.HttpContext.SignOutAsync(context.Scheme.Name);
            }
            else
            {
                context.Properties.Items[validationKey] = DateTimeOffset.UtcNow.ToString("O");
                context.ShouldRenew = true;
            }
        };
    })
    .AddCookie(googleExternalCookie, options =>
    {
        options.Cookie.Name = "WuangEvents.GoogleExternal";
        options.Cookie.HttpOnly = true;
        options.Cookie.SameSite = SameSiteMode.Lax;
        options.Cookie.SecurePolicy = CookieSecurePolicy.SameAsRequest;
        options.ExpireTimeSpan = TimeSpan.FromMinutes(5);
    })
    .AddGoogle(GoogleDefaults.AuthenticationScheme, options =>
    {
        options.SignInScheme = googleExternalCookie;
        options.ClientId = googleClientId;
        options.ClientSecret = googleClientSecret;
        options.CallbackPath = "/signin-google";
        options.SaveTokens = false;
        options.Events.OnRemoteFailure = context =>
        {
            string returnUrl = "/";
            if (context.Properties?.Items.TryGetValue("returnUrl", out string? savedReturnUrl) == true
                && !string.IsNullOrWhiteSpace(savedReturnUrl)
                && savedReturnUrl.StartsWith('/')
                && !savedReturnUrl.StartsWith("//"))
            {
                returnUrl = savedReturnUrl;
            }
            context.Response.Redirect(
                "/Account/DangNhap?googleError=failed&returnUrl=" + Uri.EscapeDataString(returnUrl));
            context.HandleResponse();
            return Task.CompletedTask;
        };
    });

// Hoàn thành cấu hình và tạo đối tượng web app.
var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    // Ở production, lỗi chưa bắt sẽ chuyển tới Home/Error thay vì hiện stack trace.
    app.UseExceptionHandler("/Home/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

// Middleware chạy theo đúng thứ tự từ trên xuống.
// HTTP được chuyển sang HTTPS, sau đó routing xác định endpoint.
app.UseHttpsRedirection();

// Ảnh do ban tổ chức tải lên được tạo sau thời điểm build, nên phục vụ riêng thư mục này.
string uploadsPath = Path.Combine(app.Environment.WebRootPath, "uploads");
Directory.CreateDirectory(uploadsPath);
app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new PhysicalFileProvider(uploadsPath),
    RequestPath = "/uploads"
});

app.Use(async (context, next) =>
{
    context.Response.Headers["X-Content-Type-Options"] = "nosniff";
    context.Response.Headers["X-Frame-Options"] = "SAMEORIGIN";
    context.Response.Headers["Referrer-Policy"] = "strict-origin-when-cross-origin";
    context.Response.Headers["Permissions-Policy"] = "camera=(self), microphone=(), geolocation=()";
    await next();
});
app.UseRouting();
app.UseRateLimiter();

// Session phải chạy trước Controller để BookingController đọc được bản nháp.
app.UseSession();

// Authentication phải chạy trước Authorization:
// bước đầu đọc cookie tạo User, bước sau kiểm tra [Authorize]/Roles.
app.UseAuthentication();
app.UseAuthorization();

// Cho phép phục vụ file tĩnh trong wwwroot như CSS, JS, ảnh upload.
app.MapStaticAssets();

// Route mặc định: /Controller/Action/Id-không-bắt-buộc.
// Không ghi controller/action thì dùng /Home/Index.
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}")
    .WithStaticAssets();


// Bắt đầu web server và chờ HTTP request.
app.Run();
