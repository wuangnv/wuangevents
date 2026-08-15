namespace QuanLySuKienWuangEvents.Models;

// MODEL ánh xạ bảng NguoiDung, dùng chung cho khách, BTC, Staff và Admin.
public class NguoiDung
{
    public Guid Id { get; set; }

    // Email dùng đăng nhập và có UNIQUE trong database.
    public string Email { get; set; } = "";

    // Không lưu mật khẩu gốc. BCrypt tạo chuỗi băm và đăng nhập dùng Verify.
    public string MatKhauHash { get; set; } = "";
    public string HoTen { get; set; } = "";
    public string? SoDienThoai { get; set; }
    public string? AnhDaiDien { get; set; }

    // 0 khách hàng, 1 Ban tổ chức, 2 Staff, 3 Admin.
    public byte VaiTro { get; set; }

    // 0 bị khóa, 1 hoạt động. Đăng nhập phải kiểm tra trạng thái này.
    public byte TrangThai { get; set; }

    // Chỉ true sau khi người dùng bấm liên kết xác minh email.
    public bool EmailXacNhan { get; set; }
    public string? TokenXacNhan { get; set; }
    public DateTime NgayTao { get; set; }
    public DateTime? NgayCapNhat { get; set; }

    // Thông tin ngân hàng của nhà tổ chức; khách thường có thể để null.
    public string? TenNganHang { get; set; }
    public string? SoTaiKhoan { get; set; }
    public string? ChuTaiKhoan { get; set; }

    // Quy trình xin làm BTC: 0 chưa gửi, 1 chờ duyệt, 2 đã duyệt, 3 từ chối.
    public byte YeuCauBanToChuc { get; set; }
    public string? SdtBanToChuc { get; set; }
    public string? TenToChuc { get; set; }

    // 0 cá nhân, 1 doanh nghiệp/đơn vị; null khi chưa tạo hồ sơ Ban tổ chức.
    public byte? LoaiChuTheBTC { get; set; }
    public string? MoTaYeuCauBTC { get; set; }
    public bool DaDongYDieuKhoanBTC { get; set; }
    public string? LyDoTuChoiBTC { get; set; }
    public DateTime? NgayYeuCauBTC { get; set; }
}
