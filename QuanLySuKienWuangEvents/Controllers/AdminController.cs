// ADMIN CONTROLLER — Quản trị hệ thống
// Chức năng:
//   - Dashboard: thống kê tổng quan
//   - Danh mục: thêm/sửa/xóa danh mục sự kiện
//   - Đối tác: duyệt/từ chối nhà tổ chức
//   - Sự kiện: duyệt/từ chối/ẩn/hủy sự kiện
//   - Đơn hàng: xem tất cả đơn hàng trên hệ thống
//   - Người dùng: xem/khóa/mở khóa tài khoản
//
// Lưu ý: Chỉ Admin (VaiTro = 3) mới truy cập được

using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Dapper;
using QuanLySuKienWuangEvents.Models;

namespace QuanLySuKienWuangEvents.Controllers;

[Authorize(Roles = "Quản trị viên")]         // Chỉ Admin mới vào được
[Route("Admin/[action]/{id?}")]      // URL mẫu: /Admin/SuKien, /Admin/NguoiDung, v.v.
public class AdminController : Controller
{
    // PHẦN 1: DASHBOARD — Trang tổng quan thống kê

    // TRANG TỔNG QUAN ADMIN
    // URL: GET /Admin/Index
    public async Task<IActionResult> Index()
    {
        // Lấy các con số thống kê để hiển thị trên dashboard
        ViewBag.SoNguoiDung = await Db.LayGiaTri<int>(
            "SELECT COUNT(*) FROM NguoiDung"
        );

        ViewBag.SoSuKien = await Db.LayGiaTri<int>(
            "SELECT COUNT(*) FROM SuKien"
        );

        ViewBag.SoDonHang = await Db.LayGiaTri<int>(
            "SELECT COUNT(*) FROM DonHang"
        );

        // ISNULL(…, 0) để trả về 0 thay vị NULL khi chưa có đơn nào
        ViewBag.DoanhThu = await Db.LayGiaTri<decimal>(
            "SELECT ISNULL(SUM(TongThanhToan), 0) FROM DonHang WHERE TrangThai = 1"
        );

        // Các việc cần làm khẩn (chờ duyệt)
        ViewBag.SoSuKienChoDuyet = await Db.LayGiaTri<int>(
            "SELECT COUNT(*) FROM SuKien WHERE TrangThai = 1"
        );
        
        ViewBag.SoYeuCauBTCChoDuyet = await Db.LayGiaTri<int>(
            "SELECT COUNT(*) FROM NguoiDung WHERE YeuCauBanToChuc = 1"
        );

        return View();
    }

    // PHẦN 2: DANH MỤC SỰ KIỆN

    // DANH SÁCH DANH MỤC
    // URL: GET /Admin/DanhMuc
    public async Task<IActionResult> DanhMuc()
    {
        string sql = @"
            SELECT *
            FROM DanhMuc
            ORDER BY ThuTu, Id
        ";
        var danhSachDanhMuc = await Db.LayDanhSach<DanhMuc>(sql);
        return View(danhSachDanhMuc);
    }

    // Hiển thị form tạo danh mục mới
    [HttpGet]
    public IActionResult TaoMoiDanhMuc()
    {
        return View();
    }

    // Xử lý tạo danh mục mới
    [HttpPost]
    public async Task<IActionResult> TaoMoiDanhMuc(DanhMuc model)
    {
        string sql = @"
            INSERT INTO DanhMuc
                (TenDanhMuc, MoTa, Icon, ThuTu, TrangThai)
            VALUES
                (@TenDanhMuc, @MoTa, @Icon, @ThuTu, @TrangThai)
        ";
        await Db.ThucThi(sql, model);
        return RedirectToAction("DanhMuc");
    }

    // Hiển thị form chỉnh sửa danh mục
    [HttpGet]
    public async Task<IActionResult> ChinhSuaDanhMuc(int id)
    {
        var danhMuc = await Db.LayDonLe<DanhMuc>(
            "SELECT * FROM DanhMuc WHERE Id = @id", new { id }
        );
        if (danhMuc == null) return NotFound();
        return View(danhMuc);
    }

