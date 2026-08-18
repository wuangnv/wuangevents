# WuangEvents

Website quản lý sự kiện và bán vé xây dựng bằng ASP.NET Core MVC, Razor Views,
Dapper và SQL Server.

## Yêu cầu chạy

- .NET 9 SDK và Visual Studio 2022 phiên bản hỗ trợ .NET 9.
- SQL Server/SQL Server Express.
- Chứng chỉ HTTPS phát triển của ASP.NET Core.

## Khởi tạo dữ liệu

1. Trước mỗi lần demo, chạy file `CHUAN_BI_DON_CHO_DEMO.cmd` ở thư mục cha của
   project bằng cách nhấp đúp. File tự tạo database `WuangEvents` nếu chưa có,
   xóa dữ liệu demo cũ, seed lại rồi kiểm tra dữ liệu đầu ra.
2. Nếu SQL Server không dùng tên `localhost`, mở file CMD và sửa duy nhất dòng
   `set "SQL_SERVER=localhost"`; sau đó cập nhật `ConnectionStrings:DefaultConnection`
   trong `appsettings.json` cho trùng tên máy chủ.
3. Có thể chạy trực tiếp `Database_WuangEvents.sql` trong SSMS khi cần, sau đó
   chạy `Tools/Verify-DemoData.sql` để kiểm tra bộ dữ liệu.

Seed dùng mốc tương đối theo lúc chạy: có sự kiện sắp diễn ra, đang mở check-in,
đã kết thúc, sự kiện trực tuyến, vé miễn phí/trả phí, đơn hoàn tất/hủy/hết hạn và
một đơn chờ thanh toán mới trong 10 phút. Vì script xóa và dựng lại toàn bộ bảng
trong `WuangEvents`, tuyệt đối không chạy trên database có dữ liệu thật cần giữ lại.

### Tài khoản demo chính

Mật khẩu chung của dữ liệu seed: `123456`.

| Vai trò | Email | Phạm vi dữ liệu demo |
|---|---|---|
| Quản trị viên | `admin@gmail.com` | Duyệt BTC, sự kiện, người dùng, danh mục và đơn hàng |
| Ban tổ chức | `organizer1@gmail.com` | Đủ trạng thái sự kiện, online/offline, ghế, vé, voucher, staff, đơn và check-in |
| Người mua | `battlegrounds2004@gmail.com` | Đủ đơn chờ thanh toán, hoàn tất, đã hủy và hết hạn |
| Nhân viên soát vé | `staff1@gmail.com` | Sự kiện đã được phân công để kiểm tra vé |

## Cấu hình bí mật trên máy phát triển

Không ghi khóa thật vào `appsettings.json` và không đưa `secrets.json` lên Git.
Chạy các lệnh sau trong thư mục dự án, thay phần `<...>` bằng giá trị sandbox:

```powershell
dotnet user-secrets set "VnPay:TmnCode" "<tmn-code>"
dotnet user-secrets set "VnPay:HashSecret" "<hash-secret>"
dotnet user-secrets set "MoMo:PartnerCode" "<partner-code>"
dotnet user-secrets set "MoMo:AccessKey" "<access-key>"
dotnet user-secrets set "MoMo:SecretKey" "<secret-key>"
dotnet user-secrets set "ZaloPay:AppId" "<app-id>"
dotnet user-secrets set "ZaloPay:Key1" "<key-1>"
dotnet user-secrets set "ZaloPay:Key2" "<key-2>"
dotnet user-secrets set "Authentication:Google:ClientId" "<client-id>"
dotnet user-secrets set "Authentication:Google:ClientSecret" "<client-secret>"
dotnet user-secrets set "Smtp:UserName" "<gmail>"
dotnet user-secrets set "Smtp:Password" "<gmail-app-password>"
```

Google OAuth cần khai báo redirect URI `https://localhost:7039/signin-google` cho
client phát triển. Callback server-to-server của MoMo/ZaloPay không gọi được vào
`localhost`; khi kiểm thử callback đầy đủ cần URL HTTPS công khai và cập nhật
`MoMo:NotifyUrl`, `ZaloPay:CallbackUrl` tương ứng.

## Kiểm tra trước khi nộp

```powershell
dotnet restore
dotnet build -c Release
dotnet list package --vulnerable --include-transitive
dotnet publish QuanLySuKienWuangEvents.csproj -c Release -o ./publish
```

Các ràng buộc quan trọng cần nhớ khi trình bày:

- Đơn chỉ được tạo khi người mua bấm xác nhận thanh toán; đơn chờ quá 10 phút tự hết hạn.
- Transaction mức `Serializable` cùng khóa SQL ngăn hai người mua vượt tồn vé hoặc giữ cùng ghế.
- Vé miễn phí hoàn tất ngay, không hiển thị cổng thanh toán.
- Sự kiện trực tuyến dùng đường dẫn phòng; sự kiện trực tiếp mới phát hành QR và check-in.
- Vì project không có nghiệp vụ hoàn tiền, sự kiện đã có đơn thanh toán không được phép hủy.
- Ảnh tải lên được kiểm tra dung lượng, MIME và chữ ký tệp trước khi lưu trong `wwwroot/uploads`.

Khóa sandbox từng được dùng để demo nên cần thu hồi/đổi lại trước khi triển khai
thật. Cơ sở dữ liệu seed chỉ phục vụ trình diễn, không dùng cho môi trường thật.
