// HOME CONTROLLER
// Trang công khai: lọc sự kiện và xem chi tiết; View nằm trong Views/Home.

using Microsoft.AspNetCore.Mvc;
using QuanLySuKienWuangEvents.Models;

namespace QuanLySuKienWuangEvents.Controllers;

public class HomeController : Controller
{
    // GET / hoặc /Home/Index: lọc theo từ khóa, danh mục, thành phố, hình thức và giá vé.
    public async Task<IActionResult> Index(
        string? q, int? danhMucId, string? thanhPho, string loaiSuKien = "tat-ca", string giaVe = "tat-ca")
    {
        if (User.Identity?.IsAuthenticated == true)
        {
            if (User.IsInRole("Quản trị viên")) return Redirect("/Admin/Index");
            if (User.IsInRole("Nhân viên soát vé")) return Redirect("/Staff/Index");
        }

        q = q?.Trim();
        loaiSuKien = ChuanHoaLoaiSuKien(loaiSuKien);
        giaVe = ChuanHoaGiaVe(giaVe);
        byte? loaiSuKienValue = LayGiaTriLoaiSuKien(loaiSuKien);

        // Lấy danh sách danh mục hiển thị trên thanh lọc
        string sqlDanhMuc = @"
            SELECT *
            FROM DanhMuc
            WHERE TrangThai = 1
            ORDER BY ThuTu
        ";
        ViewBag.DanhMucs   = await Db.LayDanhSach<DanhMuc>(sqlDanhMuc);
        ViewBag.TuKhoa     = q;
        ViewBag.DanhMucId  = danhMucId;
        ViewBag.LoaiSuKien = loaiSuKien;
        ViewBag.GiaVe      = giaVe;

        // Bộ lọc thành phố dùng cả sự kiện sắp tới và sự kiện đã diễn ra.
        string sqlCities = @"
            SELECT DISTINCT ThanhPhoDiaDiem
            FROM SuKien
            WHERE ThanhPhoDiaDiem IS NOT NULL 
              AND ThanhPhoDiaDiem != '' 
              AND HienThiCongKhai = 1 
              AND TrangThai IN (3, 5)
            ORDER BY ThanhPhoDiaDiem
        ";
        var citiesList = await Db.LayDanhSach<string>(sqlCities);
        ViewBag.Cities = citiesList;
        ViewBag.SelectedCity = thanhPho;

        // Lấy danh sách sự kiện công khai, đang bán vé (TrangThai = 3)
        string sqlSuKien = @"
            SELECT *
            FROM SuKien
            WHERE HienThiCongKhai = 1
              AND TrangThai = 3
              AND NgayKetThuc > DATEADD(HOUR, 7, GETUTCDATE())
              AND (
                    @q = ''
                 OR TenSuKien COLLATE Latin1_General_100_CI_AI LIKE N'%' + @q + N'%'
                 OR ISNULL(TenDiaDiem, N'') COLLATE Latin1_General_100_CI_AI LIKE N'%' + @q + N'%'
                 OR ISNULL(ThanhPhoDiaDiem, N'') COLLATE Latin1_General_100_CI_AI LIKE N'%' + @q + N'%'
              )
              AND (@danhMucId IS NULL OR DanhMucId = @danhMucId)
              AND (@thanhPho IS NULL OR @thanhPho = '' OR ThanhPhoDiaDiem = @thanhPho)
              AND (@loaiSuKienValue IS NULL OR LoaiSuKien = @loaiSuKienValue)
              AND (
                    @giaVe = 'tat-ca'
                 OR (
                        @giaVe = 'mien-phi'
                    AND EXISTS (SELECT 1 FROM LoaiVe lv WHERE lv.SuKienId = SuKien.Id AND lv.TrangThai = 1)
                    AND NOT EXISTS (SELECT 1 FROM LoaiVe lv WHERE lv.SuKienId = SuKien.Id AND lv.TrangThai = 1 AND lv.GiaBan > 0)
                 )
                 OR (
                        @giaVe = 'co-phi'
                    AND EXISTS (SELECT 1 FROM LoaiVe lv WHERE lv.SuKienId = SuKien.Id AND lv.TrangThai = 1 AND lv.GiaBan > 0)
                 )
              )
            ORDER BY NgayBatDau ASC
        ";

        var danhSachSuKien = await Db.LayDanhSach<SuKien>(sqlSuKien, new
        {
            q         = q ?? "",
            danhMucId = danhMucId,
            thanhPho  = thanhPho ?? "",
            loaiSuKienValue,
            giaVe
        });

        // Trang chủ có thêm một dải sự kiện cũ để khách có thể xem lại.
        ViewBag.SuKienDaQua = await Db.LayDanhSach<SuKien>(@"
            SELECT TOP (6) *
            FROM SuKien
            WHERE HienThiCongKhai = 1
              AND TrangThai IN (3, 5)
              AND NgayKetThuc <= DATEADD(HOUR, 7, GETUTCDATE())
              AND (@loaiSuKienValue IS NULL OR LoaiSuKien = @loaiSuKienValue)
              AND (
                    @giaVe = 'tat-ca'
                 OR (
                        @giaVe = 'mien-phi'
                    AND EXISTS (SELECT 1 FROM LoaiVe lv WHERE lv.SuKienId = SuKien.Id AND lv.TrangThai = 1)
                    AND NOT EXISTS (SELECT 1 FROM LoaiVe lv WHERE lv.SuKienId = SuKien.Id AND lv.TrangThai = 1 AND lv.GiaBan > 0)
                 )
                 OR (
                        @giaVe = 'co-phi'
                    AND EXISTS (SELECT 1 FROM LoaiVe lv WHERE lv.SuKienId = SuKien.Id AND lv.TrangThai = 1 AND lv.GiaBan > 0)
                 )
              )
            ORDER BY NgayBatDau DESC", new { loaiSuKienValue, giaVe });

        return View(danhSachSuKien);
    }

    // DANH SÁCH SỰ KIỆN - Bộ lọc nâng cao theo từ khóa, danh mục, thành phố và giá vé.
    // URL: GET /Home/SuKien
    public async Task<IActionResult> SuKien(
        string? q, int? danhMucId, string? thanhPho,
        string thoiGian = "sap-dien-ra", string loaiSuKien = "tat-ca", string giaVe = "tat-ca")
    {
        string[] boLocHopLe = ["sap-dien-ra", "da-dien-ra", "tat-ca"];
        if (!boLocHopLe.Contains(thoiGian)) thoiGian = "sap-dien-ra";
        q = q?.Trim();
        loaiSuKien = ChuanHoaLoaiSuKien(loaiSuKien);
        giaVe = ChuanHoaGiaVe(giaVe);
        byte? loaiSuKienValue = LayGiaTriLoaiSuKien(loaiSuKien);

        // Lấy danh sách danh mục hiển thị trên thanh lọc
        string sqlDanhMuc = @"
            SELECT *
            FROM DanhMuc
            WHERE TrangThai = 1
            ORDER BY ThuTu
        ";
        ViewBag.DanhMucs   = await Db.LayDanhSach<DanhMuc>(sqlDanhMuc);
        ViewBag.TuKhoa     = q;
        ViewBag.DanhMucId  = danhMucId;

        // Thành phố được lấy từ toàn bộ kho sự kiện công khai.
        string sqlCities = @"
            SELECT DISTINCT ThanhPhoDiaDiem
            FROM SuKien
            WHERE ThanhPhoDiaDiem IS NOT NULL 
              AND ThanhPhoDiaDiem != '' 
              AND HienThiCongKhai = 1 
              AND TrangThai IN (3, 5)
            ORDER BY ThanhPhoDiaDiem
        ";
        var citiesList = await Db.LayDanhSach<string>(sqlCities);
        ViewBag.Cities = citiesList;
        ViewBag.SelectedCity = thanhPho;
        ViewBag.ThoiGian = thoiGian;
        ViewBag.LoaiSuKien = loaiSuKien;
        ViewBag.GiaVe = giaVe;

        // Lọc ba nhóm: sắp diễn ra, đã diễn ra hoặc toàn bộ.
        string sqlSuKien = @"
            SELECT *
            FROM SuKien
            WHERE HienThiCongKhai = 1
              AND TrangThai IN (3, 5)
              AND (
                    (@thoiGian = 'sap-dien-ra' AND TrangThai = 3 AND NgayKetThuc > DATEADD(HOUR, 7, GETUTCDATE()))
                 OR (@thoiGian = 'da-dien-ra' AND (TrangThai = 5 OR NgayKetThuc <= DATEADD(HOUR, 7, GETUTCDATE())))
                 OR (@thoiGian = 'tat-ca')
              )
              AND (
                    @q = ''
                 OR TenSuKien COLLATE Latin1_General_100_CI_AI LIKE N'%' + @q + N'%'
                 OR ISNULL(TenDiaDiem, N'') COLLATE Latin1_General_100_CI_AI LIKE N'%' + @q + N'%'
                 OR ISNULL(ThanhPhoDiaDiem, N'') COLLATE Latin1_General_100_CI_AI LIKE N'%' + @q + N'%'
              )
              AND (@danhMucId IS NULL OR DanhMucId = @danhMucId)
              AND (@thanhPho IS NULL OR @thanhPho = '' OR ThanhPhoDiaDiem = @thanhPho)
              AND (@loaiSuKienValue IS NULL OR LoaiSuKien = @loaiSuKienValue)
              AND (
                    @giaVe = 'tat-ca'
                 OR (
                        @giaVe = 'mien-phi'
                    AND EXISTS (SELECT 1 FROM LoaiVe lv WHERE lv.SuKienId = SuKien.Id AND lv.TrangThai = 1)
                    AND NOT EXISTS (SELECT 1 FROM LoaiVe lv WHERE lv.SuKienId = SuKien.Id AND lv.TrangThai = 1 AND lv.GiaBan > 0)
                 )
                 OR (
                        @giaVe = 'co-phi'
                    AND EXISTS (SELECT 1 FROM LoaiVe lv WHERE lv.SuKienId = SuKien.Id AND lv.TrangThai = 1 AND lv.GiaBan > 0)
                 )
              )
            ORDER BY
                CASE WHEN TrangThai = 3 AND NgayKetThuc > DATEADD(HOUR, 7, GETUTCDATE()) THEN 0 ELSE 1 END,
                CASE WHEN TrangThai = 3 AND NgayKetThuc > DATEADD(HOUR, 7, GETUTCDATE()) THEN NgayBatDau END ASC,
                NgayBatDau DESC
        ";

        var danhSachSuKien = await Db.LayDanhSach<SuKien>(sqlSuKien, new
        {
            q         = q ?? "",
            danhMucId = danhMucId,
            thanhPho  = thanhPho ?? "",
            thoiGian,
            loaiSuKienValue,
            giaVe
        });

        return View(danhSachSuKien);
    }

    private static string ChuanHoaLoaiSuKien(string? value) => value switch
    {
        "truc-tiep" => "truc-tiep",
        "truc-tuyen" => "truc-tuyen",
        _ => "tat-ca"
    };

    private static byte? LayGiaTriLoaiSuKien(string value) => value switch
    {
        "truc-tiep" => 0,
        "truc-tuyen" => 1,
        _ => null
    };

    private static string ChuanHoaGiaVe(string? value) => value switch
    {
        "mien-phi" => "mien-phi",
        "co-phi" => "co-phi",
        _ => "tat-ca"
    };

    // CHI TIẾT SỰ KIỆN - Xem thông tin 1 sự kiện + loại vé
    // URL: GET /Home/ChiTiet?id={slug hoặc Id}
    public async Task<IActionResult> ChiTiet(string id)
    {
        // Tự động giải phóng đơn chờ quá 10 phút để cập nhật lại vé/ghế trống.
        await BookingController.GiaiPhongDonHangHetHan();

        // Tìm sự kiện theo slug hoặc Id
        string sqlSuKien = @"
            SELECT *
            FROM SuKien
            WHERE Slug = @id OR CONVERT(varchar(36), Id) = @id
        ";

        var suKien = await Db.LayDonLe<SuKien>(sqlSuKien, new { id });

        // Nếu không tìm thấy sự kiện thì trả về trang 404
        if (suKien == null)
        {
            return NotFound();
        }

        // Kiểm tra quyền xem: Nếu ẩn công khai hoặc chưa được duyệt (Nháp 0, Chờ duyệt 1, Từ chối 7)
        if (suKien.HienThiCongKhai == false || suKien.TrangThai == 0 || suKien.TrangThai == 1 || suKien.TrangThai == 7)
        {
            var userClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);
            Guid userId = userClaim != null && Guid.TryParse(userClaim.Value, out Guid parsedUserId)
                ? parsedUserId : Guid.Empty;
            bool laAdmin = User.IsInRole("Quản trị viên");
            bool laChuSoHuu = suKien.NguoiToChucId == userId;

            if (!laAdmin && !laChuSoHuu)
            {
                return NotFound();
            }
        }


        // Lấy danh sách loại vé đang mở bán của sự kiện này
        string sqlLoaiVe = @"
            SELECT lv.*,
                   CASE
                       WHEN @coSoDo = 1 AND ISNULL(g.SoGheTrong, 0) < (lv.SoLuongTong - lv.SoLuongDaBan - lv.SoLuongGiuCho)
                           THEN ISNULL(g.SoGheTrong, 0)
                       ELSE lv.SoLuongTong - lv.SoLuongDaBan - lv.SoLuongGiuCho
                   END AS SoLuongKhaDung
            FROM LoaiVe lv
            OUTER APPLY (
                SELECT COUNT(*) AS SoGheTrong
                FROM ChoNgoi cn
                JOIN HangGhe hg ON hg.Id = cn.HangGheId
                JOIN KhuVuc kv ON kv.Id = hg.KhuVucId
                JOIN SoDoChoNgoi sd ON sd.Id = kv.SoDoChoNgoiId
                WHERE sd.SuKienId = lv.SuKienId
                  AND kv.LoaiVeId = lv.Id
                  AND cn.TrangThai = 0
            ) g
            WHERE lv.SuKienId = @suKienId
              AND lv.TrangThai = 1
            ORDER BY lv.ThuTuHienThi, lv.Id
        ";
        var danhSachLoaiVe = await Db.LayDanhSach<LoaiVe>(sqlLoaiVe,
            new { suKienId = suKien.Id, coSoDo = suKien.CoSoDoChoNgoi });

        // Gửi danh sách loại vé sang View qua ViewBag
        ViewBag.LoaiVes = danhSachLoaiVe;

        return View(suKien);
    }

    [Microsoft.AspNetCore.Authorization.Authorize(Roles = "Quản trị viên")]
    [HttpPost]
    public async Task<IActionResult> CleanSlugs()
    {
        var list = await Db.LayDanhSach<SuKien>("SELECT Id, TenSuKien FROM SuKien");
        foreach (var item in list)
        {
            string slug = TaoSlug(item.TenSuKien);
            var existing = await Db.LayDonLe<SuKien>("SELECT Id FROM SuKien WHERE Slug = @slug AND Id != @id", new { slug, id = item.Id });
            if (existing != null)
            {
                slug += "-" + Random.Shared.Next(10, 99);
            }
            await Db.ThucThi("UPDATE SuKien SET Slug = @slug WHERE Id = @id", new { slug, id = item.Id });
        }
        return Content("All event slugs cleaned successfully!");
    }

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

    // TRANG LỖI - Hiển thị khi hệ thống xảy ra sự cố
    // URL: GET /Home/Error
    public IActionResult Error()
    {
        return View();
    }
}