    // Xử lý lưu chỉnh sửa danh mục
    [HttpPost]
    public async Task<IActionResult> ChinhSuaDanhMuc(DanhMuc model)
    {
        string sql = @"
            UPDATE DanhMuc
            SET TenDanhMuc = @TenDanhMuc,
                MoTa       = @MoTa,
                Icon       = @Icon,
                ThuTu      = @ThuTu,
                TrangThai  = @TrangThai
            WHERE Id = @Id
        ";
        await Db.ThucThi(sql, model);
        return RedirectToAction("DanhMuc");
    }

    // Xóa danh mục
    [HttpPost]
    public async Task<IActionResult> XoaDanhMuc(int id)
    {
        await Db.ThucThi("DELETE FROM DanhMuc WHERE Id = @id", new { id });
        return RedirectToAction("DanhMuc");
    }

    // PHẦN 3: DUYỆT BAN TỔ CHỨC

    // DANH SÁCH YÊU CẦU LÊN BAN TỔ CHỨC
    // URL: GET /Admin/DuyetBTCList
    public async Task<IActionResult> DuyetBTCList()
    {
        string sql = @"
            SELECT *
            FROM NguoiDung
            WHERE YeuCauBanToChuc = 1
            ORDER BY NgayYeuCauBTC DESC
        ";
        var danhSachYeuCau = await Db.LayDanhSach<NguoiDung>(sql);
        return View(danhSachYeuCau);
    }

    // XỬ LÝ DUYỆT / TỪ CHỐI YÊU CẦU LÊN BAN TỔ CHỨC
    // URL: POST /Admin/XuLyDuyetBTC
    [HttpPost]
    public async Task<IActionResult> XuLyDuyetBTC(Guid id, bool status, string? lyDo)
    {
        if (status)
        {
            // Phê duyệt thành công: Đổi VaiTro = 1 (Ban tổ chức) và YeuCauBanToChuc = 2 (Đã duyệt)
            string sqlApprove = @"
                UPDATE NguoiDung
                SET VaiTro = 1,
                    YeuCauBanToChuc = 2,
                    LyDoTuChoiBTC = NULL,
                    NgayCapNhat = GETUTCDATE()
                WHERE Id = @id AND YeuCauBanToChuc = 1
            ";
            int rows = await Db.ThucThi(sqlApprove, new { id });
            if (rows > 0)
            {
                TempData["Message"] = "Đã phê duyệt tài khoản làm Ban tổ chức thành công.";
            }
            else
            {
                TempData["Error"] = "Phê duyệt thất bại hoặc yêu cầu không tồn tại.";
            }
        }
        else
        {
            // Từ chối phê duyệt: Đổi YeuCauBanToChuc = 3 (Bị từ chối) và lưu lý do
            string sqlReject = @"
                UPDATE NguoiDung
                SET YeuCauBanToChuc = 3,
                    LyDoTuChoiBTC = @lyDo,
                    NgayCapNhat = GETUTCDATE()
                WHERE Id = @id AND YeuCauBanToChuc = 1
            ";
            int rows = await Db.ThucThi(sqlReject, new { id, lyDo = lyDo?.Trim() ?? "Không có lý do cụ thể." });
            if (rows > 0)
            {
                TempData["Message"] = "Đã từ chối phê duyệt tài khoản làm Ban tổ chức.";
            }
            else
            {
                TempData["Error"] = "Từ chối phê duyệt thất bại hoặc yêu cầu không tồn tại.";
            }
        }

        return RedirectToAction("DuyetBTCList");
    }

    // PHẦN 4: DUYỆT SỰ KIỆN

    // DANH SÁCH SỰ KIỆN (để Admin duyệt)
    // URL: GET /Admin/SuKien
    // TrangThai: 1=Nháp, 2=Đang bán, 3=Đã duyệt/Sắp diễn ra, 4=Đã kết thúc,
    //            5=Chờ duyệt, 6=Đã hủy, 7=Bị từ chối
    public async Task<IActionResult> SuKien(byte? trangThai)
    {
        string sql = @"
            SELECT *
            FROM SuKien
            WHERE (@trangThai IS NULL OR TrangThai = @trangThai)
            ORDER BY NgayTao DESC
        ";
        var danhSachSuKien = await Db.LayDanhSach<SuKien>(sql, new { trangThai });
        ViewBag.TrangThai = trangThai;
        return View(danhSachSuKien);
    }

