namespace QuanLySuKienWuangEvents.Models;

// MODEL trung tâm ánh xạ bảng SuKien.
// Home đọc để bán vé; Organizer tạo/sửa; Admin duyệt; Staff check-in.
public class SuKien
{
    // Khóa chính và hai khóa ngoại chỉ chủ sở hữu/danh mục.
    public Guid Id { get; set; }
    public Guid NguoiToChucId { get; set; }
    public int DanhMucId { get; set; }

    // Slug là chuỗi thân thiện dùng trên URL thay cho Guid.
    public string TenSuKien { get; set; } = "";
    public string Slug { get; set; } = "";
    public string? MoTaNgan { get; set; }
    public string? MoTaChiTiet { get; set; }
    public string? AnhBia { get; set; }
    public string? AnhThumbnail { get; set; }

    // Ngày kết thúc phải sau ngày bắt đầu; Controller tạo/sửa kiểm tra điều này.
    public DateTime NgayBatDau { get; set; }
    public DateTime NgayKetThuc { get; set; }

    // 0 offline, 1 online. Online cần LinkOnline; offline dùng địa điểm.
    public byte LoaiSuKien { get; set; }
    public string? LinkOnline { get; set; }
    public bool CoSoDoChoNgoi { get; set; }

    // Quy ước thực tế: 0 nháp, 1 chờ duyệt, 2 tạm dừng,
    // 3 đang bán, 6 đã hủy, 7 bị từ chối.
    public byte TrangThai { get; set; }
    public string? LyDoTuChoi { get; set; }
    public bool HienThiCongKhai { get; set; }
    public DateTime NgayTao { get; set; }
    public DateTime? NgayCapNhat { get; set; }

    // Nếu null, check-in thường dùng khoảng thời gian của sự kiện.
    public DateTime? BatDauCheckIn { get; set; }
    public DateTime? KetThucCheckIn { get; set; }

    // Thông tin địa điểm được gộp trực tiếp vào bảng SuKien.
    public string? TenDiaDiem { get; set; }
    public string? DiaChiDiaDiem { get; set; }
    public string? ThanhPhoDiaDiem { get; set; }
    public string? QuanHuyenDiaDiem { get; set; }
    public int? SucChuaDiaDiem { get; set; }

    // Property thống kê bổ sung, không phải cột bảng SuKien.
    // SQL phải SELECT alias cùng tên để Dapper gán khi màn hình cần dùng.
    public int VeDaBan { get; set; }
    public decimal DoanhThu { get; set; }
    public int TongVe { get; set; }

    // Ảnh chụp thật dự phòng đang có trong wwwroot/uploads/banners/professional/.
    private static readonly string[] BannersThucTe =
    {
        "/uploads/banners/professional/real-art-gallery.jpg",
        "/uploads/banners/professional/real-jazz-stage.jpg",
        "/uploads/banners/professional/real-saigon-basketball.jpg",
        "/uploads/banners/professional/real-tech-conference.jpg",
        "/uploads/banners/professional/real-trade-expo.jpg",
        "/uploads/banners/professional/real-vietnam-craft-workshop.jpg",
        "/uploads/banners/professional/real-vietnam-food-festival.jpg",
        "/uploads/banners/professional/real-vietnam-lantern-festival.jpg",
        "/uploads/banners/professional/real-vietnam-running.jpg",
        "/uploads/banners/professional/real-vietnamese-performing-arts.jpg",
        "/uploads/banners/professional/real-vn-concert.jpg"
    };

    // Property tính toán dùng trong View; không phải cột database vì chỉ có get.
    public string LayAnhBiaHienThi
    {
        get
        {
            // Database đã có đường dẫn local hợp lệ thì dùng chính ảnh đó.
            if (!string.IsNullOrWhiteSpace(AnhBia) &&
                !AnhBia.Contains("unsplash") &&
                !AnhBia.Equals("/images/default-event.svg", StringComparison.OrdinalIgnoreCase))
            {
                return AnhBia;
            }

            // Nếu thiếu ảnh, hash Id giúp cùng sự kiện luôn nhận cùng ảnh dự phòng.
            int index = Math.Abs(Id.GetHashCode()) % BannersThucTe.Length;
            return BannersThucTe[index];
        }
    }
}
