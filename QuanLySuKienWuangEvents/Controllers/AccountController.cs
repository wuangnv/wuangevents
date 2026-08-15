// ACCOUNT CONTROLLER
// Quản lý tài khoản, mật khẩu, email/OAuth; GET hiển thị và POST xử lý form.

using System.Security.Claims;
using System.Net.Mail;
using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authentication.Google;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Dapper;
using QuanLySuKienWuangEvents.Models;

using QuanLySuKienWuangEvents.Services;

namespace QuanLySuKienWuangEvents.Controllers;

public class AccountController : Controller
{
    private const string GoogleExternalCookie = "GoogleExternal";
    private readonly EmailService _emailService;
    private readonly IConfiguration _config;

    public AccountController(EmailService emailService, IConfiguration config)
    {
        _emailService = emailService;
        _config = config;
    }

    // HIỂN THỊ TRANG ĐĂNG NHẬP
    // URL: GET /Account/DangNhap
    [HttpGet]
    public IActionResult DangNhap(string? returnUrl, string? googleError)

    {
        // Lưu lại URL người dùng định vào trước khi bị yêu cầu đăng nhập
        ViewBag.ReturnUrl = returnUrl;
        if (!string.IsNullOrWhiteSpace(googleError))
        {
            ViewBag.Error = googleError == "not_configured"
                ? "Đăng nhập Google chưa được cấu hình Client ID và Client Secret."
                : "Google không thể xác thực tài khoản. Vui lòng thử lại.";
        }
        return View();
    }

    // XỬ LÝ ĐĂNG NHẬP
    // URL: POST /Account/DangNhap
    [HttpPost]
    [EnableRateLimiting("auth")]
    public async Task<IActionResult> DangNhap(string? email, string? matKhau, string? returnUrl)
    {
        // Bước 1: Tìm người dùng theo email trong database
        var nguoiDung = await TimNguoiDungTheoEmail(email);

        // Bước 2: Kiểm tra email tồn tại và mật khẩu có đúng không
        bool matKhauDung = nguoiDung != null && !string.IsNullOrEmpty(matKhau)
            && BCrypt.Net.BCrypt.Verify(matKhau, nguoiDung.MatKhauHash);
        if (!matKhauDung)
        {
            ViewBag.Error     = "Email hoặc mật khẩu không đúng.";
            ViewBag.ReturnUrl = returnUrl;
            return View();
        }

        // Bước 3: Kiểm tra tài khoản có bị khóa không
        // TrangThai = 0 → bị khóa, TrangThai = 1 → đang hoạt động
        if (nguoiDung!.TrangThai == 0)
        {
            ViewBag.Error     = "Tài khoản đang bị khóa. Liên hệ quản trị viên.";
            ViewBag.ReturnUrl = returnUrl;
            return View();
        }

        // Tài khoản đăng ký bằng mật khẩu phải bấm liên kết xác minh trước khi đăng nhập.
        if (!nguoiDung.EmailXacNhan)
        {
            ViewBag.Error = "Email chưa được xác minh. Vui lòng kiểm tra hộp thư hoặc gửi lại email xác minh.";
            ViewBag.EmailChuaXacMinh = nguoiDung.Email;
            ViewBag.ReturnUrl = returnUrl;
            return View();
        }

        // Bước 4: Tạo thông tin đăng nhập (Claims) để hệ thống nhận diện người dùng
        // Claims giống như "thẻ nhân viên" chứa thông tin cơ bản của người dùng
        var danhSachQuyen = new List<Claim>
        {
            new Claim(ClaimTypes.NameIdentifier, nguoiDung.Id.ToString()),  // ID người dùng
            new Claim(ClaimTypes.Name,           nguoiDung.HoTen),          // Họ tên
            new Claim(ClaimTypes.Email,          nguoiDung.Email),           // Email
            new Claim(ClaimTypes.Role,           LayTenVaiTro(nguoiDung.VaiTro)) // Vai trò (Admin/Organizer/User)
        };

        var thongTinDangNhap = new ClaimsIdentity(danhSachQuyen, CookieAuthenticationDefaults.AuthenticationScheme);
        await HttpContext.SignInAsync(
            CookieAuthenticationDefaults.AuthenticationScheme,
            new ClaimsPrincipal(thongTinDangNhap)
        );

        // Bước 5: Điều hướng sau khi đăng nhập thành công
        // Nếu có URL cần quay lại thì về đó, không thì về trang chủ theo vai trò
        if (!string.IsNullOrWhiteSpace(returnUrl) && Url.IsLocalUrl(returnUrl))
        {
            return Redirect(returnUrl);
        }

        // VaiTro: 3 = Admin, 1 = Organizer (Nhà tổ chức), 2 = Staff (Nhân viên soát vé), 0 = User (Khách hàng)
        if (nguoiDung.VaiTro == 3) return Redirect("/Admin/Index");
        if (nguoiDung.VaiTro == 1) return Redirect("/Organizer/Index");
        if (nguoiDung.VaiTro == 2) return Redirect("/Staff/Index");
        return RedirectToAction("Index", "Home");
    }

