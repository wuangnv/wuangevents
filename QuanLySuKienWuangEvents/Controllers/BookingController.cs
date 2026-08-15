// BOOKING CONTROLLER — chọn vé/ghế, tạo đơn chờ và nhận kết quả thanh toán.
using System.Data;
using System.Globalization;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Dapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using QRCoder;
using QuanLySuKienWuangEvents.Models;
using QuanLySuKienWuangEvents.Services;

namespace QuanLySuKienWuangEvents.Controllers;

[Authorize]
public class BookingController : Controller
{
    public const int PaymentTimeoutMinutes = 10;
    private const string DraftSessionPrefix = "booking-draft:";

    private readonly IConfiguration _configuration;
    private readonly EmailService _emailService;
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly ILogger<BookingController> _logger;
    private readonly int _paymentTimeoutMinutes;

    public BookingController(
        IConfiguration configuration,
        EmailService emailService,
        IHttpClientFactory httpClientFactory,
        ILogger<BookingController> logger)
    {
        _configuration = configuration;
        _emailService = emailService;
        _httpClientFactory = httpClientFactory;
        _logger = logger;
        _paymentTimeoutMinutes = configuration.GetValue<int?>("Booking:PaymentTimeoutMinutes")
            ?? PaymentTimeoutMinutes;
    }