    // Duyệt sự kiện → cho phép bán vé
    [HttpPost]
    public async Task<IActionResult> DuyetSuKien(Guid id)
    {
        string sql = @"
            UPDATE SuKien
            SET TrangThai    = 3,
                NgayCapNhat  = GETUTCDATE()
            WHERE Id = @id
        ";
        await Db.ThucThi(sql, new { id });
        TempData["Message"] = "Đã duyệt sự kiện.";
        return RedirectToAction("SuKien");
    }

    // Từ chối sự kiện (cần ghi lý do trả về cho nhà tổ chức)
    [HttpPost]
    public async Task<IActionResult> TuChoiSuKien(Guid id, string? lyDo)
    {
        string sql = @"
            UPDATE SuKien
            SET TrangThai    = 7,
                LyDoTuChoi   = @lyDo,
                NgayCapNhat  = GETUTCDATE()
            WHERE Id = @id
        ";
        await Db.ThucThi(sql, new { id, lyDo });
        TempData["Message"] = "Đã từ chối sự kiện.";
        return RedirectToAction("SuKien");
    }

    // Ẩn / Hiện sự kiện trên trang chủ (bật/tắt HienThiCongKhai)
    [HttpPost]
    public async Task<IActionResult> HienThiCongKhaiSuKien(Guid id)
    {
        string sql = @"
            UPDATE SuKien
            SET HienThiCongKhai = CASE WHEN HienThiCongKhai = 1 THEN 0 ELSE 1 END,
                NgayCapNhat     = GETUTCDATE()
            WHERE Id = @id
        ";
        await Db.ThucThi(sql, new { id });
        TempData["Message"] = "Đã thay đổi trạng thái hiển thị sự kiện.";
        return RedirectToAction("SuKien");
    }

