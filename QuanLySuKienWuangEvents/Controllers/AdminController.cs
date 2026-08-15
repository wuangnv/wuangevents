// ADMIN CONTROLLER — Quản trị hệ thống
// Dashboard, danh mục, duyệt, đơn và user; chỉ Admin, route /Admin/{action}/{id?}.

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
    [HttpGet]
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
    [HttpGet]
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
        if (string.IsNullOrWhiteSpace(model.TenDanhMuc))
        {
            ModelState.AddModelError(nameof(model.TenDanhMuc), "Tên danh mục là bắt buộc.");
        }
        if (model.ThuTu < 0)
        {
            ModelState.AddModelError(nameof(model.ThuTu), "Thứ tự hiển thị không được là số âm.");
        }
        if (!ModelState.IsValid)
        {
            return View(model);
        }

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
        if (string.IsNullOrWhiteSpace(model.TenDanhMuc))
        {
            ModelState.AddModelError(nameof(model.TenDanhMuc), "Tên danh mục là bắt buộc.");
        }
        if (model.ThuTu < 0)
        {
            ModelState.AddModelError(nameof(model.ThuTu), "Thứ tự hiển thị không được là số âm.");
        }
        if (!ModelState.IsValid)
        {
            return View(model);
        }

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
        int soSuKienDangDung = await Db.LayGiaTri<int>(
            "SELECT COUNT(1) FROM SuKien WHERE DanhMucId = @id", new { id });
        if (soSuKienDangDung > 0)
        {
            TempData["Error"] = "Không thể xóa danh mục đang được sự kiện sử dụng. Hãy ẩn danh mục thay vì xóa.";
            return RedirectToAction("DanhMuc");
        }

        await Db.ThucThi("DELETE FROM DanhMuc WHERE Id = @id", new { id });
        TempData["Message"] = "Đã xóa danh mục.";
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
    [ValidateAntiForgeryToken]
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
                WHERE Id = @id
                  AND YeuCauBanToChuc = 1
                  AND EmailXacNhan = 1
                  AND SdtBanToChuc IS NOT NULL
                  AND TenToChuc IS NOT NULL
                  AND LoaiChuTheBTC IN (0, 1)
                  AND LEN(MoTaYeuCauBTC) >= 30
                  AND DaDongYDieuKhoanBTC = 1
            ";
            int rows = await Db.ThucThi(sqlApprove, new { id });
            if (rows > 0)
            {
                TempData["Message"] = "Đã phê duyệt tài khoản làm Ban tổ chức thành công.";
            }
            else
            {
                TempData["Error"] = "Không thể phê duyệt vì hồ sơ chưa đủ điều kiện hoặc không còn ở trạng thái chờ.";
            }
        }
        else
        {
            if (string.IsNullOrWhiteSpace(lyDo))
            {
                TempData["Error"] = "Vui lòng nhập lý do từ chối hồ sơ.";
                return RedirectToAction("DuyetBTCList");
            }

            // Từ chối phê duyệt: Đổi YeuCauBanToChuc = 3 (Bị từ chối) và lưu lý do
            string sqlReject = @"
                UPDATE NguoiDung
                SET YeuCauBanToChuc = 3,
                    LyDoTuChoiBTC = @lyDo,
                    NgayCapNhat = GETUTCDATE()
                WHERE Id = @id AND YeuCauBanToChuc = 1
            ";
            int rows = await Db.ThucThi(sqlReject, new { id, lyDo = lyDo.Trim() });
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

    // GET /Admin/SuKien: trạng thái 0 nháp, 1 chờ, 2 dừng, 3 bán, 6 hủy, 7 từ chối.
    [HttpGet]
    public async Task<IActionResult> SuKien(byte? trangThai, string? q)
    {
        string sql = @"
            SELECT *
            FROM SuKien
            WHERE (@trangThai IS NULL OR TrangThai = @trangThai)
              AND (@q = '' OR TenSuKien LIKE '%' + @q + '%'
                           OR MoTaNgan LIKE '%' + @q + '%')
            ORDER BY NgayTao DESC
        ";
        var danhSachSuKien = await Db.LayDanhSach<SuKien>(sql, new
        {
            trangThai,
            q = q?.Trim() ?? ""
        });
        ViewBag.TrangThai = trangThai;
        ViewBag.Search = q;
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
              AND TrangThai = 1
              AND NgayKetThuc > DATEADD(HOUR, 7, GETUTCDATE())
              AND EXISTS (
                    SELECT 1 FROM LoaiVe lv
                    WHERE lv.SuKienId = SuKien.Id
                      AND lv.TrangThai = 1
                      AND lv.SoLuongTong > 0
              )
              AND (LoaiSuKien = 0 OR LinkOnline LIKE 'https://%')
              AND (CoSoDoChoNgoi = 0 OR EXISTS (
                    SELECT 1 FROM SoDoChoNgoi sd
                    WHERE sd.SuKienId = SuKien.Id
              ))
        ";
        int soDongCapNhat = await Db.ThucThi(sql, new { id });
        TempData[soDongCapNhat > 0 ? "Message" : "Error"] = soDongCapNhat > 0
            ? "Đã duyệt sự kiện."
            : "Không thể duyệt: sự kiện phải đang chờ duyệt, còn hạn, có loại vé và đủ cấu hình hình thức tổ chức.";
        return RedirectToAction("SuKien");
    }

    // Từ chối sự kiện (cần ghi lý do trả về cho nhà tổ chức)
    [HttpPost]
    public async Task<IActionResult> TuChoiSuKien(Guid id, string? lyDo)
    {
        lyDo = lyDo?.Trim();
        if (string.IsNullOrWhiteSpace(lyDo) || lyDo.Length < 5 || lyDo.Length > 500)
        {
            TempData["Error"] = "Lý do từ chối phải có từ 5 đến 500 ký tự.";
            return RedirectToAction("SuKien");
        }

        string sql = @"
            UPDATE SuKien
            SET TrangThai    = 7,
                LyDoTuChoi   = @lyDo,
                NgayCapNhat  = GETUTCDATE()
            WHERE Id = @id
              AND TrangThai = 1
        ";
        int soDongCapNhat = await Db.ThucThi(sql, new { id, lyDo });
        TempData[soDongCapNhat > 0 ? "Message" : "Error"] = soDongCapNhat > 0
            ? "Đã từ chối sự kiện."
            : "Chỉ có thể từ chối sự kiện đang ở trạng thái chờ duyệt.";
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
              AND TrangThai IN (3, 5)
        ";
        int soDongCapNhat = await Db.ThucThi(sql, new { id });
        TempData[soDongCapNhat > 0 ? "Message" : "Error"] = soDongCapNhat > 0
            ? "Đã thay đổi trạng thái hiển thị sự kiện."
            : "Chỉ sự kiện đang bán hoặc đã lưu trữ mới được hiển thị công khai.";
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
            var suKien = await connection.QueryFirstOrDefaultAsync<dynamic>(@"
                SELECT TrangThai
                FROM SuKien WITH (UPDLOCK, HOLDLOCK)
                WHERE Id = @id", new { id }, transaction);

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

            string sql = @"
                UPDATE SuKien
                SET TrangThai       = 6,
                    HienThiCongKhai = 0,
                    LyDoTuChoi      = @lyDo,
                    NgayCapNhat     = GETUTCDATE()
                WHERE Id = @id
                  AND TrangThai IN (0, 1, 2, 3, 7)
            ";
            int affected = await connection.ExecuteAsync(sql, new { id, lyDo = lyDo ?? "Admin hủy sự kiện" }, transaction);
            if (affected > 0)
            {
                // Đơn chưa thanh toán không được tiếp tục quay lại từ cổng sau khi sự kiện đã hủy.
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

        TempData["Message"] = "Đã hủy sự kiện.";
        return RedirectToAction("SuKien");
    }

    // PHẦN 5: QUẢN LÝ ĐƠN HÀNG

    // GET /Admin/DonHang: nhận trạng thái/từ khóa từ query string và trả danh sách đơn.
    public async Task<IActionResult> DonHang(byte? trangThai, string? search)
    {
        // @"..." là chuỗi C# nhiều dòng, dùng để chứa câu lệnh SQL cho dễ đọc.
        // d và s chỉ là tên viết tắt: d = DonHang, s = SuKien.
        string sql = @"
            -- d.* lấy toàn bộ cột của bảng DonHang.
            -- DonHang chỉ giữ SuKienId, nên phải JOIN để lấy thêm TenSuKien.
            SELECT d.*,
                   s.TenSuKien
            FROM DonHang d

            -- Ghép một đơn với sự kiện có Id bằng SuKienId của đơn.
            JOIN SuKien s ON s.Id = d.SuKienId

            -- Không chọn trạng thái: @trangThai IS NULL đúng -> không lọc.
            -- Có chọn trạng thái: chỉ lấy d.TrangThai bằng giá trị được chọn.
            WHERE (@trangThai IS NULL OR d.TrangThai = @trangThai)

              -- Search rỗng thì điều kiện @search = '' đúng -> không lọc chữ.
              -- Search có chữ thì LIKE tìm chữ đó trong mã đơn/email/họ tên.
              AND (@search = '' OR d.MaDonHang      LIKE '%' + @search + '%'
                               OR d.EmailNguoiMua   LIKE '%' + @search + '%'
                               OR d.HoTenNguoiMua   LIKE '%' + @search + '%')

            -- DESC = giảm dần: đơn mới nhất đứng trên cùng.
            ORDER BY d.NgayTao DESC
        ";

        // Dùng dynamic vì SELECT thêm TenSuKien; object ẩn danh truyền tham số cho Dapper.
        var danhSachTho = await Db.LayDanhSach<dynamic>(sql, new
        {
            // Viết tắt của trangThai = trangThai.
            trangThai,

            // ?.Trim(): nếu search không null thì xóa khoảng trắng đầu/cuối.
            // ?? "": nếu search null thì dùng chuỗi rỗng.
            search = search?.Trim() ?? ""
        });

        // Tạo danh sách DonHang rỗng để chuẩn bị đưa vào @model của View.
        var danhSachDonHang = new List<DonHang>();

        // Dictionary ánh xạ SuKienId -> TenSuKien để View tra tên.
        var tenSuKienTheoId = new Dictionary<Guid, string>();

        // foreach chạy một lần cho mỗi dòng SQL mà Dapper vừa trả về.
        foreach (var dong in danhSachTho)
        {
            // Chuyển dòng dynamic thành model DonHang rõ kiểu.
            // Bên trái là property của model; bên phải là cột SQL của dòng hiện tại.
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

            // Sau khi dựng xong một DonHang, thêm nó vào List<DonHang>.
            danhSachDonHang.Add(donHang);

            // Nhiều đơn cùng sự kiện dùng chung một tên trong dictionary.
            tenSuKienTheoId[donHang.SuKienId] = dong.TenSuKien;
        }

        // Model chỉ gửi được danhSachDonHang qua return View(...).
        // Các dữ liệu phụ được đặt vào ViewBag của đúng request hiện tại.
        ViewBag.Events    = tenSuKienTheoId;
        ViewBag.TrangThai = trangThai;
        ViewBag.Search    = search;

        // Render Views/Admin/DonHang.cshtml với danhSachDonHang làm Model.
        return View(danhSachDonHang);
    }

    // GET /Admin/ChiTietDonHang/{id}: lấy đơn và các vé con để Admin xem.
    public async Task<IActionResult> ChiTietDonHang(Guid id)
    {
        // SQL thứ nhất: lấy đúng một đơn theo Id và lấy thêm tên sự kiện.
        string sqlDonHang = @"
            SELECT d.*,
                   s.TenSuKien
            FROM DonHang d
            JOIN SuKien s ON s.Id = d.SuKienId
            WHERE d.Id = @id
        ";

        // LayDonLe<dynamic> gọi QueryFirstOrDefaultAsync của Dapper trong Db.cs.
        // new { id } tạo tham số @id; không tìm thấy thì dong nhận null.
        var dong = await Db.LayDonLe<dynamic>(sqlDonHang, new { id });

        // Phải kiểm tra null trước khi đọc dong.MaDonHang, dong.SuKienId,...
        // Nếu không có đơn, trả HTTP 404 thay vì để chương trình lỗi NullReference.
        if (dong == null)
        {
            return NotFound();
        }

        // Chuyển dòng dynamic thành model DonHang để View có kiểu dữ liệu rõ ràng.
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

        // SQL thứ hai: một DonHang có thể có nhiều ChiTietDonHang (nhiều vé).
        // ct.* lấy các cột của vé; hai JOIN lấy thêm TenLoaiVe và SoGhe.
        string sqlChiTiet = @"
            SELECT ct.*, lv.TenLoaiVe, cn.SoGhe
            FROM ChiTietDonHang ct

            -- LEFT JOIN giữ lại vé kể cả khi dữ liệu được nối không tồn tại.
            -- Đặc biệt ChoNgoiId có thể null với sự kiện không chọn ghế.
            LEFT JOIN LoaiVe lv ON lv.Id = ct.LoaiVeId
            LEFT JOIN ChoNgoi cn ON cn.Id = ct.ChoNgoiId

            -- Chỉ lấy những vé con thuộc đơn đang xem.
            WHERE ct.DonHangId = @donHangId
        ";

        // Dữ liệu chính của View là donHang; hai dữ liệu phụ đi qua ViewBag.
        ViewBag.TenSuKien = dong.TenSuKien;

        // Dapper ghép TenLoaiVe/SoGhe vào property bổ sung; @donHangId nhận id.
        ViewBag.ChiTiet   = await Db.LayDanhSach<ChiTietDonHang>(sqlChiTiet, new { donHangId = id });

        // Tìm Views/Admin/ChiTietDonHang.cshtml và gán donHang vào Model.
        return View(donHang);
    }

    // PHẦN 6: QUẢN LÝ TÀI KHOẢN NGƯỜI DÙNG

    // GET /Admin/NguoiDung: lọc role (0 khách, 1 BTC, 2 Staff, 3 Admin) và trạng thái.
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
        return Guid.TryParse(idChuoi, out Guid id) ? id : Guid.Empty;
    }
}
