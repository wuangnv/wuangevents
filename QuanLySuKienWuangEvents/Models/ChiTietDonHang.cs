namespace QuanLySuKienWuangEvents.Models;

public class ChiTietDonHang
{
    public int Id { get; set; }
    public Guid DonHangId { get; set; }
    public int LoaiVeId { get; set; }
    public int? ChoNgoiId { get; set; }
    public decimal GiaVe { get; set; }
    public string? TenNguoiThamDu { get; set; }
    public string? EmailNguoiThamDu { get; set; }

    // Gộp thông tin vé điện tử & check-in
    public string? MaVe { get; set; }
    public string? MaQRCode { get; set; }
    public byte TrangThaiCheckin { get; set; } // 0: ChuaCheckin, 1: DaCheckin, 2: DaHuy
    public DateTime? NgayCheckin { get; set; }
    public Guid? NguoiCheckinId { get; set; }

    // Thông tin JOIN từ bảng khác (không lưu DB)
    public string? TenLoaiVe { get; set; }
    public string? SoGhe { get; set; }
}