    // Hủy sự kiện hoàn toàn
    [HttpPost]
    public async Task<IActionResult> HuySuKien(Guid id, string? lyDo)
    {
        using var connection = Db.TaoKetNoi();
        await connection.OpenAsync();
        using var transaction = connection.BeginTransaction();
        try
        {
            string sql = @"
                UPDATE SuKien
                SET TrangThai       = 6,
                    HienThiCongKhai = 0,
                    LyDoTuChoi      = @lyDo,
                    NgayCapNhat     = GETUTCDATE()
                WHERE Id = @id
            ";
            int affected = await connection.ExecuteAsync(sql, new { id, lyDo = lyDo ?? "Admin hủy sự kiện" }, transaction);
            if (affected > 0)
            {
                // Reset SoLuongGiuCho của các loại vé đi kèm
                string sqlResetGiuCho = @"
                    UPDATE LoaiVe
                    SET SoLuongGiuCho = 0
                    WHERE SuKienId = @id
                ";
                await connection.ExecuteAsync(sqlResetGiuCho, new { id }, transaction);

                // Giải phóng các ghế đang bị giữ ở trạng thái Chờ thanh toán (TrangThai = 2 -> 0)
                string sqlReleaseSeats = @"
                    UPDATE ChoNgoi
                    SET TrangThai = 0
                    WHERE TrangThai = 2
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

        TempData["Message"] = "Đã hủy sự kiện.";
        return RedirectToAction("SuKien");
    }

    // PHẦN 5: QUẢN LÝ ĐƠN HÀNG

    // DANH SÁCH TẤT CẢ ĐƠN HÀNG
    // URL: GET /Admin/DonHang
    public async Task<IActionResult> DonHang(byte? trangThai, string? search)
    {
        // Lấy đơn hàng kèm tên sự kiện (từ bảng SuKien)
        string sql = @"
            SELECT d.*,
                   s.TenSuKien
            FROM DonHang d
            JOIN SuKien s ON s.Id = d.SuKienId
            WHERE (@trangThai IS NULL OR d.TrangThai = @trangThai)
              AND (@search = '' OR d.MaDonHang      LIKE '%' + @search + '%'
                               OR d.EmailNguoiMua   LIKE '%' + @search + '%'
                               OR d.HoTenNguoiMua   LIKE '%' + @search + '%')
            ORDER BY d.NgayTao DESC
        ";

        var danhSachTho = await Db.LayDanhSach<dynamic>(sql, new
        {
            trangThai,
            search = search?.Trim() ?? ""
        });

        // Tách tên sự kiện ra khỏi kết quả để gửi qua ViewBag
        var danhSachDonHang = new List<DonHang>();
        var tenSuKienTheoId = new Dictionary<Guid, string>(); // key=SuKienId, value=TenSuKien

        foreach (var dong in danhSachTho)
        {
            var donHang = new DonHang
            {
                Id             = dong.Id,
                MaDonHang      = dong.MaDonHang,
                NguoiMuaId     = dong.NguoiMuaId,
                SuKienId       = dong.SuKienId,
                MaGiamGiaId    = dong.MaGiamGiaId,
                HoTenNguoiMua  = dong.HoTenNguoiMua,
                EmailNguoiMua  = dong.EmailNguoiMua,
                SdtNguoiMua    = dong.SdtNguoiMua,
                TongTienVe     = dong.TongTienVe,
                TienGiamGia    = dong.TienGiamGia,
                TongThanhToan  = dong.TongThanhToan,
                TrangThai      = dong.TrangThai,
                NgayTao        = dong.NgayTao,
                NgayCapNhat    = dong.NgayCapNhat
            };
            danhSachDonHang.Add(donHang);
            tenSuKienTheoId[donHang.SuKienId] = dong.TenSuKien;
        }

        ViewBag.Events    = tenSuKienTheoId;
        ViewBag.TrangThai = trangThai;
        ViewBag.Search    = search;
        return View(danhSachDonHang);
    }

    // CHI TIẾT ĐƠN HÀNG (Admin xem)
    // URL: GET /Admin/ChiTietDonHang?id={donHangId}
    public async Task<IActionResult> ChiTietDonHang(Guid id)
    {
        // Lấy đơn hàng kèm tên sự kiện
        string sqlDonHang = @"
            SELECT d.*,
                   s.TenSuKien
            FROM DonHang d
            JOIN SuKien s ON s.Id = d.SuKienId
            WHERE d.Id = @id
        ";
        var dong = await Db.LayDonLe<dynamic>(sqlDonHang, new { id });

        if (dong == null)
        {
            return NotFound();
        }

        // Map dữ liệu vào model DonHang
        var donHang = new DonHang
        {
            Id             = dong.Id,
            MaDonHang      = dong.MaDonHang,
            NguoiMuaId     = dong.NguoiMuaId,
            SuKienId       = dong.SuKienId,
            MaGiamGiaId    = dong.MaGiamGiaId,
            HoTenNguoiMua  = dong.HoTenNguoiMua,
            EmailNguoiMua  = dong.EmailNguoiMua,
            SdtNguoiMua    = dong.SdtNguoiMua,
            TongTienVe     = dong.TongTienVe,
            TienGiamGia    = dong.TienGiamGia,
            TongThanhToan  = dong.TongThanhToan,
            TrangThai      = dong.TrangThai,
            NgayTao        = dong.NgayTao,
            NgayCapNhat    = dong.NgayCapNhat
        };

        // Lấy danh sách từng vé trong đơn hàng
        string sqlChiTiet = @"
            SELECT ct.*, lv.TenLoaiVe, cn.SoGhe
            FROM ChiTietDonHang ct
            LEFT JOIN LoaiVe lv ON lv.Id = ct.LoaiVeId
            LEFT JOIN ChoNgoi cn ON cn.Id = ct.ChoNgoiId
            WHERE ct.DonHangId = @donHangId
        ";

        ViewBag.TenSuKien = dong.TenSuKien;
        ViewBag.ChiTiet   = await Db.LayDanhSach<ChiTietDonHang>(sqlChiTiet, new { donHangId = id });
        return View(donHang);
    }

    // PHẦN 6: QUẢN LÝ TÀI KHOẢN NGƯỜI DÙNG

    // DANH SÁCH NGƯỜI DÙNG
    // URL: GET /Admin/NguoiDung
    // VaiTro: 0=Khách hàng, 1=Nhà tổ chức, 3=Admin
    // TrangThai: 0=Bị khóa, 1=Đang hoạt động
    public async Task<IActionResult> NguoiDung(byte? vaiTro, byte? trangThai, string? search)
    {
        string sql = @"
            SELECT *
            FROM NguoiDung
            WHERE (@vaiTro    IS NULL OR VaiTro    = @vaiTro)
              AND (@trangThai IS NULL OR TrangThai = @trangThai)
              AND (@search = '' OR HoTen LIKE '%' + @search + '%'
                               OR Email LIKE '%' + @search + '%')
            ORDER BY NgayTao DESC
        ";

        var danhSachNguoiDung = await Db.LayDanhSach<NguoiDung>(sql, new
        {
            vaiTro,
            trangThai,
            search = search?.Trim() ?? ""
        });

        ViewBag.VaiTro    = vaiTro;
        ViewBag.TrangThai = trangThai;
        ViewBag.Search    = search;
        return View(danhSachNguoiDung);
    }

    // Khóa / Mở khóa tài khoản người dùng (không áp dụng cho Admin)
    [HttpPost]
    public async Task<IActionResult> KhoaMoKhoaNguoiDung(Guid id)
    {
        // VaiTro <> 3: đảm bảo không khóa được tài khoản Admin
        string sql = @"
            UPDATE NguoiDung
            SET TrangThai   = CASE WHEN TrangThai = 1 THEN 0 ELSE 1 END,
                NgayCapNhat = GETUTCDATE()
            WHERE Id     = @id
              AND VaiTro <> 3
        ";
        await Db.ThucThi(sql, new { id });
        TempData["Message"] = "Đã cập nhật trạng thái tài khoản.";
        return RedirectToAction("NguoiDung");
    }

    // XUẤT FILE CSV DANH SÁCH NGƯỜI DÙNG
    // URL: GET /Admin/XuatFileCsvNguoiDung
    public async Task<IActionResult> XuatFileCsvNguoiDung(byte? vaiTro, byte? trangThai, string? search)
    {
        string sql = @"
            SELECT HoTen,
                   Email,
                   ISNULL(SoDienThoai, '') AS SoDienThoai,
                   VaiTro,
                   TrangThai,
                   NgayTao
            FROM NguoiDung
            WHERE (@vaiTro    IS NULL OR VaiTro    = @vaiTro)
              AND (@trangThai IS NULL OR TrangThai = @trangThai)
              AND (@search = '' OR HoTen LIKE '%' + @search + '%'
                               OR Email LIKE '%' + @search + '%')
        ";

        var danhSach = await Db.LayDanhSach<dynamic>(sql, new
        {
            vaiTro,
            trangThai,
            search = search?.Trim() ?? ""
        });

        // Tạo nội dung file CSV (Comma-Separated Values)
        var noiDungCsv = new StringBuilder("Ho ten,Email,So dien thoai,Vai tro,Trang thai,Ngay tao\r\n");

        foreach (var dong in danhSach)
        {
            string hoTen       = dong.HoTen;
            string email       = dong.Email;
            string soDienThoai = dong.SoDienThoai;
            byte   vaiTroSo    = dong.VaiTro;
            byte   trangThaiSo = dong.TrangThai;
            DateTime ngayTao   = dong.NgayTao;

            // Replace dấu phẩy trong tên để không vỡ định dạng CSV
            noiDungCsv.AppendLine($"{hoTen.Replace(',', ' ')},{email},{soDienThoai},{vaiTroSo},{trangThaiSo},{ngayTao:dd/MM/yyyy}");
        }

        // Thêm BOM (Byte Order Mark) để Excel đọc tiếng Việt đúng
        byte[] fileBytes = Encoding.UTF8.GetPreamble()
            .Concat(Encoding.UTF8.GetBytes(noiDungCsv.ToString()))
            .ToArray();

        return File(fileBytes, "text/csv", "nguoi-dung.csv");
    }

    // CHI TIẾT NGƯỜI DÙNG
    // URL: GET /Admin/ChiTietNguoiDung/{id}
    public async Task<IActionResult> ChiTietNguoiDung(Guid id)
    {
        string sql = "SELECT * FROM NguoiDung WHERE Id = @id";
        var nguoiDung = await Db.LayDonLe<NguoiDung>(sql, new { id });
        if (nguoiDung == null)
        {
            return NotFound();
        }

        // 1. Thống kê chung nếu là Người mua (VaiTro == 0)
        if (nguoiDung.VaiTro == 0)
        {
            string sqlBookingStats = @"
                SELECT COUNT(Id) AS TotalOrders,
                       ISNULL(SUM(TongThanhToan), 0) AS TotalSpent
                FROM DonHang
                WHERE NguoiMuaId = @id AND TrangThai = 1
            ";
            var stats = await Db.LayDonLe<dynamic>(sqlBookingStats, new { id });
            ViewBag.TotalOrders = stats?.TotalOrders ?? 0;
            ViewBag.TotalSpent  = stats?.TotalSpent ?? 0;
            
            // Get last 5 orders
            string sqlLastOrders = @"
                SELECT TOP 5 d.Id, d.MaDonHang, d.TongThanhToan, d.NgayTao, d.TrangThai, s.TenSuKien
                FROM DonHang d
                JOIN SuKien s ON s.Id = d.SuKienId
                WHERE d.NguoiMuaId = @id
                ORDER BY d.NgayTao DESC
            ";
            ViewBag.LastOrders = await Db.LayDanhSach<dynamic>(sqlLastOrders, new { id });
        }
        // 2. Thống kê chung nếu là Ban tổ chức (VaiTro == 1)
        else if (nguoiDung.VaiTro == 1)
        {
            ViewBag.OrgProfile = nguoiDung;

            string sqlOrgStats = @"
                SELECT COUNT(s.Id) AS TotalEvents,
                       ISNULL(SUM(d.TongThanhToan), 0) AS TotalRevenue,
                       (SELECT COUNT(d2.Id) FROM DonHang d2 JOIN SuKien s2 ON s2.Id = d2.SuKienId WHERE s2.NguoiToChucId = @id AND d2.TrangThai = 1) AS TotalOrders
                FROM SuKien s
                LEFT JOIN DonHang d ON d.SuKienId = s.Id AND d.TrangThai = 1
                WHERE s.NguoiToChucId = @id
            ";
            var stats = await Db.LayDonLe<dynamic>(sqlOrgStats, new { id });
            ViewBag.TotalEvents  = stats?.TotalEvents ?? 0;
            ViewBag.TotalRevenue = stats?.TotalRevenue ?? 0;
            ViewBag.TotalOrders  = stats?.TotalOrders ?? 0;

            // Get last 5 events
            string sqlLastEvents = @"
                SELECT TOP 5 Id, TenSuKien, NgayTao, TrangThai, VeDaBan, TongVe
                FROM SuKien
                WHERE NguoiToChucId = @id
                ORDER BY NgayTao DESC
            ";
            ViewBag.LastEvents = await Db.LayDanhSach<dynamic>(sqlLastEvents, new { id });
        }
        // 3. Thống kê chung nếu là Staff (VaiTro == 2)
        else if (nguoiDung.VaiTro == 2)
        {
            string sqlStaffEvents = @"
                SELECT s.Id, s.TenSuKien, s.NgayBatDau, nv.NgayThem
                FROM NhanVienSuKien nv
                JOIN SuKien s ON s.Id = nv.SuKienId
                WHERE nv.NguoiDungId = @id
                ORDER BY nv.NgayThem DESC
            ";
            ViewBag.StaffEvents = await Db.LayDanhSach<dynamic>(sqlStaffEvents, new { id });
        }

        return View(nguoiDung);
    }

    // HÀM HỖ TRỢ

    // Lấy ID của Admin đang đăng nhập (dùng để ghi lại ai đã duyệt)
    private Guid LayAdminId()
    {
        string? idChuoi = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.Parse(idChuoi ?? Guid.Empty.ToString());
    }
}