    // HIỂN THỊ TRANG ĐĂNG KÝ
    // URL: GET /Account/DangKy
    [HttpGet]
    public IActionResult DangKy()
    {
        return View();
    }

    // XỬ LÝ ĐĂNG KÝ TÀI KHOẢN MỚI
    // URL: POST /Account/DangKy
    [HttpPost]
    [EnableRateLimiting("auth")]
    public async Task<IActionResult> DangKy(string? hoTen, string? email, string? matKhau, string? soDienThoai)
    {
        // Bước 1: Kiểm tra dữ liệu nhập vào
        bool thongTinThieu = string.IsNullOrWhiteSpace(hoTen)
                          || string.IsNullOrWhiteSpace(email)
                          || !MailAddress.TryCreate(email, out _)
                          || matKhau is not { Length: >= 6 and <= 100 };
        if (thongTinThieu)
        {
            ViewBag.Error = "Vui lòng nhập đủ thông tin. Mật khẩu phải có ít nhất 6 ký tự.";
            return View();
        }

        // Bước 2: Kiểm tra email đã có ai dùng chưa
        var nguoiDungCu = await TimNguoiDungTheoEmail(email);
        if (nguoiDungCu != null)
        {
            ViewBag.Error = "Email này đã được đăng ký. Bạn có thể đăng nhập.";
            return View();
        }

        // Bước 3: Chuẩn bị dữ liệu để lưu vào database
        var nguoiDungId = Guid.NewGuid();
        string tokenXacNhan = Guid.NewGuid().ToString("N");
        // Dùng transaction để đảm bảo nếu có lỗi thì không lưu nửa chừng
        using var connection = Db.TaoKetNoi();
        await connection.OpenAsync();
        using var transaction = connection.BeginTransaction();
        bool daGuiEmailXacMinh = false;

        try
        {
            // Bước 4: Thêm người dùng mới vào bảng NguoiDung (EmailXacNhan = 0, TokenXacNhan)
            string sqlTaoTaiKhoan = @"
                INSERT INTO NguoiDung
                    (Id, Email, MatKhauHash, HoTen, SoDienThoai, VaiTro, TrangThai, EmailXacNhan, TokenXacNhan, NgayTao)
                VALUES
                    (@id, @email, @matKhauHash, @hoTen, @soDienThoai, 0, 1, 0, @tokenXacNhan, GETUTCDATE())
            ";
            await connection.ExecuteAsync(sqlTaoTaiKhoan, new
            {
                id           = nguoiDungId,
                email        = email!.Trim(),
                matKhauHash  = BCrypt.Net.BCrypt.HashPassword(matKhau!),
                hoTen        = hoTen!.Trim(),
                soDienThoai  = soDienThoai,
                tokenXacNhan = tokenXacNhan
            }, transaction);

            // Bước 6: Lưu tất cả vào database
            await transaction.CommitAsync();

            // Gửi email xác minh tài khoản
            string callbackUrl = Url.Action("XacMinhEmail", "Account", new { token = tokenXacNhan }, Request.Scheme) ?? "";
            daGuiEmailXacMinh = await _emailService.GuiEmailXacMinhAsync(email!.Trim(), hoTen!.Trim(), tokenXacNhan, callbackUrl);
        }
        catch
        {
            // Nếu có lỗi thì hủy bỏ toàn bộ, không lưu gì cả
            await transaction.RollbackAsync();
            throw;
        }

        TempData[daGuiEmailXacMinh ? "Message" : "Error"] = daGuiEmailXacMinh
            ? "Đăng ký thành công. Vui lòng kiểm tra email để xác minh tài khoản."
            : "Tạo tài khoản thành công nhưng chưa gửi được email xác minh. Vui lòng thử gửi lại sau.";
        return RedirectToAction("DangNhap");

    }

