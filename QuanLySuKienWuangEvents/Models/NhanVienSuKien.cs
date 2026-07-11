using System;

namespace QuanLySuKienWuangEvents.Models
{
    public class NhanVienSuKien
    {
        public int Id { get; set; }
        public Guid NguoiDungId { get; set; }
        public Guid SuKienId { get; set; }
        public string VaiTroNV { get; set; } = "CheckIn";
        public DateTime NgayThem { get; set; }

        // Các trường mở rộng phục vụ hiển thị (JOIN với bảng NguoiDung, SuKien)
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
}