    // Sự kiện có ghế đi thẳng tới sơ đồ; chưa tạo DonHang ở bước này.
    [HttpGet]
    public async Task<IActionResult> ChonGhe(Guid suKienId)
    {
        await GiaiPhongDonHangHetHan(_paymentTimeoutMinutes);

        var suKien = await Db.LayDonLe<SuKien>(
            "SELECT * FROM SuKien WHERE Id = @suKienId", new { suKienId });
        if (suKien == null || !suKien.CoSoDoChoNgoi) return NotFound();

        string? loi = KiemTraSuKienCoTheBan(suKien, LayIdNguoiDangNhap());
        if (loi != null)
        {
            TempData["Message"] = loi;
            return RedirectToAction("ChiTiet", "Home", new { id = suKienId });
        }

        ViewBag.LoaiVes = await Db.LayDanhSach<LoaiVe>(@"
            SELECT * FROM LoaiVe
            WHERE SuKienId = @suKienId AND TrangThai = 1
            ORDER BY ThuTuHienThi, Id", new { suKienId });
        return View(suKien);
    }

    // Nhận ghế hoặc số lượng vé, kiểm tra rồi lưu bản nháp vào Session.
    [HttpPost]
    [AllowAnonymous]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> DatVe(
        Guid suKienId,
        Dictionary<int, int>? veChon,
        List<int>? choNgoiIds)
    {
        // Không quay lại action POST sau đăng nhập vì trình duyệt sẽ dùng GET và gây 404.
        if (User.Identity?.IsAuthenticated != true)
        {
            string returnUrl = Url.Action("ChiTiet", "Home", new { id = suKienId }) ?? "/";
            return RedirectToAction("DangNhap", "Account", new { returnUrl });
        }

        await GiaiPhongDonHangHetHan(_paymentTimeoutMinutes);

        var suKien = await Db.LayDonLe<SuKien>(
            "SELECT * FROM SuKien WHERE Id = @suKienId", new { suKienId });
        if (suKien == null) return NotFound();

        Guid nguoiMuaId = LayIdNguoiDangNhap();
        string? loiSuKien = KiemTraSuKienCoTheBan(suKien, nguoiMuaId);
        if (loiSuKien != null)
        {
            TempData["Message"] = loiSuKien;
            return RedirectToAction("ChiTiet", "Home", new { id = suKienId });
        }

        var draft = new BookingDraft
        {
            NguoiMuaId = nguoiMuaId,
            SuKienId = suKienId,
            ChoNgoiIds = (choNgoiIds ?? new List<int>()).Where(x => x > 0).Distinct().ToList(),
            SoLuongTheoLoaiVe = (veChon ?? new Dictionary<int, int>())
                .Where(x => x.Value > 0).ToDictionary(x => x.Key, x => x.Value)
        };

        if (suKien.CoSoDoChoNgoi)
        {
            draft.SoLuongTheoLoaiVe.Clear();
            if (draft.ChoNgoiIds.Count == 0)
            {
                TempData["Error"] = "Vui lòng chọn ít nhất một ghế trên sơ đồ.";
                return RedirectToAction("ChonGhe", new { suKienId });
            }
        }
        else
        {
            draft.ChoNgoiIds.Clear();
            if (draft.SoLuongTheoLoaiVe.Count == 0)
            {
                TempData["Message"] = "Vui lòng chọn ít nhất một vé.";
                return RedirectToAction("ChiTiet", "Home", new { id = suKienId });
            }
        }

        var ketQua = await TaoModelThanhToan(draft, "");
        if (ketQua.Model == null)
        {
            TempData["Error"] = ketQua.Error;
            return suKien.CoSoDoChoNgoi
                ? RedirectToAction("ChonGhe", new { suKienId })
                : RedirectToAction("ChiTiet", "Home", new { id = suKienId });
        }

        string token = Guid.NewGuid().ToString("N");
        LuuBanNhap(token, draft);
        return RedirectToAction("ThanhToan", new { token });
    }

    // token = bản nháp chưa có DB; id = đơn đã vào cổng và đang giữ chỗ.
    [HttpGet]
    public async Task<IActionResult> ThanhToan(string? token, Guid? id)
    {
        await GiaiPhongDonHangHetHan(_paymentTimeoutMinutes);

        if (id.HasValue)
        {
            return await HienThiDonHangChoThanhToan(id.Value);
        }

        if (string.IsNullOrWhiteSpace(token)) return NotFound();
        var draft = DocBanNhap(token);
        if (draft == null || draft.NguoiMuaId != LayIdNguoiDangNhap())
        {
            TempData["Error"] = "Phiên chọn vé đã hết hạn. Vui lòng chọn lại.";
            return RedirectToAction("Index", "Home");
        }

        var ketQua = await TaoModelThanhToan(draft, token);
        if (ketQua.Model == null)
        {
            XoaBanNhap(token);
            TempData["Error"] = ketQua.Error;
            return draft.ChoNgoiIds.Count > 0
                ? RedirectToAction("ChonGhe", new { suKienId = draft.SuKienId })
                : RedirectToAction("ChiTiet", "Home", new { id = draft.SuKienId });
        }

        return View(ketQua.Model);
    }

    // Voucher chỉ cập nhật Session; database DonHang vẫn chưa có.
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> ApDungVoucher(string token, string maCode)
    {
        var draft = DocBanNhap(token);
        if (draft == null || draft.NguoiMuaId != LayIdNguoiDangNhap()) return NotFound();

        var ketQua = await TaoModelThanhToan(draft, token, boQuaVoucher: true);
        if (ketQua.Model == null)
        {
            TempData["Error"] = ketQua.Error;
            return RedirectToAction("ThanhToan", new { token });
        }

        var voucher = await TimVoucherHopLe(
            draft.SuKienId, maCode, ketQua.Model.TongTienVe, tinhDonDangCho: true);
        if (voucher == null)
        {
            TempData["Error"] = "Mã giảm giá không hợp lệ, đã hết lượt hoặc đơn chưa đủ điều kiện.";
        }
        else
        {
            draft.MaGiamGia = voucher.MaCode;
            LuuBanNhap(token, draft);
            TempData["Message"] = $"Đã áp dụng mã {voucher.MaCode}.";
        }

        return RedirectToAction("ThanhToan", new { token });
    }

    // Chỉ tại nút này mới INSERT DonHang, giữ tồn kho/ghế và chuyển sang cổng.
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> XacNhanThanhToan(string token, string phuongThuc = "vnpay")
    {
        var draft = DocBanNhap(token);
        if (draft == null || draft.NguoiMuaId != LayIdNguoiDangNhap())
        {
            TempData["Error"] = "Phiên chọn vé đã hết hạn. Vui lòng chọn lại.";
            return RedirectToAction("Index", "Home");
        }

        phuongThuc = ChuanHoaPhuongThuc(phuongThuc);
        try
        {
            var donHang = await TaoDonHangVaGiuCho(draft, phuongThuc);
            XoaBanNhap(token);

            if (donHang.TongThanhToan <= 0)
            {
                var mienPhi = await HoanTatThanhToan(donHang.Id, "FREE", 1, 0);
                return mienPhi is KetQuaThanhToan.ThanhCong or KetQuaThanhToan.DaXuLy
                    ? RedirectToAction("ThanhCong", new { id = donHang.Id })
                    : RedirectToAction("DonHangCuaToi");
            }

            return await ChuyenHuongTheoPhuongThuc(
                donHang.Id, donHang.TongThanhToan, donHang.MaDonHang, phuongThuc);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Khong the bat dau thanh toan cho ban nhap {Token}", token);
            TempData["Error"] = "Không thể bắt đầu thanh toán. Vui lòng thử lại.";
            return RedirectToAction("ThanhToan", new { token });
        }
    }

    // Cho phép tiếp tục cổng thanh toán trong thời gian 10 phút đang giữ chỗ.
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> TiepTucThanhToan(Guid id)
    {
        await GiaiPhongDonHangHetHan(_paymentTimeoutMinutes);
        var donHang = await TimDonHang(id, LayIdNguoiDangNhap());
        if (donHang == null || donHang.TrangThai != 0)
        {
            TempData["Error"] = "Đơn không còn trong thời gian chờ thanh toán.";
            return RedirectToAction("DonHangCuaToi");
        }

        string phuongThuc = donHang.PhuongThucThanhToan switch
        {
            3 => "momo",
            4 => "zalopay",
            _ => "vnpay"
        };
        return await ChuyenHuongTheoPhuongThuc(
            donHang.Id, donHang.TongThanhToan, donHang.MaDonHang, phuongThuc);
    }

    // API công khai để vẽ sơ đồ; trạng thái giữ/bán không chứa dữ liệu riêng tư.
    [HttpGet]
    [AllowAnonymous]
    public async Task<IActionResult> LaySoDoGheTheoSuKien(Guid suKienId)
    {
        await GiaiPhongDonHangHetHan();
        var ghe = await Db.LayDanhSach<dynamic>(@"
            SELECT g.Id, g.HangGheId, g.SoGhe, g.TrangThai,
                   h.TenHang, h.ThuTu AS ThuTuHang,
                   k.Id AS KhuVucId, k.TenKhuVuc, k.MauSac,
                   k.ViTriX AS KhuVucViTriX, k.ViTriY AS KhuVucViTriY,
                   k.ThuTu AS ThuTuKhuVuc,
                   sdn.LoaiSoDo, sdn.SanKhauX, sdn.SanKhauY,
                   k.LoaiVeId, lv.TenLoaiVe, lv.GiaBan, lv.GioiHanMoiDon,
                   lv.SoLuongTong - lv.SoLuongDaBan - lv.SoLuongGiuCho AS SoVeConLai,
                   lv.TrangThai AS LoaiVeDangBan,
                   CASE WHEN (lv.NgayBatDauBan IS NULL OR lv.NgayBatDauBan <= DATEADD(HOUR, 7, GETUTCDATE()))
                          AND (lv.NgayKetThucBan IS NULL OR lv.NgayKetThucBan >= DATEADD(HOUR, 7, GETUTCDATE()))
                        THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END AS TrongThoiGianBan
            FROM ChoNgoi g
            JOIN HangGhe h ON g.HangGheId = h.Id
            JOIN KhuVuc k ON h.KhuVucId = k.Id
            JOIN SoDoChoNgoi sdn ON k.SoDoChoNgoiId = sdn.Id
            JOIN LoaiVe lv ON k.LoaiVeId = lv.Id
            WHERE sdn.SuKienId = @suKienId
            ORDER BY k.ThuTu, h.ThuTu, g.ViTriX, g.Id", new { suKienId });
        return Json(ghe);
    }

    // API cũ được giữ để các liên kết cũ không lỗi.
    [HttpGet]
    [AllowAnonymous]
    public async Task<IActionResult> LaySoDoGhe(int loaiVeId)
    {
        var ghe = await Db.LayDanhSach<dynamic>(@"
            SELECT g.Id, g.SoGhe, g.TrangThai, h.TenHang, h.ThuTu AS ThuTuHang,
                   k.TenKhuVuc, k.MauSac, k.LoaiVeId
            FROM ChoNgoi g
            JOIN HangGhe h ON h.Id = g.HangGheId
            JOIN KhuVuc k ON k.Id = h.KhuVucId
            WHERE k.LoaiVeId = @loaiVeId
            ORDER BY h.ThuTu, g.ViTriX, g.Id", new { loaiVeId });
        return Json(ghe);
    }

    private async Task<DonHang> TaoDonHangVaGiuCho(BookingDraft draft, string phuongThuc)
    {
        using var connection = Db.TaoKetNoi();
        await connection.OpenAsync();
        using var transaction = connection.BeginTransaction(IsolationLevel.Serializable);

        try
        {
            var suKien = await connection.QueryFirstOrDefaultAsync<SuKien>(@"
                SELECT * FROM SuKien WITH (UPDLOCK, HOLDLOCK) WHERE Id = @id",
                new { id = draft.SuKienId }, transaction);
            if (suKien == null) throw new Exception("Sự kiện không tồn tại.");

            string? loiSuKien = KiemTraSuKienCoTheBan(suKien, draft.NguoiMuaId);
            if (loiSuKien != null) throw new Exception(loiSuKien);

            var gheDaChon = new List<GheDatVeViewModel>();
            Dictionary<int, int> soLuongTheoLoai;

            if (suKien.CoSoDoChoNgoi)
            {
                var ids = draft.ChoNgoiIds.Distinct().ToList();
                if (ids.Count == 0) throw new Exception("Bạn chưa chọn ghế.");

                gheDaChon = (await connection.QueryAsync<GheDatVeViewModel>(@"
                    SELECT g.Id, g.SoGhe, g.TrangThai, h.TenHang,
                           k.TenKhuVuc, k.MauSac, k.LoaiVeId,
                           lv.TenLoaiVe, lv.GiaBan
                    FROM ChoNgoi g WITH (UPDLOCK, HOLDLOCK)
                    JOIN HangGhe h ON h.Id = g.HangGheId
                    JOIN KhuVuc k ON k.Id = h.KhuVucId
                    JOIN SoDoChoNgoi sd ON sd.Id = k.SoDoChoNgoiId
                    JOIN LoaiVe lv ON lv.Id = k.LoaiVeId
                    WHERE sd.SuKienId = @suKienId AND g.Id IN @ids",
                    new { suKienId = draft.SuKienId, ids }, transaction)).ToList();

                if (gheDaChon.Count != ids.Count || gheDaChon.Any(x => x.TrangThai != 0))
                    throw new Exception("Có ghế vừa được người khác giữ hoặc không thuộc sự kiện. Vui lòng chọn lại.");

                soLuongTheoLoai = gheDaChon
                    .GroupBy(x => x.LoaiVeId)
                    .ToDictionary(x => x.Key, x => x.Count());
            }
            else
            {
                soLuongTheoLoai = draft.SoLuongTheoLoaiVe
                    .Where(x => x.Value > 0).ToDictionary(x => x.Key, x => x.Value);
                if (soLuongTheoLoai.Count == 0) throw new Exception("Bạn chưa chọn vé.");
            }

            var loaiVeIds = soLuongTheoLoai.Keys.ToList();
            var cacLoaiVe = (await connection.QueryAsync<LoaiVe>(@"
                SELECT * FROM LoaiVe WITH (UPDLOCK, HOLDLOCK)
                WHERE SuKienId = @suKienId AND Id IN @loaiVeIds",
                new { suKienId = draft.SuKienId, loaiVeIds }, transaction))
                .ToDictionary(x => x.Id);
            if (cacLoaiVe.Count != loaiVeIds.Count)
                throw new Exception("Có loại vé không thuộc sự kiện.");

            decimal tongTienVe = 0;
            foreach (var (loaiVeId, soLuong) in soLuongTheoLoai)
            {
                var loaiVe = cacLoaiVe[loaiVeId];
                string? loiVe = KiemTraLoaiVeCoTheBan(loaiVe, soLuong);
                if (loiVe != null) throw new Exception(loiVe);

                int daGiu = await connection.ExecuteAsync(@"
                    UPDATE LoaiVe
                    SET SoLuongGiuCho = SoLuongGiuCho + @soLuong
                    WHERE Id = @loaiVeId
                      AND SoLuongDaBan + SoLuongGiuCho + @soLuong <= SoLuongTong",
                    new { loaiVeId, soLuong }, transaction);
                if (daGiu != 1) throw new Exception($"Vé '{loaiVe.TenLoaiVe}' vừa hết.");
                tongTienVe += loaiVe.GiaBan * soLuong;
            }

            VoucherData? voucher = null;
            decimal tienGiam = 0;
            if (!string.IsNullOrWhiteSpace(draft.MaGiamGia))
            {
                voucher = await TimVoucherHopLeTrongTransaction(
                    connection, transaction, draft.SuKienId, draft.MaGiamGia, tongTienVe);
                if (voucher == null)
                    throw new Exception("Mã giảm giá vừa hết lượt hoặc không còn hiệu lực.");
                tienGiam = TinhTienGiam(voucher, tongTienVe);
            }

            decimal tongThanhToan = Math.Max(0, tongTienVe - tienGiam);
            var donHang = new DonHang
            {
                Id = Guid.NewGuid(),
                MaDonHang = "DH" + VietnamTime.Now.ToString("yyMMddHHmmss")
                    + Guid.NewGuid().ToString("N")[..6].ToUpperInvariant(),
                NguoiMuaId = draft.NguoiMuaId,
                SuKienId = draft.SuKienId,
                MaGiamGiaId = voucher?.Id,
                HoTenNguoiMua = User.Identity?.Name ?? "Khách hàng",
                EmailNguoiMua = User.FindFirstValue(ClaimTypes.Email) ?? "",
                TongTienVe = tongTienVe,
                TienGiamGia = tienGiam,
                TongThanhToan = tongThanhToan,
                TrangThai = 0,
                PhuongThucThanhToan = tongThanhToan <= 0 ? (byte)1 : MaPhuongThuc(phuongThuc),
                NgayTao = DateTime.UtcNow
            };

            await connection.ExecuteAsync(@"
                INSERT INTO DonHang
                    (Id, MaDonHang, NguoiMuaId, SuKienId, MaGiamGiaId,
                     HoTenNguoiMua, EmailNguoiMua, TongTienVe, TienGiamGia,
                     TongThanhToan, TrangThai, PhuongThucThanhToan, NgayTao)
                VALUES
                    (@Id, @MaDonHang, @NguoiMuaId, @SuKienId, @MaGiamGiaId,
                     @HoTenNguoiMua, @EmailNguoiMua, @TongTienVe, @TienGiamGia,
                     @TongThanhToan, 0, @PhuongThucThanhToan, GETUTCDATE())",
                donHang, transaction);

            const string sqlChiTiet = @"
                INSERT INTO ChiTietDonHang
                    (DonHangId, LoaiVeId, ChoNgoiId, GiaVe,
                     TenNguoiThamDu, EmailNguoiThamDu, TrangThaiCheckin)
                VALUES
                    (@donHangId, @loaiVeId, @choNgoiId, @giaVe,
                     @hoTen, @email, 0)";

            if (suKien.CoSoDoChoNgoi)
            {
                foreach (var ghe in gheDaChon)
                {
                    await connection.ExecuteAsync(sqlChiTiet, new
                    {
                        donHangId = donHang.Id,
                        loaiVeId = ghe.LoaiVeId,
                        choNgoiId = (int?)ghe.Id,
                        giaVe = cacLoaiVe[ghe.LoaiVeId].GiaBan,
                        hoTen = donHang.HoTenNguoiMua,
                        email = donHang.EmailNguoiMua
                    }, transaction);
                }

                int soGheDaGiu = await connection.ExecuteAsync(@"
                    UPDATE ChoNgoi SET TrangThai = 1
                    WHERE Id IN @ids AND TrangThai = 0",
                    new { ids = gheDaChon.Select(x => x.Id).ToList() }, transaction);
                if (soGheDaGiu != gheDaChon.Count)
                    throw new Exception("Có ghế vừa được người khác chọn. Vui lòng chọn lại.");
            }
            else
            {
                foreach (var (loaiVeId, soLuong) in soLuongTheoLoai)
                {
                    for (int i = 0; i < soLuong; i++)
                    {
                        await connection.ExecuteAsync(sqlChiTiet, new
                        {
                            donHangId = donHang.Id,
                            loaiVeId,
                            choNgoiId = (int?)null,
                            giaVe = cacLoaiVe[loaiVeId].GiaBan,
                            hoTen = donHang.HoTenNguoiMua,
                            email = donHang.EmailNguoiMua
                        }, transaction);
                    }
                }
            }

            await transaction.CommitAsync();
            return donHang;
        }
        catch
        {
            await transaction.RollbackAsync();
            throw;
        }
    }

    private async Task<IActionResult> HienThiDonHangChoThanhToan(Guid id)
    {
        var donHang = await TimDonHang(id, LayIdNguoiDangNhap());
        if (donHang == null) return NotFound();
        if (donHang.TrangThai == 1) return RedirectToAction("ThanhCong", new { id });
        if (donHang.TrangThai != 0)
        {
            TempData["Error"] = donHang.TrangThai == 4
                ? "Đơn đã hết 10 phút giữ chỗ và được tự động giải phóng."
                : "Đơn này không còn chờ thanh toán.";
            return RedirectToAction("DonHangCuaToi");
        }

        var suKien = await Db.LayDonLe<SuKien>(
            "SELECT * FROM SuKien WHERE Id = @id", new { id = donHang.SuKienId });
        if (suKien == null) return NotFound();

        var chiTiet = await Db.LayDanhSach<ChiTietDonHang>(@"
            SELECT ct.*, lv.TenLoaiVe, cn.SoGhe
            FROM ChiTietDonHang ct
            JOIN LoaiVe lv ON lv.Id = ct.LoaiVeId
            LEFT JOIN ChoNgoi cn ON cn.Id = ct.ChoNgoiId
            WHERE ct.DonHangId = @id ORDER BY ct.Id", new { id });

        return View("ChoThanhToan", new ChoThanhToanViewModel
        {
            DonHang = donHang,
            SuKien = suKien,
            ChiTiet = chiTiet,
            HetHanLucUtc = DateTime.SpecifyKind(donHang.NgayTao, DateTimeKind.Utc)
                .AddMinutes(_paymentTimeoutMinutes),
            SoPhutGiuCho = _paymentTimeoutMinutes
        });
    }

    private async Task<(ThanhToanViewModel? Model, string Error)> TaoModelThanhToan(
        BookingDraft draft, string token, bool boQuaVoucher = false)
    {
        var suKien = await Db.LayDonLe<SuKien>(
            "SELECT * FROM SuKien WHERE Id = @id", new { id = draft.SuKienId });
        if (suKien == null) return (null, "Sự kiện không tồn tại.");

        string? loiSuKien = KiemTraSuKienCoTheBan(suKien, draft.NguoiMuaId);
        if (loiSuKien != null) return (null, loiSuKien);

        var model = new ThanhToanViewModel
        {
            Token = token,
            SuKien = suKien,
            CoSoDo = suKien.CoSoDoChoNgoi
        };

        Dictionary<int, int> soLuongTheoLoai;
        if (suKien.CoSoDoChoNgoi)
        {
            var ids = draft.ChoNgoiIds.Distinct().ToList();
            if (ids.Count == 0) return (null, "Bạn chưa chọn ghế.");

            model.GheDaChon = await Db.LayDanhSach<GheDatVeViewModel>(@"
                SELECT g.Id, g.SoGhe, g.TrangThai, h.TenHang,
                       k.TenKhuVuc, k.MauSac, k.LoaiVeId,
                       lv.TenLoaiVe, lv.GiaBan
                FROM ChoNgoi g
                JOIN HangGhe h ON h.Id = g.HangGheId
                JOIN KhuVuc k ON k.Id = h.KhuVucId
                JOIN SoDoChoNgoi sd ON sd.Id = k.SoDoChoNgoiId
                JOIN LoaiVe lv ON lv.Id = k.LoaiVeId
                WHERE sd.SuKienId = @suKienId AND g.Id IN @ids
                ORDER BY k.ThuTu, h.ThuTu, g.ViTriX, g.Id",
                new { suKienId = draft.SuKienId, ids });
            if (model.GheDaChon.Count != ids.Count || model.GheDaChon.Any(x => x.TrangThai != 0))
                return (null, "Một hoặc nhiều ghế vừa được người khác giữ. Vui lòng chọn lại.");

            soLuongTheoLoai = model.GheDaChon.GroupBy(x => x.LoaiVeId)
                .ToDictionary(x => x.Key, x => x.Count());
        }
        else
        {
            soLuongTheoLoai = draft.SoLuongTheoLoaiVe
                .Where(x => x.Value > 0).ToDictionary(x => x.Key, x => x.Value);
            if (soLuongTheoLoai.Count == 0) return (null, "Bạn chưa chọn vé.");
        }

        var loaiVeIds = soLuongTheoLoai.Keys.ToList();
        var cacLoaiVe = (await Db.LayDanhSach<LoaiVe>(@"
            SELECT * FROM LoaiVe
            WHERE SuKienId = @suKienId AND Id IN @loaiVeIds",
            new { suKienId = draft.SuKienId, loaiVeIds })).ToDictionary(x => x.Id);
        if (cacLoaiVe.Count != loaiVeIds.Count) return (null, "Có loại vé không hợp lệ.");

        foreach (var (loaiVeId, soLuong) in soLuongTheoLoai)
        {
            var loaiVe = cacLoaiVe[loaiVeId];
            string? loiVe = KiemTraLoaiVeCoTheBan(loaiVe, soLuong);
            if (loiVe != null) return (null, loiVe);

            model.CacLoaiVe.Add(new DongVeThanhToanViewModel
            {
                LoaiVeId = loaiVe.Id,
                TenLoaiVe = loaiVe.TenLoaiVe,
                MauSac = loaiVe.MauSac,
                SoLuong = soLuong,
                DonGia = loaiVe.GiaBan
            });
        }

        model.CacLoaiVe = model.CacLoaiVe.OrderBy(x => cacLoaiVe[x.LoaiVeId].ThuTuHienThi).ToList();
        model.TongTienVe = model.CacLoaiVe.Sum(x => x.ThanhTien);

        if (!boQuaVoucher && !string.IsNullOrWhiteSpace(draft.MaGiamGia))
        {
            var voucher = await TimVoucherHopLe(
                draft.SuKienId, draft.MaGiamGia, model.TongTienVe, tinhDonDangCho: true);
            if (voucher != null)
            {
                model.MaGiamGia = voucher.MaCode;
                model.TienGiamGia = TinhTienGiam(voucher, model.TongTienVe);
            }
        }

        return (model, "");
    }

    private static string? KiemTraSuKienCoTheBan(SuKien suKien, Guid nguoiMuaId)
    {
        if (suKien.TrangThai != 3) return "Sự kiện hiện không trong trạng thái bán vé.";
        if (suKien.NguoiToChucId == nguoiMuaId) return "Bạn không thể mua vé sự kiện do chính mình tổ chức.";
        if (VietnamTime.Now > suKien.NgayKetThuc) return "Sự kiện đã kết thúc.";
        return null;
    }

    private static string? KiemTraLoaiVeCoTheBan(LoaiVe loaiVe, int soLuong)
    {
        DateTime now = VietnamTime.Now;
        if (!loaiVe.TrangThai) return $"Vé '{loaiVe.TenLoaiVe}' đã ngừng bán.";
        if (loaiVe.NgayBatDauBan.HasValue && now < loaiVe.NgayBatDauBan.Value)
            return $"Vé '{loaiVe.TenLoaiVe}' chưa mở bán.";
        if (loaiVe.NgayKetThucBan.HasValue && now > loaiVe.NgayKetThucBan.Value)
            return $"Vé '{loaiVe.TenLoaiVe}' đã kết thúc bán.";
        if (soLuong <= 0) return "Số lượng vé phải lớn hơn 0.";
        if (soLuong > loaiVe.GioiHanMoiDon)
            return $"Mỗi đơn chỉ được tối đa {loaiVe.GioiHanMoiDon} vé '{loaiVe.TenLoaiVe}'.";
        int conLai = loaiVe.SoLuongTong - loaiVe.SoLuongDaBan - loaiVe.SoLuongGiuCho;
        if (soLuong > conLai) return $"Vé '{loaiVe.TenLoaiVe}' chỉ còn {Math.Max(0, conLai)} vé.";
        return null;
    }

    private async Task<VoucherData?> TimVoucherHopLe(
        Guid suKienId, string maCode, decimal tongTienVe, bool tinhDonDangCho)
    {
        string sql = @"
            SELECT TOP 1 m.Id, m.MaCode, m.LoaiGiamGia, m.GiaTri, m.GiamToiDa
            FROM MaGiamGia m
            WHERE m.SuKienId = @suKienId AND m.MaCode = @maCode
              AND m.TrangThai = 1
              AND DATEADD(HOUR, 7, GETUTCDATE()) BETWEEN m.NgayBatDau AND m.NgayKetThuc
              AND ISNULL(m.DonToiThieu, 0) <= @tongTienVe
              AND m.SoLuongDaDung + CASE WHEN @tinhDonDangCho = 1 THEN
                    (SELECT COUNT(*) FROM DonHang d
                     WHERE d.MaGiamGiaId = m.Id AND d.TrangThai = 0)
                  ELSE 0 END < m.SoLuongTong";
        return await Db.LayDonLe<VoucherData>(sql, new
        {
            suKienId,
            maCode = (maCode ?? "").Trim(),
            tongTienVe,
            tinhDonDangCho
        });
    }

    private static async Task<VoucherData?> TimVoucherHopLeTrongTransaction(
        System.Data.Common.DbConnection connection,
        IDbTransaction transaction,
        Guid suKienId,
        string maCode,
        decimal tongTienVe)
    {
        return await connection.QueryFirstOrDefaultAsync<VoucherData>(@"
            SELECT TOP 1 m.Id, m.MaCode, m.LoaiGiamGia, m.GiaTri, m.GiamToiDa
            FROM MaGiamGia m WITH (UPDLOCK, HOLDLOCK)
            WHERE m.SuKienId = @suKienId AND m.MaCode = @maCode
              AND m.TrangThai = 1
              AND DATEADD(HOUR, 7, GETUTCDATE()) BETWEEN m.NgayBatDau AND m.NgayKetThuc
              AND ISNULL(m.DonToiThieu, 0) <= @tongTienVe
              AND m.SoLuongDaDung +
                    (SELECT COUNT(*) FROM DonHang d WITH (UPDLOCK, HOLDLOCK)
                     WHERE d.MaGiamGiaId = m.Id AND d.TrangThai = 0) < m.SoLuongTong",
            new { suKienId, maCode = maCode.Trim(), tongTienVe }, transaction);
    }

    private static decimal TinhTienGiam(VoucherData voucher, decimal tongTienVe)
    {
        decimal tienGiam = voucher.LoaiGiamGia == 0
            ? tongTienVe * voucher.GiaTri / 100m
            : voucher.GiaTri;
        if (voucher.GiamToiDa.HasValue) tienGiam = Math.Min(tienGiam, voucher.GiamToiDa.Value);
        return Math.Max(0, Math.Min(tienGiam, tongTienVe));
    }

    private async Task<IActionResult> ChuyenHuongTheoPhuongThuc(
        Guid id, decimal tongThanhToan, string maDonHang, string phuongThuc)
    {
        return phuongThuc switch
        {
            "momo" => await ChuyenHuongMomo(id, tongThanhToan, maDonHang),
            "zalopay" => await ChuyenHuongZaloPay(id, tongThanhToan, maDonHang),
            _ => ChuyenHuongVnPay(id, tongThanhToan, maDonHang)
        };
    }

    private IActionResult ChuyenHuongVnPay(Guid id, decimal tongThanhToan, string maDonHang)
    {
        string tmnCode = _configuration["VnPay:TmnCode"] ?? "";
        string hashSecret = _configuration["VnPay:HashSecret"] ?? "";
        string vnpayUrl = _configuration["VnPay:Url"] ?? "";
        string returnUrl = Url.Action("VnPayReturn", "Booking", null, Request.Scheme) ?? "";
        if (ThieuCauHinh(tmnCode, hashSecret, vnpayUrl, returnUrl))
            return BaoLoiCongThanhToan(id, "VNPAY");

        var vnpay = new VnPayLibrary();
        vnpay.AddRequestData("vnp_Version", "2.1.0");
        vnpay.AddRequestData("vnp_Command", "pay");
        vnpay.AddRequestData("vnp_TmnCode", tmnCode);
        vnpay.AddRequestData("vnp_Amount", ((long)(tongThanhToan * 100)).ToString());
        vnpay.AddRequestData("vnp_CreateDate", VietnamTime.Now.ToString("yyyyMMddHHmmss"));
        vnpay.AddRequestData("vnp_ExpireDate", VietnamTime.Now.AddMinutes(_paymentTimeoutMinutes).ToString("yyyyMMddHHmmss"));
        vnpay.AddRequestData("vnp_CurrCode", "VND");
        string ip = HttpContext.Connection.RemoteIpAddress?.ToString() ?? "127.0.0.1";
        vnpay.AddRequestData("vnp_IpAddr", ip is "::1" or "" ? "127.0.0.1" : ip);
        vnpay.AddRequestData("vnp_Locale", "vn");
        vnpay.AddRequestData("vnp_OrderInfo", "Thanh toan don hang " + maDonHang);
        vnpay.AddRequestData("vnp_OrderType", "other");
        vnpay.AddRequestData("vnp_ReturnUrl", returnUrl);
        vnpay.AddRequestData("vnp_TxnRef", id.ToString());
        return Redirect(vnpay.CreateRequestUrl(vnpayUrl, hashSecret));
    }

    private async Task<IActionResult> ChuyenHuongMomo(Guid id, decimal tongThanhToan, string maDonHang)
    {
        string partnerCode = _configuration["MoMo:PartnerCode"] ?? "";
        string accessKey = _configuration["MoMo:AccessKey"] ?? "";
        string secretKey = _configuration["MoMo:SecretKey"] ?? "";
        string endpoint = _configuration["MoMo:Endpoint"] ?? "";
        string returnUrl = _configuration["MoMo:ReturnUrl"]
            ?? Url.Action("MomoReturn", "Booking", null, Request.Scheme) ?? "";
        string notifyUrl = _configuration["MoMo:NotifyUrl"]
            ?? Url.Action("MomoNotify", "Booking", null, Request.Scheme) ?? "";
        string orderId = id.ToString();
        string requestId = Guid.NewGuid().ToString();
        string amount = ((long)tongThanhToan).ToString();
        string orderInfo = "Thanh toan don hang WuangEvents " + maDonHang;
        string extraData = "";
        string requestType = "payWithATM";
        if (ThieuCauHinh(partnerCode, accessKey, secretKey, endpoint, returnUrl, notifyUrl))
            return BaoLoiCongThanhToan(id, "MoMo");
        string rawHash = $"accessKey={accessKey}&amount={amount}&extraData={extraData}&ipnUrl={notifyUrl}&orderId={orderId}&orderInfo={orderInfo}&partnerCode={partnerCode}&redirectUrl={returnUrl}&requestId={requestId}&requestType={requestType}";
        string signature = TinhHmacSha256(rawHash, secretKey);

        try
        {
            using var http = _httpClientFactory.CreateClient();
            var body = new
            {
                partnerCode, accessKey, requestId, amount, orderId, orderInfo,
                redirectUrl = returnUrl, ipnUrl = notifyUrl, extraData,
                requestType, signature, lang = "vi"
            };
            using var content = new StringContent(JsonSerializer.Serialize(body), Encoding.UTF8, "application/json");
            using var response = await http.PostAsync(endpoint, content);
            using var json = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
            if (json.RootElement.TryGetProperty("payUrl", out var payUrl)
                && !string.IsNullOrWhiteSpace(payUrl.GetString()))
                return Redirect(payUrl.GetString()!);

            TempData["Error"] = "Chưa kết nối được MoMo. Đơn vẫn được giữ trong 10 phút để bạn thử lại.";
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Khong tao duoc giao dich MoMo cho don {OrderId}", id);
            TempData["Error"] = "Không thể kết nối MoMo lúc này. Vui lòng thử lại.";
        }
        return RedirectToAction("ThanhToan", new { id });
    }

    private async Task<IActionResult> ChuyenHuongZaloPay(Guid id, decimal tongThanhToan, string maDonHang)
    {
        string appId = _configuration["ZaloPay:AppId"] ?? "";
        string key1 = _configuration["ZaloPay:Key1"] ?? "";
        string key2 = _configuration["ZaloPay:Key2"] ?? "";
        string endpoint = _configuration["ZaloPay:Endpoint"] ?? "";
        string returnUrl = _configuration["ZaloPay:ReturnUrl"]
            ?? Url.Action("ZaloPayReturn", "Booking", null, Request.Scheme) ?? "";
        string callbackUrl = _configuration["ZaloPay:CallbackUrl"]
            ?? Url.Action("ZaloPayCallback", "Booking", null, Request.Scheme) ?? "";
        if (ThieuCauHinh(appId, key1, key2, endpoint, returnUrl, callbackUrl))
            return BaoLoiCongThanhToan(id, "ZaloPay");
        string appTransId = VietnamTime.Now.ToString("yyMMdd") + "_" + maDonHang
            + "_" + Random.Shared.Next(1000, 9999);
        string appUser = "WuangEventsClient";
        long appTime = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
        long amount = (long)tongThanhToan;
        string embedData = JsonSerializer.Serialize(new { redirecturl = returnUrl });
        string item = "[]";
        string description = $"Thanh toan don hang WuangEvents #{maDonHang}";
        string mac = TinhHmacSha256(
            $"{appId}|{appTransId}|{appUser}|{amount}|{appTime}|{embedData}|{item}", key1);

        try
        {
            using var http = _httpClientFactory.CreateClient();
            using var content = new FormUrlEncodedContent(new Dictionary<string, string>
            {
                ["app_id"] = appId, ["app_user"] = appUser,
                ["app_trans_id"] = appTransId, ["app_time"] = appTime.ToString(),
                ["amount"] = amount.ToString(), ["item"] = item,
                ["embed_data"] = embedData, ["description"] = description,
                ["bank_code"] = "", ["callback_url"] = callbackUrl, ["mac"] = mac
            });
            using var response = await http.PostAsync(endpoint, content);
            using var json = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
            if (json.RootElement.TryGetProperty("return_code", out var code) && code.GetInt32() == 1
                && json.RootElement.TryGetProperty("order_url", out var url)
                && !string.IsNullOrWhiteSpace(url.GetString()))
                return Redirect(url.GetString()!);

            TempData["Error"] = "Chưa kết nối được ZaloPay. Đơn vẫn được giữ trong 10 phút để bạn thử lại.";
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Khong tao duoc giao dich ZaloPay cho don {OrderId}", id);
            TempData["Error"] = "Không thể kết nối ZaloPay lúc này. Vui lòng thử lại.";
        }
        return RedirectToAction("ThanhToan", new { id });
    }

    [HttpGet]
    [AllowAnonymous]
    public async Task<IActionResult> VnPayReturn()
    {
        string hashSecret = _configuration["VnPay:HashSecret"] ?? "";
        if (string.IsNullOrWhiteSpace(hashSecret))
        {
            TempData["Error"] = "Cổng VNPAY chưa được cấu hình.";
            return RedirectToAction("DonHangCuaToi");
        }
        var vnpay = new VnPayLibrary();
        foreach (string key in Request.Query.Keys.Where(x => x.StartsWith("vnp_")))
            vnpay.AddResponseData(key, Request.Query[key].ToString());

        if (!Guid.TryParse(vnpay.GetResponseData("vnp_TxnRef"), out Guid id))
            return RedirectToAction("Index", "Home");
        if (!vnpay.ValidateSignature(
                Request.Query["vnp_SecureHash"].ToString(),
                hashSecret))
        {
            TempData["Error"] = "Chữ ký VNPAY không hợp lệ.";
            return RedirectToAction("DonHangCuaToi");
        }

        string code = vnpay.GetResponseData("vnp_ResponseCode");
        string transactionStatus = vnpay.GetResponseData("vnp_TransactionStatus");
        if (code != "00" || transactionStatus != "00")
        {
            await HuyDonHangChoThanhToan(id, 2);
            TempData["Error"] = $"Giao dịch VNPAY không thành công (mã {code}); ghế đã được trả lại.";
            return RedirectToAction("DonHangCuaToi");
        }

        decimal amount = decimal.TryParse(vnpay.GetResponseData("vnp_Amount"), out decimal raw)
            ? raw / 100m : -1;
        var ketQua = await HoanTatThanhToan(
            id, vnpay.GetResponseData("vnp_TransactionNo"), 2, amount);
        return XuLyKetQuaCallback(ketQua, id, "VNPAY");
    }

    [HttpGet]
    [AllowAnonymous]
    public async Task<IActionResult> VnPayIpn()
    {
        string hashSecret = _configuration["VnPay:HashSecret"] ?? "";
        if (string.IsNullOrWhiteSpace(hashSecret))
            return Json(new { RspCode = "99", Message = "Gateway not configured" });
        var vnpay = new VnPayLibrary();
        foreach (string key in Request.Query.Keys.Where(x => x.StartsWith("vnp_")))
            vnpay.AddResponseData(key, Request.Query[key].ToString());
        if (!Guid.TryParse(vnpay.GetResponseData("vnp_TxnRef"), out Guid id))
            return Json(new { RspCode = "01", Message = "Order not found" });
        if (!vnpay.ValidateSignature(
                Request.Query["vnp_SecureHash"].ToString(),
                hashSecret))
            return Json(new { RspCode = "97", Message = "Invalid signature" });

        if (vnpay.GetResponseData("vnp_ResponseCode") != "00"
            || vnpay.GetResponseData("vnp_TransactionStatus") != "00")
        {
            await HuyDonHangChoThanhToan(id, 2);
            return Json(new { RspCode = "00", Message = "Failed payment processed" });
        }

        decimal amount = decimal.TryParse(vnpay.GetResponseData("vnp_Amount"), out decimal raw)
            ? raw / 100m : -1;
        var ketQua = await HoanTatThanhToan(
            id, vnpay.GetResponseData("vnp_TransactionNo"), 2, amount);
        return ketQua switch
        {
            KetQuaThanhToan.ThanhCong => Json(new { RspCode = "00", Message = "Confirm Success" }),
            KetQuaThanhToan.DaXuLy => Json(new { RspCode = "02", Message = "Order already confirmed" }),
            KetQuaThanhToan.SaiSoTien => Json(new { RspCode = "04", Message = "Invalid amount" }),
            _ => Json(new { RspCode = "01", Message = "Order unavailable" })
        };
    }

    [HttpGet]
    [AllowAnonymous]
    public async Task<IActionResult> MomoReturn(
        string? partnerCode, string? orderId, string? requestId,
        string? amount, string? orderInfo, string? orderType,
        string? transId, int? resultCode, string? message,
        string? payType, string? responseTime, string? extraData, string? signature)
    {
        if (!Guid.TryParse(orderId, out Guid id)) return RedirectToAction("Index", "Home");

        string accessKey = _configuration["MoMo:AccessKey"] ?? "";
        string raw = $"accessKey={accessKey}&amount={amount}&extraData={extraData}&message={message}&orderId={orderId}&orderInfo={orderInfo}&orderType={orderType}&partnerCode={partnerCode}&payType={payType}&requestId={requestId}&responseTime={responseTime}&resultCode={resultCode}&transId={transId}";
        if (!ChuKyHopLe(raw, signature ?? "", _configuration["MoMo:SecretKey"] ?? ""))
        {
            TempData["Error"] = "Chữ ký MoMo không hợp lệ.";
            return RedirectToAction("DonHangCuaToi");
        }

        if (resultCode != 0)
        {
            await HuyDonHangChoThanhToan(id, 2);
            TempData["Error"] = "Giao dịch MoMo đã hủy; ghế đã được trả lại.";
            return RedirectToAction("DonHangCuaToi");
        }

        decimal gatewayAmount = decimal.TryParse(amount, NumberStyles.Number, CultureInfo.InvariantCulture, out decimal parsed)
            ? parsed : -1;
        var ketQua = await HoanTatThanhToan(id, transId ?? "", 3, gatewayAmount);
        return XuLyKetQuaCallback(ketQua, id, "MoMo");
    }

    [HttpPost]
    [AllowAnonymous]
    [IgnoreAntiforgeryToken]
    public async Task<IActionResult> MomoNotify([FromBody] JsonElement payload)
    {
        string partnerCode = DocGiaTriJson(payload, "partnerCode");
        string orderId = DocGiaTriJson(payload, "orderId");
        string requestId = DocGiaTriJson(payload, "requestId");
        string amount = DocGiaTriJson(payload, "amount");
        string orderInfo = DocGiaTriJson(payload, "orderInfo");
        string orderType = DocGiaTriJson(payload, "orderType");
        string transId = DocGiaTriJson(payload, "transId");
        string resultCode = DocGiaTriJson(payload, "resultCode");
        string message = DocGiaTriJson(payload, "message");
        string payType = DocGiaTriJson(payload, "payType");
        string responseTime = DocGiaTriJson(payload, "responseTime");
        string extraData = DocGiaTriJson(payload, "extraData");
        string signature = DocGiaTriJson(payload, "signature");

        if (!Guid.TryParse(orderId, out Guid id))
            return BadRequest(new { message = "Order not found" });

        string accessKey = _configuration["MoMo:AccessKey"] ?? "";
        string raw = $"accessKey={accessKey}&amount={amount}&extraData={extraData}&message={message}&orderId={orderId}&orderInfo={orderInfo}&orderType={orderType}&partnerCode={partnerCode}&payType={payType}&requestId={requestId}&responseTime={responseTime}&resultCode={resultCode}&transId={transId}";
        if (!ChuKyHopLe(raw, signature, _configuration["MoMo:SecretKey"] ?? ""))
            return Unauthorized(new { message = "Invalid signature" });

        if (resultCode != "0")
        {
            await HuyDonHangChoThanhToan(id, 2);
            return Ok(new { message = "Failed payment processed" });
        }

        decimal gatewayAmount = decimal.TryParse(
            amount, NumberStyles.Number, CultureInfo.InvariantCulture, out decimal parsed)
            ? parsed : -1;
        var ketQua = await HoanTatThanhToan(id, transId, 3, gatewayAmount);
        return ketQua switch
        {
            KetQuaThanhToan.ThanhCong or KetQuaThanhToan.DaXuLy
                => Ok(new { message = "Success" }),
            KetQuaThanhToan.SaiSoTien
                => BadRequest(new { message = "Invalid amount" }),
            _ => BadRequest(new { message = "Order unavailable" })
        };
    }

    [HttpGet]
    [AllowAnonymous]
    public async Task<IActionResult> ZaloPayReturn(
        [FromQuery] string? appid,
        [FromQuery] string? apptransid,
        [FromQuery] string? pmcid,
        [FromQuery] string? bankcode,
        [FromQuery] string? amount,
        [FromQuery] string? discountamount,
        [FromQuery] string? status,
        [FromQuery] string? checksum)
    {
        if (string.IsNullOrWhiteSpace(apptransid) || apptransid.Split('_').Length < 2)
            return RedirectToAction("Index", "Home");
        string maDonHang = apptransid.Split('_')[1];
        var donHang = await Db.LayDonLe<DonHang>(
            "SELECT * FROM DonHang WHERE MaDonHang = @maDonHang", new { maDonHang });
        if (donHang == null) return NotFound();

        string key2 = _configuration["ZaloPay:Key2"] ?? "";
        if (string.IsNullOrWhiteSpace(key2))
        {
            TempData["Error"] = "Cổng ZaloPay chưa được cấu hình.";
            return RedirectToAction("DonHangCuaToi");
        }
        string expected = TinhHmacSha256(
            $"{appid}|{apptransid}|{pmcid}|{bankcode}|{amount}|{discountamount}|{status}",
            key2);
        if (!string.Equals(checksum, expected, StringComparison.OrdinalIgnoreCase))
        {
            TempData["Error"] = "Chữ ký ZaloPay không hợp lệ.";
            return RedirectToAction("DonHangCuaToi");
        }

        // Chỉ xử lý thất bại sau khi đã xác minh checksum; nếu kiểm tra status trước,
        // kẻ lạ có thể giả URL return để hủy đơn của người khác.
        if (status != "1")
        {
            await HuyDonHangChoThanhToan(donHang.Id, 2);
            TempData["Error"] = "Giao dịch ZaloPay đã hủy; ghế đã được trả lại.";
            return RedirectToAction("DonHangCuaToi");
        }

        decimal gatewayAmount = decimal.TryParse(amount, NumberStyles.Number, CultureInfo.InvariantCulture, out decimal parsed)
            ? parsed : -1;
        var ketQua = await HoanTatThanhToan(donHang.Id, apptransid, 4, gatewayAmount);
        return XuLyKetQuaCallback(ketQua, donHang.Id, "ZaloPay");
    }

    [HttpPost]
    [AllowAnonymous]
    [IgnoreAntiforgeryToken]
    public async Task<IActionResult> ZaloPayCallback([FromBody] ZaloPayCallbackRequest? request)
    {
        if (request == null || string.IsNullOrWhiteSpace(request.Data)
            || string.IsNullOrWhiteSpace(request.Mac))
            return Json(new { return_code = -1, return_message = "Invalid payload" });

        string key2 = _configuration["ZaloPay:Key2"] ?? "";
        if (string.IsNullOrWhiteSpace(key2))
            return Json(new { return_code = -1, return_message = "Gateway not configured" });
        string expected = TinhHmacSha256(request.Data, key2);
        if (!string.Equals(request.Mac, expected, StringComparison.OrdinalIgnoreCase))
            return Json(new { return_code = -1, return_message = "Invalid signature" });

        try
        {
            using var document = JsonDocument.Parse(request.Data);
            JsonElement data = document.RootElement;
            string appTransId = DocGiaTriJson(data, "app_trans_id");
            string[] parts = appTransId.Split('_', StringSplitOptions.RemoveEmptyEntries);
            if (parts.Length < 2)
                return Json(new { return_code = 2, return_message = "Order not found" });

            string maDonHang = parts[1];
            var donHang = await Db.LayDonLe<DonHang>(
                "SELECT * FROM DonHang WHERE MaDonHang = @maDonHang", new { maDonHang });
            if (donHang == null)
                return Json(new { return_code = 2, return_message = "Order not found" });

            decimal gatewayAmount = decimal.TryParse(
                DocGiaTriJson(data, "amount"), NumberStyles.Number,
                CultureInfo.InvariantCulture, out decimal parsed) ? parsed : -1;
            string transactionId = DocGiaTriJson(data, "zp_trans_id");
            var ketQua = await HoanTatThanhToan(
                donHang.Id, transactionId, 4, gatewayAmount);

            return ketQua is KetQuaThanhToan.ThanhCong or KetQuaThanhToan.DaXuLy
                ? Json(new { return_code = 1, return_message = "Success" })
                : Json(new { return_code = 2, return_message = "Order unavailable" });
        }
        catch (JsonException ex)
        {
            _logger.LogWarning(ex, "Du lieu callback ZaloPay khong hop le");
            return Json(new { return_code = 2, return_message = "Invalid data" });
        }
    }

    private IActionResult XuLyKetQuaCallback(KetQuaThanhToan ketQua, Guid id, string tenCong)
    {
        if (ketQua is KetQuaThanhToan.ThanhCong or KetQuaThanhToan.DaXuLy)
        {
            TempData["Message"] = $"Thanh toán {tenCong} thành công.";
            return RedirectToAction("ThanhCong", new { id });
        }
        TempData["Error"] = ketQua == KetQuaThanhToan.HetHan
            ? "Giao dịch về sau khi đơn đã hết thời gian giữ chỗ. Vui lòng liên hệ hỗ trợ."
            : "Số tiền hoặc trạng thái giao dịch không khớp với đơn hàng.";
        return RedirectToAction("DonHangCuaToi");
    }

    private async Task<KetQuaThanhToan> HoanTatThanhToan(
        Guid id, string maGiaoDich, byte phuongThuc, decimal soTienCongThanhToan,
        int lanThu = 1)
    {
        using var connection = Db.TaoKetNoi();
        await connection.OpenAsync();
        using var transaction = connection.BeginTransaction(IsolationLevel.Serializable);
        try
        {
            var donHang = await connection.QueryFirstOrDefaultAsync<DonHang>(@"
                SELECT * FROM DonHang WITH (UPDLOCK, HOLDLOCK) WHERE Id = @id",
                new { id }, transaction);
            if (donHang == null) return KetQuaThanhToan.KhongHopLe;
            if (donHang.TrangThai == 1) return KetQuaThanhToan.DaXuLy;
            if (donHang.TrangThai != 0) return donHang.TrangThai == 4
                ? KetQuaThanhToan.HetHan : KetQuaThanhToan.KhongHopLe;

            if (donHang.NgayTao.AddMinutes(_paymentTimeoutMinutes) < DateTime.UtcNow)
            {
                await GiaiPhongMotDonTrongTransaction(connection, transaction, id, 4);
                await transaction.CommitAsync();
                return KetQuaThanhToan.HetHan;
            }
            if (soTienCongThanhToan != donHang.TongThanhToan)
            {
                await transaction.RollbackAsync();
                return KetQuaThanhToan.SaiSoTien;
            }

            // Khóa sự kiện trước khi đọc chi tiết và cập nhật tồn vé để giữ cùng thứ tự
            // với transaction tạo đơn, tránh deadlock khi nhiều khách chốt cùng lúc.
            var suKien = await connection.QueryFirstOrDefaultAsync<SuKien>(
                "SELECT LoaiSuKien, TrangThai, NgayKetThuc FROM SuKien WITH (UPDLOCK, HOLDLOCK) WHERE Id = @id",
                new { id = donHang.SuKienId }, transaction);
            if (suKien == null || suKien.TrangThai != 3 || suKien.NgayKetThuc <= VietnamTime.Now)
            {
                await GiaiPhongMotDonTrongTransaction(connection, transaction, id, 2);
                await transaction.CommitAsync();
                return KetQuaThanhToan.KhongHopLe;
            }
            byte loaiSuKien = suKien.LoaiSuKien;

            var thongKeVe = await connection.QueryAsync<LoaiVeSoLuong>(@"
                SELECT LoaiVeId, COUNT(*) AS SoLuong
                FROM ChiTietDonHang WHERE DonHangId = @id GROUP BY LoaiVeId",
                new { id }, transaction);
            foreach (var item in thongKeVe)
            {
                int affected = await connection.ExecuteAsync(@"
                    UPDATE LoaiVe
                    SET SoLuongGiuCho = SoLuongGiuCho - @SoLuong,
                        SoLuongDaBan = SoLuongDaBan + @SoLuong
                    WHERE Id = @LoaiVeId AND SoLuongGiuCho >= @SoLuong",
                    item, transaction);
                if (affected != 1) throw new Exception("Tồn kho giữ chỗ không khớp.");
            }

            var gheIds = (await connection.QueryAsync<int>(@"
                SELECT ChoNgoiId FROM ChiTietDonHang
                WHERE DonHangId = @id AND ChoNgoiId IS NOT NULL",
                new { id }, transaction)).ToList();
            if (gheIds.Count > 0)
            {
                int daBan = await connection.ExecuteAsync(@"
                    UPDATE ChoNgoi SET TrangThai = 2
                    WHERE Id IN @gheIds AND TrangThai = 1", new { gheIds }, transaction);
                if (daBan != gheIds.Count) throw new Exception("Trạng thái ghế giữ chỗ không khớp.");
            }

            var chiTietIds = (await connection.QueryAsync<int>(
                "SELECT Id FROM ChiTietDonHang WHERE DonHangId = @id ORDER BY Id",
                new { id }, transaction)).ToList();
            foreach (int chiTietId in chiTietIds)
            {
                string maVe = "VE" + Guid.NewGuid().ToString("N")[..16].ToUpperInvariant();
                string? maQr = loaiSuKien == 0
                    ? "QR-" + Guid.NewGuid().ToString("N").ToUpperInvariant()
                    : null;
                await connection.ExecuteAsync(@"
                    UPDATE ChiTietDonHang
                    SET MaVe = @maVe, MaQRCode = @maQr, TrangThaiCheckin = 0
                    WHERE Id = @chiTietId", new { chiTietId, maVe, maQr }, transaction);
            }

            if (donHang.MaGiamGiaId.HasValue)
            {
                int voucher = await connection.ExecuteAsync(@"
                    UPDATE MaGiamGia SET SoLuongDaDung = SoLuongDaDung + 1
                    WHERE Id = @id AND SoLuongDaDung < SoLuongTong",
                    new { id = donHang.MaGiamGiaId.Value }, transaction);
                if (voucher != 1) throw new Exception("Lượt voucher không còn hợp lệ.");
            }

            int orderUpdated = await connection.ExecuteAsync(@"
                UPDATE DonHang
                SET TrangThai = 1, MaGiaoDich = @maGiaoDich,
                    PhuongThucThanhToan = @phuongThuc,
                    NgayThanhToan = GETUTCDATE(), NgayCapNhat = GETUTCDATE()
                WHERE Id = @id AND TrangThai = 0",
                new { id, maGiaoDich, phuongThuc }, transaction);
            if (orderUpdated != 1) throw new Exception("Đơn hàng đã được xử lý.");

            await transaction.CommitAsync();
            return KetQuaThanhToan.ThanhCong;
        }
        catch (SqlException ex) when (ex.Number == 1205 && lanThu < 3)
        {
            await transaction.RollbackAsync();
            await Task.Delay(50 * lanThu);
            return await HoanTatThanhToan(
                id, maGiaoDich, phuongThuc, soTienCongThanhToan, lanThu + 1);
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            _logger.LogError(ex, "Khong the hoan tat thanh toan cho don {OrderId}", id);
            return KetQuaThanhToan.KhongHopLe;
        }
    }

    private async Task HuyDonHangChoThanhToan(Guid id, byte trangThaiMoi)
    {
        using var connection = Db.TaoKetNoi();
        await connection.OpenAsync();
        using var transaction = connection.BeginTransaction(IsolationLevel.Serializable);
        try
        {
            byte? status = await connection.QueryFirstOrDefaultAsync<byte?>(@"
                SELECT TrangThai FROM DonHang WITH (UPDLOCK, HOLDLOCK) WHERE Id = @id",
                new { id }, transaction);
            if (status == 0)
                await GiaiPhongMotDonTrongTransaction(connection, transaction, id, trangThaiMoi);
            await transaction.CommitAsync();
        }
        catch
        {
            await transaction.RollbackAsync();
        }
    }

    private static async Task GiaiPhongMotDonTrongTransaction(
        System.Data.Common.DbConnection connection,
        IDbTransaction transaction,
        Guid id,
        byte trangThaiMoi)
    {
        var gheIds = (await connection.QueryAsync<int>(@"
            SELECT ChoNgoiId FROM ChiTietDonHang
            WHERE DonHangId = @id AND ChoNgoiId IS NOT NULL",
            new { id }, transaction)).ToList();
        if (gheIds.Count > 0)
            await connection.ExecuteAsync(
                "UPDATE ChoNgoi SET TrangThai = 0 WHERE Id IN @gheIds AND TrangThai = 1",
                new { gheIds }, transaction);

        var thongKe = await connection.QueryAsync<LoaiVeSoLuong>(@"
            SELECT LoaiVeId, COUNT(*) AS SoLuong
            FROM ChiTietDonHang WHERE DonHangId = @id GROUP BY LoaiVeId",
            new { id }, transaction);
        foreach (var item in thongKe)
        {
            await connection.ExecuteAsync(@"
                UPDATE LoaiVe
                SET SoLuongGiuCho = CASE WHEN SoLuongGiuCho >= @SoLuong
                    THEN SoLuongGiuCho - @SoLuong ELSE 0 END
                WHERE Id = @LoaiVeId", item, transaction);
        }

        await connection.ExecuteAsync(@"
            UPDATE DonHang SET TrangThai = @trangThaiMoi, NgayCapNhat = GETUTCDATE()
            WHERE Id = @id AND TrangThai = 0", new { id, trangThaiMoi }, transaction);
    }

    public async Task<IActionResult> ThanhCong(Guid id)
    {
        var donHang = await TimDonHang(id, LayIdNguoiDangNhap());
        if (donHang == null || donHang.TrangThai != 1) return NotFound();
        ViewBag.SuKien = await Db.LayDonLe<SuKien>(
            "SELECT * FROM SuKien WHERE Id = @id", new { id = donHang.SuKienId });
        _ = GuiEmailVeDienTuChoDonHang(id);
        return View(donHang);
    }

    public async Task<IActionResult> DonHangCuaToi()
    {
        await GiaiPhongDonHangHetHan(_paymentTimeoutMinutes);
        Guid nguoiMuaId = LayIdNguoiDangNhap();
        var danhSach = await Db.LayDanhSach<dynamic>(@"
            SELECT dh.*, sk.TenSuKien, sk.AnhBia,
                   sk.NgayBatDau AS NgayToChucSuKien,
                   sk.TenDiaDiem AS DiaDiemSuKien,
                   sk.LoaiSuKien
            FROM DonHang dh
            LEFT JOIN SuKien sk ON sk.Id = dh.SuKienId
            WHERE dh.NguoiMuaId = @nguoiMuaId
            ORDER BY dh.NgayTao DESC", new { nguoiMuaId });
        ViewBag.PaymentTimeoutMinutes = _paymentTimeoutMinutes;
        return View(danhSach);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> HuyDonHang(Guid id)
    {
        var donHang = await TimDonHang(id, LayIdNguoiDangNhap());
        if (donHang == null || donHang.TrangThai != 0)
        {
            TempData["Error"] = "Chỉ có thể hủy đơn đang chờ thanh toán.";
            return RedirectToAction("DonHangCuaToi");
        }
        await HuyDonHangChoThanhToan(id, 2);
        TempData["Message"] = "Đã hủy đơn và giải phóng ghế giữ chỗ.";
        return RedirectToAction("DonHangCuaToi");
    }

    public async Task<IActionResult> ChiTietDonHang(Guid id)
    {
        var donHang = await TimDonHang(id, LayIdNguoiDangNhap());
        if (donHang == null) return NotFound();
        if (donHang.TrangThai != 1)
        {
            TempData["Error"] = "Chỉ đơn đã thanh toán mới có vé điện tử.";
            return RedirectToAction("DonHangCuaToi");
        }

        var suKien = await Db.LayDonLe<SuKien>(
            "SELECT * FROM SuKien WHERE Id = @id", new { id = donHang.SuKienId });
        if (suKien == null) return NotFound();

        var danhSachVe = await Db.LayDanhSach<ChiTietDonHang>(@"
            SELECT ct.*, lv.TenLoaiVe, cn.SoGhe
            FROM ChiTietDonHang ct
            JOIN LoaiVe lv ON lv.Id = ct.LoaiVeId
            LEFT JOIN ChoNgoi cn ON cn.Id = ct.ChoNgoiId
            WHERE ct.DonHangId = @id ORDER BY ct.Id", new { id });
        var qr = new Dictionary<int, string>();
        if (suKien.LoaiSuKien == 0)
        {
            foreach (var ve in danhSachVe.Where(x => !string.IsNullOrWhiteSpace(x.MaQRCode)))
                qr[ve.Id] = SinhAnhQRBase64(ve.MaQRCode!);
        }

        ViewBag.ChiTiet = danhSachVe;
        ViewBag.QrImages = qr;
        ViewBag.SuKien = suKien;
        return View(donHang);
    }

    private async Task GuiEmailVeDienTuChoDonHang(Guid donHangId)
    {
        try
        {
            using var connection = Db.TaoKetNoi();
            var donHang = await connection.QueryFirstOrDefaultAsync<dynamic>(@"
                SELECT d.MaDonHang, d.HoTenNguoiMua, d.EmailNguoiMua, d.TongThanhToan,
                       s.TenSuKien, s.NgayBatDau, s.TenDiaDiem,
                       s.LoaiSuKien, s.LinkOnline
                FROM DonHang d JOIN SuKien s ON s.Id = d.SuKienId
                WHERE d.Id = @id", new { id = donHangId });
            if (donHang == null) return;

            var ve = (await connection.QueryAsync<dynamic>(@"
                SELECT c.MaVe, c.MaQRCode, c.TenNguoiThamDu, l.TenLoaiVe, g.SoGhe
                FROM ChiTietDonHang c
                JOIN LoaiVe l ON l.Id = c.LoaiVeId
                LEFT JOIN ChoNgoi g ON g.Id = c.ChoNgoiId
                WHERE c.DonHangId = @id", new { id = donHangId })).ToList();
            await _emailService.GuiEmailVeDienTuAsync(
                (string)donHang.EmailNguoiMua,
                (string)donHang.HoTenNguoiMua,
                (string)donHang.MaDonHang,
                (string)donHang.TenSuKien,
                ((DateTime)donHang.NgayBatDau).ToString("dd/MM/yyyy HH:mm"),
                (byte)donHang.LoaiSuKien == 1 ? "Sự kiện trực tuyến" : (string)(donHang.TenDiaDiem ?? "Chưa cập nhật"),
                (decimal)donHang.TongThanhToan,
                ve,
                (byte)donHang.LoaiSuKien == 1,
                (string?)donHang.LinkOnline);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Khong gui duoc email ve cua don {OrderId}", donHangId);
        }
    }

    private Guid LayIdNguoiDangNhap()
    {
        return Guid.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out Guid id)
            ? id : Guid.Empty;
    }

    private async Task<DonHang?> TimDonHang(Guid id, Guid nguoiMuaId)
    {
        return await Db.LayDonLe<DonHang>(@"
            SELECT * FROM DonHang WHERE Id = @id AND NguoiMuaId = @nguoiMuaId",
            new { id, nguoiMuaId });
    }

    private void LuuBanNhap(string token, BookingDraft draft)
        => HttpContext.Session.SetString(DraftSessionPrefix + token, JsonSerializer.Serialize(draft));

    private BookingDraft? DocBanNhap(string token)
    {
        try
        {
            string? json = HttpContext.Session.GetString(DraftSessionPrefix + token);
            return json == null ? null : JsonSerializer.Deserialize<BookingDraft>(json);
        }
        catch
        {
            return null;
        }
    }

    private void XoaBanNhap(string token) => HttpContext.Session.Remove(DraftSessionPrefix + token);

    private static string ChuanHoaPhuongThuc(string? value)
        => value?.ToLowerInvariant() is "momo" or "zalopay" ? value.ToLowerInvariant() : "vnpay";

    private static byte MaPhuongThuc(string value) => value switch
    {
        "momo" => 3,
        "zalopay" => 4,
        _ => 2
    };

    private IActionResult BaoLoiCongThanhToan(Guid id, string tenCong)
    {
        _logger.LogWarning("Cong thanh toan {Gateway} chua duoc cau hinh day du", tenCong);
        TempData["Error"] = $"Cổng {tenCong} chưa được cấu hình. Vui lòng chọn phương thức khác.";
        return RedirectToAction("ThanhToan", new { id });
    }

    private static bool ThieuCauHinh(params string[] values)
        => values.Any(string.IsNullOrWhiteSpace);

    private static string DocGiaTriJson(JsonElement element, string propertyName)
    {
        if (!element.TryGetProperty(propertyName, out JsonElement value)
            || value.ValueKind is JsonValueKind.Null or JsonValueKind.Undefined)
            return "";
        return value.ValueKind == JsonValueKind.String
            ? value.GetString() ?? ""
            : value.GetRawText();
    }

    private static bool ChuKyHopLe(string raw, string signature, string secretKey)
    {
        if (string.IsNullOrWhiteSpace(signature) || string.IsNullOrWhiteSpace(secretKey))
            return false;
        string expected = TinhHmacSha256(raw, secretKey);
        return CryptographicOperations.FixedTimeEquals(
            Encoding.UTF8.GetBytes(expected),
            Encoding.UTF8.GetBytes(signature.ToLowerInvariant()));
    }

    private static string TinhHmacSha256(string message, string key)
    {
        using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(key));
        return Convert.ToHexString(hmac.ComputeHash(Encoding.UTF8.GetBytes(message))).ToLowerInvariant();
    }

    private static string SinhAnhQRBase64(string duLieu)
    {
        using var generator = new QRCodeGenerator();
        var data = generator.CreateQrCode(duLieu, QRCodeGenerator.ECCLevel.M);
        using var qr = new PngByteQRCode(data);
        return "data:image/png;base64," + Convert.ToBase64String(qr.GetGraphic(6));
    }

    // Mỗi request liên quan vé gọi hàm này để tự trả ghế của đơn quá 10 phút.
    public static async Task GiaiPhongDonHangHetHan(int soPhut = PaymentTimeoutMinutes)
    {
        using var connection = Db.TaoKetNoi();
        await connection.OpenAsync();
        using var transaction = connection.BeginTransaction(IsolationLevel.Serializable);
        try
        {
            var ids = (await connection.QueryAsync<Guid>(@"
                SELECT Id FROM DonHang WITH (UPDLOCK, HOLDLOCK)
                WHERE TrangThai = 0
                  AND NgayTao < DATEADD(minute, -@soPhut, GETUTCDATE())",
                new { soPhut }, transaction)).ToList();
            foreach (Guid id in ids)
                await GiaiPhongMotDonTrongTransaction(connection, transaction, id, 4);
            await transaction.CommitAsync();
        }
        catch
        {
            await transaction.RollbackAsync();
        }
    }

    private sealed class VoucherData
    {
        public int Id { get; set; }
        public string MaCode { get; set; } = "";
        public byte LoaiGiamGia { get; set; }
        public decimal GiaTri { get; set; }
        public decimal? GiamToiDa { get; set; }
    }

    // Dapper ánh xạ hai cột thống kê để cập nhật tồn kho trong cùng transaction.
    private sealed class LoaiVeSoLuong
    {
        public int LoaiVeId { get; set; }
        public int SoLuong { get; set; }
    }

    public sealed class ZaloPayCallbackRequest
    {
        public string Data { get; set; } = "";
        public string Mac { get; set; } = "";
        public int Type { get; set; }
    }

    private enum KetQuaThanhToan
    {
        ThanhCong,
        DaXuLy,
        HetHan,
        SaiSoTien,
        KhongHopLe
    }
}