    // GET /Account/HoSo: hiển thị hồ sơ của tài khoản đã đăng nhập.
    [Authorize]
    [HttpGet]
    public async Task<IActionResult> HoSo()
    {
        // Lấy ID người đang đăng nhập từ cookie phiên làm việc
        var nguoiDungId = LayIdNguoiDangNhap();

        // Lấy thông tin đầy đủ từ database
        var nguoiDung = await TimNguoiDungTheoId(nguoiDungId);

        if (nguoiDung == null)
        {
            return NotFound();
        }

        return View(nguoiDung);
    }

    // CẬP NHẬT HỒ SƠ CÁ NHÂN
    // URL: POST /Account/CapNhatHoSo
    [Authorize]
    [HttpPost]
    public async Task<IActionResult> CapNhatHoSo(string? hoTen, string? soDienThoai, string? anhDaiDien)
    {
        string tenChuan = hoTen?.Trim() ?? "";
        string dienThoaiChuan = Regex.Replace(soDienThoai ?? "", @"[\s\.\-\(\)]", "");
        string anhChuan = anhDaiDien?.Trim() ?? "";
        bool anhHopLe = string.IsNullOrEmpty(anhChuan)
            || (Uri.TryCreate(anhChuan, UriKind.Absolute, out Uri? uri)
                && uri.Scheme is "http" or "https")
            || (anhChuan.StartsWith('/') && !anhChuan.StartsWith("//") && !anhChuan.Contains('\\'));
        if (tenChuan.Length is < 2 or > 100
            || (!string.IsNullOrEmpty(dienThoaiChuan)
                && !Regex.IsMatch(dienThoaiChuan, @"^0(3|5|7|8|9)\d{8}$"))
            || !anhHopLe || anhChuan.Length > 500)
        {
            TempData["Error"] = "Thông tin hồ sơ không hợp lệ. Vui lòng kiểm tra họ tên, số điện thoại và ảnh đại diện.";
            return RedirectToAction("HoSo");
        }

        string sql = @"
            UPDATE NguoiDung
            SET HoTen       = @hoTen,
                SoDienThoai = @soDienThoai,
                AnhDaiDien  = @anhDaiDien,
                NgayCapNhat = GETUTCDATE()
            WHERE Id = @id
        ";

        await Db.ThucThi(sql, new
        {
            id          = LayIdNguoiDangNhap(),
            hoTen       = tenChuan,
            soDienThoai = string.IsNullOrEmpty(dienThoaiChuan) ? null : dienThoaiChuan,
            anhDaiDien  = string.IsNullOrEmpty(anhChuan) ? null : anhChuan
        });

        TempData["Message"] = "Đã cập nhật hồ sơ thành công.";
        return RedirectToAction("HoSo");
    }

