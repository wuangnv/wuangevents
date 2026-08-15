using System;
// Hiển thị ca được phân công và xử lý quét vé tại cổng sự kiện.
// Check-in yêu cầu đúng Staff/sự kiện/giờ, đơn đã thanh toán và vé chưa dùng.

using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;
using System.Linq;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Dapper;
using QuanLySuKienWuangEvents.Models;

namespace QuanLySuKienWuangEvents.Controllers
{
    [Authorize(Roles = "Nhân viên soát vé")]
    [Route("Staff/[action]/{id?}")]
    public class StaffController : Controller
    {
        // Lấy ID của nhân viên đăng nhập từ Cookie Claims
        private Guid LayIdNguoiDangNhap()
        {
            string? value = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return Guid.TryParse(value, out Guid id) ? id : Guid.Empty;
        }

        // Kiểm tra xem nhân viên này có được phân công cho sự kiện này không
        private async Task<bool> LaSuKienDuocPhanCong(Guid suKienId)
        {
            var userId = LayIdNguoiDangNhap();
            string sql = "SELECT COUNT(1) FROM NhanVienSuKien WHERE NguoiDungId = @userId AND SuKienId = @suKienId";
            int count = await Db.LayGiaTri<int>(sql, new { userId, suKienId });
            return count > 0;
        }

        private async Task<string> LayTenSuKien(Guid suKienId)
        {
            return await Db.LayGiaTri<string>("SELECT TenSuKien FROM SuKien WHERE Id = @suKienId", new { suKienId }) ?? "Sự kiện không tên";
        }

        // Trang chủ của Staff - Hiển thị danh sách sự kiện được phân công soát vé
        public async Task<IActionResult> Index()
        {
            var userId = LayIdNguoiDangNhap();
            string sql = @"
                SELECT nv.Id, nv.NguoiDungId, nv.SuKienId, nv.VaiTroNV, nv.NgayThem,
                       s.TenSuKien, s.AnhBia AS AnhBiaSuKien, s.NgayBatDau AS NgayBatDauSuKien,
                       s.NgayKetThuc AS NgayKetThucSuKien, s.TrangThai AS TrangThaiSuKien, s.TenDiaDiem,
                       s.BatDauCheckIn AS BatDauCheckInSuKien, s.KetThucCheckIn AS KetThucCheckInSuKien
                FROM NhanVienSuKien nv
                JOIN SuKien s ON s.Id = nv.SuKienId
                WHERE nv.NguoiDungId = @userId
                  AND s.LoaiSuKien = 0
                ORDER BY s.NgayBatDau ASC
            ";
            var list = await Db.LayDanhSach<NhanVienSuKien>(sql, new { userId });
            return View(list);
        }

        // Trang soát vé của sự kiện
        public async Task<IActionResult> CheckIn(Guid suKienId, string? search, byte? trangThai)
        {
            if (!await LaSuKienDuocPhanCong(suKienId)) return Forbid();

            string sqlSuKien = "SELECT NgayBatDau, NgayKetThuc, TrangThai, LoaiSuKien, BatDauCheckIn, KetThucCheckIn FROM SuKien WHERE Id = @suKienId";
            var skInfo = await Db.LayDonLe<dynamic>(sqlSuKien, new { suKienId });
            if (skInfo == null) return NotFound();
            if ((byte)skInfo.LoaiSuKien == 1)
            {
                TempData["Error"] = "Sự kiện trực tuyến không sử dụng QR hoặc check-in tại cổng.";
                return RedirectToAction("Index");
            }
            ViewBag.TrangThaiSuKien = (int)skInfo.TrangThai;
            ViewBag.NgayBatDauSuKien = (DateTime)skInfo.NgayBatDau;
            ViewBag.NgayKetThucSuKien = (DateTime)skInfo.NgayKetThuc;
            ViewBag.BatDauCheckIn = (DateTime?)skInfo.BatDauCheckIn;
            ViewBag.KetThucCheckIn = (DateTime?)skInfo.KetThucCheckIn;

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
                suKienId,
                trangThai,
                search = search?.Trim() ?? ""
            });

            ViewBag.SuKienId  = suKienId;
            ViewBag.TenSuKien = await LayTenSuKien(suKienId);
            ViewBag.Search    = search;
            ViewBag.TrangThai = trangThai;
            ViewBag.DaCheckin = list.Count(x => x.TrangThaiCheckin == 1);
            ViewBag.TongVe    = await Db.LayGiaTri<int>(@"
                SELECT COUNT(1) 
                FROM ChiTietDonHang ct 
                JOIN DonHang d ON d.Id = ct.DonHangId 
                WHERE d.SuKienId = @suKienId AND d.TrangThai = 1", new { suKienId });

            return View(list);
        }

        // Xử lý soát vé
        [HttpPost]
        public async Task<IActionResult> QuetVeCheckIn(Guid suKienId, string? code)
        {
            if (!await LaSuKienDuocPhanCong(suKienId)) return Forbid();
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
                return RedirectToAction("Index");
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
                TempData["Error"] = "Lỗi: Không tìm thấy vé hợp lệ hoặc đơn hàng chưa thanh toán.";
                return RedirectToAction("CheckIn", new { suKienId });
            }

            int ticketId = ticket.Id;
            byte trangThaiCheckin = ticket.TrangThaiCheckin;
            string tenKhach = ticket.TenNguoiThamDu ?? "Khách";
            var nguoiCheckinId = LayIdNguoiDangNhap();

            if (trangThaiCheckin == 1)
            {
                await transaction.RollbackAsync();
                TempData["Error"] = $"Cảnh báo: Vé của khách '{tenKhach}' đã check-in từ trước!";
                return RedirectToAction("CheckIn", new { suKienId });
            }
            else if (trangThaiCheckin == 2)
            {
                await transaction.RollbackAsync();
                TempData["Error"] = $"Cảnh báo: Vé của khách '{tenKhach}' đã bị hủy bỏ, không hợp lệ!";
                return RedirectToAction("CheckIn", new { suKienId });
            }

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
            TempData["Message"] = $"Check-in thành công cho khách '{tenKhach}'!";
            return RedirectToAction("CheckIn", new { suKienId });
        }
    }
}
