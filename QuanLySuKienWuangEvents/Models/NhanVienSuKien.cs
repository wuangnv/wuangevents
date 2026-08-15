namespace QuanLySuKienWuangEvents.Models;

// MODEL chính ánh xạ bảng nối NhanVienSuKien.
// Một Staff có thể được phân công nhiều sự kiện và ngược lại.
public class NhanVienSuKien
{
    public int Id { get; set; }

    // Hai khóa ngoại tạo quan hệ nhiều-nhiều NguoiDung <-> SuKien.
    public Guid NguoiDungId { get; set; }
    public Guid SuKienId { get; set; }
    public string VaiTroNV { get; set; } = "CheckIn";
    public DateTime NgayThem { get; set; }

    // Property hiển thị lấy thêm bằng JOIN NguoiDung/SuKien, không thuộc bảng nối chính.
    public string? HoTenNV { get; set; }
    public string? EmailNV { get; set; }
    public string? TenSuKien { get; set; }
    public string? AnhBiaSuKien { get; set; }
    public DateTime? NgayBatDauSuKien { get; set; }
    public DateTime? NgayKetThucSuKien { get; set; }
    public int? TrangThaiSuKien { get; set; }
    public string? TenDiaDiem { get; set; }
    public DateTime? BatDauCheckInSuKien { get; set; }
    public DateTime? KetThucCheckInSuKien { get; set; }
}