    // ĐỔI MẬT KHẨU
    // URL: POST /Account/DoiMatKhau
    [Authorize]
    [HttpPost]
    public async Task<IActionResult> DoiMatKhau(string? matKhauCu, string? matKhauMoi)
    {
        // Lấy thông tin người đang đăng nhập
        var nguoiDung = await TimNguoiDungTheoId(LayIdNguoiDangNhap());

        // Kiểm tra mật khẩu cũ có đúng không
        bool matKhauCuDung = nguoiDung != null && !string.IsNullOrEmpty(matKhauCu)
            && BCrypt.Net.BCrypt.Verify(matKhauCu, nguoiDung.MatKhauHash);
        if (!matKhauCuDung)
        {
            TempData["Error"] = "Mật khẩu cũ không đúng.";
            return RedirectToAction("HoSo");
        }

        // Kiểm tra mật khẩu mới có đủ dài không
        if (matKhauMoi is not { Length: >= 6 and <= 100 })
        {
            TempData["Error"] = "Mật khẩu mới phải có ít nhất 6 ký tự.";
            return RedirectToAction("HoSo");
        }

        // Cập nhật mật khẩu mới (đã mã hóa) vào database
        string sql = @"
            UPDATE NguoiDung
            SET MatKhauHash = @hash,
                NgayCapNhat = GETUTCDATE()
            WHERE Id = @id
        ";
        await Db.ThucThi(sql, new
        {
            id   = nguoiDung!.Id,
            hash = BCrypt.Net.BCrypt.HashPassword(matKhauMoi)
        });

        TempData["Message"] = "Đổi mật khẩu thành công.";
        return RedirectToAction("HoSo");
    }

    // HIỂN THỊ TRANG QUÊN MẬT KHẨU
    // URL: GET /Account/QuenMatKhau
    [HttpGet]
    public IActionResult QuenMatKhau()
    {
        return View();
    }

    // XỬ LÝ QUÊN MẬT KHẨU
    // URL: POST /Account/QuenMatKhau
    [HttpPost]
    [EnableRateLimiting("auth")]
    public async Task<IActionResult> QuenMatKhau(string? email)
    {
        // Tìm người dùng theo email
        var nguoiDung = await TimNguoiDungTheoEmail(email);

        if (nguoiDung != null && nguoiDung.EmailXacNhan && nguoiDung.TrangThai == 1)
        {
            string token = Guid.NewGuid().ToString("N");
            string sql = @"
                UPDATE NguoiDung
                SET TokenXacNhan = @token, NgayCapNhat = GETUTCDATE()
                WHERE Id = @id AND EmailXacNhan = 1 AND TrangThai = 1
            ";
            await Db.ThucThi(sql, new { token, id = nguoiDung.Id });

            string callbackUrl = Url.Action(
                "DatLaiMatKhau", "Account", new { token }, Request.Scheme) ?? "";
            await _emailService.GuiEmailDatLaiMatKhauAsync(
                nguoiDung.Email, nguoiDung.HoTen, callbackUrl);
        }

        ViewBag.Message = "Nếu email hợp lệ, hướng dẫn đặt lại mật khẩu sẽ được gửi.";
        return View();
    }

