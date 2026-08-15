namespace QuanLySuKienWuangEvents.Models;

public class ChiTietDonHang
{
    // Id của từng vé/dòng chi tiết. Trong SQL đây là INT IDENTITY tự tăng.
    public int Id { get; set; }

    // Khóa ngoại chỉ ra dòng vé này thuộc đơn hàng nào.
    public Guid DonHangId { get; set; }

    // Loại vé bắt buộc; ghế có thể null với sự kiện không có sơ đồ ghế.
    public int LoaiVeId { get; set; }
    public int? ChoNgoiId { get; set; }

    // Giá vé và người tham dự được lưu riêng cho từng vé.
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
