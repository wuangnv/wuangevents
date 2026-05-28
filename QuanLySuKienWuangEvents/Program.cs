using Microsoft.AspNetCore.Authentication.Cookies;
using QuanLySuKienWuangEvents.Models;

var builder = WebApplication.CreateBuilder(args);

// Khởi tạo SQL connection helper đóng gói Dapper
Db.Init(builder.Configuration.GetConnectionString("DefaultConnection") ?? "");

// Add services to the container.
builder.Services.AddControllersWithViews();
builder.Services.AddScoped<QuanLySuKienWuangEvents.Services.EmailService>();

builder.Services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
    .AddCookie(options =>
    {
        options.LoginPath = "/Account/DangNhap";
        options.LogoutPath = "/Account/DangXuat";
        options.AccessDeniedPath = "/Account/DangNhap";
        options.Cookie.Name = "WuangEvents.Student";
    });

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseRouting();

app.UseAuthentication();
app.UseAuthorization();

app.MapStaticAssets();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}")
    .WithStaticAssets();


app.Run();
