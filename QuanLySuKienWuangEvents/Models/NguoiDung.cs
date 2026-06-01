namespace QuanLySuKienWuangEvents.Models;

public class NguoiDung
{
    public Guid Id { get; set; }
    public string Email { get; set; } = "";
    public string MatKhauHash { get; set; } = "";
    public string HoTen { get; set; } = "";
    public string? SoDienThoai { get; set; }
    public string? AnhDaiDien { get; set; }
    public byte VaiTro { get; set; }
    public byte TrangThai { get; set; }
    public bool EmailXacNhan { get; set; }
    public string? TokenXacNhan { get; set; }
    public DateTime NgayTao { get; set; }
    public DateTime? NgayCapNhat { get; set; }

    // Thông tin ngân hàng của nhà tổ chức
    public string? TenNganHang { get; set; }
    public string? SoTaiKhoan { get; set; }
    public string? ChuTaiKhoan { get; set; }

    // Thông tin duyệt Ban Tổ Chức
    public byte YeuCauBanToChuc { get; set; } // 0: ChuaGui, 1: ChoDuyet, 2: DaDuyet, 3: TuChoi
    public string? SdtBanToChuc { get; set; }
    public string? LyDoTuChoiBTC { get; set; }
    public DateTime? NgayYeuCauBTC { get; set; }
}
