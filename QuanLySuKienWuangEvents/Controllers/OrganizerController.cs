// ORGANIZER CONTROLLER — Phân hệ Ban Tổ Chức
// Quản lý toàn bộ nghiệp vụ BTC; SQL luôn kiểm tra NguoiToChucId để phân quyền.

using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Dapper;
using QuanLySuKienWuangEvents.Models;

namespace QuanLySuKienWuangEvents.Controllers;

[Authorize(Roles = "Ban tổ chức,Quản trị viên")] // Yêu cầu đăng nhập với quyền Nhà tổ chức hoặc Admin
[Route("Organizer/[action]/{id?}")]    // Đường dẫn mẫu: /Organizer/SuKien, /Organizer/TaoMoiSuKien, ...
public class OrganizerController : Controller
{
    private readonly ILogger<OrganizerController> _logger;
    private readonly IWebHostEnvironment _environment;

    public OrganizerController(
        ILogger<OrganizerController> logger,
        IWebHostEnvironment environment)
    {
        _logger = logger;
        _environment = environment;
    }

    // 1. DASHBOARD & THỐNG KÊ

    // TRANG CHỦ DASHBOARD NHÀ TỔ CHỨC
    // URL: GET /Organizer/Index
    public async Task<IActionResult> Index()
    {
        var organizerId = LayIdNguoiDangNhap();

        // Thống kê 1: Tổng số sự kiện đã tạo
        string sqlSoSuKien = @"
            SELECT COUNT(*)
            FROM SuKien
            WHERE NguoiToChucId = @organizerId
        ";
        ViewBag.SoSuKien = await Db.LayGiaTri<int>(sqlSoSuKien, new { organizerId });

        // Thống kê 2: Tổng số đơn đặt vé từ khách hàng
        string sqlSoDonHang = @"
            SELECT COUNT(*)
            FROM DonHang d
            JOIN SuKien s ON s.Id = d.SuKienId
            WHERE s.NguoiToChucId = @organizerId
        ";
        ViewBag.SoDonHang = await Db.LayGiaTri<int>(sqlSoDonHang, new { organizerId });

        // Thống kê 3: Tổng doanh thu từ các đơn hàng đã thanh toán thành công (TrangThai = 1)
        string sqlDoanhThu = @"
            SELECT ISNULL(SUM(d.TongThanhToan), 0)
            FROM DonHang d
            JOIN SuKien s ON s.Id = d.SuKienId
            WHERE s.NguoiToChucId = @organizerId
              AND d.TrangThai = 1
        ";
        ViewBag.DoanhThu = await Db.LayGiaTri<decimal>(sqlDoanhThu, new { organizerId });

        return View();
    }

    // 2. QUẢN LÝ SỰ KIỆN

    // DANH SÁCH SỰ KIỆN CỦA TÔI
    // URL: GET /Organizer/SuKien
    public async Task<IActionResult> SuKien()
    {
        var organizerId = LayIdNguoiDangNhap();

        // Lấy danh sách sự kiện kèm theo thống kê doanh thu và vé đã bán của từng sự kiện
        string sql = @"
            SELECT s.*,
                   (SELECT COUNT(*) FROM ChiTietDonHang c JOIN DonHang d ON d.Id = c.DonHangId WHERE d.SuKienId = s.Id AND d.TrangThai = 1) AS VeDaBan,
                   (SELECT ISNULL(SUM(d.TongThanhToan), 0) FROM DonHang d WHERE d.SuKienId = s.Id AND d.TrangThai = 1) AS DoanhThu,
                   (SELECT ISNULL(SUM(SoLuongTong), 0) FROM LoaiVe WHERE SuKienId = s.Id) AS TongVe
            FROM SuKien s
            WHERE s.NguoiToChucId = @organizerId
            ORDER BY s.NgayTao DESC
        ";
        var list = await Db.LayDanhSach<SuKien>(sql, new { organizerId });
        return View(list);
    }

    // XEM CHI TIẾT SỰ KIỆN
    // URL: GET /Organizer/ChiTietSuKien/{id}
    public async Task<IActionResult> ChiTietSuKien(Guid id)
    {
        if (!await LaSuKienCuaToi(id)) return NotFound();

        string sql = "SELECT * FROM SuKien WHERE Id = @id";
        var suKien = await Db.LayDonLe<SuKien>(sql, new { id });
        if (suKien == null) return NotFound();

        if (suKien.DanhMucId > 0)
        {
            ViewBag.TenDanhMuc = await Db.LayGiaTri<string>("SELECT TenDanhMuc FROM DanhMuc WHERE Id = @id", new { id = suKien.DanhMucId });
        }

        // Lấy thống kê vé & doanh thu
        string sqlStats = @"
            SELECT 
                (SELECT COUNT(*) FROM ChiTietDonHang c JOIN DonHang d ON d.Id = c.DonHangId WHERE d.SuKienId = @id AND d.TrangThai = 1) AS VeDaBan,
                (SELECT ISNULL(SUM(d.TongThanhToan), 0) FROM DonHang d WHERE d.SuKienId = @id AND d.TrangThai = 1) AS DoanhThu,
                (SELECT ISNULL(SUM(SoLuongTong), 0) FROM LoaiVe WHERE SuKienId = @id) AS TongVe
        ";
        var stats = await Db.LayDonLe<dynamic>(sqlStats, new { id });
        ViewBag.VeDaBan = stats?.VeDaBan ?? 0;
        ViewBag.DoanhThu = stats?.DoanhThu ?? 0;
        ViewBag.TongVe = stats?.TongVe ?? 0;

        return View(suKien);
    }

    // CẬP NHẬT NHANH GIỜ SOÁT VÉ (không cần vào form sửa sự kiện)
    // URL: POST /Organizer/CapNhatGioCheckIn
    [HttpPost]
    public async Task<IActionResult> CapNhatGioCheckIn(
        Guid id,
        DateTime? batDauCheckIn,
        DateTime? ketThucCheckIn)
    {
        if (!await LaSuKienCuaToi(id))
            return NotFound();

        byte loaiSuKien = await Db.LayGiaTri<byte>(
            "SELECT LoaiSuKien FROM SuKien WHERE Id = @id", new { id });
        if (loaiSuKien == 1)
        {
            TempData["Error"] = "Sự kiện trực tuyến không sử dụng khung giờ check-in tại cổng.";
            return RedirectToAction("ChiTietSuKien", new { id });
        }

        var organizerId = LayIdNguoiDangNhap();
        string sql = @"
            UPDATE SuKien
            SET BatDauCheckIn  = @batDauCheckIn,
                KetThucCheckIn = @ketThucCheckIn,
                NgayCapNhat    = GETUTCDATE()
            WHERE Id = @id AND NguoiToChucId = @organizerId
        ";

        await Db.ThucThi(sql, new { id, batDauCheckIn, ketThucCheckIn, organizerId });

        TempData["Message"] = "Đã cập nhật khung giờ soát vé thành công!";
        return RedirectToAction("ChiTietSuKien", new { id });
    }

    // Cập nhật riêng đường dẫn phòng mà không đổi trạng thái sự kiện đang mở bán.
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> CapNhatLinkOnline(Guid id, string linkOnline)
    {
        if (!await LaSuKienCuaToi(id)) return NotFound();

        var suKien = await Db.LayDonLe<SuKien>(
            "SELECT Id, LoaiSuKien FROM SuKien WHERE Id = @id", new { id });
        if (suKien == null || suKien.LoaiSuKien != 1)
        {
            TempData["Error"] = "Chỉ sự kiện trực tuyến mới có đường dẫn phòng.";
            return RedirectToAction("ChiTietSuKien", new { id });
        }

        string link = linkOnline?.Trim() ?? "";
        if (!LaLinkPhongHopLe(link))
        {
            TempData["Error"] = "Đường dẫn phòng chưa hợp lệ. Hãy tạo phòng thật rồi dán toàn bộ link https:// vào đây.";
            return RedirectToAction("ChiTietSuKien", new { id });
        }

        await Db.ThucThi(@"
            UPDATE SuKien
            SET LinkOnline = @link, NgayCapNhat = GETUTCDATE()
            WHERE Id = @id AND NguoiToChucId = @organizerId AND LoaiSuKien = 1",
            new { id, link, organizerId = LayIdNguoiDangNhap() });

        TempData["Message"] = "Đã cập nhật đường dẫn tham dự trực tuyến.";
        return RedirectToAction("ChiTietSuKien", new { id });
    }

    // Hiển thị form tạo mới sự kiện
    [HttpGet]
    public async Task<IActionResult> TaoMoiSuKien()
    {
        await NapDuLieuChoForm();
        return View();
    }

    // Xử lý tạo mới sự kiện
    [HttpPost]
    public async Task<IActionResult> TaoMoiSuKien(
        string tenSuKien,
        int danhMucId,
        byte loaiSuKien, // 0: Offline, 1: Online
        string? linkOnline,
        string? anhBia,
        string? anhThumbnail,
        string? moTaNgan,
        string? moTaChiTiet,
        string? tenToChuc,
        string? moTaToChuc,
        
        string? tenDiaDiem,
        string? tinhThanh,
        string? quanHuyenPhuongXa,
        string? soNhaDuong,

        DateTime ngayBatDau,
        DateTime ngayKetThuc,
        string[] tenLoaiVe,
        decimal[] giaVe,
        int[] soLuongVe,
        int[] gioiHanMoiDon,
        
        DateTime? batDauCheckIn,
        DateTime? ketThucCheckIn,
        IFormFile? fileAnhBia,

        string submitAction = "submit")
    {
        // Xử lý tệp hình ảnh tải lên nếu có
        if (fileAnhBia != null && fileAnhBia.Length > 0)
        {
            try
            {
                anhBia = await LuuAnhSuKien(fileAnhBia);
                anhThumbnail = anhBia;
            }
            catch (InvalidDataException ex)
            {
                ModelState.AddModelError("", ex.Message);
            }
            catch
            {
                ModelState.AddModelError("", "Không thể lưu ảnh bìa. Vui lòng thử lại.");
            }
        }
        else if (string.IsNullOrWhiteSpace(anhBia))
        {
            anhBia = "/images/default-event.svg";
            anhThumbnail = "/images/default-event.svg";
        }

        // Kiểm tra hợp lệ dữ liệu cơ bản
        linkOnline = linkOnline?.Trim();
        string? loiDuLieu = KiemTraDuLieuSuKien(
            tenSuKien, loaiSuKien, linkOnline, tenDiaDiem, tinhThanh,
            ngayBatDau, ngayKetThuc, batDauCheckIn, ketThucCheckIn,
            tenLoaiVe, giaVe, soLuongVe, gioiHanMoiDon, submitAction != "draft", anhBia);
        if (loiDuLieu != null) ModelState.AddModelError("", loiDuLieu);

        if (!ModelState.IsValid)
        {
            await NapDuLieuChoForm();
            return View();
        }
        anhThumbnail = anhBia;

        var suKienId = Guid.NewGuid();
        string slug  = TaoSlug(tenSuKien) + "-" + VietnamTime.Now.ToString("yyMMddHHmmss");
        var organizerId = LayIdNguoiDangNhap();
        
        // submitAction: "draft" là bản nháp (TrangThai = 0), ngược lại là gửi duyệt (TrangThai = 1)
        int trangThai = (submitAction == "draft") ? 0 : 1;

        using var connection = Db.TaoKetNoi();
        await connection.OpenAsync();
        using var transaction = connection.BeginTransaction();

        try
        {
            // Thêm thông tin sự kiện kèm địa điểm trực tiếp vào bảng SuKien
            string sqlInsertSuKien = @"
                INSERT INTO SuKien
                    (Id, NguoiToChucId, DanhMucId, TenSuKien, Slug,
                     MoTaNgan, MoTaChiTiet, AnhBia, AnhThumbnail, NgayBatDau, NgayKetThuc,
                     LoaiSuKien, LinkOnline,
                     CoSoDoChoNgoi, TrangThai, HienThiCongKhai, NgayTao,
                     BatDauCheckIn, KetThucCheckIn,
                     TenDiaDiem, DiaChiDiaDiem, ThanhPhoDiaDiem, QuanHuyenDiaDiem, SucChuaDiaDiem)
                VALUES
                    (@id, @nguoiToChucId, @danhMucId, @tenSuKien, @slug,
                     @moTaNgan, @moTaChiTiet, @anhBia, @anhThumbnail, @ngayBatDau, @ngayKetThuc,
                     @loaiSuKien, @linkOnline,
                     0, @trangThai, 1, GETUTCDATE(),
                     @batDauCheckIn, @ketThucCheckIn,
                     @tenDiaDiem, @diaChiDiaDiem, @thanhPhoDiaDiem, @quanHuyenDiaDiem, @sucChuaDiaDiem)
            ";

            int tongSoGhe = 0;
            if (soLuongVe != null)
            {
                foreach (var sl in soLuongVe) 
                    tongSoGhe += sl;
            }

            await connection.ExecuteAsync(sqlInsertSuKien, new
            {
                id            = suKienId,
                nguoiToChucId = organizerId,
                danhMucId,
                tenSuKien     = tenSuKien.Trim(),
                slug,
                moTaNgan,
                moTaChiTiet = SafeHtml.Sanitize(moTaChiTiet),
                anhBia,
                anhThumbnail,
                ngayBatDau,
                ngayKetThuc,
                loaiSuKien,
                linkOnline,
                trangThai,
                batDauCheckIn = (loaiSuKien == 0) ? batDauCheckIn : null,
                ketThucCheckIn = (loaiSuKien == 0) ? ketThucCheckIn : null,
                // Gán trực tiếp dữ liệu địa điểm
                tenDiaDiem       = (loaiSuKien == 0) ? tenDiaDiem?.Trim() : null,
                diaChiDiaDiem    = (loaiSuKien == 0) ? soNhaDuong?.Trim() : null,
                thanhPhoDiaDiem  = (loaiSuKien == 0) ? tinhThanh?.Trim() : null,
                quanHuyenDiaDiem = (loaiSuKien == 0) ? quanHuyenPhuongXa?.Trim() : null,
                sucChuaDiaDiem   = (loaiSuKien == 0) ? ((tongSoGhe > 0) ? tongSoGhe : 100) : (int?)null
            }, transaction);

            // Thêm các loại vé đã nhập
            if (tenLoaiVe != null && giaVe != null && soLuongVe != null && gioiHanMoiDon != null)
            {
                for (int i = 0; i < tenLoaiVe.Length; i++)
                {
                    if (string.IsNullOrWhiteSpace(tenLoaiVe[i])) continue;
                    if (i >= giaVe.Length || i >= soLuongVe.Length || i >= gioiHanMoiDon.Length) continue;

                    string sqlInsertLoaiVe = @"
                        INSERT INTO LoaiVe
                            (SuKienId, TenLoaiVe, GiaBan, SoLuongTong, GioiHanMoiDon,
                             NgayBatDauBan, NgayKetThucBan, ThuTuHienThi, TrangThai)
                        VALUES
                            (@suKienId, @tenLoaiVe, @giaVe, @soLuongVe, @gioiHan,
                             DATEADD(HOUR, 7, GETUTCDATE()), @ngayKetThuc, @thuTu, 1)
                    ";

                    await connection.ExecuteAsync(sqlInsertLoaiVe, new
                    {
                        suKienId    = suKienId,
                        tenLoaiVe   = tenLoaiVe[i].Trim(),
                        giaVe       = giaVe[i],
                        soLuongVe   = soLuongVe[i],
                        gioiHan     = gioiHanMoiDon[i],
                        ngayKetThuc,
                        thuTu       = i
                    }, transaction);
                }
            }

            await transaction.CommitAsync();
        }
        catch
        {
            await transaction.RollbackAsync();
            throw;
        }

        TempData["Message"] = (trangThai == 0) ? "Đã lưu bản nháp sự kiện." : "Đã tạo sự kiện thành công và gửi duyệt.";
        return RedirectToAction("SuKien");
    }

