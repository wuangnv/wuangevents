namespace QuanLySuKienWuangEvents.Models;

// MODEL ánh xạ bảng LoaiVe. Một SuKien có thể có nhiều LoaiVe.
public class LoaiVe
{
    // Khóa chính tự tăng và khóa ngoại tới sự kiện sở hữu loại vé.
    public int Id { get; set; }
    public Guid SuKienId { get; set; }

    // Nội dung hiển thị cho người mua.
    public string TenLoaiVe { get; set; } = "";
    public string? MoTa { get; set; }

    // decimal được dùng vì đây là tiền cần tính chính xác.
    public decimal GiaBan { get; set; }

    // Vé còn khả dụng thường = tổng - đã bán - đang giữ.
    public int SoLuongTong { get; set; }
    public int SoLuongDaBan { get; set; }
    public int SoLuongGiuCho { get; set; }

    // Số vé còn thực tế; với sự kiện có sơ đồ, giá trị này còn bị giới hạn bởi số ghế trống.
    public int SoLuongKhaDung { get; set; }

    // Ràng buộc một đơn không được mua quá số lượng này.
    public int GioiHanMoiDon { get; set; }

    // Có thể null nếu không giới hạn riêng thời gian bán loại vé.
    public DateTime? NgayBatDauBan { get; set; }
    public DateTime? NgayKetThucBan { get; set; }

    // Điều khiển thứ tự, màu và trạng thái hiển thị trên View.
    public int ThuTuHienThi { get; set; }
    public string? MauSac { get; set; }
    public bool TrangThai { get; set; }
}
