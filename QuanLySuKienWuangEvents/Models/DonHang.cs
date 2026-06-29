namespace QuanLySuKienWuangEvents.Models;

public class DonHang
{
    public Guid Id { get; set; }
    public string MaDonHang { get; set; } = "";
    public Guid NguoiMuaId { get; set; }
    public Guid SuKienId { get; set; }
    public int? MaGiamGiaId { get; set; }
    public string HoTenNguoiMua { get; set; } = "";
    public string EmailNguoiMua { get; set; } = "";
    public string? SdtNguoiMua { get; set; }
    public decimal TongTienVe { get; set; }
    public decimal TienGiamGia { get; set; }
    public decimal TongThanhToan { get; set; }
    public byte TrangThai { get; set; }
    public DateTime NgayTao { get; set; }
    public DateTime? NgayCapNhat { get; set; }

    // Gộp thông tin thanh toán
    public string? MaGiaoDich { get; set; }
    public byte? PhuongThucThanhToan { get; set; }
    public DateTime? NgayThanhToan { get; set; }
}