    // Hiển thị form chỉnh sửa sự kiện
    [HttpGet]
    public async Task<IActionResult> ChinhSuaSuKien(Guid id)
    {
        var suKien = await LaySuKienCuaToi(id);
        if (suKien == null) return NotFound();

        await NapDuLieuChoForm();
        ViewBag.LoaiVes = await LayDanhSachLoaiVe(id);
        ViewBag.SoDonHang = await Db.LayGiaTri<int>(
            "SELECT COUNT(1) FROM DonHang WHERE SuKienId = @suKienId", 
            new { suKienId = id }
        );
        ViewBag.Profile = await Db.LayDonLe<NguoiDung>(
            "SELECT Id, HoTen, TenNganHang, SoTaiKhoan, ChuTaiKhoan FROM NguoiDung WHERE Id = @id",
            new { id = LayIdNguoiDangNhap() }
        );

        return View(suKien);
    }

    // Xử lý chỉnh sửa sự kiện
    [HttpPost]
    public async Task<IActionResult> ChinhSuaSuKien(
        Guid id,
        string tenSuKien,
        int danhMucId,
        byte loaiSuKien, // 0: Offline, 1: Online
        string? linkOnline,
        string? anhBia,
        string? anhThumbnail,
        string? moTaNgan,
        string? moTaChiTiet,
        string? tenToChuc,
        string? moTaToChuc,
        
        string? tenDiaDiem,
        string? tinhThanh,
        string? quanHuyenPhuongXa,
        string? soNhaDuong,

        DateTime ngayBatDau,
        DateTime ngayKetThuc,
        string[] tenLoaiVe,
        decimal[] giaVe,
        int[] soLuongVe,
        int[] gioiHanMoiDon,

        DateTime? batDauCheckIn,
        DateTime? ketThucCheckIn,
        string? tinNhanXacNhan, // Giữ lại tham số để không gãy route, nhưng sẽ không lưu vào CSDL
        
        IFormFile? fileAnhBia,

        string submitAction = "submit")
    {
        // Xử lý tệp hình ảnh tải lên nếu có
        if (fileAnhBia != null && fileAnhBia.Length > 0)
        {
            try
            {
                anhBia = await LuuAnhSuKien(fileAnhBia);
                anhThumbnail = anhBia;
            }
            catch (InvalidDataException ex)
            {
                TempData["Error"] = ex.Message;
                return RedirectToAction("ChinhSuaSuKien", new { id });
            }
            catch
            {
                TempData["Error"] = "Không thể lưu ảnh bìa. Vui lòng thử lại.";
                return RedirectToAction("ChinhSuaSuKien", new { id });
            }
        }

        if (ngayKetThuc <= ngayBatDau)
        {
            TempData["Error"] = "Ngày kết thúc phải diễn ra sau ngày bắt đầu.";
            return RedirectToAction("ChinhSuaSuKien", new { id });
        }
        linkOnline = linkOnline?.Trim();
        string? loiDuLieu = KiemTraDuLieuSuKien(
            tenSuKien, loaiSuKien, linkOnline, tenDiaDiem, tinhThanh,
            ngayBatDau, ngayKetThuc, batDauCheckIn, ketThucCheckIn,
            tenLoaiVe, giaVe, soLuongVe, gioiHanMoiDon, submitAction != "draft", anhBia);
        if (loiDuLieu != null)
        {
            TempData["Error"] = loiDuLieu;
            return RedirectToAction("ChinhSuaSuKien", new { id });
        }
        anhThumbnail = anhBia;

        var organizerId = LayIdNguoiDangNhap();
        int trangThai   = (submitAction == "draft") ? 0 : 1;

        using var connection = Db.TaoKetNoi();
        await connection.OpenAsync();
        using var transaction = connection.BeginTransaction();

        try
        {
            // Kiểm tra sự kiện này có đúng của người đăng nhập không
            var checkSql = @"
                SELECT COUNT(1)
                FROM SuKien
                WHERE Id = @id
                  AND NguoiToChucId = @organizerId
            ";
            int count = await connection.ExecuteScalarAsync<int>(checkSql, new { id, organizerId }, transaction);
            if (count == 0) return NotFound();

            int tongSoGhe = 0;
            if (soLuongVe != null)
            {
                foreach (var sl in soLuongVe) tongSoGhe += sl;
            }

            // Cập nhật thông tin sự kiện chính kèm địa điểm trực tiếp (bỏ NgayDongBanVe, TinNhanXacNhan)
            string sqlUpdateSuKien = @"
                UPDATE SuKien
                SET TenSuKien        = @tenSuKien,
                    DanhMucId        = @danhMucId,
                    MoTaNgan         = @moTaNgan,
                    MoTaChiTiet      = @moTaChiTiet,
                    AnhBia           = @anhBia,
                    AnhThumbnail     = @anhThumbnail,
                    NgayBatDau       = @ngayBatDau,
                    NgayKetThuc      = @ngayKetThuc,
                    LoaiSuKien       = @loaiSuKien,
                    LinkOnline       = @linkOnline,
                    TrangThai        = @trangThai,
                    LyDoTuChoi       = NULL,
                    NgayCapNhat      = GETUTCDATE(),
                    BatDauCheckIn    = @batDauCheckIn,
                    KetThucCheckIn   = @ketThucCheckIn,
                    TenDiaDiem       = @tenDiaDiem,
                    DiaChiDiaDiem    = @diaChiDiaDiem,
                    ThanhPhoDiaDiem  = @thanhPhoDiaDiem,
                    QuanHuyenDiaDiem = @quanHuyenDiaDiem,
                    SucChuaDiaDiem   = @sucChuaDiaDiem
                WHERE Id            = @id
                  AND NguoiToChucId = @organizerId
                  AND TrangThai    IN (0, 1, 2, 7)
            ";

            int soDongSuKien = await connection.ExecuteAsync(sqlUpdateSuKien, new
            {
                id,
                organizerId,
                tenSuKien = tenSuKien.Trim(),
                danhMucId,
                moTaNgan,
                moTaChiTiet = SafeHtml.Sanitize(moTaChiTiet),
                anhBia,
                anhThumbnail,
                ngayBatDau,
                ngayKetThuc,
                loaiSuKien,
                linkOnline,
                trangThai,
                batDauCheckIn = (loaiSuKien == 0) ? batDauCheckIn : null,
                ketThucCheckIn = (loaiSuKien == 0) ? ketThucCheckIn : null,
                // Gán trực tiếp dữ liệu địa điểm
                tenDiaDiem       = (loaiSuKien == 0) ? tenDiaDiem?.Trim() : null,
                diaChiDiaDiem    = (loaiSuKien == 0) ? soNhaDuong?.Trim() : null,
                thanhPhoDiaDiem  = (loaiSuKien == 0) ? tinhThanh?.Trim() : null,
                quanHuyenDiaDiem = (loaiSuKien == 0) ? quanHuyenPhuongXa?.Trim() : null,
                sucChuaDiaDiem   = (loaiSuKien == 0) ? ((tongSoGhe > 0) ? tongSoGhe : 100) : (int?)null
            }, transaction);

            if (soDongSuKien == 0)
            {
                await transaction.RollbackAsync();
                TempData["Error"] = "Trạng thái hiện tại không cho phép sửa thông tin. Hãy tạm dừng bán vé trước khi chỉnh sửa.";
                return RedirectToAction("ChinhSuaSuKien", new { id });
            }

            // Không tạo lại loại vé khi đã có đơn hoặc sơ đồ ghế: KhuVuc đang tham chiếu LoaiVe.
            int soDonHang = await connection.ExecuteScalarAsync<int>(
                "SELECT COUNT(1) FROM DonHang WHERE SuKienId = @id", 
                new { id }, 
                transaction
            );
            int soDoDaCauHinh = await connection.ExecuteScalarAsync<int>(
                "SELECT COUNT(1) FROM SoDoChoNgoi WHERE SuKienId = @id",
                new { id },
                transaction
            );

            if (soDonHang == 0 && soDoDaCauHinh == 0)
            {
                await connection.ExecuteAsync("DELETE FROM LoaiVe WHERE SuKienId = @suKienId", new { suKienId = id }, transaction);

                if (tenLoaiVe != null && giaVe != null && soLuongVe != null && gioiHanMoiDon != null)
                {
                    for (int i = 0; i < tenLoaiVe.Length; i++)
                    {
                        if (string.IsNullOrWhiteSpace(tenLoaiVe[i])) continue;
                        if (i >= giaVe.Length || i >= soLuongVe.Length || i >= gioiHanMoiDon.Length) continue;

                        string sqlInsertLoaiVe = @"
                            INSERT INTO LoaiVe
                                (SuKienId, TenLoaiVe, GiaBan, SoLuongTong, GioiHanMoiDon,
                                 NgayBatDauBan, NgayKetThucBan, ThuTuHienThi, TrangThai)
                            VALUES
                                (@suKienId, @tenLoaiVe, @giaVe, @soLuongVe, @gioiHan,
                                 DATEADD(HOUR, 7, GETUTCDATE()), @ngayKetThuc, @thuTu, 1)
                        ";

                        await connection.ExecuteAsync(sqlInsertLoaiVe, new
                        {
                            suKienId  = id,
                            tenLoaiVe = tenLoaiVe[i].Trim(),
                            giaVe     = giaVe[i],
                            soLuongVe = soLuongVe[i],
                            gioiHan   = gioiHanMoiDon[i],
                            ngayKetThuc,
                            thuTu     = i
                        }, transaction);
                    }
                }
            }

            await transaction.CommitAsync();
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            _logger.LogError(ex, "Khong the cap nhat su kien {EventId}", id);
            TempData["Error"] = "Không thể cập nhật sự kiện lúc này. Vui lòng kiểm tra lại thông tin và thử lại.";
            return RedirectToAction("ChinhSuaSuKien", new { id });
        }

        TempData["Message"] = (trangThai == 0) ? "Đã lưu bản nháp." : "Đã gửi lại yêu cầu duyệt sự kiện.";
        return RedirectToAction("SuKien");
    }

    // Dừng bán vé sự kiện (Trạng thái = 2)
    [HttpPost]
    public async Task<IActionResult> DungBanVeSuKien(Guid id)
    {
        var suKien = await LaySuKienCuaToi(id);
        if (suKien == null) return NotFound();

        if (suKien.TrangThai != 3)
        {
            TempData["Error"] = "Chỉ có thể dừng bán vé khi sự kiện đang mở bán.";
            return RedirectToAction("SuKien");
        }

        await DoiTrangThaiSuKien(id, 2, "Đã dừng bán vé sự kiện thành công.");
        return RedirectToAction("SuKien");
    }

    // Mở bán lại sự kiện (Trạng thái = 3)
    [HttpPost]
    public async Task<IActionResult> MoBanVeSuKienLai(Guid id)
    {
        var suKien = await LaySuKienCuaToi(id);
        if (suKien == null) return NotFound();

        if (suKien.TrangThai != 2)
        {
            TempData["Error"] = "Chỉ có thể mở bán lại khi sự kiện đang tạm dừng bán vé.";
            return RedirectToAction("SuKien");
        }

        int soDongCapNhat = await Db.ThucThi(@"
            UPDATE SuKien
            SET TrangThai = 3, NgayCapNhat = GETUTCDATE()
            WHERE Id = @id
              AND NguoiToChucId = @organizerId
              AND TrangThai = 2
              AND NgayKetThuc > DATEADD(HOUR, 7, GETUTCDATE())
              AND EXISTS (
                    SELECT 1 FROM LoaiVe lv
                    WHERE lv.SuKienId = SuKien.Id
                      AND lv.TrangThai = 1
                      AND lv.SoLuongTong > lv.SoLuongDaBan + lv.SoLuongGiuCho
                      AND (lv.NgayBatDauBan IS NULL OR lv.NgayBatDauBan <= DATEADD(HOUR, 7, GETUTCDATE()))
                      AND (lv.NgayKetThucBan IS NULL OR lv.NgayKetThucBan >= DATEADD(HOUR, 7, GETUTCDATE()))
              )
              AND (LoaiSuKien = 0 OR LinkOnline LIKE 'https://%')
              AND (CoSoDoChoNgoi = 0 OR EXISTS (
                    SELECT 1 FROM SoDoChoNgoi sd WHERE sd.SuKienId = SuKien.Id
              ))",
            new { id, organizerId = LayIdNguoiDangNhap() });

        TempData[soDongCapNhat > 0 ? "Message" : "Error"] = soDongCapNhat > 0
            ? "Sự kiện đã được mở bán vé trở lại."
            : "Không thể mở bán: sự kiện phải còn hạn, còn vé và đủ cấu hình hình thức tổ chức.";
        return RedirectToAction("SuKien");
    }

