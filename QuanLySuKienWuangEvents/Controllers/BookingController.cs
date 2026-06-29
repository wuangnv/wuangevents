// BOOKING CONTROLLER — Đặt vé & Thanh toán
// Chức năng: Đặt vé, áp dụng voucher, thanh toán,
//            xem đơn hàng, xem chi tiết vé + QR code
//
// Lưu ý: Tất cả action trong Controller này đều yêu cầu
//        người dùng phải đăng nhập [Authorize]

using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Dapper;
using QRCoder;
using QuanLySuKienWuangEvents.Models;
using Microsoft.Extensions.Configuration;

using QuanLySuKienWuangEvents.Services;

namespace QuanLySuKienWuangEvents.Controllers;

[Authorize] // Toàn bộ controller này yêu cầu đăng nhập
public class BookingController : Controller
{
    private readonly IConfiguration _configuration;
    private readonly EmailService _emailService;

    public BookingController(IConfiguration configuration, EmailService emailService)
    {
        _configuration = configuration;
        _emailService = emailService;
    }

    // ĐẶT VÉ - Tạo đơn hàng tạm thời (chưa thanh toán)
    // URL: POST /Booking/DatVe
    // Tham số:
    //   suKienId = ID sự kiện
    //   loaiVeId = ID loại vé (Thường / VIP / ...)
    //   soLuong  = số vé muốn mua
    [HttpPost]
    public async Task<IActionResult> DatVe(Guid suKienId, Dictionary<int, int> veChon)
    {
        // Tự động giải phóng các đơn hàng quá hạn 15 phút chưa thanh toán
        await GiaiPhongDonHangHetHan();

        // Lọc ra các loại vé được chọn có số lượng > 0
        var selectedTickets = veChon?.Where(x => x.Value > 0).ToDictionary(x => x.Key, x => x.Value) ?? new Dictionary<int, int>();
        if (selectedTickets.Count == 0)
        {
            TempData["Message"] = "Vui lòng chọn ít nhất một vé để đặt hàng.";
            return RedirectToAction("ChiTiet", "Home", new { id = suKienId });
        }

        // Lấy thông tin người đang đăng nhập
        var nguoiMuaId = LayIdNguoiDangNhap();
        var hoTen      = User.Identity?.Name ?? "";
        var email      = User.FindFirstValue(ClaimTypes.Email) ?? "";

        // Kiểm tra trạng thái sự kiện
        var suKien = await Db.LayDonLe<SuKien>("SELECT * FROM SuKien WHERE Id = @id", new { id = suKienId });
        if (suKien == null || suKien.TrangThai != 3)
        {
            TempData["Message"] = "Sự kiện hiện tại không trong trạng thái bán vé (đang tạm dừng hoặc đã hủy).";
            return RedirectToAction("ChiTiet", "Home", new { id = suKienId });
        }

        // Chặn nhà tổ chức tự đặt vé của chính mình
        if (suKien.NguoiToChucId == nguoiMuaId)
        {
            TempData["Message"] = "Bạn không thể đặt vé cho sự kiện do chính mình tổ chức.";
            return RedirectToAction("ChiTiet", "Home", new { id = suKienId });
        }

        if (DateTime.UtcNow > suKien.NgayKetThuc)
        {
            TempData["Message"] = "Sự kiện này đã kết thúc thời gian diễn ra.";
            return RedirectToAction("ChiTiet", "Home", new { id = suKienId });
        }

        // Kiểm tra tính hợp lệ và số lượng của từng loại vé được chọn
        decimal tongTien = 0;
        DateTime now = DateTime.UtcNow;

        foreach (var item in selectedTickets)
        {
            int loaiVeId = item.Key;
            int soLuong = item.Value;

            string sqlLoaiVe = @"
                SELECT *
                FROM LoaiVe
                WHERE Id       = @id
                  AND SuKienId = @suKienId
                  AND TrangThai = 1
            ";
            var loaiVe = await Db.LayDonLe<LoaiVe>(sqlLoaiVe, new { id = loaiVeId, suKienId });
            if (loaiVe == null)
            {
                TempData["Message"] = "Có loại vé không tồn tại hoặc đã ngừng bán.";
                return RedirectToAction("ChiTiet", "Home", new { id = suKienId });
            }

            // Kiểm tra khung giờ mở bán của vé
            if (loaiVe.NgayBatDauBan.HasValue && now < loaiVe.NgayBatDauBan.Value)
            {
                TempData["Message"] = $"Vé '{loaiVe.TenLoaiVe}' chưa đến thời gian mở bán.";
                return RedirectToAction("ChiTiet", "Home", new { id = suKienId });
            }
            if (loaiVe.NgayKetThucBan.HasValue && now > loaiVe.NgayKetThucBan.Value)
            {
                TempData["Message"] = $"Vé '{loaiVe.TenLoaiVe}' đã kết thúc thời gian bán.";
                return RedirectToAction("ChiTiet", "Home", new { id = suKienId });
            }

            // Điều chỉnh số lượng nếu vượt giới hạn mỗi đơn
            if (soLuong > loaiVe.GioiHanMoiDon)
            {
                soLuong = loaiVe.GioiHanMoiDon;
                selectedTickets[loaiVeId] = soLuong;
            }

            // Kiểm tra còn đủ vé không (bao gồm cả giữ chỗ)
            int soVeConLai = loaiVe.SoLuongTong - loaiVe.SoLuongDaBan - loaiVe.SoLuongGiuCho;
            if (soLuong > soVeConLai)
            {
                TempData["Message"] = $"Loại vé '{loaiVe.TenLoaiVe}' không đủ số lượng khả dụng. Còn lại: {soVeConLai} vé.";
                return RedirectToAction("ChiTiet", "Home", new { id = suKienId });
            }

            tongTien += loaiVe.GiaBan * soLuong;
        }

        // Bước 4: Tạo mã đơn hàng
        var donHangId  = Guid.NewGuid();
        var maDonHang  = "DH" + DateTime.Now.ToString("yyMMddHHmmss") + Random.Shared.Next(100, 999);

        // Bước 5: Lưu đơn hàng và chi tiết vào database
        try
        {
            using var connection = Db.TaoKetNoi();
            await connection.OpenAsync();
            using var transaction = connection.BeginTransaction();

            try
            {
                // Tạo đơn hàng chính (TrangThai = 0 = chờ thanh toán)
                string sqlTaoDonHang = @"
                    INSERT INTO DonHang
                        (Id, MaDonHang, NguoiMuaId, SuKienId,
                         HoTenNguoiMua, EmailNguoiMua,
                         TongTienVe, TienGiamGia, TongThanhToan,
                         TrangThai, NgayTao)
                    VALUES
                        (@id, @maDonHang, @nguoiMuaId, @suKienId,
                         @hoTen, @email,
                         @tongTien, 0, @tongTien,
                         0, GETUTCDATE())
                ";
                await connection.ExecuteAsync(sqlTaoDonHang, new
                {
                    id         = donHangId,
                    maDonHang,
                    nguoiMuaId,
                    suKienId,
                    hoTen,
                    email,
                    tongTien
                }, transaction);

                // Tạo chi tiết từng vé (mỗi vé là 1 dòng trong bảng ChiTietDonHang)
                string sqlChiTiet = @"
                    INSERT INTO ChiTietDonHang
                        (DonHangId, LoaiVeId, GiaVe, TenNguoiThamDu, EmailNguoiThamDu, MaVe, MaQRCode)
                    VALUES
                        (@donHangId, @loaiVeId, @giaVe, @ten, @email, @maVe, @maQr)
                ";

                foreach (var item in selectedTickets)
                {
                    int loaiVeId = item.Key;
                    int soLuong = item.Value;

                    decimal giaBan = await connection.ExecuteScalarAsync<decimal>(
                        "SELECT GiaBan FROM LoaiVe WHERE Id = @loaiVeId", new { loaiVeId }, transaction);

                    for (int i = 0; i < soLuong; i++)
                    {
                        string tempMaVe = "T-" + Guid.NewGuid().ToString("N").Substring(0, 10).ToUpper();
                        string tempMaQr = "T-QR-" + Guid.NewGuid().ToString("N").ToUpper();
                        await connection.ExecuteAsync(sqlChiTiet, new
                        {
                            donHangId,
                            loaiVeId,
                            giaVe = giaBan,
                            ten   = hoTen,
                            email,
                            maVe  = tempMaVe,
                            maQr  = tempMaQr
                        }, transaction);
                    }

                    // Tăng số lượng giữ chỗ tạm thời
                    string sqlTangGiuCho = @"
                        UPDATE LoaiVe
                        SET SoLuongGiuCho = SoLuongGiuCho + @soLuong
                        WHERE Id = @loaiVeId
                          AND SoLuongDaBan + SoLuongGiuCho + @soLuong <= SoLuongTong
                    ";
                    int soGiu = await connection.ExecuteAsync(sqlTangGiuCho, new { soLuong, loaiVeId }, transaction);
                    if (soGiu == 0)
                    {
                        throw new Exception("Không thể giữ vé. Vé đã hết hoặc vượt giới hạn số lượng còn lại.");
                    }
                }

                await transaction.CommitAsync();
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        }
        catch (Exception ex)
        {
            TempData["Message"] = "Lỗi đặt vé: " + ex.Message;
            return RedirectToAction("ChiTiet", "Home", new { id = suKienId });
        }

        // Chuyển sang trang thanh toán
        return RedirectToAction("ThanhToan", new { id = donHangId });
    }

    // TRANG THANH TOÁN - Xem đơn hàng + chọn ghế (nếu có)
    // URL: GET /Booking/ThanhToan?id={donHangId}
    public async Task<IActionResult> ThanhToan(Guid id)
    {
        // Tự động giải phóng các đơn hàng quá hạn 15 phút chưa thanh toán
        await GiaiPhongDonHangHetHan();

        var nguoiMuaId = LayIdNguoiDangNhap();

        // Lấy thông tin đơn hàng (chỉ lấy đơn của người đang đăng nhập)
        var donHang = await TimDonHang(id, nguoiMuaId);
        if (donHang == null)
        {
            return NotFound();
        }

        // Lấy danh sách chi tiết vé trong đơn hàng này
        string sqlChiTiet = @"
            SELECT *
            FROM ChiTietDonHang
            WHERE DonHangId = @donHangId
            ORDER BY Id
        ";
        var danhSachChiTiet = await Db.LayDanhSach<ChiTietDonHang>(sqlChiTiet, new { donHangId = id });

        ViewBag.ChiTiet = danhSachChiTiet;

        // Kiểm tra sự kiện có sơ đồ ghế không
        string sqlKiemTraSoDo = @"
            SELECT ISNULL(CoSoDoChoNgoi, 0)
            FROM SuKien
            WHERE Id = @id
        ";
        bool coSoDoGhe = await Db.LayGiaTri<bool>(sqlKiemTraSoDo, new { id = donHang.SuKienId });
        ViewBag.CoSoDo = coSoDoGhe;

        // Nếu có sơ đồ ghế → gửi loaiVeId sang View để tải sơ đồ đúng khu vực
        if (coSoDoGhe && danhSachChiTiet.Count > 0)
        {
            ViewBag.LoaiVeId = danhSachChiTiet[0].LoaiVeId;
        }

        return View(donHang);
    }

    // API LẤY SƠ ĐỒ GHẾ (JSON) - Dùng bởi JavaScript trang thanh toán
    // URL: GET /Booking/LaySoDoGhe?loaiVeId=5
    // Trả về: danh sách ghế dạng JSON
    [HttpGet]
    public async Task<IActionResult> LaySoDoGhe(int loaiVeId)
    {
        // Lấy tất cả ghế thuộc khu vực của loại vé này
        // Kèm theo tên hàng, tên khu vực và màu sắc khu vực
        string sql = @"
            SELECT g.Id,
                   g.SoGhe,
                   g.TrangThai,
                   h.TenHang,
                   h.ThuTu    AS ThuTuHang,
                   k.TenKhuVuc,
                   k.MauSac
            FROM ChoNgoi g
            JOIN HangGhe h ON h.Id = g.HangGheId     -- hàng ghế chứa ghế này
            JOIN KhuVuc  k ON k.Id = h.KhuVucId      -- khu vực chứa hàng ghế này
            WHERE k.LoaiVeId = @loaiVeId              -- chỉ lấy ghế của loại vé được chọn
            ORDER BY h.ThuTu, g.Id
        ";

        var danhSachGhe = await Db.LayDanhSach<dynamic>(sql, new { loaiVeId });
        return Json(danhSachGhe);
    }

    // API LẤY TOÀN BỘ SƠ ĐỒ GHẾ CỦA SỰ KIỆN (JSON)
    // URL: GET /Booking/LaySoDoGheTheoSuKien?suKienId=...
    [HttpGet]
    public async Task<IActionResult> LaySoDoGheTheoSuKien(Guid suKienId)
    {
        string sql = @"
            SELECT g.Id, g.HangGheId, g.SoGhe, g.TrangThai,
                   h.TenHang, h.ThuTu AS ThuTuHang,
                   k.Id AS KhuVucId, k.TenKhuVuc, k.MauSac, k.LoaiVeId,
                   lv.TenLoaiVe, lv.GiaBan
            FROM ChoNgoi g
            JOIN HangGhe h ON g.HangGheId = h.Id
            JOIN KhuVuc  k ON h.KhuVucId  = k.Id
            JOIN SoDoChoNgoi sdn ON k.SoDoChoNgoiId = sdn.Id
            JOIN LoaiVe lv ON k.LoaiVeId = lv.Id
            WHERE sdn.SuKienId = @suKienId
            ORDER BY k.ThuTu, h.ThuTu, g.SoGhe
        ";
        var danhSachGhe = await Db.LayDanhSach<dynamic>(sql, new { suKienId });
        return Json(danhSachGhe);
    }

    // ÁP DỤNG MÃ GIẢM GIÁ (VOUCHER)
    // URL: POST /Booking/ApDungVoucher
    [HttpPost]
    public async Task<IActionResult> ApDungVoucher(Guid id, string maCode)
    {
        var nguoiMuaId = LayIdNguoiDangNhap();

        // Lấy thông tin đơn hàng (cần SuKienId và tổng tiền để kiểm tra voucher)
        string sqlDonHang = @"
            SELECT SuKienId, TongTienVe
            FROM DonHang
            WHERE Id          = @id
              AND NguoiMuaId  = @nguoiMuaId
              AND TrangThai   = 0
        ";
        var donHang = await Db.LayDonLe<dynamic>(sqlDonHang, new { id, nguoiMuaId });

        if (donHang == null)
        {
            return NotFound();
        }

        Guid    suKienId   = donHang.SuKienId;
        decimal tongTienVe = donHang.TongTienVe;

        // Tìm mã giảm giá hợp lệ cho sự kiện này
        // Điều kiện: đúng sự kiện, đúng mã, đang hoạt động,
        //            còn lượt dùng, trong thời hạn, đơn hàng đủ điều kiện tối thiểu
        string sqlVoucher = @"
            SELECT TOP 1 Id, LoaiGiamGia, GiaTri, GiamToiDa
            FROM MaGiamGia
            WHERE SuKienId          = @suKienId
              AND MaCode            = @maCode
              AND TrangThai         = 1
              AND GETUTCDATE() BETWEEN NgayBatDau AND NgayKetThuc
              AND SoLuongDaDung     < SoLuongTong
              AND ISNULL(DonToiThieu, 0) <= @tongTienVe
        ";
        var voucher = await Db.LayDonLe<dynamic>(sqlVoucher, new
        {
            suKienId,
            maCode     = maCode.Trim(),
            tongTienVe
        });

        if (voucher == null)
        {
            TempData["Error"] = "Mã giảm giá không hợp lệ hoặc không đủ điều kiện áp dụng.";
            return RedirectToAction("ThanhToan", new { id });
        }

        // Tính số tiền được giảm
        // LoaiGiamGia: 0 = giảm theo % (ví dụ 10%), 1 = giảm số tiền cố định (ví dụ 50.000đ)
        decimal giaTri    = voucher.GiaTri;
        decimal? giamToiDa = voucher.GiamToiDa;

        decimal tienGiam;
        if ((byte)voucher.LoaiGiamGia == 0)
        {
            // Giảm theo phần trăm
            tienGiam = tongTienVe * giaTri / 100;
        }
        else
        {
            // Giảm cố định
            tienGiam = giaTri;
        }

        // Giới hạn số tiền giảm không vượt quá mức tối đa
        if (giamToiDa.HasValue && tienGiam > giamToiDa.Value)
        {
            tienGiam = giamToiDa.Value;
        }

        // Không giảm nhiều hơn tổng tiền
        if (tienGiam > tongTienVe)
        {
            tienGiam = tongTienVe;
        }

        // Cập nhật đơn hàng với mã giảm giá và tiền đã giảm
        string sqlCapNhat = @"
            UPDATE DonHang
            SET MaGiamGiaId    = @mgId,
                TienGiamGia    = @tienGiam,
                TongThanhToan  = TongTienVe - @tienGiam,
                NgayCapNhat    = GETUTCDATE()
            WHERE Id          = @id
              AND NguoiMuaId  = @nguoiMuaId
              AND TrangThai   = 0
        ";
        await Db.ThucThi(sqlCapNhat, new
        {
            mgId       = (int)voucher.Id,
            tienGiam,
            id,
            nguoiMuaId
        });

        TempData["Message"] = $"Áp dụng mã thành công! Bạn được giảm {tienGiam:N0} VND.";
        return RedirectToAction("ThanhToan", new { id });
    }

    // XÁC NHẬN THANH TOÁN - Hoàn tất đơn hàng, tạo mã vé + QR
    // URL: POST /Booking/XacNhanThanhToan
    // XÁC NHẬN THANH TOÁN - Chuyển hướng sang Cổng VNPAY Sandbox
    // URL: POST /Booking/XacNhanThanhToan
    [HttpPost]
    public async Task<IActionResult> XacNhanThanhToan(Guid id, string? gheChon, string phuongThuc = "vnpay")
    {
        var nguoiMuaId = LayIdNguoiDangNhap();

        try
        {
            using var connection = Db.TaoKetNoi();
            await connection.OpenAsync();
            using var transaction = connection.BeginTransaction();

            decimal tongThanhToan;
            string maDonHang;

            try
            {
                // Bước 1: Kiểm tra đơn hàng hợp lệ và chưa thanh toán
                string sqlKiemTra = @"
                    SELECT COUNT(1)
                    FROM DonHang
                    WHERE Id          = @id
                      AND NguoiMuaId  = @nguoiMuaId
                      AND TrangThai   = 0
                ";
                int soHop = await connection.ExecuteScalarAsync<int>(sqlKiemTra, new { id, nguoiMuaId }, transaction);
                if (soHop == 0)
                {
                    return NotFound();
                }

                // Kiểm tra trạng thái sự kiện (phải ở trạng thái Đang bán = 3)
                string sqlCheckSuKien = @"
                    SELECT TrangThai
                    FROM SuKien
                    WHERE Id = (SELECT SuKienId FROM DonHang WHERE Id = @id)
                ";
                int? statusSuKien = await connection.ExecuteScalarAsync<int?>(sqlCheckSuKien, new { id }, transaction);
                if (statusSuKien == null || statusSuKien != 3)
                {
                    await transaction.RollbackAsync();
                    TempData["Message"] = "Không thể tiếp tục thanh toán vì sự kiện này đã tạm dừng bán vé hoặc bị hủy.";
                    return RedirectToAction("Index", "Home");
                }

                // Bước 2: Kiểm tra sự kiện có sơ đồ ghế không
                string sqlCoSoDo = @"
                    SELECT ISNULL(CoSoDoChoNgoi, 0)
                    FROM SuKien
                    WHERE Id = (SELECT SuKienId FROM DonHang WHERE Id = @id)
                ";
                bool coSoDoGhe = await connection.ExecuteScalarAsync<bool>(sqlCoSoDo, new { id }, transaction);

                // Chuyển danh sách ghế đã chọn từ chuỗi "1,5,12" thành List số [1, 5, 12]
                var danhSachGheChon = new List<int>();
                if (!string.IsNullOrWhiteSpace(gheChon))
                {
                    foreach (string phan in gheChon.Split(',', StringSplitOptions.RemoveEmptyEntries))
                    {
                        if (int.TryParse(phan.Trim(), out int gheId) && gheId > 0)
                        {
                            danhSachGheChon.Add(gheId);
                        }
                    }
                }

                // Bước 3: Tạo mã vé tạm và gán ghế cho từng vé trong đơn hàng
                string sqlLayChiTiet = @"
                    SELECT Id
                    FROM ChiTietDonHang
                    WHERE DonHangId = @id
                    ORDER BY Id
                ";
                var danhSachChiTietId = (await connection.QueryAsync<int>(sqlLayChiTiet, new { id }, transaction)).ToList();

                for (int i = 0; i < danhSachChiTietId.Count; i++)
                {
                    int chiTietId = danhSachChiTietId[i];

                    // Tạo mã vé và mã QR duy nhất
                    string maVe = "VE" + DateTime.Now.ToString("yyMMddHHmmss") + Random.Shared.Next(1000, 9999);
                    string maQr = "QR-" + Guid.NewGuid().ToString("N").ToUpper();

                    // Xác định ghế cho vé này
                    int? choNgoiId = null;

                    if (coSoDoGhe)
                    {
                        string keyGhe = "ghe_" + chiTietId;
                        string? rawGheId = Request.Form[keyGhe];
                        if (!string.IsNullOrEmpty(rawGheId) && int.TryParse(rawGheId, out int selectId) && selectId > 0)
                        {
                            // Khách đã chọn ghế cụ thể cho dòng vé này
                            choNgoiId = selectId;
                        }
                        else
                        {
                            // Chưa chọn → tự động tìm ghế trống phù hợp loại vé
                            int loaiVeIdVe = await connection.ExecuteScalarAsync<int>(
                                "SELECT LoaiVeId FROM ChiTietDonHang WHERE Id = @ctId",
                                new { ctId = chiTietId }, transaction);

                            string sqlTimGhe = @"
                                SELECT TOP 1 g.Id
                                FROM ChoNgoi g
                                JOIN HangGhe h ON g.HangGheId = h.Id
                                JOIN KhuVuc  k ON h.KhuVucId  = k.Id
                                WHERE k.LoaiVeId = @loaiVeId
                                  AND g.TrangThai = 0
                            ";
                            choNgoiId = await connection.QueryFirstOrDefaultAsync<int?>(sqlTimGhe, new { loaiVeId = loaiVeIdVe }, transaction);
                        }

                        // Ràng buộc sơ đồ ghế: Không được phép có vé không có ghế
                        if (!choNgoiId.HasValue)
                        {
                            throw new Exception("Không còn ghế trống khả dụng cho loại vé này trong sơ đồ chỗ ngồi.");
                        }
                    }

                    // Cập nhật mã vé tạm, QR và ghế ngồi vào chi tiết đơn hàng
                    string sqlCapNhatVe = @"
                        UPDATE ChiTietDonHang
                        SET MaVe            = @maVe,
                            MaQRCode        = @maQr,
                            TrangThaiCheckin = 0,
                            ChoNgoiId       = @choNgoiId
                        WHERE Id = @chiTietId
                    ";
                    await connection.ExecuteAsync(sqlCapNhatVe, new { chiTietId, maVe, maQr, choNgoiId }, transaction);

                    // Tạm thời đánh dấu ghế là đã bán (TrangThai = 2) để giữ chỗ trong lúc thanh toán
                    if (choNgoiId.HasValue)
                    {
                        string sqlDanhDauGhe = @"
                            UPDATE ChoNgoi
                            SET TrangThai = 2
                            WHERE Id         = @gheId
                              AND TrangThai IN (0, 1)
                        ";
                        int soGheBiGiu = await connection.ExecuteAsync(sqlDanhDauGhe, new { gheId = choNgoiId.Value }, transaction);
                        if (soGheBiGiu == 0)
                        {
                            throw new Exception("Ghế bạn chọn đã được người khác đặt giữ chỗ hoặc thanh toán. Vui lòng chọn ghế khác.");
                        }
                    }
                }

                // Lấy tổng số tiền thanh toán thực tế của đơn hàng
                string sqlLayTien = "SELECT TongThanhToan, MaDonHang FROM DonHang WHERE Id = @id";
                var rawOrder = await connection.QueryFirstOrDefaultAsync<dynamic>(sqlLayTien, new { id }, transaction);
                if (rawOrder == null)
                {
                    throw new Exception("Đơn hàng không tồn tại hoặc đã bị hủy.");
                }
                tongThanhToan = rawOrder.TongThanhToan;
                maDonHang = rawOrder.MaDonHang;

                await transaction.CommitAsync();
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                TempData["Error"] = "Lỗi thanh toán: " + ex.Message;
                return RedirectToAction("ThanhToan", new { id });
            }

            // Bước 4: Chuyển hướng sang cổng thanh toán tương ứng
            switch (phuongThuc?.ToLower())
            {
                case "momo":
                    return await ChuyenHuongMomo(id, tongThanhToan, maDonHang);
                case "zalopay":
                    return await ChuyenHuongZaloPay(id, tongThanhToan, maDonHang);
                default: // vnpay
                    return ChuyenHuongVnPay(id, tongThanhToan, maDonHang);
            }
        }
        catch (Exception ex)
        {
            TempData["Error"] = "Lỗi kết nối cơ sở dữ liệu: " + ex.Message;
            return RedirectToAction("ThanhToan", new { id });
        }
    }

    // Helper: Chuyển hướng sang VNPAY
    private IActionResult ChuyenHuongVnPay(Guid id, decimal tongThanhToan, string maDonHang)
    {
        string tmnCode = _configuration["VnPay:TmnCode"] ?? "";
        string hashSecret = _configuration["VnPay:HashSecret"] ?? "";
        string vnpayUrl = _configuration["VnPay:Url"] ?? "";
        string returnUrl = Url.Action("VnPayReturn", "Booking", null, Request.Scheme) ?? "";

        var vnpay = new VnPayLibrary();
        vnpay.AddRequestData("vnp_Version", "2.1.0");
        vnpay.AddRequestData("vnp_Command", "pay");
        vnpay.AddRequestData("vnp_TmnCode", tmnCode);
        vnpay.AddRequestData("vnp_Amount", ((long)(tongThanhToan * 100)).ToString());
        vnpay.AddRequestData("vnp_CreateDate", DateTime.Now.ToString("yyyyMMddHHmmss"));
        vnpay.AddRequestData("vnp_CurrCode", "VND");
        string ipAddr = HttpContext.Connection.RemoteIpAddress?.ToString() ?? "127.0.0.1";
        if (ipAddr == "::1" || string.IsNullOrEmpty(ipAddr)) ipAddr = "127.0.0.1";
        vnpay.AddRequestData("vnp_IpAddr", ipAddr);
        vnpay.AddRequestData("vnp_Locale", "vn");
        vnpay.AddRequestData("vnp_OrderInfo", "Thanh toan don hang " + maDonHang);
        vnpay.AddRequestData("vnp_OrderType", "other");
        vnpay.AddRequestData("vnp_ReturnUrl", returnUrl);
        vnpay.AddRequestData("vnp_TxnRef", id.ToString());

        string paymentUrl = vnpay.CreateRequestUrl(vnpayUrl, hashSecret);
        return Redirect(paymentUrl);
    }

    // Helper: Chuyển hướng sang MoMo Sandbox
    private async Task<IActionResult> ChuyenHuongMomo(Guid id, decimal tongThanhToan, string maDonHang)
    {
        string partnerCode = _configuration["MoMo:PartnerCode"] ?? "";
        string accessKey = _configuration["MoMo:AccessKey"] ?? "";
        string secretKey = _configuration["MoMo:SecretKey"] ?? "";
        string endpoint = _configuration["MoMo:Endpoint"] ?? "";
        string returnUrl = _configuration["MoMo:ReturnUrl"] ?? Url.Action("MomoReturn", "Booking", null, Request.Scheme) ?? "";
        string notifyUrl = _configuration["MoMo:NotifyUrl"] ?? Url.Action("MomoNotify", "Booking", null, Request.Scheme) ?? "";

        string orderId = id.ToString();
        string requestId = Guid.NewGuid().ToString();
        string amount = ((long)tongThanhToan).ToString();
        string orderInfo = "Thanh toan don hang WuangEvents " + maDonHang;
        string extraData = "";
        string requestType = "payWithATM";

        // Tạo chữ ký HMAC-SHA256
        string rawHash = $"accessKey={accessKey}&amount={amount}&extraData={extraData}&ipnUrl={notifyUrl}&orderId={orderId}&orderInfo={orderInfo}&partnerCode={partnerCode}&redirectUrl={returnUrl}&requestId={requestId}&requestType={requestType}";
        string signature;
        using (var hmac = new System.Security.Cryptography.HMACSHA256(System.Text.Encoding.UTF8.GetBytes(secretKey)))
        {
            byte[] hashBytes = hmac.ComputeHash(System.Text.Encoding.UTF8.GetBytes(rawHash));
            signature = BitConverter.ToString(hashBytes).Replace("-", "").ToLower();
        }

        var requestBody = new
        {
            partnerCode,
            accessKey,
            requestId,
            amount,
            orderId,
            orderInfo,
            redirectUrl = returnUrl,
            ipnUrl = notifyUrl,
            extraData,
            requestType,
            signature,
            lang = "vi"
        };

        using var httpClient = new System.Net.Http.HttpClient();
        var json = System.Text.Json.JsonSerializer.Serialize(requestBody);
        var content = new System.Net.Http.StringContent(json, System.Text.Encoding.UTF8, "application/json");

        try
        {
            var response = await httpClient.PostAsync(endpoint, content);
            var responseText = await response.Content.ReadAsStringAsync();
            var responseJson = System.Text.Json.JsonDocument.Parse(responseText).RootElement;

            if (responseJson.TryGetProperty("payUrl", out var payUrlProp))
            {
                string payUrl = payUrlProp.GetString() ?? "";
                if (!string.IsNullOrEmpty(payUrl))
                    return Redirect(payUrl);
            }

            TempData["Error"] = "Không thể kết nối đến cổng MoMo. Vui lòng chọn phương thức thanh toán khác.";
            return RedirectToAction("ThanhToan", new { id });
        }
        catch
        {
            TempData["Error"] = "Lỗi kết nối đến MoMo Sandbox. Vui lòng thử lại.";
            return RedirectToAction("ThanhToan", new { id });
        }
    }

    // Helper: Chuyển hướng sang ZaloPay Sandbox
    private async Task<IActionResult> ChuyenHuongZaloPay(Guid id, decimal tongThanhToan, string maDonHang)
    {
        string appId = _configuration["ZaloPay:AppId"] ?? "2553";
        string key1 = _configuration["ZaloPay:Key1"] ?? "9phu4565jdg832465fdbo394";
        string endpoint = _configuration["ZaloPay:Endpoint"] ?? "https://sb-openapi.zalopay.vn/v2/create";
        string returnUrl = _configuration["ZaloPay:ReturnUrl"] ?? Url.Action("ZaloPayReturn", "Booking", null, Request.Scheme) ?? "";

        // app_trans_id must be in the format: yyMMdd_xxxxx
        // Sử dụng múi giờ Việt Nam (UTC+7) để lấy ngày chính xác và thêm hậu tố ngẫu nhiên để tránh trùng lặp khi bấm thanh toán lại
        string appTransId = DateTime.UtcNow.AddHours(7).ToString("yyMMdd") + "_" + maDonHang + "_" + Random.Shared.Next(1000, 9999);
        string appUser = "WuangEventsClient";
        long appTime = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
        long amount = (long)tongThanhToan;
        string description = $"Thanh toan don hang WuangEvents #{maDonHang}";
        
        var embedDataObj = new { redirecturl = returnUrl };
        string embedData = System.Text.Json.JsonSerializer.Serialize(embedDataObj);
        string item = "[]";

        // Signature: app_id + "|" + app_trans_id + "|" + app_user + "|" + amount + "|" + app_time + "|" + embed_data + "|" + item
        string rawHash = $"{appId}|{appTransId}|{appUser}|{amount}|{appTime}|{embedData}|{item}";
        string mac = TinhHmacSha256(rawHash, key1);

        using var httpClient = new System.Net.Http.HttpClient();
        var values = new Dictionary<string, string>
        {
            { "app_id", appId },
            { "app_user", appUser },
            { "app_trans_id", appTransId },
            { "app_time", appTime.ToString() },
            { "amount", amount.ToString() },
            { "item", item },
            { "embed_data", embedData },
            { "description", description },
            { "bank_code", "" },
            { "mac", mac }
        };

        try
        {
            var content = new System.Net.Http.FormUrlEncodedContent(values);
            var response = await httpClient.PostAsync(endpoint, content);
            string responseString = await response.Content.ReadAsStringAsync();
            var result = System.Text.Json.JsonDocument.Parse(responseString).RootElement;

            if (result.TryGetProperty("return_code", out var codeProp) && codeProp.GetInt32() == 1)
            {
                if (result.TryGetProperty("order_url", out var urlProp))
                {
                    string orderUrl = urlProp.GetString() ?? "";
                    if (!string.IsNullOrEmpty(orderUrl))
                    {
                        return Redirect(orderUrl);
                    }
                }
            }

            string subMsg = result.TryGetProperty("return_message", out var msgProp) ? msgProp.GetString() ?? "" : "";
            TempData["Error"] = "Không thể tạo giao dịch ZaloPay: " + subMsg;
            return RedirectToAction("ThanhToan", new { id });
        }
        catch (Exception ex)
        {
            TempData["Error"] = "Lỗi kết nối cổng thanh toán ZaloPay: " + ex.Message;
            return RedirectToAction("ThanhToan", new { id });
        }
    }

    // Helper: Tính HMAC-SHA256
    private string TinhHmacSha256(string message, string key)
    {
        var encoding = new System.Text.UTF8Encoding();
        byte[] keyByte = encoding.GetBytes(key);
        byte[] messageBytes = encoding.GetBytes(message);
        using var hmacsha256 = new System.Security.Cryptography.HMACSHA256(keyByte);
        byte[] hashmessage = hmacsha256.ComputeHash(messageBytes);
        return Convert.ToHexString(hashmessage).ToLower();
    }

    // TRANG THANH TOÁN THÀNH CÔNG
    // URL: GET /Booking/ThanhCong?id={donHangId}
    // VNPAY CALLBACK - Nhận kết quả từ VNPAY và xử lý đơn hàng
    // URL: GET /Booking/VnPayReturn
    [HttpGet]
    [AllowAnonymous] // Cho phép gọi không cần token authorize (VNPAY redirect về)
    public async Task<IActionResult> VnPayReturn()
    {
        string hashSecret = _configuration["VnPay:HashSecret"] ?? "";
        var vnpay = new VnPayLibrary();

        // Nạp toàn bộ dữ liệu Query String nhận được từ VNPAY
        foreach (var key in Request.Query.Keys)
        {
            if (!string.IsNullOrEmpty(key) && key.StartsWith("vnp_"))
            {
                vnpay.AddResponseData(key, Request.Query[key].ToString());
            }
        }

        // Lấy thông số phản hồi chính
        string donHangIdText   = vnpay.GetResponseData("vnp_TxnRef");
        string vnp_ResponseCode = vnpay.GetResponseData("vnp_ResponseCode");
        string vnp_TransactionNo= vnpay.GetResponseData("vnp_TransactionNo");
        string secureHash      = Request.Query["vnp_SecureHash"].ToString();

        if (string.IsNullOrEmpty(donHangIdText) || !Guid.TryParse(donHangIdText, out Guid id))
        {
            TempData["Error"] = "Mã giao dịch không hợp lệ.";
            return RedirectToAction("Index", "Home");
        }

        // Kiểm tra chữ ký bảo mật từ VNPAY để phòng chống giả mạo
        bool checkSignature = vnpay.ValidateSignature(secureHash, hashSecret);
        if (!checkSignature)
        {
            TempData["Error"] = "Chữ ký thanh toán không hợp lệ (Checksum failed).";
            return RedirectToAction("Index", "Home");
        }

        using var connection = Db.TaoKetNoi();
        await connection.OpenAsync();

        // Kiểm tra trạng thái đơn hàng hiện tại trong DB
        var currentOrder = await connection.QueryFirstOrDefaultAsync<dynamic>(
            "SELECT TrangThai, TongThanhToan FROM DonHang WHERE Id = @id", new { id });
        if (currentOrder == null)
        {
            return NotFound();
        }

        // Nếu đơn hàng đã xử lý rồi (ví dụ IPN đã chạy trước) thì chỉ cần redirect sang trang thành công
        if (currentOrder.TrangThai == 1)
        {
            return RedirectToAction("ThanhCong", new { id });
        }

        using var transaction = connection.BeginTransaction();
        try
        {
            if (vnp_ResponseCode == "00")
            {
                // THANH TOÁN THÀNH CÔNG:

                // 1. Trừ số lượng vé đã bán cho từng loại vé (Giảm SoLuongGiuCho và tăng SoLuongDaBan)
                string sqlThongKeVe = @"
                    SELECT LoaiVeId, COUNT(*) AS SoLuong
                    FROM ChiTietDonHang
                    WHERE DonHangId = @id
                    GROUP BY LoaiVeId
                ";
                var danhSachLoaiVe = await connection.QueryAsync<dynamic>(sqlThongKeVe, new { id }, transaction);

                foreach (var item in danhSachLoaiVe)
                {
                    int loaiVeId = item.LoaiVeId;
                    int soLuong  = item.SoLuong;

                    string sqlTruVe = @"
                        UPDATE LoaiVe
                        SET SoLuongGiuCho = CASE WHEN SoLuongGiuCho >= @soLuong THEN SoLuongGiuCho - @soLuong ELSE 0 END,
                            SoLuongDaBan  = SoLuongDaBan + @soLuong
                        WHERE Id = @loaiVeId
                    ";
                    await connection.ExecuteAsync(sqlTruVe, new { soLuong, loaiVeId }, transaction);
                }

                // 2. Tăng số lượt dùng voucher (nếu có)
                string sqlLayVoucher = "SELECT MaGiamGiaId FROM DonHang WHERE Id = @id";
                var dbOrder = await connection.QueryFirstOrDefaultAsync<dynamic>(sqlLayVoucher, new { id }, transaction);
                int? maGiamGiaId = dbOrder?.MaGiamGiaId;

                if (maGiamGiaId.HasValue)
                {
                    string sqlTangVoucher = @"
                        UPDATE MaGiamGia
                        SET SoLuongDaDung = SoLuongDaDung + 1
                        WHERE Id            = @maId
                          AND SoLuongDaDung < SoLuongTong
                    ";
                    await connection.ExecuteAsync(sqlTangVoucher, new { maId = maGiamGiaId.Value }, transaction);
                }

                // 3. Đánh dấu đơn hàng Đã thanh toán thành công
                string sqlCapNhatDonHang = @"
                    UPDATE DonHang
                    SET TrangThai           = 1,
                        MaGiaoDich          = @vnp_TransactionNo,
                        PhuongThucThanhToan = 2, -- 2: Cổng thanh toán VNPAY
                        NgayThanhToan       = GETUTCDATE(),
                        NgayCapNhat         = GETUTCDATE()
                    WHERE Id = @id
                ";
                await connection.ExecuteAsync(sqlCapNhatDonHang, new { id, vnp_TransactionNo }, transaction);

                await transaction.CommitAsync();
                TempData["Message"] = "Thanh toán qua cổng VNPAY thành công!";
                return RedirectToAction("ThanhCong", new { id });
            }
            else
            {
                // THANH TOÁN THẤT BẠI HOẶC BỊ HỦY:
                // Trả các ghế đã chọn về trạng thái trống (TrangThai = 0)
                string sqlLayGheDaGiu = "SELECT ChoNgoiId FROM ChiTietDonHang WHERE DonHangId = @id AND ChoNgoiId IS NOT NULL";
                var danhSachGheId = (await connection.QueryAsync<int>(sqlLayGheDaGiu, new { id }, transaction)).ToList();

                if (danhSachGheId.Count > 0)
                {
                    string sqlReleaseSeats = @"
                        UPDATE ChoNgoi
                        SET TrangThai = 0
                        WHERE Id IN @danhSachGheId
                    ";
                    await connection.ExecuteAsync(sqlReleaseSeats, new { danhSachGheId }, transaction);
                }

                // Xóa mã vé tạm và ghế gán trong chi tiết đơn hàng để khách hàng có thể chọn lại
                string sqlClearChiTiet = @"
                    UPDATE ChiTietDonHang
                    SET MaVe = NULL,
                        MaQRCode = NULL,
                        ChoNgoiId = NULL
                    WHERE DonHangId = @id
                ";
                await connection.ExecuteAsync(sqlClearChiTiet, new { id }, transaction);

                await transaction.CommitAsync();

                TempData["Error"] = $"Giao dịch không thành công hoặc bị hủy (Mã lỗi: {vnp_ResponseCode}). Vui lòng thử lại.";
                return RedirectToAction("ThanhToan", new { id });
            }
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            TempData["Error"] = "Lỗi xử lý thanh toán: " + ex.Message;
            return RedirectToAction("ThanhToan", new { id });
        }
    }

    // VNPAY IPN CALLBACK - Cổng gọi ngầm Server-to-Server
    // URL: GET /Booking/VnPayIpn
    [HttpGet]
    [AllowAnonymous]
    public async Task<IActionResult> VnPayIpn()
    {
        string hashSecret = _configuration["VnPay:HashSecret"] ?? "";
        var vnpay = new VnPayLibrary();

        foreach (var key in Request.Query.Keys)
        {
            if (!string.IsNullOrEmpty(key) && key.StartsWith("vnp_"))
            {
                vnpay.AddResponseData(key, Request.Query[key].ToString());
            }
        }

        string donHangIdText   = vnpay.GetResponseData("vnp_TxnRef");
        string vnp_ResponseCode = vnpay.GetResponseData("vnp_ResponseCode");
        string vnp_TransactionNo= vnpay.GetResponseData("vnp_TransactionNo");
        string secureHash      = Request.Query["vnp_SecureHash"].ToString();

        if (string.IsNullOrEmpty(donHangIdText) || !Guid.TryParse(donHangIdText, out Guid id))
        {
            return Json(new { RspCode = "01", Message = "Order not found" });
        }

        bool checkSignature = vnpay.ValidateSignature(secureHash, hashSecret);
        if (!checkSignature)
        {
            return Json(new { RspCode = "97", Message = "Invalid signature" });
        }

        using var connection = Db.TaoKetNoi();
        await connection.OpenAsync();

        var currentOrder = await connection.QueryFirstOrDefaultAsync<dynamic>(
            "SELECT TrangThai FROM DonHang WHERE Id = @id", new { id });
        
        if (currentOrder == null)
        {
            return Json(new { RspCode = "01", Message = "Order not found" });
        }

        if (currentOrder.TrangThai == 1)
        {
            return Json(new { RspCode = "02", Message = "Order already confirmed" });
        }

        using var transaction = connection.BeginTransaction();
        try
        {
            if (vnp_ResponseCode == "00")
            {
                // Trừ số lượng vé đã bán (Giảm SoLuongGiuCho và tăng SoLuongDaBan)
                string sqlThongKeVe = @"
                    SELECT LoaiVeId, COUNT(*) AS SoLuong
                    FROM ChiTietDonHang
                    WHERE DonHangId = @id
                    GROUP BY LoaiVeId
                ";
                var danhSachLoaiVe = await connection.QueryAsync<dynamic>(sqlThongKeVe, new { id }, transaction);

                foreach (var item in danhSachLoaiVe)
                {
                    int loaiVeId = item.LoaiVeId;
                    int soLuong  = item.SoLuong;

                    string sqlTruVe = @"
                        UPDATE LoaiVe
                        SET SoLuongGiuCho = CASE WHEN SoLuongGiuCho >= @soLuong THEN SoLuongGiuCho - @soLuong ELSE 0 END,
                            SoLuongDaBan  = SoLuongDaBan + @soLuong
                        WHERE Id = @loaiVeId
                    ";
                    await connection.ExecuteAsync(sqlTruVe, new { soLuong, loaiVeId }, transaction);
                }

                // Voucher
                string sqlLayVoucher = "SELECT MaGiamGiaId FROM DonHang WHERE Id = @id";
                var dbOrder = await connection.QueryFirstOrDefaultAsync<dynamic>(sqlLayVoucher, new { id }, transaction);
                int? maGiamGiaId = dbOrder?.MaGiamGiaId;

                if (maGiamGiaId.HasValue)
                {
                    string sqlTangVoucher = @"
                        UPDATE MaGiamGia
                        SET SoLuongDaDung = SoLuongDaDung + 1
                        WHERE Id            = @maId
                          AND SoLuongDaDung < SoLuongTong
                    ";
                    await connection.ExecuteAsync(sqlTangVoucher, new { maId = maGiamGiaId.Value }, transaction);
                }

                // Xác nhận thanh toán thành công
                string sqlCapNhatDonHang = @"
                    UPDATE DonHang
                    SET TrangThai           = 1,
                        MaGiaoDich          = @vnp_TransactionNo,
                        PhuongThucThanhToan = 2,
                        NgayThanhToan       = GETUTCDATE(),
                        NgayCapNhat         = GETUTCDATE()
                    WHERE Id = @id
                ";
                await connection.ExecuteAsync(sqlCapNhatDonHang, new { id, vnp_TransactionNo }, transaction);

                await transaction.CommitAsync();
                return Json(new { RspCode = "00", Message = "Confirm Success" });
            }
            else
            {
                // Thanh toán thất bại -> Giải phóng ghế
                string sqlLayGheDaGiu = "SELECT ChoNgoiId FROM ChiTietDonHang WHERE DonHangId = @id AND ChoNgoiId IS NOT NULL";
                var danhSachGheId = (await connection.QueryAsync<int>(sqlLayGheDaGiu, new { id }, transaction)).ToList();

                if (danhSachGheId.Count > 0)
                {
                    string sqlReleaseSeats = @"
                        UPDATE ChoNgoi
                        SET TrangThai = 0
                        WHERE Id IN @danhSachGheId
                    ";
                    await connection.ExecuteAsync(sqlReleaseSeats, new { danhSachGheId }, transaction);
                }

                string sqlClearChiTiet = @"
                    UPDATE ChiTietDonHang
                    SET MaVe = NULL,
                        MaQRCode = NULL,
                        ChoNgoiId = NULL
                    WHERE DonHangId = @id
                ";
                await connection.ExecuteAsync(sqlClearChiTiet, new { id }, transaction);

                // Giảm giữ chỗ vé về trạng thái cũ
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
                return Json(new { RspCode = "00", Message = "Confirm Success (Failed payment processed)" });
            }
        }
        catch
        {
            await transaction.RollbackAsync();
            return Json(new { RspCode = "99", Message = "Update failure" });
        }
    }

    // TRANG THANH TOÁN THÀNH CÔNG
    // URL: GET /Booking/ThanhCong?id={donHangId}
    public async Task<IActionResult> ThanhCong(Guid id)
    {
        var donHang = await TimDonHang(id, LayIdNguoiDangNhap());
        if (donHang == null || donHang.TrangThai != 1)
        {
            return NotFound();
        }

        // Lấy thông tin sự kiện đầy đủ
        string sqlSuKien = "SELECT * FROM SuKien WHERE Id = @id";
        ViewBag.SuKien = await Db.LayDonLe<SuKien>(sqlSuKien, new { id = donHang.SuKienId });

        // Tự động gửi Email vé điện tử đính kèm QR Code cho khách hàng
        _ = GuiEmailVeDienTuChoDonHang(id);

        return View(donHang);
    }

    private async Task GuiEmailVeDienTuChoDonHang(Guid donHangId)
    {
        try
        {
            using var connection = Db.TaoKetNoi();
            var donHang = await connection.QueryFirstOrDefaultAsync<dynamic>(@"
                SELECT d.MaDonHang, d.HoTenNguoiMua, d.EmailNguoiMua, d.TongThanhToan,
                       s.TenSuKien, s.NgayBatDau, s.TenDiaDiem
                FROM DonHang d
                JOIN SuKien s ON s.Id = d.SuKienId
                WHERE d.Id = @id", new { id = donHangId });

            if (donHang != null)
            {
                var listVe = (await connection.QueryAsync<dynamic>(@"
                    SELECT c.MaVe, c.MaQRCode, l.TenLoaiVe, g.SoGhe
                    FROM ChiTietDonHang c
                    JOIN LoaiVe l ON l.Id = c.LoaiVeId
                    LEFT JOIN ChoNgoi g ON g.Id = c.ChoNgoiId
                    WHERE c.DonHangId = @id", new { id = donHangId })).ToList();

                string ngayBd = ((DateTime)donHang.NgayBatDau).ToString("dd/MM/yyyy HH:mm");
                await _emailService.GuiEmailVeDienTuAsync(
                    (string)donHang.EmailNguoiMua,
                    (string)donHang.HoTenNguoiMua,
                    (string)donHang.MaDonHang,
                    (string)donHang.TenSuKien,
                    ngayBd,
                    (string)(donHang.TenDiaDiem ?? "Chưa cập nhật"),
                    (decimal)donHang.TongThanhToan,
                    listVe
                );
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[EMAIL TRIGGER ERROR] {ex.Message}");
        }
    }


    // MOMO CALLBACK - Người dùng quay về sau khi thanh toán MoMo
    // URL: GET /Booking/MomoReturn
    [HttpGet]
    [AllowAnonymous]
    public async Task<IActionResult> MomoReturn(
        string? partnerCode, string? orderId, string? requestId,
        string? amount, string? orderInfo, string? orderType,
        string? transId, int? resultCode, string? message,
        string? payType, string? responseTime, string? extraData, string? signature)
    {
        if (string.IsNullOrEmpty(orderId) || !Guid.TryParse(orderId, out Guid id))
        {
            TempData["Error"] = "Mã giao dịch MoMo không hợp lệ.";
            return RedirectToAction("Index", "Home");
        }

        if (resultCode != 0)
        {
            // Thanh toán thất bại hoặc bị hủy
            TempData["Error"] = $"Thanh toán MoMo không thành công: {message} (Mã lỗi: {resultCode}).";
            return RedirectToAction("ThanhToan", new { id });
        }

        using var connection = Db.TaoKetNoi();
        await connection.OpenAsync();

        var currentOrder = await connection.QueryFirstOrDefaultAsync<dynamic>(
            "SELECT TrangThai, TongThanhToan FROM DonHang WHERE Id = @id", new { id });
        if (currentOrder == null) return NotFound();
        if (currentOrder.TrangThai == 1)
            return RedirectToAction("ThanhCong", new { id });

        using var transaction = connection.BeginTransaction();
        try
        {
            // Trừ số lượng vé đã bán
            string sqlThongKeVe = "SELECT LoaiVeId, COUNT(*) AS SoLuong FROM ChiTietDonHang WHERE DonHangId = @id GROUP BY LoaiVeId";
            var danhSachLoaiVe = await connection.QueryAsync<dynamic>(sqlThongKeVe, new { id }, transaction);
            foreach (var item in danhSachLoaiVe)
            {
                int loaiVeId = item.LoaiVeId;
                int soLuong = item.SoLuong;
                await connection.ExecuteAsync(@"UPDATE LoaiVe SET SoLuongGiuCho = CASE WHEN SoLuongGiuCho >= @soLuong THEN SoLuongGiuCho - @soLuong ELSE 0 END, SoLuongDaBan = SoLuongDaBan + @soLuong WHERE Id = @loaiVeId",
                    new { soLuong, loaiVeId }, transaction);
            }

            // Cập nhật voucher
            var dbOrder = await connection.QueryFirstOrDefaultAsync<dynamic>("SELECT MaGiamGiaId FROM DonHang WHERE Id = @id", new { id }, transaction);
            int? maGiamGiaId = dbOrder?.MaGiamGiaId;
            if (maGiamGiaId.HasValue)
                await connection.ExecuteAsync("UPDATE MaGiamGia SET SoLuongDaDung = SoLuongDaDung + 1 WHERE Id = @maId AND SoLuongDaDung < SoLuongTong", new { maId = maGiamGiaId.Value }, transaction);

            // Xác nhận thanh toán
            await connection.ExecuteAsync(@"UPDATE DonHang SET TrangThai = 1, MaGiaoDich = @transId, PhuongThucThanhToan = 3, NgayThanhToan = GETUTCDATE(), NgayCapNhat = GETUTCDATE() WHERE Id = @id",
                new { id, transId = transId ?? "" }, transaction);

            await transaction.CommitAsync();
            TempData["Message"] = "Thanh toán qua MoMo thành công! 🎉";
            return RedirectToAction("ThanhCong", new { id });
        }
        catch
        {
            await transaction.RollbackAsync();
            TempData["Error"] = "Lỗi xử lý callback MoMo.";
            return RedirectToAction("ThanhToan", new { id });
        }
    }

    // MOMO IPN - Server-to-server callback từ MoMo
    // URL: POST /Booking/MomoNotify
    [HttpPost]
    [AllowAnonymous]
    public IActionResult MomoNotify()
    {
        // Ghi nhận IPN từ MoMo server (hệ thống đã xử lý tại MomoReturn)
        return Ok();
    }

    // ZALOPAY RETURN - Người dùng quay về sau khi thanh toán ZaloPay
    // URL: GET /Booking/ZaloPayReturn
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
        // Kiểm tra apptransid để lấy mã đơn hàng maDonHang
        // Format apptransid: yyMMdd_maDonHang
        if (string.IsNullOrEmpty(apptransid) || !apptransid.Contains("_"))
        {
            TempData["Error"] = "Mã giao dịch ZaloPay không hợp lệ.";
            return RedirectToAction("Index", "Home");
        }

        string maDonHang = apptransid.Split('_')[1];
        
        using var connection = Db.TaoKetNoi();
        await connection.OpenAsync();

        // Tìm đơn hàng theo mã đơn hàng
        var donHang = await connection.QueryFirstOrDefaultAsync<dynamic>(
            "SELECT Id, TrangThai, MaGiamGiaId FROM DonHang WHERE MaDonHang = @maDonHang", 
            new { maDonHang });

        if (donHang == null)
        {
            TempData["Error"] = "Đơn hàng không tồn tại.";
            return RedirectToAction("Index", "Home");
        }

        Guid id = donHang.Id;

        // Nếu đơn hàng đã được cập nhật thành công rồi thì đi thẳng tới trang thành công
        if (donHang.TrangThai == 1)
        {
            return RedirectToAction("ThanhCong", new { id });
        }

        // Kiểm tra trạng thái thanh toán từ ZaloPay callback (status == 1: Thành công)
        if (status != "1")
        {
            TempData["Error"] = $"Thanh toán ZaloPay không thành công hoặc bị hủy. (Status: {status})";
            return RedirectToAction("ThanhToan", new { id });
        }

        // Xác thực checksum từ ZaloPay
        string key2 = _configuration["ZaloPay:Key2"] ?? "Iyz27u486456jdgjhsslo3i5";
        string rawChecksum = $"{appid}|{apptransid}|{pmcid}|{bankcode}|{amount}|{discountamount}|{status}";
        string expectedChecksum = TinhHmacSha256(rawChecksum, key2);

        if (checksum != expectedChecksum)
        {
            TempData["Error"] = "Xác thực chữ ký ZaloPay thất bại. Giao dịch không an toàn.";
            return RedirectToAction("ThanhToan", new { id });
        }

        // Tiến hành cập nhật trạng thái thanh toán thành công
        using var transaction = connection.BeginTransaction();
        try
        {
            // Trừ số lượng giữ chỗ và cộng số lượng đã bán của các loại vé trong đơn hàng
            string sqlThongKeVe = "SELECT LoaiVeId, COUNT(*) AS SoLuong FROM ChiTietDonHang WHERE DonHangId = @id GROUP BY LoaiVeId";
            var danhSachLoaiVe = await connection.QueryAsync<dynamic>(sqlThongKeVe, new { id }, transaction);
            foreach (var item in danhSachLoaiVe)
            {
                int loaiVeId = item.LoaiVeId;
                int soLuong = item.SoLuong;
                await connection.ExecuteAsync(@"
                    UPDATE LoaiVe 
                    SET SoLuongGiuCho = CASE WHEN SoLuongGiuCho >= @soLuong THEN SoLuongGiuCho - @soLuong ELSE 0 END, 
                        SoLuongDaBan = SoLuongDaBan + @soLuong 
                    WHERE Id = @loaiVeId",
                    new { soLuong, loaiVeId }, transaction);
            }

            // Cộng số lượng đã dùng của mã giảm giá
            int? maGiamGiaId = (int?)donHang.MaGiamGiaId;
            if (maGiamGiaId.HasValue)
            {
                await connection.ExecuteAsync(@"
                    UPDATE MaGiamGia 
                    SET SoLuongDaDung = SoLuongDaDung + 1 
                    WHERE Id = @maId AND SoLuongDaDung < SoLuongTong", 
                    new { maId = maGiamGiaId.Value }, transaction);
            }

            // Ghi nhận trạng thái thanh toán thành công (TrangThai = 1) và phương thức là 4 (ZaloPay)
            await connection.ExecuteAsync(@"
                UPDATE DonHang 
                SET TrangThai = 1, 
                    MaGiaoDich = @transId, 
                    PhuongThucThanhToan = 4, 
                    NgayThanhToan = GETUTCDATE(), 
                    NgayCapNhat = GETUTCDATE() 
                WHERE Id = @id",
                new { id, transId = apptransid }, transaction);

            await transaction.CommitAsync();
            TempData["Message"] = "Thanh toán qua ZaloPay thành công! 🎉";
            return RedirectToAction("ThanhCong", new { id });
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            TempData["Error"] = "Lỗi xử lý callback ZaloPay: " + ex.Message;
            return RedirectToAction("ThanhToan", new { id });
        }
    }

    // ĐƠN HÀNG CỦA TÔI - Danh sách tất cả đơn đã đặt
    // URL: GET /Booking/DonHangCuaToi
    public async Task<IActionResult> DonHangCuaToi()
    {
        await GiaiPhongDonHangHetHan();
        var nguoiMuaId = LayIdNguoiDangNhap();

        string sql = @"
            SELECT dh.*,
                   sk.TenSuKien,
                   sk.AnhBia,
                   sk.NgayBatDau   AS NgayToChucSuKien,
                   sk.TenDiaDiem  AS DiaDiemSuKien
            FROM DonHang dh
            LEFT JOIN SuKien sk ON sk.Id = dh.SuKienId
            WHERE dh.NguoiMuaId = @nguoiMuaId
            ORDER BY dh.NgayTao DESC
        ";
        var danhSachDonHang = await Db.LayDanhSach<dynamic>(sql, new { nguoiMuaId });

        return View(danhSachDonHang);
    }

    // HỦY ĐẶT VÉ - Giải phóng ghế và số lượng vé giữ chỗ
    // URL: POST /Booking/HuyDonHang
    [HttpPost]
    public async Task<IActionResult> HuyDonHang(Guid id)
    {
        var nguoiMuaId = LayIdNguoiDangNhap();

        using var connection = Db.TaoKetNoi();
        await connection.OpenAsync();
        using var transaction = connection.BeginTransaction();
        try
        {
            // 1. Kiểm tra đơn hàng có đúng của người dùng và đang ở trạng thái chờ thanh toán (TrangThai = 0)
            var donHang = await connection.QueryFirstOrDefaultAsync<dynamic>(
                "SELECT Id, SuKienId FROM DonHang WHERE Id = @id AND NguoiMuaId = @nguoiMuaId AND TrangThai = 0",
                new { id, nguoiMuaId }, transaction);

            if (donHang == null)
            {
                await transaction.RollbackAsync();
                TempData["Error"] = "Đơn hàng không hợp lệ hoặc đã được thanh toán.";
                return RedirectToAction("DonHangCuaToi");
            }

            // 2. Lấy danh sách ghế đã giam của đơn hàng này
            string sqlLayGhe = "SELECT ChoNgoiId FROM ChiTietDonHang WHERE DonHangId = @id AND ChoNgoiId IS NOT NULL";
            var gheIds = (await connection.QueryAsync<int>(sqlLayGhe, new { id }, transaction)).ToList();
            if (gheIds.Count > 0)
            {
                // Trả trạng thái ghế về trống (TrangThai = 0)
                await connection.ExecuteAsync("UPDATE ChoNgoi SET TrangThai = 0 WHERE Id IN @gheIds", new { gheIds }, transaction);
            }

            // 3. Trả số lượng giữ chỗ của từng loại vé về ban đầu
            string sqlThongKe = "SELECT LoaiVeId, COUNT(*) AS SoLuong FROM ChiTietDonHang WHERE DonHangId = @id GROUP BY LoaiVeId";
            var veList = await connection.QueryAsync<dynamic>(sqlThongKe, new { id }, transaction);
            foreach (var item in veList)
            {
                int lvId = item.LoaiVeId;
                int qty = item.SoLuong;
                await connection.ExecuteAsync(@"
                    UPDATE LoaiVe 
                    SET SoLuongGiuCho = CASE WHEN SoLuongGiuCho >= @qty THEN SoLuongGiuCho - @qty ELSE 0 END 
                    WHERE Id = @lvId", new { qty, lvId }, transaction);
            }

            // 4. Xóa thông tin chi tiết vé tạm
            await connection.ExecuteAsync(@"
                UPDATE ChiTietDonHang 
                SET MaVe = NULL, MaQRCode = NULL, ChoNgoiId = NULL 
                WHERE DonHangId = @id", new { id }, transaction);

            // 5. Đổi trạng thái đơn hàng thành Hủy (TrangThai = 2)
            await connection.ExecuteAsync(@"
                UPDATE DonHang 
                SET TrangThai = 2, NgayCapNhat = GETUTCDATE() 
                WHERE Id = @id", new { id }, transaction);

            await transaction.CommitAsync();
            TempData["Message"] = "Đã hủy đơn hàng và giải phóng vé giữ chỗ thành công.";
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            TempData["Error"] = "Lỗi khi hủy đặt vé: " + ex.Message;
        }

        return RedirectToAction("Index", "Home");
    }

    // CHI TIẾT ĐƠN HÀNG - Xem từng vé + QR Code
    // URL: GET /Booking/ChiTietDonHang?id={donHangId}
    public async Task<IActionResult> ChiTietDonHang(Guid id)
    {
        var nguoiMuaId = LayIdNguoiDangNhap();

        // Lấy thông tin đơn hàng
        var donHang = await TimDonHang(id, nguoiMuaId);
        if (donHang == null)
        {
            return NotFound();
        }

        // Chỉ cho phép xem vé nếu đơn hàng đã được thanh toán thành công
        if (donHang.TrangThai != 1)
        {
            TempData["Error"] = "Đơn hàng này chưa được thanh toán hoặc đã quá hạn. Không thể xem vé điện tử.";
            return RedirectToAction("DonHangCuaToi");
        }

        // Lấy danh sách từng vé trong đơn hàng, kèm tên loại vé
        string sqlChiTiet = @"
            SELECT ct.*,
                   lv.TenLoaiVe
            FROM ChiTietDonHang ct
            LEFT JOIN LoaiVe lv ON lv.Id = ct.LoaiVeId
            WHERE ct.DonHangId = @donHangId
            ORDER BY ct.Id
        ";
        var danhSachVe = await Db.LayDanhSach<ChiTietDonHang>(sqlChiTiet, new { donHangId = id });

        // Tạo ảnh QR code (dạng base64) cho từng vé có mã QR
        var anhQrTheoId = new Dictionary<int, string>();
        foreach (var ve in danhSachVe)
        {
            if (!string.IsNullOrEmpty(ve.MaQRCode))
            {
                anhQrTheoId[ve.Id] = SinhAnhQRBase64(ve.MaQRCode);
            }
        }

        // Lấy thông tin tóm tắt sự kiện để hiển thị trên vé
        string sqlSuKien = @"
            SELECT Id, TenSuKien, MoTaNgan, LoaiSuKien, LinkOnline,
                   TenDiaDiem, DiaChiDiaDiem, ThanhPhoDiaDiem,
                   NgayBatDau, NgayKetThuc
            FROM SuKien
            WHERE Id = @id
        ";
        var thongTinSuKien = await Db.LayDonLe<SuKien>(sqlSuKien, new { id = donHang.SuKienId });

        ViewBag.ChiTiet  = danhSachVe;
        ViewBag.QrImages = anhQrTheoId;
        ViewBag.SuKien   = thongTinSuKien;

        return View(donHang);
    }

    // CÁC HÀM HỖ TRỢ (Private helpers)

    // Lấy ID người đang đăng nhập từ cookie
    private Guid LayIdNguoiDangNhap()
    {
        string? idChuoi = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.Parse(idChuoi ?? Guid.Empty.ToString());
    }

    // Tìm đơn hàng theo ID + xác nhận đúng chủ sở hữu
    private async Task<DonHang?> TimDonHang(Guid id, Guid nguoiMuaId)
    {
        string sql = @"
            SELECT *
            FROM DonHang
            WHERE Id          = @id
              AND NguoiMuaId  = @nguoiMuaId
        ";
        return await Db.LayDonLe<DonHang>(sql, new { id, nguoiMuaId });
    }

    // Tạo ảnh QR Code từ dữ liệu chuỗi, trả về chuỗi base64 để nhúng vào HTML
    // Dùng: <img src="@anhQr" /> trong View
    private static string SinhAnhQRBase64(string duLieu)
    {
        using var qrGenerator = new QRCodeGenerator();
        var qrData  = qrGenerator.CreateQrCode(duLieu, QRCodeGenerator.ECCLevel.M);
        using var qrCode = new PngByteQRCode(qrData);
        byte[] anhBytes = qrCode.GetGraphic(6); // 6 = kích thước mỗi ô pixel
        return "data:image/png;base64," + Convert.ToBase64String(anhBytes);
    }

    // Tự động giải phóng các đơn hàng quá hạn 15 phút chưa thanh toán
    // Giải phóng ghế ngồi (ChoNgoi) và số lượng giữ chỗ vé (LoaiVe)
    public static async Task GiaiPhongDonHangHetHan()
    {
        using var connection = Db.TaoKetNoi();
        await connection.OpenAsync();
        using var transaction = connection.BeginTransaction();
        try
        {
            // 1. Lấy danh sách các đơn hàng quá hạn (TrangThai = 0 và NgayTao < 15 phút trước)
            string sqlLayHetHan = @"
                SELECT Id 
                FROM DonHang 
                WHERE TrangThai = 0 
                  AND NgayTao < DATEADD(minute, -15, GETUTCDATE())
            ";
            var orders = (await connection.QueryAsync<Guid>(sqlLayHetHan, null, transaction)).ToList();

            foreach (var orderId in orders)
            {
                // A. Lấy danh sách ghế đã giam của đơn hàng này
                string sqlLayGhe = "SELECT ChoNgoiId FROM ChiTietDonHang WHERE DonHangId = @orderId AND ChoNgoiId IS NOT NULL";
                var gheIds = (await connection.QueryAsync<int>(sqlLayGhe, new { orderId }, transaction)).ToList();
                if (gheIds.Count > 0)
                {
                    // Trả trạng thái ghế về trống (TrangThai = 0)
                    await connection.ExecuteAsync("UPDATE ChoNgoi SET TrangThai = 0 WHERE Id IN @gheIds", new { gheIds }, transaction);
                }

                // B. Trả số lượng giữ chỗ của từng loại vé về ban đầu
                string sqlThongKe = "SELECT LoaiVeId, COUNT(*) AS SoLuong FROM ChiTietDonHang WHERE DonHangId = @orderId GROUP BY LoaiVeId";
                var veList = await connection.QueryAsync<dynamic>(sqlThongKe, new { orderId }, transaction);
                foreach (var item in veList)
                {
                    int lvId = item.LoaiVeId;
                    int qty = item.SoLuong;
                    await connection.ExecuteAsync(@"
                        UPDATE LoaiVe 
                        SET SoLuongGiuCho = CASE WHEN SoLuongGiuCho >= @qty THEN SoLuongGiuCho - @qty ELSE 0 END 
                        WHERE Id = @lvId", new { qty, lvId }, transaction);
                }

                // C. Xóa thông tin chi tiết vé tạm
                await connection.ExecuteAsync(@"
                    UPDATE ChiTietDonHang 
                    SET MaVe = NULL, MaQRCode = NULL, ChoNgoiId = NULL 
                    WHERE DonHangId = @orderId", new { orderId }, transaction);

                // D. Đổi trạng thái đơn hàng thành Hủy/Hết hạn (TrangThai = 2)
                await connection.ExecuteAsync(@"
                    UPDATE DonHang 
                    SET TrangThai = 2, NgayCapNhat = GETUTCDATE() 
                    WHERE Id = @orderId", new { orderId }, transaction);
            }

            await transaction.CommitAsync();
        }
        catch
        {
            await transaction.RollbackAsync();
            // Bỏ qua lỗi để không làm gián đoạn tiến trình chạy của hệ thống
        }
    }
}