    // HIỂN THỊ TRANG ĐẶT LẠI MẬT KHẨU
    // URL: GET /Account/DatLaiMatKhau?token=xxx
    [HttpGet]
    public async Task<IActionResult> DatLaiMatKhau(string token)
    {
        int hopLe = string.IsNullOrWhiteSpace(token) ? 0 : await Db.LayGiaTri<int>(@"
            SELECT COUNT(1) FROM NguoiDung
            WHERE TokenXacNhan = @token AND EmailXacNhan = 1 AND TrangThai = 1
              AND NgayCapNhat >= DATEADD(minute, -30, GETUTCDATE())", new { token });
        if (hopLe == 0)
        {
            TempData["Error"] = "Liên kết đặt lại mật khẩu không hợp lệ hoặc đã hết hạn.";
            return RedirectToAction("QuenMatKhau");
        }
        ViewBag.Token = token;
        return View();
    }

    // XỬ LÝ ĐẶT LẠI MẬT KHẨU
    // URL: POST /Account/DatLaiMatKhau
    [HttpPost]
    [EnableRateLimiting("auth")]
    public async Task<IActionResult> DatLaiMatKhau(string? token, string? matKhauMoi)
    {
        // Kiểm tra token và mật khẩu mới có hợp lệ không
        if (string.IsNullOrWhiteSpace(token) || matKhauMoi is not { Length: >= 6 and <= 100 })
        {
            ViewBag.Error = "Liên kết không hợp lệ hoặc mật khẩu quá ngắn (tối thiểu 6 ký tự).";
            ViewBag.Token = token;
            return View();
        }

        // Cập nhật mật khẩu mới cho tài khoản có token trùng khớp
        // Đồng thời xóa token đi để không dùng lại được
        string sql = @"
            UPDATE NguoiDung
            SET MatKhauHash  = @hash,
                TokenXacNhan = NULL,
                NgayCapNhat  = GETUTCDATE()
            WHERE TokenXacNhan = @token
              AND EmailXacNhan = 1 AND TrangThai = 1
              AND NgayCapNhat >= DATEADD(minute, -30, GETUTCDATE())
        ";
        int soHangCapNhat = await Db.ThucThi(sql, new
        {
            hash  = BCrypt.Net.BCrypt.HashPassword(matKhauMoi),
            token = token
        });

        // Nếu không có hàng nào được cập nhật → token không hợp lệ hoặc đã dùng rồi
        if (soHangCapNhat == 0)
        {
            ViewBag.Error = "Liên kết đặt lại mật khẩu không hợp lệ hoặc đã được sử dụng.";
            ViewBag.Token = token;
            return View();
        }

        TempData["Message"] = "Đặt lại mật khẩu thành công. Bạn có thể đăng nhập.";
        return RedirectToAction("DangNhap");
    }

    // ĐĂNG XUẤT
    [Authorize]
    [HttpPost]
    public async Task<IActionResult> DangXuat()
    {
        // Xóa cookie phiên đăng nhập
        await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
        return RedirectToAction("Index", "Home");
    }

    // TRANG THÔNG BÁO TỪ CHỐI TRUY CẬP (403 Forbidden)
    // URL: GET /Account/TuChoiTruyCap
    public IActionResult TuChoiTruyCap()
    {
        return View();
    }

    // CÁC HÀM HỖ TRỢ (Private helpers — chỉ dùng trong controller này)

    // Lấy ID của người đang đăng nhập từ cookie
    private Guid LayIdNguoiDangNhap()
    {
        string? idChuoi = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.TryParse(idChuoi, out Guid id) ? id : Guid.Empty;
    }

    // Tìm người dùng theo email (trả về null nếu không có)
    private async Task<NguoiDung?> TimNguoiDungTheoEmail(string? email)
    {
        if (string.IsNullOrWhiteSpace(email)) return null;
        string sql = "SELECT * FROM NguoiDung WHERE Email = @email";
        return await Db.LayDonLe<NguoiDung>(sql, new { email = email.Trim() });
    }

    // Tìm người dùng theo ID (trả về null nếu không có)
    private async Task<NguoiDung?> TimNguoiDungTheoId(Guid id)
    {
        string sql = "SELECT * FROM NguoiDung WHERE Id = @id";
        return await Db.LayDonLe<NguoiDung>(sql, new { id });
    }

    // ĐĂNG KÝ / XEM TRẠNG THÁI YÊU CẦU LÊN BAN TỔ CHỨC
    // URL: GET /Account/YeuCauBanToChuc
    [Authorize]
    [HttpGet]
    public async Task<IActionResult> YeuCauBanToChuc()
    {
        var userId = LayIdNguoiDangNhap();
        var user = await TimNguoiDungTheoId(userId);
        if (user == null) return NotFound();

        if (!user.EmailXacNhan)
        {
            TempData["Error"] = "Bạn cần xác minh email trước khi gửi hồ sơ Ban tổ chức.";
            return RedirectToAction("DangNhap");
        }

        if (user.VaiTro == 1 || user.YeuCauBanToChuc == 2)
        {
            TempData["Message"] = "Tài khoản của bạn đã là Ban tổ chức.";
            return RedirectToAction("Index", "Home");
        }

        return View(user);
    }

    // GỬI YÊU CẦU LÊN BAN TỔ CHỨC
    // URL: POST /Account/GuiYeuCauBanToChuc
    [Authorize]
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> GuiYeuCauBanToChuc(
        string sdt,
        string hoTen,
        string tenToChuc,
        byte? loaiChuTheBTC,
        string moTaYeuCauBTC,
        bool daDongYDieuKhoanBTC)
    {
        var userId = LayIdNguoiDangNhap();
        var user = await TimNguoiDungTheoId(userId);
        if (user == null) return NotFound();

        string sdtChuan = Regex.Replace(sdt ?? "", @"[\s\.\-\(\)]", "");
        string hoTenChuan = hoTen?.Trim() ?? "";
        string tenToChucChuan = tenToChuc?.Trim() ?? "";
        string moTaChuan = moTaYeuCauBTC?.Trim() ?? "";

        user.HoTen = hoTenChuan;
        user.SdtBanToChuc = sdtChuan;
        user.TenToChuc = tenToChucChuan;
        user.LoaiChuTheBTC = loaiChuTheBTC;
        user.MoTaYeuCauBTC = moTaChuan;
        user.DaDongYDieuKhoanBTC = daDongYDieuKhoanBTC;

        string? loi = null;
        if (!user.EmailXacNhan) loi = "Bạn cần xác minh email trước khi gửi hồ sơ.";
        else if (user.YeuCauBanToChuc == 1) loi = "Hồ sơ của bạn đang chờ Admin phê duyệt.";
        else if (hoTenChuan.Length < 2 || hoTenChuan.Length > 100) loi = "Họ và tên phải có từ 2 đến 100 ký tự.";
        else if (!Regex.IsMatch(sdtChuan, @"^0(3|5|7|8|9)\d{8}$")) loi = "Số điện thoại Việt Nam không hợp lệ.";
        else if (tenToChucChuan.Length < 2 || tenToChucChuan.Length > 150) loi = "Tên Ban tổ chức phải có từ 2 đến 150 ký tự.";
        else if (loaiChuTheBTC is not (0 or 1)) loi = "Vui lòng chọn loại chủ thể tổ chức.";
        else if (moTaChuan.Length < 30 || moTaChuan.Length > 1000) loi = "Phần giới thiệu phải có từ 30 đến 1000 ký tự.";
        else if (!daDongYDieuKhoanBTC) loi = "Bạn cần cam kết thông tin chính xác và đồng ý điều khoản tổ chức.";

        if (loi != null)
        {
            TempData["Error"] = loi;
            return View("YeuCauBanToChuc", user);
        }

        string sqlUpdate = @"
            UPDATE NguoiDung
            SET YeuCauBanToChuc = 1,
                SdtBanToChuc = @sdt,
                HoTen = @hoTen,
                SoDienThoai = @sdt,
                TenToChuc = @tenToChuc,
                LoaiChuTheBTC = @loaiChuTheBTC,
                MoTaYeuCauBTC = @moTaYeuCauBTC,
                DaDongYDieuKhoanBTC = 1,
                LyDoTuChoiBTC = NULL,
                NgayYeuCauBTC = GETUTCDATE(),
                NgayCapNhat = GETUTCDATE()
            WHERE Id = @id
              AND VaiTro = 0
              AND EmailXacNhan = 1
              AND YeuCauBanToChuc IN (0, 3)
        ";

        int rows = await Db.ThucThi(sqlUpdate, new
        {
            id = userId,
            sdt = sdtChuan,
            hoTen = hoTenChuan,
            tenToChuc = tenToChucChuan,
            loaiChuTheBTC,
            moTaYeuCauBTC = moTaChuan
        });
        if (rows > 0)
        {
            TempData["Message"] = "Gửi yêu cầu trở thành Ban tổ chức thành công. Vui lòng chờ Admin phê duyệt!";
        }
        else
        {
            TempData["Error"] = "Gửi yêu cầu thất bại hoặc tài khoản của bạn không hợp lệ.";
        }

        return RedirectToAction("YeuCauBanToChuc");
    }

    // XÁC MINH EMAIL TÀI KHOẢN
    // URL: GET /Account/XacMinhEmail?token=...
    [HttpGet]
    public async Task<IActionResult> XacMinhEmail(string token)
    {
        if (string.IsNullOrWhiteSpace(token))
        {
            TempData["Error"] = "Mã xác minh không hợp lệ.";
            return RedirectToAction("DangNhap");
        }

        using var connection = Db.TaoKetNoi();
        int rows = await connection.ExecuteAsync(@"
            UPDATE NguoiDung
            SET EmailXacNhan = 1, TokenXacNhan = NULL
            WHERE TokenXacNhan = @token", new { token = token.Trim() });

        if (rows > 0)
        {
            TempData["Message"] = "🎉 Email của bạn đã được xác minh thành công! Vui lòng đăng nhập.";
        }
        else
        {
            TempData["Error"] = "Liên kết xác minh không hợp lệ hoặc đã được sử dụng từ trước.";
        }

        return RedirectToAction("DangNhap");
    }

    // Tạo token mới và gửi lại email khi người dùng chưa xác minh.
    [HttpPost]
    [ValidateAntiForgeryToken]
    [EnableRateLimiting("auth")]
    public async Task<IActionResult> GuiLaiEmailXacMinh(string email)
    {
        var user = await TimNguoiDungTheoEmail(email ?? "");
        if (user == null || user.EmailXacNhan)
        {
            TempData["Message"] = "Nếu email cần xác minh tồn tại, hệ thống sẽ gửi lại hướng dẫn.";
            return RedirectToAction("DangNhap");
        }

        string tokenMoi = Guid.NewGuid().ToString("N");
        await Db.ThucThi(@"
            UPDATE NguoiDung
            SET TokenXacNhan = @token, NgayCapNhat = GETUTCDATE()
            WHERE Id = @id AND EmailXacNhan = 0", new { id = user.Id, token = tokenMoi });

        string callbackUrl = Url.Action("XacMinhEmail", "Account", new { token = tokenMoi }, Request.Scheme) ?? "";
        bool daGui = await _emailService.GuiEmailXacMinhAsync(user.Email, user.HoTen, tokenMoi, callbackUrl);
        TempData[daGui ? "Message" : "Error"] = daGui
            ? "Email xác minh đã được gửi lại. Vui lòng kiểm tra cả thư rác."
            : "Chưa thể gửi email xác minh lúc này. Vui lòng thử lại sau.";
        return RedirectToAction("DangNhap");
    }

    // Bắt đầu OAuth; middleware tự tạo state chống giả mạo và chuyển sang Google.
    [HttpGet]
    public IActionResult GoogleLogin(string? returnUrl)
    {
        if (!GoogleDaDuocCauHinh())
        {
            return RedirectToAction("DangNhap", new { returnUrl, googleError = "not_configured" });
        }

        string duongDanQuayLai = !string.IsNullOrWhiteSpace(returnUrl) && Url.IsLocalUrl(returnUrl)
            ? returnUrl
            : Url.Action("Index", "Home") ?? "/";
        string callback = Url.Action(nameof(GoogleCallback), "Account", new { returnUrl = duongDanQuayLai })
            ?? "/Account/GoogleCallback";

        var properties = new AuthenticationProperties { RedirectUri = callback };
        properties.Items["returnUrl"] = duongDanQuayLai;
        return Challenge(properties, GoogleDefaults.AuthenticationScheme);
    }

    // Google middleware đã xác thực xong; action này liên kết hồ sơ Google với NguoiDung.
    [HttpGet]
    public async Task<IActionResult> GoogleCallback(string? returnUrl)
    {
        var ketQuaGoogle = await HttpContext.AuthenticateAsync(GoogleExternalCookie);
        if (!ketQuaGoogle.Succeeded || ketQuaGoogle.Principal == null)
        {
            return RedirectToAction("DangNhap", new { returnUrl, googleError = "failed" });
        }

        string googleEmail = ketQuaGoogle.Principal.FindFirstValue(ClaimTypes.Email)?.Trim() ?? "";
        string googleHoTen = ketQuaGoogle.Principal.FindFirstValue(ClaimTypes.Name)?.Trim() ?? "";
        if (string.IsNullOrWhiteSpace(googleEmail))
        {
            await HttpContext.SignOutAsync(GoogleExternalCookie);
            return RedirectToAction("DangNhap", new { returnUrl, googleError = "failed" });
        }
        if (string.IsNullOrWhiteSpace(googleHoTen)) googleHoTen = googleEmail.Split('@')[0];

        var nguoiDung = await TimNguoiDungTheoEmail(googleEmail);
        if (nguoiDung == null)
        {
            var newId = Guid.NewGuid();
            string matKhauNgauNhien = Guid.NewGuid().ToString("N") + Guid.NewGuid().ToString("N");
            using var connection = Db.TaoKetNoi();
            await connection.ExecuteAsync(@"
                INSERT INTO NguoiDung
                    (Id, Email, MatKhauHash, HoTen, VaiTro, TrangThai, EmailXacNhan, NgayTao)
                VALUES
                    (@newId, @email, @hash, @hoTen, 0, 1, 1, GETUTCDATE())",
                new
                {
                    newId,
                    email = googleEmail,
                    hash = BCrypt.Net.BCrypt.HashPassword(matKhauNgauNhien),
                    hoTen = googleHoTen
                });
            nguoiDung = await TimNguoiDungTheoEmail(googleEmail);
        }

        if (nguoiDung == null || nguoiDung.TrangThai == 0)
        {
            await HttpContext.SignOutAsync(GoogleExternalCookie);
            TempData["Error"] = "Tài khoản Google này hiện đang bị khóa.";
            return RedirectToAction("DangNhap", new { returnUrl });
        }

        await HttpContext.SignOutAsync(GoogleExternalCookie);
        var claims = new List<Claim>
        {
            new Claim(ClaimTypes.NameIdentifier, nguoiDung.Id.ToString()),
            new Claim(ClaimTypes.Name, nguoiDung.HoTen),
            new Claim(ClaimTypes.Email, nguoiDung.Email),
            new Claim(ClaimTypes.Role, LayTenVaiTro(nguoiDung.VaiTro))
        };
        var identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
        await HttpContext.SignInAsync(
            CookieAuthenticationDefaults.AuthenticationScheme,
            new ClaimsPrincipal(identity));

        TempData["Message"] = $"Chào mừng {nguoiDung.HoTen} đã đăng nhập bằng Google.";
        if (!string.IsNullOrWhiteSpace(returnUrl) && Url.IsLocalUrl(returnUrl)) return Redirect(returnUrl);
        if (nguoiDung.VaiTro == 3) return Redirect("/Admin/Index");
        if (nguoiDung.VaiTro == 1) return Redirect("/Organizer/Index");
        if (nguoiDung.VaiTro == 2) return Redirect("/Staff/Index");
        return RedirectToAction("Index", "Home");
    }

    private bool GoogleDaDuocCauHinh()
    {
        string clientId = _config["Authentication:Google:ClientId"] ?? "";
        string clientSecret = _config["Authentication:Google:ClientSecret"] ?? "";
        return !string.IsNullOrWhiteSpace(clientId)
            && clientId.EndsWith(".apps.googleusercontent.com", StringComparison.OrdinalIgnoreCase)
            && !clientId.Contains("demo", StringComparison.OrdinalIgnoreCase)
            && !string.IsNullOrWhiteSpace(clientSecret)
            && !clientSecret.Contains("demo", StringComparison.OrdinalIgnoreCase);
    }

    // Chuyển số vai trò thành tên vai trò
    // VaiTro: 3 = Quản trị viên, 1 = Ban tổ chức, 2 = Nhân viên soát vé, 0 = Người mua
    private static string LayTenVaiTro(byte vaiTro)
    {
        if (vaiTro == 3) return "Quản trị viên";
        if (vaiTro == 1) return "Ban tổ chức";
        if (vaiTro == 2) return "Nhân viên soát vé";
        return "Người mua";
    }
}