    // Hủy sự kiện (Trạng thái = 6)
    [HttpPost]
    public async Task<IActionResult> HuySuKien(Guid id)
    {
        var organizerId = LayIdNguoiDangNhap();
        
        using var connection = Db.TaoKetNoi();
        await connection.OpenAsync();
        using var transaction = connection.BeginTransaction();
        try
        {
            var suKien = await connection.QueryFirstOrDefaultAsync<dynamic>(@"
                SELECT s.TrangThai
                FROM SuKien s WITH (UPDLOCK, HOLDLOCK)
                WHERE s.Id = @id AND s.NguoiToChucId = @organizerId",
                new { id, organizerId }, transaction);

            if (suKien == null)
            {
                await transaction.RollbackAsync();
                return NotFound();
            }

            int trangThaiHienTai = Convert.ToInt32(suKien.TrangThai);
            if (trangThaiHienTai is 4 or 5 or 6)
            {
                await transaction.RollbackAsync();
                TempData["Error"] = "Không thể hủy sự kiện đã kết thúc, đã lưu trữ hoặc đã hủy.";
                return RedirectToAction("SuKien");
            }

            int soDonDaThanhToan = await connection.ExecuteScalarAsync<int>(@"
                SELECT COUNT(*)
                FROM DonHang WITH (UPDLOCK, HOLDLOCK)
                WHERE SuKienId = @id AND TrangThai = 1",
                new { id }, transaction);

            if (soDonDaThanhToan > 0)
            {
                await transaction.RollbackAsync();
                TempData["Error"] = "Sự kiện đã có đơn thanh toán nên không thể hủy khi hệ thống chưa hỗ trợ hoàn tiền.";
                return RedirectToAction("SuKien");
            }

            string sqlCancelSuKien = @"
                UPDATE SuKien
                SET TrangThai   = 6,
                    HienThiCongKhai = 0,
                    NgayCapNhat = GETUTCDATE()
                WHERE Id            = @id
                  AND NguoiToChucId = @organizerId
                  AND TrangThai IN (0, 1, 2, 3, 7)
            ";
            int affected = await connection.ExecuteAsync(sqlCancelSuKien, new { id, organizerId }, transaction);
            if (affected > 0)
            {
                // Hủy các đơn đang chờ để callback thanh toán đến muộn không thể hoàn tất đơn.
                await connection.ExecuteAsync(@"
                    UPDATE DonHang
                    SET TrangThai = 2, NgayCapNhat = GETUTCDATE()
                    WHERE SuKienId = @id AND TrangThai = 0", new { id }, transaction);

                // Reset SoLuongGiuCho của các loại vé đi kèm
                string sqlResetGiuCho = @"
                    UPDATE LoaiVe
                    SET SoLuongGiuCho = 0
                    WHERE SuKienId = @id
                ";
                await connection.ExecuteAsync(sqlResetGiuCho, new { id }, transaction);

                // Ghế 1 là đang giữ; ghế 2 đã bán nên tuyệt đối không được mở lại.
                string sqlReleaseSeats = @"
                    UPDATE ChoNgoi
                    SET TrangThai = 0
                    WHERE TrangThai = 1
                      AND HangGheId IN (
                          SELECT h.Id 
                          FROM HangGhe h 
                          JOIN KhuVuc k ON h.KhuVucId = k.Id
                          JOIN SoDoChoNgoi sdn ON k.SoDoChoNgoiId = sdn.Id
                          WHERE sdn.SuKienId = @id
                      )
                ";
                await connection.ExecuteAsync(sqlReleaseSeats, new { id }, transaction);
            }
            await transaction.CommitAsync();
        }
        catch
        {
            await transaction.RollbackAsync();
            throw;
        }

        TempData["Message"] = "Đã hủy sự kiện thành công.";
        return RedirectToAction("SuKien");
    }

    // Sao chép sự kiện thành một bản nháp mới
    [HttpPost]
    public async Task<IActionResult> SaoChepSuKien(Guid id)
    {
        var organizerId = LayIdNguoiDangNhap();
        var newId       = Guid.NewGuid();
        string suffix   = VietnamTime.Now.ToString("yyMMddHHmmss");

        using var connection = Db.TaoKetNoi();
        await connection.OpenAsync();
        using var transaction = connection.BeginTransaction();

        try
        {
            // Nhân bản sự kiện (ngày bắt đầu và kết thúc tự động cộng thêm 30 ngày)
            string sqlCopySuKien = @"
                INSERT INTO SuKien
                    (Id, NguoiToChucId, DanhMucId, TenSuKien, Slug,
                     MoTaNgan, MoTaChiTiet, AnhBia, NgayBatDau, NgayKetThuc,
                     LoaiSuKien, LinkOnline,
                     CoSoDoChoNgoi, TrangThai, HienThiCongKhai, NgayTao,
                     TenDiaDiem, DiaChiDiaDiem, ThanhPhoDiaDiem, QuanHuyenDiaDiem, SucChuaDiaDiem)
                SELECT @newId, NguoiToChucId, DanhMucId,
                       N'Bản sao - ' + TenSuKien, Slug + '-' + @suffix,
                       MoTaNgan, MoTaChiTiet, AnhBia, DATEADD(day, 30, NgayBatDau),
                       DATEADD(day, 30, NgayKetThuc),
                       LoaiSuKien, LinkOnline, 0, 0, 1, GETUTCDATE(),
                       TenDiaDiem, DiaChiDiaDiem, ThanhPhoDiaDiem, QuanHuyenDiaDiem, SucChuaDiaDiem
                FROM SuKien
                WHERE Id            = @id
                  AND NguoiToChucId = @organizerId
            ";

            int rows = await connection.ExecuteAsync(sqlCopySuKien, new { newId, suffix, id, organizerId }, transaction);
            if (rows == 0) return NotFound();

            // Nhân bản các loại vé đi kèm (bỏ GiaGoc)
            string sqlCopyLoaiVe = @"
                INSERT INTO LoaiVe
                    (SuKienId, TenLoaiVe, MoTa, GiaBan, SoLuongTong,
                     GioiHanMoiDon, NgayBatDauBan, NgayKetThucBan,
                     ThuTuHienThi, MauSac, TrangThai)
                SELECT @newId, TenLoaiVe, MoTa, GiaBan, SoLuongTong,
                       GioiHanMoiDon, DATEADD(HOUR, 7, GETUTCDATE()), DATEADD(day, 30, NgayKetThucBan),
                       ThuTuHienThi, MauSac, TrangThai
                FROM LoaiVe
                WHERE SuKienId = @id
            ";

            await connection.ExecuteAsync(sqlCopyLoaiVe, new { newId, id }, transaction);

            await transaction.CommitAsync();
        }
        catch
        {
            await transaction.RollbackAsync();
            throw;
        }

        TempData["Message"] = "Đã nhân bản sự kiện thành công! Bạn đang ở chế độ chỉnh sửa bản sao.";
        return RedirectToAction("ChinhSuaSuKien", new { id = newId });
    }

    // 3. QUẢN LÝ LOẠI VÉ

    // Hiển thị danh sách loại vé của một sự kiện
    public async Task<IActionResult> LoaiVe(Guid? suKienId)
    {
        if (suKienId == null)
        {
            // Lấy sự kiện mới nhất để hiển thị nếu không truyền Id
            var organizerId = LayIdNguoiDangNhap();
            var latestId = await Db.LayGiaTri<Guid?>(
                "SELECT TOP 1 Id FROM SuKien WHERE NguoiToChucId = @organizerId AND LoaiSuKien = 0 ORDER BY NgayTao DESC", new { organizerId });
            
            if (latestId == null)
            {
                TempData["Error"] = "Vui lòng tạo sự kiện trước.";
                return RedirectToAction("SuKien");
            }
            suKienId = latestId;
        }

        var sId = suKienId.Value;
        if (!await LaSuKienCuaToi(sId)) return NotFound();

        string sql = @"
            SELECT *
            FROM LoaiVe
            WHERE SuKienId = @suKienId
            ORDER BY ThuTuHienThi, Id
        ";
        var list = await Db.LayDanhSach<LoaiVe>(sql, new { suKienId = sId });

        ViewBag.SuKiens   = await LaySuKienCuaToiDropdown();
        ViewBag.SuKienId  = sId;
        ViewBag.TenSuKien = await LayTenSuKien(sId);
        var sk = await Db.LayDonLe<SuKien>("SELECT TrangThai, NgayKetThuc FROM SuKien WHERE Id = @id", new { id = sId });
        ViewBag.TrangThaiSuKien = sk != null ? (int)sk.TrangThai : 0;
        ViewBag.NgayKetThucSuKien = sk?.NgayKetThuc;
        return View(list);
    }

    // Thêm loại vé mới cho sự kiện
    [HttpPost]
    public async Task<IActionResult> TaoMoiLoaiVe(
        Guid suKienId,
        string tenLoaiVe,
        string? moTa,
        decimal giaBan,
        int soLuongTong,
        int gioiHanMoiDon,
        DateTime? ngayBatDauBan,
        DateTime? ngayKetThucBan,
        string? mauSac)
    {
        if (!await LaSuKienCuaToi(suKienId)) return NotFound();

        if (await LaCauHinhVeHoacSoDoBiKhoa(suKienId))
        {
            TempData["Error"] = "Chỉ cấu hình vé khi sự kiện là bản nháp, đang tạm dừng hoặc bị từ chối.";
            return RedirectToAction("LoaiVe", new { suKienId });
        }
        
        if (giaBan < 0 || soLuongTong <= 0 || gioiHanMoiDon <= 0)
        {
            TempData["Error"] = "Thông số vé (giá, số lượng) không hợp lệ.";
            return RedirectToAction("LoaiVe", new { suKienId });
        }

        string sql = @"
            INSERT INTO LoaiVe
                (SuKienId, TenLoaiVe, MoTa, GiaBan, SoLuongTong,
                 GioiHanMoiDon, NgayBatDauBan, NgayKetThucBan,
                 ThuTuHienThi, MauSac, TrangThai)
            VALUES
                (@suKienId, @tenLoaiVe, @moTa, @giaBan, @soLuongTong,
                 @gioiHanMoiDon, @ngayBatDauBan, @ngayKetThucBan,
                 99, @mauSac, 1)
        ";

        await Db.ThucThi(sql, new
        {
            suKienId,
            tenLoaiVe = tenLoaiVe.Trim(),
            moTa,
            giaBan,
            soLuongTong,
            gioiHanMoiDon,
            ngayBatDauBan,
            ngayKetThucBan,
            mauSac
        });

        TempData["Message"] = "Đã thêm loại vé mới.";
        return RedirectToAction("LoaiVe", new { suKienId });
    }

    // Form chỉnh sửa loại vé
    [HttpGet]
    public async Task<IActionResult> ChinhSuaLoaiVe(int id)
    {
        var loaiVe = await Db.LayDonLe<LoaiVe>("SELECT * FROM LoaiVe WHERE Id = @id", new { id });
        if (loaiVe == null) return NotFound();
        if (!await LaSuKienCuaToi(loaiVe.SuKienId)) return Forbid();

        if (await LaCauHinhVeHoacSoDoBiKhoa(loaiVe.SuKienId))
        {
            TempData["Error"] = "Chỉ cấu hình vé khi sự kiện là bản nháp, đang tạm dừng hoặc bị từ chối.";
            return RedirectToAction("LoaiVe", new { suKienId = loaiVe.SuKienId });
        }

        return View(loaiVe);
    }

    [HttpPost]
    // POST nhận toàn bộ input có name trùng property LoaiVe vào model.
    // Action kiểm tra quyền sở hữu sự kiện/ràng buộc rồi UPDATE và redirect.
    public async Task<IActionResult> ChinhSuaLoaiVe(LoaiVe model)
    {
        var original = await Db.LayDonLe<LoaiVe>("SELECT * FROM LoaiVe WHERE Id = @id", new { id = model.Id });
        if (original == null) return NotFound();
        if (!await LaSuKienCuaToi(original.SuKienId)) return Forbid();

        if (await LaCauHinhVeHoacSoDoBiKhoa(original.SuKienId))
        {
            TempData["Error"] = "Chỉ cấu hình vé khi sự kiện là bản nháp, đang tạm dừng hoặc bị từ chối.";
            return RedirectToAction("LoaiVe", new { suKienId = original.SuKienId });
        }

        if (string.IsNullOrWhiteSpace(model.TenLoaiVe) || model.GiaBan < 0
            || model.SoLuongTong < original.SoLuongDaBan || model.GioiHanMoiDon < 1
            || (model.NgayBatDauBan.HasValue && model.NgayKetThucBan.HasValue
                && model.NgayKetThucBan <= model.NgayBatDauBan))
        {
            TempData["Error"] = "Thông tin loại vé không hợp lệ hoặc số lượng tổng nhỏ hơn số vé đã bán.";
            return RedirectToAction("ChinhSuaLoaiVe", new { id = original.Id });
        }

        // Khi đã bán vé, giữ nguyên tên và giá để dữ liệu trên vé cũ không đổi nghĩa.
        string tenLoaiVe = original.SoLuongDaBan > 0 ? original.TenLoaiVe : model.TenLoaiVe.Trim();
        decimal giaBan = original.SoLuongDaBan > 0 ? original.GiaBan : model.GiaBan;

        // Phải đảm bảo số lượng vé tổng lớn hơn hoặc bằng số lượng vé thực tế đã bán
        string sql = @"
            UPDATE lv
            SET TenLoaiVe      = @tenLoaiVe,
                MoTa           = @moTa,
                GiaBan         = @giaBan,
                SoLuongTong    = @soLuongTong,
                GioiHanMoiDon  = @gioiHanMoiDon,
                NgayBatDauBan  = @ngayBatDauBan,
                NgayKetThucBan = @ngayKetThucBan,
                MauSac         = @mauSac
            FROM LoaiVe lv
            JOIN SuKien s ON s.Id = lv.SuKienId
            WHERE lv.Id           = @id
              AND s.NguoiToChucId = @organizerId
              AND @soLuongTong   >= lv.SoLuongDaBan
        ";

        int soDong = await Db.ThucThi(sql, new
        {
            id            = model.Id,
            organizerId   = LayIdNguoiDangNhap(),
            tenLoaiVe,
            moTa          = model.MoTa,
            giaBan,
            soLuongTong   = model.SoLuongTong,
            gioiHanMoiDon = model.GioiHanMoiDon,
            ngayBatDauBan = model.NgayBatDauBan,
            ngayKetThucBan= model.NgayKetThucBan,
            mauSac        = model.MauSac
        });

        TempData[soDong > 0 ? "Message" : "Error"] = soDong > 0
            ? "Đã cập nhật loại vé."
            : "Không thể cập nhật loại vé với dữ liệu hiện tại.";
        return RedirectToAction("LoaiVe", new { suKienId = original.SuKienId });
    }

    [HttpPost]
    // Bật/tắt bán một loại vé. suKienId dùng redirect; quyền vẫn phải kiểm tra bằng SQL.
    public async Task<IActionResult> BatTatLoaiVe(int id, Guid suKienId)
    {
        if (!await LaSuKienCuaToi(suKienId)) return Forbid();

        if (await LaCauHinhVeHoacSoDoBiKhoa(suKienId))
        {
            TempData["Error"] = "Chỉ thay đổi loại vé khi sự kiện là bản nháp, đang tạm dừng hoặc bị từ chối.";
            return RedirectToAction("LoaiVe", new { suKienId });
        }

        string sql = @"
            UPDATE lv
            SET TrangThai = CASE WHEN lv.TrangThai = 1 THEN 0 ELSE 1 END
            FROM LoaiVe lv
            JOIN SuKien s ON s.Id = lv.SuKienId
            WHERE lv.Id           = @id
              AND s.NguoiToChucId = @organizerId
        ";
        await Db.ThucThi(sql, new { id, organizerId = LayIdNguoiDangNhap() });
        return RedirectToAction("LoaiVe", new { suKienId });
    }

    // 4. QUẢN LÝ MÃ GIẢM GIÁ (VOUCHER)

    // Hiển thị danh sách mã giảm giá
    public async Task<IActionResult> MaGiamGia(Guid? suKienId)
    {
        var events = await LaySuKienCuaToiDropdown();
        if (suKienId == null)
        {
            var organizerId = LayIdNguoiDangNhap();
            var latestId = await Db.LayGiaTri<Guid?>(
                "SELECT TOP 1 Id FROM SuKien WHERE NguoiToChucId = @organizerId ORDER BY NgayTao DESC", new { organizerId });
            
            if (latestId == null)
            {
                TempData["Error"] = "Vui lòng tạo sự kiện trước.";
                return RedirectToAction("SuKien");
            }
            suKienId = latestId;
        }

        var sId = suKienId.Value;
        if (!events.ContainsKey(sId)) return NotFound();

        string sql = @"
            SELECT mg.*
            FROM MaGiamGia mg
            JOIN SuKien s ON s.Id = mg.SuKienId
            WHERE s.NguoiToChucId = @organizerId
              AND mg.SuKienId = @suKienId
            ORDER BY mg.NgayTao DESC
        ";

        var list = await Db.LayDanhSach<MaGiamGia>(sql, new
        { 
            organizerId = LayIdNguoiDangNhap(), 
            suKienId = sId 
        });

        ViewBag.SuKiens  = events;
        ViewBag.SuKienId = sId;
        var sk = await Db.LayDonLe<SuKien>("SELECT TrangThai, NgayKetThuc FROM SuKien WHERE Id = @id", new { id = sId });
        ViewBag.TrangThaiSuKien = sk != null ? (int)sk.TrangThai : 0;
        ViewBag.NgayKetThucSuKien = sk?.NgayKetThuc;
        return View(list);
    }

    [HttpPost]
    // POST form tạo voucher; model binding ghép input vào MaGiamGia model.
    public async Task<IActionResult> TaoMoiMaGiamGia(MaGiamGia model)
    {
        var events = await LaySuKienCuaToiDropdown();
        if (!events.ContainsKey(model.SuKienId)) return NotFound();

        if (await LaNghiepVuVanHanhBiKhoa(model.SuKienId))
        {
            TempData["Error"] = "Không thể tạo mã khi sự kiện chờ duyệt, đã hủy hoặc đã kết thúc.";
            return RedirectToAction("MaGiamGia", new { suKienId = model.SuKienId });
        }

        if (model.NgayBatDau >= model.NgayKetThuc)
        {
            TempData["Error"] = "Ngày bắt đầu khuyến mãi phải trước ngày kết thúc.";
            return RedirectToAction("MaGiamGia", new { suKienId = model.SuKienId });
        }

        if (model.LoaiGiamGia == 0 && (model.GiaTri <= 0 || model.GiaTri > 100))
        {
            TempData["Error"] = "Giá trị giảm theo phần trăm phải nằm trong khoảng từ 1% đến 100%.";
            return RedirectToAction("MaGiamGia", new { suKienId = model.SuKienId });
        }

        if (model.GiaTri <= 0 || model.SoLuongTong <= 0 || model.DonToiThieu < 0 || (model.GiamToiDa.HasValue && model.GiamToiDa.Value < 0))
        {
            TempData["Error"] = "Các thông số giá trị, số lượng, hoặc mức giảm tối thiểu không hợp lệ.";
            return RedirectToAction("MaGiamGia", new { suKienId = model.SuKienId });
        }

        string sql = @"
            INSERT INTO MaGiamGia
                (SuKienId, MaCode, MoTa, LoaiGiamGia, GiaTri, GiamToiDa,
                 DonToiThieu, SoLuongTong, NgayBatDau,
                 NgayKetThuc, TrangThai, NgayTao)
            VALUES
                (@SuKienId, @MaCode, @MoTa, @LoaiGiamGia, @GiaTri, @GiamToiDa,
                 @DonToiThieu, @SoLuongTong, @NgayBatDau,
                 @NgayKetThuc, 1, GETUTCDATE())
        ";

        model.MaCode = model.MaCode.Trim().ToUpperInvariant(); // Viết hoa toàn bộ code voucher

        try
        {
            await Db.ThucThi(sql, model);
            TempData["Message"] = "Đã tạo mã giảm giá mới.";
        }
        catch
        {
            TempData["Error"] = "Lỗi: Mã code này đã tồn tại trên hệ thống.";
        }
        return RedirectToAction("MaGiamGia", new { suKienId = model.SuKienId });
    }

    // Form sửa mã giảm giá
    [HttpGet]
    public async Task<IActionResult> ChinhSuaMaGiamGia(int id)
    {
        var model = await LayMaGiamGia(id);
        return (model == null) ? NotFound() : View(model);
    }

    [HttpPost]
    // POST lưu voucher sau khi kiểm tra thời gian, giá trị và quyền qua SuKien.
    public async Task<IActionResult> ChinhSuaMaGiamGia(MaGiamGia model)
    {
        var original = await LayMaGiamGia(model.Id);
        if (original == null) return NotFound();

        if (await LaNghiepVuVanHanhBiKhoa(original.SuKienId))
        {
            TempData["Error"] = "Không thể sửa mã khi sự kiện chờ duyệt, đã hủy hoặc đã kết thúc.";
            return RedirectToAction("MaGiamGia", new { suKienId = original.SuKienId });
        }

        if (model.NgayBatDau >= model.NgayKetThuc)
        {
            TempData["Error"] = "Ngày bắt đầu khuyến mãi phải trước ngày kết thúc.";
            return RedirectToAction("ChinhSuaMaGiamGia", new { id = model.Id });
        }

        if (model.LoaiGiamGia == 0 && (model.GiaTri <= 0 || model.GiaTri > 100))
        {
            TempData["Error"] = "Giá trị giảm theo phần trăm phải nằm trong khoảng từ 1% đến 100%.";
            return RedirectToAction("ChinhSuaMaGiamGia", new { id = model.Id });
        }

        if (model.GiaTri <= 0 || model.SoLuongTong <= 0 || model.DonToiThieu < 0 || (model.GiamToiDa.HasValue && model.GiamToiDa.Value < 0))
        {
            TempData["Error"] = "Các thông số cấu hình mã giảm giá không hợp lệ.";
            return RedirectToAction("ChinhSuaMaGiamGia", new { id = model.Id });
        }

        string sql = @"
            UPDATE mg
            SET MaCode           = @MaCode,
                MoTa             = @MoTa,
                LoaiGiamGia      = @LoaiGiamGia,
                GiaTri           = @GiaTri,
                GiamToiDa        = @GiamToiDa,
                DonToiThieu      = @DonToiThieu,
                SoLuongTong      = @SoLuongTong,
                NgayBatDau       = @NgayBatDau,
                NgayKetThuc      = @NgayKetThuc,
                TrangThai        = @TrangThai
            FROM MaGiamGia mg
            JOIN SuKien s ON s.Id = mg.SuKienId
            WHERE mg.Id           = @Id
              AND s.NguoiToChucId = @organizerId
              AND @SoLuongTong   >= mg.SoLuongDaDung
        ";

        model.MaCode = model.MaCode.Trim().ToUpperInvariant();

        await Db.ThucThi(sql, new
        {
            model.Id,
            model.MaCode,
            model.MoTa,
            model.LoaiGiamGia,
            model.GiaTri,
            model.GiamToiDa,
            model.DonToiThieu,
            model.SoLuongTong,
            model.NgayBatDau,
            model.NgayKetThuc,
            model.TrangThai,
            organizerId = LayIdNguoiDangNhap()
        });

        TempData["Message"] = "Đã cập nhật mã giảm giá.";
        return RedirectToAction("MaGiamGia", new { suKienId = model.SuKienId });
    }

    [HttpPost]
    // POST xóa mã; trước khi DELETE phải xác nhận mã thuộc sự kiện của BTC hiện tại.
    public async Task<IActionResult> XoaMaGiamGia(int id)
    {
        var model = await LayMaGiamGia(id);
        if (model == null) return NotFound();

        if (await LaNghiepVuVanHanhBiKhoa(model.SuKienId))
        {
            TempData["Error"] = "Không thể xóa mã khi sự kiện chờ duyệt, đã hủy hoặc đã kết thúc.";
            return RedirectToAction("MaGiamGia", new { suKienId = model.SuKienId });
        }

        string sql = @"
            DELETE FROM MaGiamGia
            WHERE Id             = @id
              AND SoLuongDaDung  = 0
        ";
        int soDong = await Db.ThucThi(sql, new { id });
        
        if (soDong > 0)
        {
            TempData["Message"] = "Đã xóa mã giảm giá thành công.";
        }
        else
        {
            TempData["Error"] = "Không thể xóa vì mã này đã có người sử dụng. Hãy chuyển trạng thái hoạt động sang Tắt.";
        }
        return RedirectToAction("MaGiamGia", new { suKienId = model.SuKienId });
    }

    // 5. QUẢN LÝ ĐƠN ĐẶT VÉ & KHÁCH THAM DỰ

    // Danh sách đơn hàng
    public async Task<IActionResult> DonHang(Guid? suKienId, byte? trangThai, string? search)
    {
        if (!suKienId.HasValue || suKienId.Value == Guid.Empty)
        {
            TempData["Error"] = "Vui lòng chọn sự kiện cần quản lý đơn hàng.";
            return RedirectToAction("SuKien");
        }

        Guid eventId = suKienId.Value;
        if (!await LaSuKienCuaToi(eventId)) return NotFound();

        string sql = @"
            SELECT d.*
            FROM DonHang d
            JOIN SuKien s ON s.Id = d.SuKienId
            WHERE s.NguoiToChucId = @organizerId
              AND d.SuKienId = @suKienId
              AND (@trangThai IS NULL OR d.TrangThai = @trangThai)
              AND (@search = '' OR d.MaDonHang    LIKE '%' + @search + '%'
                               OR d.EmailNguoiMua LIKE '%' + @search + '%'
                               OR d.HoTenNguoiMua LIKE '%' + @search + '%')
            ORDER BY d.NgayTao DESC
        ";

        var list = await Db.LayDanhSach<DonHang>(sql, new
        { 
            organizerId = LayIdNguoiDangNhap(),
            suKienId = eventId,
            trangThai,
            search      = search?.Trim() ?? ""
        });

        ViewBag.SuKienId  = eventId;
        ViewBag.TenSuKien = await LayTenSuKien(eventId);
        ViewBag.TrangThai = trangThai;
        ViewBag.Search    = search;
        return View(list);
    }

    // Xem chi tiết đơn hàng
    public async Task<IActionResult> ChiTietDonHang(Guid id)
    {
        string sql = @"
            SELECT d.*
            FROM DonHang d
            JOIN SuKien s ON s.Id = d.SuKienId
            WHERE d.Id           = @id
              AND s.NguoiToChucId = @organizerId
        ";
        var donHang = await Db.LayDonLe<DonHang>(sql, new { id, organizerId = LayIdNguoiDangNhap() });
        if (donHang == null) return NotFound();

        string sqlChiTiet = @"
            SELECT ct.*, lv.TenLoaiVe, cn.SoGhe
            FROM ChiTietDonHang ct
            LEFT JOIN LoaiVe lv ON lv.Id = ct.LoaiVeId
            LEFT JOIN ChoNgoi cn ON cn.Id = ct.ChoNgoiId
            WHERE ct.DonHangId = @id
        ";
        ViewBag.ChiTiet   = await Db.LayDanhSach<ChiTietDonHang>(sqlChiTiet, new { id });
        ViewBag.TenSuKien = await LayTenSuKien(donHang.SuKienId);
        ViewBag.ActiveEventId = donHang.SuKienId;
        ViewBag.ActiveEventName = ViewBag.TenSuKien;
        return View(donHang);
    }

    // Hủy đơn hàng (phần XacNhanThanhToan thủ công đã được loại bỏ — chỉ dùng VNPAY/MoMo/ZaloPay)

    // Hủy đơn hàng

    [HttpPost]
    public async Task<IActionResult> HuyDonHang(Guid id)
    {
        var organizerId = LayIdNguoiDangNhap();
        
        using var connection = Db.TaoKetNoi();
        await connection.OpenAsync();
        using var transaction = connection.BeginTransaction();
        
        try
        {
            // 1. Kiểm tra đơn hàng thuộc sự kiện của organizer này và ở trạng thái Chờ thanh toán
            string sqlCheck = @"
                SELECT d.*
                FROM DonHang d
                JOIN SuKien s ON s.Id = d.SuKienId
                WHERE d.Id = @id AND s.NguoiToChucId = @organizerId AND d.TrangThai = 0
            ";
            var donHang = await connection.QueryFirstOrDefaultAsync<dynamic>(sqlCheck, new { id, organizerId }, transaction);
            if (donHang == null)
            {
                await transaction.RollbackAsync();
                TempData["Error"] = "Không tìm thấy đơn hàng chờ thanh toán phù hợp.";
                return RedirectToAction("DonHang");
            }

            // 2. Giải phóng các ghế đã giữ (nếu có)
            string sqlLayGheDaGiu = "SELECT ChoNgoiId FROM ChiTietDonHang WHERE DonHangId = @id AND ChoNgoiId IS NOT NULL";
            var danhSachGheId = (await connection.QueryAsync<int>(sqlLayGheDaGiu, new { id }, transaction)).ToList();

            if (danhSachGheId.Count > 0)
            {
                string sqlReleaseSeats = @"
                    UPDATE ChoNgoi
                    SET TrangThai = 0
                    WHERE Id IN @danhSachGheId
                      AND TrangThai = 1
                ";
                await connection.ExecuteAsync(sqlReleaseSeats, new { danhSachGheId }, transaction);
            }

            // 3. Đánh dấu đơn hàng là Đã hủy (TrangThai = 2)
            string sqlCancel = @"
                UPDATE DonHang
                SET TrangThai = 2,
                    NgayCapNhat = GETUTCDATE()
                WHERE Id = @id
            ";
            await connection.ExecuteAsync(sqlCancel, new { id }, transaction);

            // Giảm số lượng giữ chỗ của các loại vé trong đơn
            string sqlThongKeVeHuy = @"
                SELECT LoaiVeId, COUNT(*) AS SoLuong
                FROM ChiTietDonHang
                WHERE DonHangId = @id
                GROUP BY LoaiVeId
            ";
            var listVeHuy = await connection.QueryAsync<dynamic>(sqlThongKeVeHuy, new { id }, transaction);
            foreach (var item in listVeHuy)
            {
                int lvId = item.LoaiVeId;
                int qty = item.SoLuong;
                await connection.ExecuteAsync(@"
                    UPDATE LoaiVe
                    SET SoLuongGiuCho = CASE WHEN SoLuongGiuCho >= @qty THEN SoLuongGiuCho - @qty ELSE 0 END
                    WHERE Id = @lvId", new { qty, lvId }, transaction);
            }
 
            await transaction.CommitAsync();
            TempData["Message"] = "Đã hủy đơn hàng thành công.";
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            _logger.LogError(ex, "Khong huy duoc don {OrderId}", id);
            TempData["Error"] = "Không thể hủy đơn hàng lúc này.";
        }

        return RedirectToAction("ChiTietDonHang", new { id });
    }

    // Danh sách người tham dự (chỉ lấy từ đơn hàng đã thanh toán TrangThai = 1)
    public async Task<IActionResult> KhachThamDu(Guid suKienId, string? search)
    {
        if (!await LaSuKienCuaToi(suKienId)) return NotFound();

        string sql = @"
            SELECT ct.*, lv.TenLoaiVe
            FROM ChiTietDonHang ct
            JOIN DonHang d ON d.Id = ct.DonHangId
            LEFT JOIN LoaiVe lv ON lv.Id = ct.LoaiVeId
            WHERE d.SuKienId = @suKienId
              AND d.TrangThai = 1
              AND (@search = '' OR ct.TenNguoiThamDu   LIKE '%' + @search + '%'
                               OR ct.EmailNguoiThamDu LIKE '%' + @search + '%')
            ORDER BY ct.TenNguoiThamDu
        ";

        var list = await Db.LayDanhSach<ChiTietDonHang>(sql, new { suKienId, search = search?.Trim() ?? "" });

        ViewBag.SuKienId  = suKienId;
        ViewBag.TenSuKien = await LayTenSuKien(suKienId);
        ViewBag.Search    = search;
        return View(list);
    }

    // Xuất danh sách khách tham dự ra file CSV
    public async Task<IActionResult> XuatKhachThamDuCsv(Guid suKienId)
    {
        if (!await LaSuKienCuaToi(suKienId)) return NotFound();

        string sql = @"
            SELECT ct.TenNguoiThamDu,
                   ct.EmailNguoiThamDu,
                   lv.TenLoaiVe,
                   ISNULL(ct.MaVe, '')            AS MaVe,
                   ISNULL(ct.TrangThaiCheckin, 0) AS TrangThaiCheckin
            FROM ChiTietDonHang ct
            JOIN DonHang d ON d.Id = ct.DonHangId
            JOIN LoaiVe lv ON lv.Id = ct.LoaiVeId
            WHERE d.SuKienId = @suKienId
              AND d.TrangThai = 1
            ORDER BY ct.TenNguoiThamDu
        ";

        var rawList = await Db.LayDanhSach<dynamic>(sql, new { suKienId });

        var csv = new StringBuilder();
        csv.AppendLine("Ten nguoi tham du,Email,Loai ve,Ma ve,Trang thai");
        foreach (var row in rawList)
        {
            string ten       = (row.TenNguoiThamDu ?? "").Replace(",", " ");
            string email     = row.EmailNguoiThamDu ?? "";
            string loaiVe    = (row.TenLoaiVe ?? "").Replace(",", " ");
            string maVe      = row.MaVe;
            string trangThai = (row.TrangThaiCheckin == 1) ? "Da check-in" : "Chua check-in";
            csv.AppendLine($"{ten},{email},{loaiVe},{maVe},{trangThai}");
        }

        byte[] bytes = Encoding.UTF8.GetPreamble().Concat(Encoding.UTF8.GetBytes(csv.ToString())).ToArray();
        return File(bytes, "text/csv", $"khach-tham-du-{suKienId}.csv");
    }

    // 6. QUÉT VÉ SOÁT VÉ (CHECK-IN)

    // Danh sách check-in
    public async Task<IActionResult> CheckIn(Guid? suKienId, string? search, byte? trangThai)
    {
        if (suKienId == null)
        {
            var organizerId = LayIdNguoiDangNhap();
            var latestId = await Db.LayGiaTri<Guid?>(
                "SELECT TOP 1 Id FROM SuKien WHERE NguoiToChucId = @organizerId ORDER BY NgayTao DESC", new { organizerId });
            
            if (latestId == null)
            {
                TempData["Error"] = "Vui lòng tạo sự kiện trước.";
                return RedirectToAction("SuKien");
            }
            suKienId = latestId;
        }

        var sId = suKienId.Value;
        if (!await LaSuKienCuaToi(sId)) return Forbid();

        string sqlSuKien = "SELECT NgayBatDau, NgayKetThuc, TrangThai, LoaiSuKien, BatDauCheckIn, KetThucCheckIn FROM SuKien WHERE Id = @sId";
        var sk = await Db.LayDonLe<dynamic>(sqlSuKien, new { sId });
        if (sk == null) return NotFound();
        if ((byte)sk.LoaiSuKien == 1)
        {
            TempData["Error"] = "Sự kiện trực tuyến không sử dụng QR hoặc check-in tại cổng.";
            return RedirectToAction("ChiTietSuKien", new { id = sId });
        }
        if (sk != null)
        {
            ViewBag.BatDauCheckIn = (DateTime?)sk.BatDauCheckIn;
            ViewBag.KetThucCheckIn = (DateTime?)sk.KetThucCheckIn;
            ViewBag.NgayBatDau = (DateTime)sk.NgayBatDau;
            ViewBag.NgayKetThuc = (DateTime)sk.NgayKetThuc;
            ViewBag.TrangThaiSuKien = (int)sk.TrangThai;
        }

        string sql = @"
            SELECT ct.*,
                   lv.TenLoaiVe
            FROM ChiTietDonHang ct
            JOIN DonHang d ON d.Id = ct.DonHangId
            LEFT JOIN LoaiVe lv ON lv.Id = ct.LoaiVeId
            WHERE d.SuKienId = @suKienId
              AND d.TrangThai = 1
              AND (@trangThai IS NULL OR ct.TrangThaiCheckin = @trangThai)
              AND (@search = '' OR ct.MaVe            LIKE '%' + @search + '%'
                               OR ct.TenNguoiThamDu   LIKE '%' + @search + '%'
                               OR ct.EmailNguoiThamDu LIKE '%' + @search + '%')
            ORDER BY ct.TrangThaiCheckin, ct.TenNguoiThamDu
        ";

        var list = await Db.LayDanhSach<ChiTietDonHang>(sql, new
        { 
            suKienId  = sId, 
            trangThai, 
            search    = search?.Trim() ?? "" 
        });

        ViewBag.SuKienId  = sId;
        ViewBag.TenSuKien = await LayTenSuKien(sId);
        ViewBag.Search    = search;
        ViewBag.TrangThai = trangThai;
        ViewBag.DaCheckin = list.Count(x => x.TrangThaiCheckin == 1);
        return View(list);
    }

    // Xử lý Check-in bằng cách quét QR Code hoặc gõ tay mã vé
    [HttpPost]
    public async Task<IActionResult> QuetVeCheckIn(Guid suKienId, string? code)
    {
        if (!await LaSuKienCuaToi(suKienId)) return Forbid();
        if (string.IsNullOrWhiteSpace(code))
        {
            TempData["Error"] = "Vui lòng quét hoặc nhập mã vé.";
            return RedirectToAction("CheckIn", new { suKienId });
        }

        string sqlSuKien = "SELECT NgayBatDau, NgayKetThuc, TrangThai, LoaiSuKien, BatDauCheckIn, KetThucCheckIn FROM SuKien WHERE Id = @suKienId";
        var skInfo = await Db.LayDonLe<dynamic>(sqlSuKien, new { suKienId });
        if (skInfo == null) return NotFound();
        if ((byte)skInfo.LoaiSuKien == 1)
        {
            TempData["Error"] = "Sự kiện trực tuyến không sử dụng QR hoặc check-in tại cổng.";
            return RedirectToAction("ChiTietSuKien", new { id = suKienId });
        }

        if (skInfo.TrangThai == 2 || skInfo.TrangThai == 6)
        {
            TempData["Error"] = "Cảnh báo: Sự kiện đang tạm dừng hoặc đã bị hủy, không thể thực hiện check-in.";
            return RedirectToAction("CheckIn", new { suKienId });
        }

        // Quy đổi thời gian hiện tại sang giờ Việt Nam (UTC+7)
        DateTime now = VietnamTime.Now;
        
        // Thiết lập mốc check-in thông minh (Smart Default): BĐ trước 1 tiếng, KT bằng giờ kết thúc sự kiện
        DateTime batDauCheckIn = skInfo.BatDauCheckIn ?? ((DateTime)skInfo.NgayBatDau).AddHours(-1);
        DateTime ketThucCheckIn = skInfo.KetThucCheckIn ?? skInfo.NgayKetThuc;

        if (now < batDauCheckIn)
        {
            TempData["Error"] = $"Cảnh báo: Chưa đến thời gian cho phép check-in. Thời gian check-in bắt đầu từ: {batDauCheckIn.ToString("dd/MM/yyyy HH:mm")}";
            return RedirectToAction("CheckIn", new { suKienId });
        }

        if (now > ketThucCheckIn)
        {
            TempData["Error"] = $"Cảnh báo: Thời gian soát vé của sự kiện này đã kết thúc (Hạn chót soát vé: {ketThucCheckIn.ToString("dd/MM/yyyy HH:mm")}).";
            return RedirectToAction("CheckIn", new { suKienId });
        }

        using var connection = Db.TaoKetNoi();
        await connection.OpenAsync();
        using var transaction = connection.BeginTransaction();

        // Tìm vé khớp với mã vé hoặc mã QR trong sự kiện này (Yêu cầu đơn hàng đã thanh toán TrangThai = 1)
        string sqlSearch = @"
            SELECT TOP 1 ct.Id,
                         ct.TrangThaiCheckin,
                         ct.TenNguoiThamDu
            FROM ChiTietDonHang ct
            JOIN DonHang d ON d.Id = ct.DonHangId
            WHERE d.SuKienId = @suKienId
              AND d.TrangThai = 1
              AND (ct.MaVe = @code OR ct.MaQRCode = @code)
        ";

        var ticket = await connection.QueryFirstOrDefaultAsync<dynamic>(sqlSearch, new { suKienId, code = code.Trim() }, transaction);

        if (ticket == null)
        {
            await transaction.RollbackAsync();
            TempData["Error"] = "Lỗi: Không tìm thấy vé hợp lệ hoặc đơn hàng chưa được thanh toán thành công.";
            return RedirectToAction("CheckIn", new { suKienId });
        }

        int  ticketId = ticket.Id;
        byte trangThaiCheckin = ticket.TrangThaiCheckin;
        var  nguoiCheckinId    = LayIdNguoiDangNhap();

        // Kiểm tra xem vé đã được dùng hoặc bị hủy chưa
        if (trangThaiCheckin == 1)
        {
            await transaction.RollbackAsync();
            TempData["Error"] = $"Cảnh báo: Vé của khách '{ticket.TenNguoiThamDu}' đã check-in từ trước!";
            return RedirectToAction("CheckIn", new { suKienId });
        }
        else if (trangThaiCheckin == 2)
        {
            await transaction.RollbackAsync();
            TempData["Error"] = $"Cảnh báo: Vé của khách '{ticket.TenNguoiThamDu}' đã bị hủy bỏ, không hợp lệ!";
            return RedirectToAction("CheckIn", new { suKienId });
        }

        // Cập nhật trạng thái check-in (TrangThaiCheckin = 1, ghi nhận thời gian và người soát vé)
        string sqlUpdate = @"
            UPDATE ChiTietDonHang
            SET TrangThaiCheckin = 1,
                NgayCheckin      = GETUTCDATE(),
                NguoiCheckinId   = @nguoiCheckinId
            WHERE Id               = @ticketId
              AND TrangThaiCheckin = 0
        ";

        int soDong = await connection.ExecuteAsync(sqlUpdate, new { ticketId, nguoiCheckinId }, transaction);
        if (soDong == 0)
        {
            await transaction.RollbackAsync();
            TempData["Error"] = "Có lỗi xảy ra. Vé đã soát trên thiết bị khác.";
            return RedirectToAction("CheckIn", new { suKienId });
        }

        await transaction.CommitAsync();
        TempData["Message"] = "Check-in thành công!";
        return RedirectToAction("CheckIn", new { suKienId });
    }

    // 6.5. QUẢN LÝ NHÂN VIÊN SOÁX VÉ (STAFF)

    // Hiển thị danh sách nhân viên soát vé của sự kiện
    // Hiển thị danh sách nhân viên soát vé của sự kiện (Phân công soát vé)
    public async Task<IActionResult> QuanLyStaff(Guid? suKienId)
    {
        var organizerId = LayIdNguoiDangNhap();
        var events = await LaySuKienCuaToiDropdown();

        if (suKienId == null)
        {
            var latestId = await Db.LayGiaTri<Guid?>(
                "SELECT TOP 1 Id FROM SuKien WHERE NguoiToChucId = @organizerId ORDER BY NgayTao DESC", new { organizerId });
            
            if (latestId == null)
            {
                TempData["Error"] = "Vui lòng tạo sự kiện trước.";
                return RedirectToAction("SuKien");
            }
            suKienId = latestId;
        }

        var sId = suKienId.Value;
        if (!await LaSuKienCuaToi(sId)) return Forbid();

        string sql = @"
            SELECT nv.*,
                   nd.HoTen AS HoTenNV,
                   nd.Email AS EmailNV
            FROM NhanVienSuKien nv
            JOIN NguoiDung nd ON nd.Id = nv.NguoiDungId
            WHERE nv.SuKienId = @suKienId
            ORDER BY nv.NgayThem DESC
        ";

        var list = await Db.LayDanhSach<NhanVienSuKien>(sql, new { suKienId = sId });

        // Lấy danh sách nhân viên Staff do BTC này quản lý/tạo ra để phân công
        string sqlStaff = "SELECT * FROM NguoiDung WHERE VaiTro = 2 AND NguoiTaoId = @organizerId ORDER BY HoTen";
        ViewBag.CreatedStaff = await Db.LayDanhSach<NguoiDung>(sqlStaff, new { organizerId });

        ViewBag.SuKiens = events;
        ViewBag.SuKienId = sId;
        ViewBag.TenSuKien = await LayTenSuKien(sId);
        var sk = await Db.LayDonLe<SuKien>("SELECT TrangThai, NgayKetThuc FROM SuKien WHERE Id = @id", new { id = sId });
        ViewBag.TrangThaiSuKien = sk != null ? (int)sk.TrangThai : 0;
        ViewBag.NgayKetThucSuKien = sk?.NgayKetThuc;
        return View(list);
    }

    [HttpPost]
    // POST tạo dòng bảng nối NhanVienSuKien để phân công Staff vào sự kiện.
    public async Task<IActionResult> ThemStaff(Guid suKienId, Guid nguoiDungId)
    {
        if (!await LaSuKienCuaToi(suKienId)) return Forbid();

        if (await LaNghiepVuVanHanhBiKhoa(suKienId))
        {
            TempData["Error"] = "Không thể phân công khi sự kiện chờ duyệt, đã hủy hoặc đã kết thúc.";
            return RedirectToAction("QuanLyStaff", new { suKienId });
        }

        // Kiểm tra xem tài khoản này có thuộc quyền quản lý của BTC này không
        string sqlCheckOwner = "SELECT COUNT(1) FROM NguoiDung WHERE Id = @nguoiDungId AND NguoiTaoId = @organizerId";
        var organizerId = LayIdNguoiDangNhap();
        int isMyStaff = await Db.LayGiaTri<int>(sqlCheckOwner, new { nguoiDungId, organizerId });
        if (isMyStaff == 0)
        {
            TempData["Error"] = "Lỗi: Không tìm thấy nhân sự này trong danh sách quản lý của bạn.";
            return RedirectToAction("QuanLyStaff", new { suKienId });
        }

        // Kiểm tra xem đã được phân công chưa
        string sqlCheckStaff = "SELECT COUNT(1) FROM NhanVienSuKien WHERE NguoiDungId = @nguoiDungId AND SuKienId = @suKienId";
        int alreadyStaff = await Db.LayGiaTri<int>(sqlCheckStaff, new { nguoiDungId, suKienId });
        if (alreadyStaff > 0)
        {
            TempData["Error"] = "Nhân viên này đã được phân công vào sự kiện này từ trước.";
            return RedirectToAction("QuanLyStaff", new { suKienId });
        }

        // Phân công
        string sqlInsert = @"
            INSERT INTO NhanVienSuKien (NguoiDungId, SuKienId, NgayThem)
            VALUES (@nguoiDungId, @suKienId, GETUTCDATE())
        ";
        await Db.ThucThi(sqlInsert, new { nguoiDungId, suKienId });
        TempData["Message"] = "Phân công nhân viên soát vé thành công!";
        return RedirectToAction("QuanLyStaff", new { suKienId });
    }

    [HttpPost]
    // POST xóa một dòng phân công, không xóa tài khoản NguoiDung của Staff.
    public async Task<IActionResult> XoaStaff(int id, Guid suKienId)
    {
        if (!await LaSuKienCuaToi(suKienId)) return Forbid();

        if (await LaNghiepVuVanHanhBiKhoa(suKienId))
        {
            TempData["Error"] = "Không thể thay đổi nhân sự khi sự kiện chờ duyệt, đã hủy hoặc đã kết thúc.";
            return RedirectToAction("QuanLyStaff", new { suKienId });
        }

        string sql = "DELETE FROM NhanVienSuKien WHERE Id = @id AND SuKienId = @suKienId";
        await Db.ThucThi(sql, new { id, suKienId });

        TempData["Message"] = "Đã gỡ nhân viên soát vé khỏi sự kiện.";
        return RedirectToAction("QuanLyStaff", new { suKienId });
    }

    // 6.6. QUẢN LÝ TÀI KHOẢN NHÂN VIÊN (STAFF ACCOUNTS)

    // Hiển thị danh sách tài khoản Staff do BTC này tạo ra
    public async Task<IActionResult> NhanVienStaff()
    {
        var organizerId = LayIdNguoiDangNhap();
        string sql = @"
            SELECT * 
            FROM NguoiDung 
            WHERE VaiTro = 2 AND NguoiTaoId = @organizerId 
            ORDER BY HoTen
        ";
        var list = await Db.LayDanhSach<NguoiDung>(sql, new { organizerId });
        return View(list);
    }

    // Thêm (tạo mới) tài khoản Staff
    [HttpPost]
    public async Task<IActionResult> TaoNhanVienStaff(string hoTen, string email, string matKhau)
    {
        var organizerId = LayIdNguoiDangNhap();
        if (string.IsNullOrWhiteSpace(hoTen) || string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(matKhau))
        {
            TempData["Error"] = "Vui lòng điền đầy đủ các thông tin bắt buộc.";
            return RedirectToAction("NhanVienStaff");
        }

        string sqlCheckEmail = "SELECT COUNT(1) FROM NguoiDung WHERE Email = @email";
        int exists = await Db.LayGiaTri<int>(sqlCheckEmail, new { email = email.Trim() });
        if (exists > 0)
        {
            TempData["Error"] = "Email này đã được sử dụng trên hệ thống.";
            return RedirectToAction("NhanVienStaff");
        }

        string sqlInsert = @"
            INSERT INTO NguoiDung (Id, Email, MatKhauHash, HoTen, VaiTro, TrangThai, EmailXacNhan, NguoiTaoId, NgayTao)
            VALUES (@id, @email, @hash, @hoTen, 2, 1, 1, @organizerId, GETUTCDATE())
        ";
        await Db.ThucThi(sqlInsert, new
        {
            id = Guid.NewGuid(),
            email = email.Trim(),
            hash = BCrypt.Net.BCrypt.HashPassword(matKhau.Trim()),
            hoTen = hoTen.Trim(),
            organizerId
        });

        TempData["Message"] = "Đã tạo tài khoản nhân viên thành công.";
        return RedirectToAction("NhanVienStaff");
    }

    // Sửa thông tin tài khoản Staff
    [HttpPost]
    public async Task<IActionResult> SuaNhanVienStaff(Guid id, string hoTen, string? matKhau)
    {
        var organizerId = LayIdNguoiDangNhap();
        if (string.IsNullOrWhiteSpace(hoTen))
        {
            TempData["Error"] = "Vui lòng điền đầy đủ họ tên.";
            return RedirectToAction("NhanVienStaff");
        }

        // Kiểm tra xem tài khoản này có thuộc quyền quản lý của BTC này không
        string sqlCheckOwner = "SELECT COUNT(1) FROM NguoiDung WHERE Id = @id AND NguoiTaoId = @organizerId";
        int isMyStaff = await Db.LayGiaTri<int>(sqlCheckOwner, new { id, organizerId });
        if (isMyStaff == 0) return Forbid();

        if (string.IsNullOrWhiteSpace(matKhau))
        {
            // Sửa không đổi mật khẩu
            string sqlUpdate = "UPDATE NguoiDung SET HoTen = @hoTen, NgayCapNhat = GETUTCDATE() WHERE Id = @id";
            await Db.ThucThi(sqlUpdate, new { id, hoTen = hoTen.Trim() });
        }
        else
        {
            // Sửa có đổi mật khẩu
            string sqlUpdate = "UPDATE NguoiDung SET HoTen = @hoTen, MatKhauHash = @hash, NgayCapNhat = GETUTCDATE() WHERE Id = @id";
            await Db.ThucThi(sqlUpdate, new 
            { 
                id, 
                hoTen = hoTen.Trim(),
                hash = BCrypt.Net.BCrypt.HashPassword(matKhau.Trim())
            });
        }

        TempData["Message"] = "Đã cập nhật thông tin nhân viên.";
        return RedirectToAction("NhanVienStaff");
    }

    // Xóa tài khoản Staff
    [HttpPost]
    public async Task<IActionResult> XoaNhanVienStaff(Guid id)
    {
        var organizerId = LayIdNguoiDangNhap();
        // Kiểm tra xem tài khoản này có thuộc quyền quản lý của BTC này không
        string sqlCheckOwner = "SELECT COUNT(1) FROM NguoiDung WHERE Id = @id AND NguoiTaoId = @organizerId";
        int isMyStaff = await Db.LayGiaTri<int>(sqlCheckOwner, new { id, organizerId });
        if (isMyStaff == 0) return Forbid();

        using var connection = Db.TaoKetNoi();
        await connection.OpenAsync();
        using var transaction = connection.BeginTransaction();
        try
        {
            // Xóa liên kết phân công trước
            await connection.ExecuteAsync("DELETE FROM NhanVienSuKien WHERE NguoiDungId = @id", new { id }, transaction);
            // Xóa tài khoản người dùng
            await connection.ExecuteAsync("DELETE FROM NguoiDung WHERE Id = @id", new { id }, transaction);

            await transaction.CommitAsync();
            TempData["Message"] = "Đã xóa tài khoản nhân viên.";
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            _logger.LogError(ex, "Khong xoa duoc tai khoan staff {StaffId}", id);
            TempData["Error"] = "Không thể xóa tài khoản nhân viên lúc này.";
        }

        return RedirectToAction("NhanVienStaff");
    }

    // 7. THỐNG KÊ DOANH THU & LIÊN LẠC (BÁO CÁO)

    // Hiển thị báo cáo doanh thu theo sự kiện
    public async Task<IActionResult> BaoCao(Guid? suKienId)
    {
        if (suKienId == null)
        {
            var organizerId = LayIdNguoiDangNhap();
            var latestId = await Db.LayGiaTri<Guid?>(
                "SELECT TOP 1 Id FROM SuKien WHERE NguoiToChucId = @organizerId ORDER BY NgayTao DESC", new { organizerId });
            
            if (latestId == null)
            {
                TempData["Error"] = "Vui lòng tạo sự kiện trước.";
                return RedirectToAction("SuKien");
            }
            suKienId = latestId;
        }

        var sId = suKienId.Value;
        if (!await LaSuKienCuaToi(sId)) return NotFound();

        ViewBag.SuKienId  = sId;
        ViewBag.TenSuKien = await Db.LayGiaTri<string>("SELECT TenSuKien FROM SuKien WHERE Id = @id", new { id = sId });
        
        // Thống kê tổng số đơn hàng đã hoàn tất
        ViewBag.SoDon = await Db.LayGiaTri<int>(
            "SELECT COUNT(*) FROM DonHang WHERE SuKienId = @id AND TrangThai = 1", new { id = sId }
        );
        
        // Thống kê tổng tiền thanh toán thực tế
        ViewBag.DoanhThu = await Db.LayGiaTri<decimal>(
            "SELECT ISNULL(SUM(TongThanhToan), 0) FROM DonHang WHERE SuKienId = @id AND TrangThai = 1", new { id = sId }
        );
        
        // Thống kê số tiền được giảm bởi voucher
        ViewBag.TienGiam = await Db.LayGiaTri<decimal>(
            "SELECT ISNULL(SUM(TienGiamGia), 0) FROM DonHang WHERE SuKienId = @id AND TrangThai = 1", new { id = sId }
        );
        
        // Thống kê số lượng vé đã xuất ra
        ViewBag.SoVe = await Db.LayGiaTri<int>(
            "SELECT COUNT(*) FROM ChiTietDonHang ct JOIN DonHang d ON d.Id = ct.DonHangId WHERE d.SuKienId = @id AND d.TrangThai = 1", new { id = sId }
        );
        
        // Thống kê số lượng vé đã quét check-in
        ViewBag.DaCheckin = await Db.LayGiaTri<int>(
            "SELECT COUNT(*) FROM ChiTietDonHang ct JOIN DonHang d ON d.Id = ct.DonHangId WHERE d.SuKienId = @id AND ct.TrangThaiCheckin = 1", new { id = sId }
        );

        // Hiển thị thống kê chi tiết của từng loại vé thuộc sự kiện này
        var listLoaiVe = await Db.LayDanhSach<LoaiVe>(
            "SELECT * FROM LoaiVe WHERE SuKienId = @id ORDER BY ThuTuHienThi", new { id = sId });
            
        return View(listLoaiVe);
    }

    // Xuất báo cáo doanh thu vé ra CSV
    public async Task<IActionResult> XuatBaoCaoCsv(Guid suKienId)
    {
        if (!await LaSuKienCuaToi(suKienId)) return NotFound();

        string sql = @"
            SELECT TenLoaiVe,
                   GiaBan,
                   SoLuongTong,
                   SoLuongDaBan
            FROM LoaiVe
            WHERE SuKienId = @id
        ";
        var rawList = await Db.LayDanhSach<dynamic>(sql, new { id = suKienId });

        var csv = new StringBuilder("Loai ve,Gia ban,Tong ve,Da ban,Ty le lap day\r\n");
        foreach (var row in rawList)
        {
            string  tenLoaiVe = row.TenLoaiVe;
            decimal giaBan    = row.GiaBan;
            int     tong      = row.SoLuongTong;
            int     daBan     = row.SoLuongDaBan;
            decimal tyLe      = (tong == 0) ? 0 : daBan * 100m / tong;

            csv.AppendLine($"{tenLoaiVe.Replace(',', ' ')},{giaBan},{tong},{daBan},{tyLe:N1}%");
        }

        byte[] bytes = Encoding.UTF8.GetPreamble().Concat(Encoding.UTF8.GetBytes(csv.ToString())).ToArray();
        return File(bytes, "text/csv", $"bao-cao-{suKienId}.csv");
    }

    // Trang soạn tin nhắn gửi thông báo cho khách hàng đã mua vé
    public async Task<IActionResult> LienLac(Guid? suKienId)
    {
        if (suKienId == null)
        {
            var organizerId = LayIdNguoiDangNhap();
            var latestId = await Db.LayGiaTri<Guid?>(
                "SELECT TOP 1 Id FROM SuKien WHERE NguoiToChucId = @organizerId ORDER BY NgayTao DESC", new { organizerId });
            
            if (latestId == null)
            {
                TempData["Error"] = "Vui lòng tạo sự kiện trước.";
                return RedirectToAction("SuKien");
            }
            suKienId = latestId;
        }

        var sId = suKienId.Value;
        if (!await LaSuKienCuaToi(sId)) return NotFound();

        ViewBag.TenSuKien = await Db.LayGiaTri<string>("SELECT TenSuKien FROM SuKien WHERE Id = @id", new { id = sId });
        
        // Đếm số người mua duy nhất (để hiển thị số người sẽ nhận được tin nhắn)
        ViewBag.SoNguoiNhan = await Db.LayGiaTri<int>(
            "SELECT COUNT(DISTINCT NguoiMuaId) FROM DonHang WHERE SuKienId = @id AND TrangThai = 1", new { id = sId }
        );

        ViewBag.SuKienId = sId;
        return View();
    }

    // Gửi thông báo hệ thống hàng loạt cho người mua vé của sự kiện này
    [HttpPost]
    public async Task<IActionResult> GuiThongBao(Guid suKienId, string tieuDe, string noiDung)
    {
        if (!await LaSuKienCuaToi(suKienId)) return NotFound();
        
        // Thêm thông báo mới cho mỗi người dùng từng thanh toán vé thành công
        string sql = @"
            INSERT INTO ThongBao
                (NguoiNhanId, TieuDe, NoiDung, LoaiThongBao, DuongDan, DaDoc, NgayTao)
            SELECT DISTINCT
                   d.NguoiMuaId,
                   @tieuDe,
                   @noiDung,
                   3,
                   @duongDan,
                   0,
                   GETUTCDATE()
            FROM DonHang d
            WHERE d.SuKienId = @suKienId
              AND d.TrangThai = 1
        ";

        int soLuongGui = await Db.ThucThi(sql, new
        {
            tieuDe   = tieuDe.Trim(),
            noiDung  = noiDung.Trim(),
            duongDan = "/Home/ChiTiet/" + suKienId,
            suKienId
        });

        TempData["Message"] = $"Đã gửi thông báo thành công tới {soLuongGui} khách hàng.";
        return RedirectToAction("LienLac", new { suKienId });
    }

    // 8. THIẾT LẬP SƠ ĐỒ CHỖ NGỒI (SEAT MAP EDITOR)

    // Trang cấu hình sơ đồ ghế
    public async Task<IActionResult> SoDoChoNgoi(Guid? suKienId)
    {
        if (suKienId == null)
        {
            var organizerId = LayIdNguoiDangNhap();
            var latestId = await Db.LayGiaTri<Guid?>(
                "SELECT TOP 1 Id FROM SuKien WHERE NguoiToChucId = @organizerId ORDER BY NgayTao DESC", new { organizerId });
            
            if (latestId == null)
            {
                TempData["Error"] = "Vui lòng tạo sự kiện trước.";
                return RedirectToAction("SuKien");
            }
            suKienId = latestId;
        }

        var sId = suKienId.Value;
        if (!await LaSuKienCuaToi(sId)) return NotFound();

        ViewBag.SuKiens   = await LaySuKienCuaToiDropdown();
        ViewBag.SuKienId  = sId;
        ViewBag.TenSuKien = await LayTenSuKien(sId);
        ViewBag.LoaiVes   = await LayLoaiVeList(sId);
        ViewBag.Ghe       = new List<ChoNgoi>();
        ViewBag.Hang      = new Dictionary<int, string>();
        ViewBag.KhuVucTheoHang = new Dictionary<int, KhuVuc>();
        var sk = await Db.LayDonLe<SuKien>("SELECT TrangThai, NgayKetThuc FROM SuKien WHERE Id = @id", new { id = sId });
        ViewBag.TrangThaiSuKien = sk != null ? (int)sk.TrangThai : 0;
        ViewBag.NgayKetThucSuKien = sk?.NgayKetThuc;

        var model = await Db.LayDonLe<SoDoChoNgoi>(
            "SELECT * FROM SoDoChoNgoi WHERE SuKienId = @id", new { id = sId }
        );
        if (model == null) return View(new SoDoChoNgoi { SuKienId = sId });

        var seats = new List<ChoNgoi>();
        var rows  = new Dictionary<int, string>();
        var zonesByRow = new Dictionary<int, KhuVuc>();

        string sqlSeats = @"
            SELECT g.*,
                   h.TenHang,
                   k.Id AS KhuVucId,
                   k.LoaiVeId,
                   k.TenKhuVuc,
                   k.MauSac,
                   k.ViTriX AS KhuVucViTriX,
                   k.ViTriY AS KhuVucViTriY,
                   k.ThuTu AS ThuTuKhuVuc
            FROM ChoNgoi g
            JOIN HangGhe h ON h.Id = g.HangGheId
            JOIN KhuVuc  k ON k.Id = h.KhuVucId
            WHERE k.SoDoChoNgoiId = @id
            ORDER BY h.ThuTu, g.Id
        ";

        var rawSeats = await Db.LayDanhSach<dynamic>(sqlSeats, new { id = model.Id });
        foreach (var seat in rawSeats)
        {
            seats.Add(new ChoNgoi
            {
                Id        = seat.Id,
                HangGheId = seat.HangGheId,
                SoGhe     = seat.SoGhe,
                ViTriX    = seat.ViTriX,
                ViTriY    = seat.ViTriY,
                TrangThai = seat.TrangThai
            });
            int hId      = seat.HangGheId;
            string tHang = seat.TenHang;
            rows[hId]    = tHang;
            zonesByRow[hId] = new KhuVuc
            {
                Id = seat.KhuVucId,
                SoDoChoNgoiId = model.Id,
                LoaiVeId = seat.LoaiVeId,
                TenKhuVuc = seat.TenKhuVuc,
                MauSac = seat.MauSac,
                ViTriX = seat.KhuVucViTriX,
                ViTriY = seat.KhuVucViTriY,
                ThuTu = seat.ThuTuKhuVuc
            };
        }

        ViewBag.Ghe  = seats;
        ViewBag.Hang = rows;
        ViewBag.KhuVucTheoHang = zonesByRow;
        return View(model);
    }

    // Xử lý Thiết lập sơ đồ theo mẫu
    [HttpPost]
    public async Task<IActionResult> TaoSoDo(
        Guid suKienId,
        string tenSoDo,
        string loaiSoDo,
        List<string>? zoneTen,
        List<int>? zoneLoaiVeId,
        List<int>? zoneSoHang,
        List<int>? zoneSoGheMoiHang,
        List<string>? zoneMauSac,
        List<int>? zoneViTriX,
        List<int>? zoneViTriY,
        List<string>? zoneLoaiKhuVuc,
        List<int>? zoneSucChua,
        List<string>? zoneTienTo,
        List<string>? zoneHuongDanhSo,
        List<int>? zoneSoBatDau,
        int? sanKhauX,
        int? sanKhauY)
    {
        if (!await LaSuKienCuaToi(suKienId)) return Forbid();

        loaiSoDo = (loaiSoDo ?? "").Trim().ToLowerInvariant();
        string[] cacLoaiSoDoHopLe = ["none", "auditorium", "theatre", "cinema", "arena", "custom", "concert"];
        if (!cacLoaiSoDoHopLe.Contains(loaiSoDo)) loaiSoDo = "custom";

        if (await LaCauHinhVeHoacSoDoBiKhoa(suKienId))
        {
            TempData["Error"] = "Chỉ cấu hình sơ đồ khi sự kiện là bản nháp, đang tạm dừng hoặc bị từ chối.";
            return RedirectToAction("SoDoChoNgoi", new { suKienId });
        }

        // Không đổi cấu trúc sơ đồ sau khi đã phát sinh đơn giữ chỗ hoặc vé đã bán.
        int donDangSuDung = await Db.LayGiaTri<int>(@"
            SELECT COUNT(*) FROM DonHang
            WHERE SuKienId = @suKienId AND TrangThai IN (0, 1)", new { suKienId });
        if (donDangSuDung > 0)
        {
            TempData["Error"] = "Không thể tạo lại sơ đồ vì sự kiện đã có đơn đang giữ chỗ hoặc đã thanh toán.";
            return RedirectToAction("SoDoChoNgoi", new { suKienId });
        }

        int stageX = sanKhauX ?? 5;
        int stageY = sanKhauY ?? 1;
        var zones = new List<ZoneDefinition>();
        if (loaiSoDo != "none")
        {
            int count = zoneTen?.Count ?? 0;
            bool mangKhongKhop = count == 0 || count > 30
                || zoneLoaiVeId?.Count != count
                || zoneMauSac?.Count != count;
            if (mangKhongKhop)
            {
                TempData["Error"] = "Dữ liệu khu vực không hợp lệ. Sơ đồ cần từ 1 đến 30 khu vực.";
                return RedirectToAction("SoDoChoNgoi", new { suKienId });
            }

            var loaiVeHopLe = (await Db.LayDanhSach<LoaiVe>(
                "SELECT * FROM LoaiVe WHERE SuKienId = @suKienId", new { suKienId }))
                .ToDictionary(x => x.Id);
            for (int i = 0; i < count; i++)
            {
                int loaiVeId = zoneLoaiVeId![i];
                string loaiKhu = zoneLoaiKhuVuc?.ElementAtOrDefault(i) ?? "seated";
                bool isGA = loaiKhu == "ga";
                int soHang = isGA ? 0 : (zoneSoHang?.ElementAtOrDefault(i) ?? 1);
                int soGhe  = isGA ? 0 : (zoneSoGheMoiHang?.ElementAtOrDefault(i) ?? 1);
                int sucChua = isGA ? Math.Max(1, zoneSucChua?.ElementAtOrDefault(i) ?? 100) : 0;

                if (!loaiVeHopLe.ContainsKey(loaiVeId) || string.IsNullOrWhiteSpace(zoneTen![i]))
                {
                    TempData["Error"] = "Mỗi khu phải dùng loại vé hợp lệ của sự kiện."; 
                    return RedirectToAction("SoDoChoNgoi", new { suKienId });
                }
                if (!isGA && (soHang is < 1 or > 50 || soGhe is < 1 or > 60))
                {
                    TempData["Error"] = "Khu ghế ngồi phải có 1–50 hàng và 1–60 ghế mỗi hàng.";
                    return RedirectToAction("SoDoChoNgoi", new { suKienId });
                }
                string mau = string.IsNullOrWhiteSpace(zoneMauSac![i]) ? "#7c3aed" : zoneMauSac[i]!;
                if (!System.Text.RegularExpressions.Regex.IsMatch(mau, "^#[0-9a-fA-F]{6}$")) mau = "#7c3aed";
                int viTriX = zoneViTriX?.ElementAtOrDefault(i) ?? ((i % 3) * 4 + 1);
                int viTriY = zoneViTriY?.ElementAtOrDefault(i) ?? ((i / 3) * 3 + 2);
                string tienTo = zoneTienTo?.ElementAtOrDefault(i) ?? "";
                string huong  = zoneHuongDanhSo?.ElementAtOrDefault(i) ?? "ltr";
                int soBD = Math.Max(1, zoneSoBatDau?.ElementAtOrDefault(i) ?? 1);
                zones.Add(new ZoneDefinition
                {
                    Ten = zoneTen![i].Trim(), LoaiVeId = loaiVeId,
                    SoHang = soHang, SoGheMoiHang = soGhe, MauSac = mau,
                    ViTriX = viTriX, ViTriY = viTriY,
                    LoaiKhuVuc = loaiKhu, SucChua = sucChua,
                    TienToHangGhe = tienTo, HuongDanhSo = huong, SoBatDau = soBD
                });
            }

            int tongGhe = zones.Where(z => z.LoaiKhuVuc != "ga").Sum(x => x.SoHang * x.SoGheMoiHang);
            int tongGA  = zones.Where(z => z.LoaiKhuVuc == "ga").Sum(x => x.SucChua);
            if (tongGhe + tongGA > 10000)
            {
                TempData["Error"] = "Một sơ đồ được tối đa 10.000 chỗ ngồi để đảm bảo hiệu năng.";
                return RedirectToAction("SoDoChoNgoi", new { suKienId });
            }

            foreach (var group in zones.GroupBy(x => x.LoaiVeId))
            {
                int tongSoCuaLoai = group.Sum(x => x.LoaiKhuVuc == "ga" ? x.SucChua : x.SoHang * x.SoGheMoiHang);
                if (tongSoCuaLoai > loaiVeHopLe[group.Key].SoLuongTong)
                {
                    TempData["Error"] = $"Các khu dùng vé '{loaiVeHopLe[group.Key].TenLoaiVe}' phân bổ {tongSoCuaLoai} chỗ nhưng tổng số vé chỉ có {loaiVeHopLe[group.Key].SoLuongTong}.";
                    return RedirectToAction("SoDoChoNgoi", new { suKienId });
                }
            }
        }

        using var connection = Db.TaoKetNoi();
        await connection.OpenAsync();
        using var transaction = connection.BeginTransaction();
        try
        {
            var currentSoDoId = await connection.ExecuteScalarAsync<int?>(
                "SELECT Id FROM SoDoChoNgoi WHERE SuKienId = @id", new { id = suKienId }, transaction);
            if (currentSoDoId.HasValue)
            {
                var sId = currentSoDoId.Value;
                await connection.ExecuteAsync("DELETE FROM ChoNgoi WHERE HangGheId IN (SELECT h.Id FROM HangGhe h JOIN KhuVuc k ON h.KhuVucId = k.Id WHERE k.SoDoChoNgoiId = @sId)", new { sId }, transaction);
                await connection.ExecuteAsync("DELETE FROM HangGhe WHERE KhuVucId IN (SELECT Id FROM KhuVuc WHERE SoDoChoNgoiId = @sId)", new { sId }, transaction);
                await connection.ExecuteAsync("DELETE FROM KhuVuc WHERE SoDoChoNgoiId = @sId", new { sId }, transaction);
                await connection.ExecuteAsync("DELETE FROM SoDoChoNgoi WHERE Id = @sId", new { sId }, transaction);
            }

            if (loaiSoDo == "none")
            {
                await connection.ExecuteAsync("UPDATE SuKien SET CoSoDoChoNgoi = 0 WHERE Id = @id", new { id = suKienId }, transaction);
                await transaction.CommitAsync();
                TempData["Message"] = "Đã chuyển sự kiện sang bán vé không chọn ghế.";
                return RedirectToAction("SoDoChoNgoi", new { suKienId });
            }

            var mapId = await connection.QuerySingleAsync<int>(@"
                INSERT INTO SoDoChoNgoi
                    (SuKienId, TenSoDo, LoaiSoDo, SanKhauX, SanKhauY, NgayTao)
                OUTPUT INSERTED.Id
                VALUES
                    (@suKienId, @tenSoDo, @loaiSoDo, @stageX, @stageY, GETUTCDATE())
            ", new
            {
                suKienId,
                loaiSoDo,
                stageX,
                stageY,
                tenSoDo = string.IsNullOrEmpty(tenSoDo) ? "Sơ đồ ghế mặc định" : tenSoDo.Trim()
            }, transaction);

            int currentOverallRow = 0;
            int orderCounter      = 1;

            foreach (var z in zones)
            {
                if (z.LoaiVeId <= 0) continue;

                var zoneId = await connection.QuerySingleAsync<int>(@"
                    INSERT INTO KhuVuc
                        (SoDoChoNgoiId, LoaiVeId, TenKhuVuc, MauSac, ViTriX, ViTriY, ThuTu)
                    OUTPUT INSERTED.Id
                    VALUES
                        (@mapId, @loaiVeId, @ten, @mau, @viTriX, @viTriY, @order)
                ", new
                {
                    mapId,
                    loaiVeId = z.LoaiVeId,
                    ten      = z.Ten,
                    mau      = z.MauSac,
                    viTriX   = z.ViTriX,
                    viTriY   = z.ViTriY,
                    order    = orderCounter++
                }, transaction);

                // Khu vực đứng (GA): Tạo 1 hàng đặc biệt với số ghế = sức chứa tối đa
                if (z.LoaiKhuVuc == "ga")
                {
                    var rowId = await connection.QuerySingleAsync<int>(@"
                        INSERT INTO HangGhe (KhuVucId, TenHang, SoGhe, ThuTu)
                        OUTPUT INSERTED.Id
                        VALUES (@zoneId, N'GA', @sucChua, 1)
                    ", new { zoneId, sucChua = z.SucChua }, transaction);

                    for (int seat = 1; seat <= z.SucChua; seat++)
                    {
                        await connection.ExecuteAsync(@"
                            INSERT INTO ChoNgoi (HangGheId, SoGhe, ViTriX, ViTriY, TrangThai)
                            VALUES (@rowId, @seat, @x, 1, 0)
                        ", new { rowId, seat = seat.ToString(), x = seat }, transaction);
                    }
                    continue;
                }

                // Khu vực ghế ngồi cố định (Seated)
                string prefix = string.IsNullOrWhiteSpace(z.TienToHangGhe) ? "" : z.TienToHangGhe.Trim();
                bool rtl = z.HuongDanhSo == "rtl";

                for (int r = 0; r < z.SoHang; r++)
                {
                    string rowLabel = TaoTenHang(currentOverallRow);
                    string rowName  = prefix + rowLabel;
                    currentOverallRow++;

                    var rowId = await connection.QuerySingleAsync<int>(@"
                        INSERT INTO HangGhe (KhuVucId, TenHang, SoGhe, ThuTu)
                        OUTPUT INSERTED.Id
                        VALUES (@zoneId, @rowName, @soGhe, @order)
                    ", new { zoneId, rowName, soGhe = z.SoGheMoiHang, order = currentOverallRow }, transaction);

                    for (int col = 0; col < z.SoGheMoiHang; col++)
                    {
                        int seatNum = z.SoBatDau + (rtl ? (z.SoGheMoiHang - 1 - col) : col);
                        string seatLabel = rowName + seatNum;
                        await connection.ExecuteAsync(@"
                            INSERT INTO ChoNgoi (HangGheId, SoGhe, ViTriX, ViTriY, TrangThai)
                            VALUES (@rowId, @seatLabel, @x, @y, 0)
                        ", new { rowId, seatLabel, x = col + 1, y = currentOverallRow }, transaction);
                    }
                }
            }

            // Đánh dấu sự kiện đã kích hoạt sơ đồ chỗ ngồi
            await connection.ExecuteAsync("UPDATE SuKien SET CoSoDoChoNgoi = 1 WHERE Id = @id", new { id = suKienId }, transaction);
            await transaction.CommitAsync();
            TempData["Message"] = "Đã tạo sơ đồ chỗ ngồi thành công.";
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            _logger.LogError(ex, "Khong tao duoc so do cho su kien {EventId}", suKienId);
            TempData["Error"] = "Không thể tạo sơ đồ lúc này. Vui lòng kiểm tra dữ liệu và thử lại.";
        }

        return RedirectToAction("SoDoChoNgoi", new { suKienId });
    }

    private class ZoneDefinition
    {
        public string Ten { get; set; } = "";
        public int LoaiVeId { get; set; }
        public int SoHang { get; set; }
        public int SoGheMoiHang { get; set; }
        public string MauSac { get; set; } = "#198754";
        public int ViTriX { get; set; }
        public int ViTriY { get; set; }
        public int RongCanvas { get; set; }
        public int CaoCanvas { get; set; }
        public string LoaiKhuVuc { get; set; } = "seated"; // "seated" | "ga"
        public int SucChua { get; set; }
        public string TienToHangGhe { get; set; } = "";
        public string HuongDanhSo { get; set; } = "ltr"; // "ltr" | "rtl"
        public int SoBatDau { get; set; } = 1;
    }

    private static bool HinhChuNhatGiaoNhau(int x1, int y1, int width1, int height1, int x2, int y2, int width2, int height2)
        => x1 <= x2 + width2 - 1 && x1 + width1 - 1 >= x2
        && y1 <= y2 + height2 - 1 && y1 + height1 - 1 >= y2;

    private static string TaoTenHang(int index)
    {
        string result = "";
        for (int value = index + 1; value > 0; value = (value - 1) / 26)
            result = (char)('A' + (value - 1) % 26) + result;
        return result;
    }

    [HttpPost]
    // POST khóa/mở một ghế; SQL JOIN ngược lên sơ đồ/sự kiện để kiểm tra chủ sở hữu.
    public async Task<IActionResult> DoiTrangThaiGhe(Guid suKienId, int seatId)
    {
        if (!await LaSuKienCuaToi(suKienId)) return NotFound();

        if (await LaCauHinhVeHoacSoDoBiKhoa(suKienId))
        {
            TempData["Error"] = "Hãy tạm dừng bán vé trước khi khóa hoặc mở ghế.";
            return RedirectToAction("SoDoChoNgoi", new { suKienId });
        }

        string sql = @"
            UPDATE g
            SET TrangThai = CASE WHEN g.TrangThai = 3 THEN 0 ELSE 3 END
            FROM ChoNgoi g
            JOIN HangGhe h ON h.Id = g.HangGheId
            JOIN KhuVuc  k ON k.Id = h.KhuVucId
            JOIN SoDoChoNgoi sd ON sd.Id = k.SoDoChoNgoiId
            WHERE g.Id          = @seatId
              AND sd.SuKienId   = @suKienId
              AND g.TrangThai  IN (0, 3)
        ";
        await Db.ThucThi(sql, new { seatId, suKienId });
        return RedirectToAction("SoDoChoNgoi", new { suKienId });
    }

    [HttpPost]
    // AJAX khóa/mở một ghế — trả về JSON không reload trang.
    public async Task<IActionResult> DoiTrangThaiGheAjax(Guid suKienId, int seatId)
    {
        if (!await LaSuKienCuaToi(suKienId)) return Json(new { success = false, message = "Không có quyền truy cập." });

        string sqlCheck = @"
            SELECT g.TrangThai FROM ChoNgoi g
            JOIN HangGhe h ON h.Id = g.HangGheId
            JOIN KhuVuc  k ON k.Id = h.KhuVucId
            JOIN SoDoChoNgoi sd ON sd.Id = k.SoDoChoNgoiId
            WHERE g.Id = @seatId AND sd.SuKienId = @suKienId";
        int? trangThai = await Db.LayGiaTri<int?>(sqlCheck, new { seatId, suKienId });
        if (trangThai == null) return Json(new { success = false, message = "Ghế không tồn tại." });
        if (trangThai is 1 or 2) return Json(new { success = false, message = "Không thể đổi trạng thái ghế đang giữ/đã bán." });

        int newStatus = trangThai == 3 ? 0 : 3;
        string sqlUpdate = @"
            UPDATE g SET TrangThai = @newStatus
            FROM ChoNgoi g
            JOIN HangGhe h ON h.Id = g.HangGheId
            JOIN KhuVuc  k ON k.Id = h.KhuVucId
            JOIN SoDoChoNgoi sd ON sd.Id = k.SoDoChoNgoiId
            WHERE g.Id = @seatId AND sd.SuKienId = @suKienId AND g.TrangThai IN (0,3)";
        await Db.ThucThi(sqlUpdate, new { seatId, suKienId, newStatus });
        return Json(new { success = true, newStatus });
    }

    [HttpGet]
    // Xuất sơ đồ ghế của sự kiện ra JSON để tái sử dụng cho các sự kiện khác.
    public async Task<IActionResult> ExportSoDo(Guid suKienId)
    {
        if (!await LaSuKienCuaToi(suKienId)) return Forbid();

        var soDo = await Db.LayDonLe<SoDoChoNgoi>("SELECT * FROM SoDoChoNgoi WHERE SuKienId = @suKienId", new { suKienId });
        if (soDo == null) return NotFound();

        var khuVucs = await Db.LayDanhSach<KhuVuc>("SELECT * FROM KhuVuc WHERE SoDoChoNgoiId = @id ORDER BY ThuTu", new { id = soDo.Id });
        var hangGhes = await Db.LayDanhSach<HangGhe>("SELECT h.* FROM HangGhe h JOIN KhuVuc k ON k.Id = h.KhuVucId WHERE k.SoDoChoNgoiId = @id ORDER BY h.ThuTu", new { id = soDo.Id });

        var exportObj = new
        {
            version = "1.0",
            tenSoDo = soDo.TenSoDo,
            loaiSoDo = soDo.LoaiSoDo,
            sanKhauX = soDo.SanKhauX,
            sanKhauY = soDo.SanKhauY,
            zones = khuVucs.Select(k => new
            {
                ten = k.TenKhuVuc,
                loaiVeId = k.LoaiVeId,
                mauSac = k.MauSac,
                viTriX = k.ViTriX,
                viTriY = k.ViTriY,
                soHang = hangGhes.Count(h => h.KhuVucId == k.Id),
                soGheMoiHang = hangGhes.Where(h => h.KhuVucId == k.Id).Select(h => h.SoGhe).FirstOrDefault()
            })
        };

        string json = System.Text.Json.JsonSerializer.Serialize(exportObj, new System.Text.Json.JsonSerializerOptions { WriteIndented = true });
        string fileName = $"seating-{suKienId}.json";
        return File(System.Text.Encoding.UTF8.GetBytes(json), "application/json", fileName);
    }

    [HttpPost]
    // POST xóa sơ đồ. ON DELETE CASCADE xử lý khu vực/hàng/ghế con theo schema.
    public async Task<IActionResult> XoaSoDo(Guid suKienId)
    {
        if (!await LaSuKienCuaToi(suKienId)) return NotFound();

        if (await LaCauHinhVeHoacSoDoBiKhoa(suKienId))
        {
            TempData["Error"] = "Hãy tạm dừng bán vé trước khi xóa sơ đồ ghế.";
            return RedirectToAction("SoDoChoNgoi", new { suKienId });
        }

        int donDangSuDung = await Db.LayGiaTri<int>(@"
            SELECT COUNT(*) FROM DonHang
            WHERE SuKienId = @suKienId AND TrangThai IN (0, 1)", new { suKienId });
        if (donDangSuDung > 0)
        {
            TempData["Error"] = "Không thể xóa sơ đồ đang có đơn giữ chỗ hoặc vé đã thanh toán.";
            return RedirectToAction("SoDoChoNgoi", new { suKienId });
        }

        using var connection = Db.TaoKetNoi();
        await connection.OpenAsync();
        using var transaction = connection.BeginTransaction();
        try
        {
            await connection.ExecuteAsync("DELETE FROM SoDoChoNgoi WHERE SuKienId = @id", new { id = suKienId }, transaction);
            await connection.ExecuteAsync("UPDATE SuKien SET CoSoDoChoNgoi = 0 WHERE Id = @id", new { id = suKienId }, transaction);
            await transaction.CommitAsync();
            TempData["Message"] = "Đã xóa sơ đồ chỗ ngồi của sự kiện.";
        }
        catch
        {
            await transaction.RollbackAsync();
            throw;
        }
        return RedirectToAction("SoDoChoNgoi", new { suKienId });
    }

    // 9. QUẢN LÝ HỒ SƠ DOANH NGHIỆP (NHÀ TỔ CHỨC)

    // Trang thông tin hồ sơ ngân hàng của nhà tổ chức (Đã vô hiệu hóa)
    [HttpGet]
    public IActionResult HoSo()
    {
        return RedirectToAction("Index");
    }

    // PHƯƠNG THỨC HỖ TRỢ (HELPERS)

    // Xác nhận sự kiện thuộc quyền sở hữu của Ban Tổ Chức đang thao tác
    private async Task<bool> LaSuKienCuaToi(Guid id)
    {
        var count = await Db.LayGiaTri<int>(
            "SELECT COUNT(1) FROM SuKien WHERE Id = @id AND NguoiToChucId = @organizerId",
            new { id, organizerId = LayIdNguoiDangNhap() });
        return count > 0;
    }

    private static bool LaLinkPhongHopLe(string? value)
    {
        if (!Uri.TryCreate(value?.Trim(), UriKind.Absolute, out var uri)
            || (uri.Scheme != Uri.UriSchemeHttps && uri.Scheme != Uri.UriSchemeHttp)
            || string.IsNullOrWhiteSpace(uri.Host))
            return false;

        if (!uri.Host.Equals("meet.google.com", StringComparison.OrdinalIgnoreCase))
            return true;

        string maPhong = uri.AbsolutePath.Trim('/');
        return !string.IsNullOrWhiteSpace(maPhong)
            && !maPhong.Equals("abc-defg-hij", StringComparison.OrdinalIgnoreCase);
    }

    // Cấu trúc vé/ghế chỉ đổi ở bản nháp, tạm dừng hoặc bị từ chối.
    private async Task<bool> LaCauHinhVeHoacSoDoBiKhoa(Guid suKienId)
    {
        var sk = await Db.LayDonLe<SuKien>("SELECT TrangThai, NgayKetThuc FROM SuKien WHERE Id = @suKienId", new { suKienId });
        if (sk == null) return true;
        return sk.TrangThai is not (0 or 2 or 7) || VietnamTime.Now > sk.NgayKetThuc;
    }

    // Voucher/nhân sự vẫn vận hành khi mở bán, nhưng khóa lúc chờ duyệt, hủy hoặc kết thúc.
    private async Task<bool> LaNghiepVuVanHanhBiKhoa(Guid suKienId)
    {
        var sk = await Db.LayDonLe<SuKien>("SELECT TrangThai, NgayKetThuc FROM SuKien WHERE Id = @suKienId", new { suKienId });
        if (sk == null) return true;
        return sk.TrangThai is 1 or 5 or 6 || VietnamTime.Now > sk.NgayKetThuc;
    }

    // Lấy tên sự kiện theo Id
    private async Task<string> LayTenSuKien(Guid id)
    {
        return await Db.LayGiaTri<string>("SELECT TenSuKien FROM SuKien WHERE Id = @id", new { id }) ?? "";
    }

    // Lấy danh sách loại vé của sự kiện
    private async Task<List<LoaiVe>> LayLoaiVeList(Guid suKienId)
    {
        return await Db.LayDanhSach<LoaiVe>("SELECT * FROM LoaiVe WHERE SuKienId = @id", new { id = suKienId });
    }

    // Lấy hồ sơ ban tổ chức


    // Lấy danh sách sự kiện phục vụ dropdown bộ lọc
    private async Task<Dictionary<Guid, string>> LaySuKienCuaToiDropdown()
    {
        var list = await Db.LayDanhSach<SuKien>(
            "SELECT Id, TenSuKien FROM SuKien WHERE NguoiToChucId = @id ORDER BY NgayTao DESC", 
            new { id = LayIdNguoiDangNhap() }
        );
        var result = new Dictionary<Guid, string>();
        foreach (var item in list)
        {
            result[item.Id] = item.TenSuKien;
        }
        return result;
    }

    // Lấy chi tiết một mã giảm giá
    private async Task<MaGiamGia?> LayMaGiamGia(int id)
    {
        string sql = @"
            SELECT mg.*
            FROM MaGiamGia mg
            JOIN SuKien s ON s.Id = mg.SuKienId
            WHERE mg.Id           = @id
              AND s.NguoiToChucId = @organizerId
        ";
        return await Db.LayDonLe<MaGiamGia>(sql, new { id, organizerId = LayIdNguoiDangNhap() });
    }

    // Thay đổi trạng thái sự kiện
    private async Task DoiTrangThaiSuKien(Guid id, byte trangThai, string message)
    {
        string sql = @"
            UPDATE SuKien
            SET TrangThai   = @trangThai,
                NgayCapNhat = GETUTCDATE()
            WHERE Id            = @id
              AND NguoiToChucId = @organizerId
              AND TrangThai = 3
        ";
        int soDongCapNhat = await Db.ThucThi(
            sql, new { trangThai, id, organizerId = LayIdNguoiDangNhap() });
        TempData[soDongCapNhat > 0 ? "Message" : "Error"] = soDongCapNhat > 0
            ? message
            : "Trạng thái sự kiện đã thay đổi. Vui lòng tải lại trang.";
    }

    // Lấy thông tin sự kiện của tôi
    private async Task<SuKien?> LaySuKienCuaToi(Guid id)
    {
        return await Db.LayDonLe<SuKien>(
            "SELECT * FROM SuKien WHERE Id = @id AND NguoiToChucId = @organizerId", 
            new { id, organizerId = LayIdNguoiDangNhap() }
        );
    }

    // Nạp dữ liệu danh mục cho form Dropdown
    private async Task NapDuLieuChoForm()
    {
        ViewBag.DanhMucs = await Db.LayDanhSach<DanhMuc>("SELECT * FROM DanhMuc WHERE TrangThai = 1 ORDER BY ThuTu");
    }

    // Lấy danh sách loại vé đang hoạt động
    private async Task<List<LoaiVe>> LayDanhSachLoaiVe(Guid suKienId)
    {
        return await Db.LayDanhSach<LoaiVe>(
            "SELECT * FROM LoaiVe WHERE SuKienId = @suKienId AND TrangThai = 1", new { suKienId }
        );
    }

    private async Task<string> LuuAnhSuKien(IFormFile file)
    {
        const long maxBytes = 5 * 1024 * 1024;
        string extension = Path.GetExtension(file.FileName).ToLowerInvariant();
        string[] extensions = [".jpg", ".jpeg", ".png", ".webp"];
        string[] contentTypes = ["image/jpeg", "image/png", "image/webp"];
        if (file.Length <= 0 || file.Length > maxBytes
            || !extensions.Contains(extension)
            || !contentTypes.Contains(file.ContentType.ToLowerInvariant()))
            throw new InvalidDataException("Ảnh bìa chỉ nhận JPG, PNG, WEBP và tối đa 5 MB.");

        await using var input = file.OpenReadStream();
        using var memory = new MemoryStream();
        await input.CopyToAsync(memory);
        byte[] bytes = memory.ToArray();
        bool dungDinhDang = extension switch
        {
            ".jpg" or ".jpeg" => bytes.Length >= 3
                && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF,
            ".png" => bytes.Length >= 8
                && bytes.AsSpan(0, 8).SequenceEqual(
                    new byte[] { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A }),
            ".webp" => bytes.Length >= 12
                && Encoding.ASCII.GetString(bytes, 0, 4) == "RIFF"
                && Encoding.ASCII.GetString(bytes, 8, 4) == "WEBP",
            _ => false
        };
        if (!dungDinhDang)
            throw new InvalidDataException("Nội dung tệp không đúng định dạng ảnh đã chọn.");

        string uploadsDir = Path.Combine(_environment.WebRootPath, "uploads");
        Directory.CreateDirectory(uploadsDir);
        string fileName = Guid.NewGuid().ToString("N") + extension;
        await System.IO.File.WriteAllBytesAsync(Path.Combine(uploadsDir, fileName), bytes);
        return "/uploads/" + fileName;
    }

    private static string? KiemTraDuLieuSuKien(
        string? tenSuKien, byte loaiSuKien, string? linkOnline,
        string? tenDiaDiem, string? tinhThanh,
        DateTime ngayBatDau, DateTime ngayKetThuc,
        DateTime? batDauCheckIn, DateTime? ketThucCheckIn,
        string[]? tenLoaiVe, decimal[]? giaVe, int[]? soLuongVe,
        int[]? gioiHanMoiDon, bool guiDuyet, string? anhBia)
    {
        if (string.IsNullOrWhiteSpace(tenSuKien) || tenSuKien.Trim().Length > 200)
            return "Tên sự kiện bắt buộc và không quá 200 ký tự.";
        if (loaiSuKien is not (0 or 1)) return "Hình thức sự kiện không hợp lệ.";
        if (ngayKetThuc <= ngayBatDau) return "Ngày kết thúc phải sau ngày bắt đầu.";
        if (guiDuyet && ngayKetThuc <= VietnamTime.Now)
            return "Không thể gửi duyệt sự kiện đã kết thúc.";
        if (loaiSuKien == 1 && guiDuyet && string.IsNullOrWhiteSpace(linkOnline))
            return "Sự kiện trực tuyến cần có đường dẫn phòng họp.";
        if (loaiSuKien == 1 && !string.IsNullOrWhiteSpace(linkOnline) && !LaLinkPhongHopLe(linkOnline))
            return "Đường dẫn phòng trực tuyến chưa hợp lệ.";
        if (loaiSuKien == 0 && guiDuyet
            && (string.IsNullOrWhiteSpace(tenDiaDiem) || string.IsNullOrWhiteSpace(tinhThanh)))
            return "Sự kiện trực tiếp cần có tên địa điểm và tỉnh/thành phố.";
        if (loaiSuKien == 0 && batDauCheckIn.HasValue && ketThucCheckIn.HasValue
            && ketThucCheckIn <= batDauCheckIn)
            return "Thời gian đóng check-in phải sau thời gian mở check-in.";
        if (!string.IsNullOrWhiteSpace(anhBia) && !LaDuongDanAnhHopLe(anhBia))
            return "Đường dẫn ảnh bìa chỉ nhận HTTP, HTTPS hoặc đường dẫn nội bộ.";

        int count = tenLoaiVe?.Length ?? 0;
        if (count == 0 || giaVe?.Length != count || soLuongVe?.Length != count
            || gioiHanMoiDon?.Length != count)
            return "Cần khai báo đầy đủ thông tin cho ít nhất một loại vé.";
        string[] tenVe = tenLoaiVe!;
        if (tenVe.Any(string.IsNullOrWhiteSpace)
            || tenVe.Any(x => x.Trim().Length > 100)
            || tenVe.Select(x => x.Trim()).Distinct(StringComparer.OrdinalIgnoreCase).Count() != count)
            return "Tên loại vé không được trống, trùng nhau hoặc dài quá 100 ký tự.";
        if (giaVe!.Any(x => x < 0) || soLuongVe!.Any(x => x <= 0)
            || gioiHanMoiDon!.Any(x => x is < 1 or > 20))
            return "Giá vé không âm, số lượng phải lớn hơn 0 và giới hạn mỗi đơn từ 1–20 vé.";
        return null;
    }

    private static bool LaDuongDanAnhHopLe(string value)
    {
        value = value.Trim();
        if (value.StartsWith('/') && !value.StartsWith("//") && !value.Contains('\\')) return true;
        return Uri.TryCreate(value, UriKind.Absolute, out Uri? uri)
            && uri.Scheme is "http" or "https";
    }



    // Lấy ID người đang đăng nhập từ token Claims
    private Guid LayIdNguoiDangNhap()
    {
        string? idText = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.TryParse(idText, out Guid id) ? id : Guid.Empty;
    }

    // Sinh Slug thân thiện với SEO từ chuỗi tiếng Việt (ví dụ: "Sự Kiện Ca Nhạc" -> "su-kien-ca-nhac")
    private static string TaoSlug(string text)
    {
        if (string.IsNullOrEmpty(text)) return "";
        text = text.ToLowerInvariant();
        string[] arr1 = new string[] { "á", "à", "ả", "ã", "ạ", "â", "ấ", "ầ", "ẩ", "ẫ", "ậ", "ă", "ắ", "ằ", "ẳ", "ẵ", "ặ",
            "đ",
            "é","è","ẻ","ẽ","ẹ","ê","ế","ề","ể","ễ","ệ",
            "í","ì","ỉ","ĩ","ị",
            "ó","ò","ỏ","õ","ọ","ô","ố","ồ","ổ","ỗ","ộ","ơ","ớ","ờ","ở","ỡ","ợ",
            "ú","ù","ủ","ũ","ụ","ư","ứ","ừ","ử","ữ","ự",
            "ý","ỳ","ỷ","ỹ","ỵ",};
        string[] arr2 = new string[] { "a", "a", "a", "a", "a", "a", "a", "a", "a", "a", "a", "a", "a", "a", "a", "a", "a",
            "d",
            "e","e","e","e","e","e","e","e","e","e","e",
            "i","i","i","i","i",
            "o","o","o","o","o","o","o","o","o","o","o","o","o","o","o","o","o",
            "u","u","u","u","u","u","u","u","u","u","u",
            "y","y","y","y","y",};
        for (int i = 0; i < arr1.Length; i++)
        {
            text = text.Replace(arr1[i], arr2[i]);
        }
        string result = "";
        foreach (char character in text)
        {
            if (char.IsLetterOrDigit(character)) result += character;
            else if (result.EndsWith('-') == false) result += "-";
        }
        return result.Trim('-');
    }

    public override async Task OnActionExecutionAsync(
        Microsoft.AspNetCore.Mvc.Filters.ActionExecutingContext context,
        Microsoft.AspNetCore.Mvc.Filters.ActionExecutionDelegate next)
    {
        Guid? suKienId = null;

        // Try to get from route parameters
        if (context.RouteData.Values.TryGetValue("id", out var routeVal) && routeVal != null)
        {
            if (Guid.TryParse(routeVal.ToString(), out Guid parsedRouteId))
            {
                // Verify if it is a valid event ID
                var count = await Db.LayGiaTri<int>("SELECT COUNT(1) FROM SuKien WHERE Id = @id", new { id = parsedRouteId });
                if (count > 0)
                {
                    suKienId = parsedRouteId;
                }
            }
        }

        // Try to get from query parameters
        if (suKienId == null && context.HttpContext.Request.Query.TryGetValue("suKienId", out var queryVal))
        {
            if (Guid.TryParse(queryVal.ToString(), out Guid parsedQueryId))
            {
                suKienId = parsedQueryId;
            }
        }

        if (suKienId.HasValue && suKienId.Value != Guid.Empty)
        {
            var organizerId = LayIdNguoiDangNhap();
            if (organizerId != Guid.Empty)
            {
                var suKien = await Db.LayDonLe<SuKien>(
                    "SELECT Id, TenSuKien FROM SuKien WHERE Id = @id AND NguoiToChucId = @organizerId",
                    new { id = suKienId.Value, organizerId }
                );
                if (suKien != null)
                {
                    ViewBag.ActiveEventId = suKien.Id;
                    ViewBag.ActiveEventName = suKien.TenSuKien;
                }
            }
        }

        await next();
    }
}
