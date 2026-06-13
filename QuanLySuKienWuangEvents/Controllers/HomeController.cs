// HOME CONTROLLER
// Chức năng: Trang chủ, xem danh sách sự kiện, xem chi tiết

using Microsoft.AspNetCore.Mvc;
using QuanLySuKienWuangEvents.Models;

namespace QuanLySuKienWuangEvents.Controllers;

public class HomeController : Controller
{
    // TRANG CHỦ - Hiển thị danh sách sự kiện đang mở bán
    // URL: GET /Home/Index  hoặc  GET /
    // Tham số:
    //   q         = từ khoá tìm kiếm (ví dụ: "rock việt")
    //   danhMucId = lọc theo danh mục (ví dụ: 1 = Âm nhạc)
    public async Task<IActionResult> Index(string? q, int? danhMucId, string? thanhPho)
    {
        if (User.Identity?.IsAuthenticated == true)
        {
            if (User.IsInRole("Quản trị viên")) return Redirect("/Admin/Index");
            if (User.IsInRole("Nhân viên soát vé")) return Redirect("/Staff/Index");
        }

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

        // Lấy danh sách các tỉnh thành đang có sự kiện (để làm bộ lọc)
        string sqlCities = @"
            SELECT DISTINCT ThanhPhoDiaDiem
            FROM SuKien
            WHERE ThanhPhoDiaDiem IS NOT NULL 
              AND ThanhPhoDiaDiem != '' 
              AND HienThiCongKhai = 1 
              AND TrangThai = 3
              AND NgayKetThuc > GETUTCDATE()
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
              AND NgayKetThuc > GETUTCDATE()
              AND (@q = '' OR TenSuKien LIKE '%' + @q + '%')
              AND (@danhMucId IS NULL OR DanhMucId = @danhMucId)
              AND (@thanhPho IS NULL OR @thanhPho = '' OR ThanhPhoDiaDiem = @thanhPho)
            ORDER BY NgayBatDau ASC
        ";

        var danhSachSuKien = await Db.LayDanhSach<SuKien>(sqlSuKien, new
        {
            q         = q ?? "",
            danhMucId = danhMucId,
            thanhPho  = thanhPho ?? ""
        });

        return View(danhSachSuKien);
    }

    // DANH SÁCH SỰ KIỆN - Bộ lọc nâng cao theo từ khóa, danh mục, thành phố
    // URL: GET /Home/SuKien
    public async Task<IActionResult> SuKien(string? q, int? danhMucId, string? thanhPho)
    {
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

        // Lấy danh sách các tỉnh thành đang có sự kiện (để làm bộ lọc)
        string sqlCities = @"
            SELECT DISTINCT ThanhPhoDiaDiem
            FROM SuKien
            WHERE ThanhPhoDiaDiem IS NOT NULL 
              AND ThanhPhoDiaDiem != '' 
              AND HienThiCongKhai = 1 
              AND TrangThai = 3
              AND NgayKetThuc > GETUTCDATE()
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
              AND NgayKetThuc > GETUTCDATE()
              AND (@q = '' OR TenSuKien LIKE '%' + @q + '%')
              AND (@danhMucId IS NULL OR DanhMucId = @danhMucId)
              AND (@thanhPho IS NULL OR @thanhPho = '' OR ThanhPhoDiaDiem = @thanhPho)
            ORDER BY NgayBatDau ASC
        ";

        var danhSachSuKien = await Db.LayDanhSach<SuKien>(sqlSuKien, new
        {
            q         = q ?? "",
            danhMucId = danhMucId,
            thanhPho  = thanhPho ?? ""
        });

        return View(danhSachSuKien);
    }

    // CHI TIẾT SỰ KIỆN - Xem thông tin 1 sự kiện + loại vé
    // URL: GET /Home/ChiTiet?id={slug hoặc Id}
    public async Task<IActionResult> ChiTiet(string id)
    {
        // Tự động giải phóng các đơn hàng quá hạn 15 phút chưa thanh toán để cập nhật vé trống
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
            Guid userId = userClaim != null ? Guid.Parse(userClaim.Value) : Guid.Empty;
            bool laAdmin = User.IsInRole("Quản trị viên");
            bool laChuSoHuu = suKien.NguoiToChucId == userId;

            if (!laAdmin && !laChuSoHuu)
            {
                return NotFound();
            }
        }


        // Lấy danh sách loại vé đang mở bán của sự kiện này
        string sqlLoaiVe = @"
            SELECT *
            FROM LoaiVe
            WHERE SuKienId = @suKienId
              AND TrangThai = 1
            ORDER BY ThuTuHienThi, Id
        ";
        var danhSachLoaiVe = await Db.LayDanhSach<LoaiVe>(sqlLoaiVe, new { suKienId = suKien.Id });

        // Gửi danh sách loại vé sang View qua ViewBag
        ViewBag.LoaiVes = danhSachLoaiVe;

        return View(suKien);
    }

    [Microsoft.AspNetCore.Authorization.Authorize(Roles = "Quản trị viên")]
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
