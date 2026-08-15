namespace QuanLySuKienWuangEvents.Models;

public class DonHang
{
    // Guid tương ứng với kiểu UNIQUEIDENTIFIER của cột DonHang.Id trong SQL Server.
    public Guid Id { get; set; }

    // Mã ngắn để con người đọc/tìm kiếm. = "" giúp property không bị null.
    public string MaDonHang { get; set; } = "";

    // Hai khóa ngoại: ai mua đơn này và đơn này mua vé của sự kiện nào.
    public Guid NguoiMuaId { get; set; }
    public Guid SuKienId { get; set; }

    // Dấu ? nghĩa là có thể null vì khách có thể không sử dụng mã giảm giá.
    public int? MaGiamGiaId { get; set; }

    // Thông tin được chụp lại tại thời điểm đặt vé.
    public string HoTenNguoiMua { get; set; } = "";
    public string EmailNguoiMua { get; set; } = "";
    public string? SdtNguoiMua { get; set; }

    // decimal được dùng cho tiền vì tính toán chính xác hơn float/double.
    public decimal TongTienVe { get; set; }
    public decimal TienGiamGia { get; set; }
    public decimal TongThanhToan { get; set; }

    // byte tương ứng TINYINT: 0 chờ, 1 đã trả, 2 đã hủy, 4 hết hạn.
    public byte TrangThai { get; set; }
    public DateTime NgayTao { get; set; }
    public DateTime? NgayCapNhat { get; set; }

    // Gộp thông tin thanh toán
    public string? MaGiaoDich { get; set; }
    public byte? PhuongThucThanhToan { get; set; }
    public DateTime? NgayThanhToan { get; set; }
}
