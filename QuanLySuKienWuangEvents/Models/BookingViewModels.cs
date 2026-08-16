namespace QuanLySuKienWuangEvents.Models;

// Bản nháp chỉ lưu trong Session; chưa tạo DonHang và chưa giữ ghế trong database.
public class BookingDraft
{
    public Guid NguoiMuaId { get; set; }
    public Guid SuKienId { get; set; }
    public Dictionary<int, int> SoLuongTheoLoaiVe { get; set; } = new();
    public List<int> ChoNgoiIds { get; set; } = new();
    // Khu đứng chọn số lượng theo Id KhuVuc. Không tạo ChoNgoi giả cho GA.
    public Dictionary<int, int> SoLuongTheoKhuVucDung { get; set; } = new();
    public string? MaGiamGia { get; set; }
}

// Một dòng tóm tắt loại vé trên màn hình thanh toán.
public class DongVeThanhToanViewModel
{
    public int LoaiVeId { get; set; }
    public string TenLoaiVe { get; set; } = "";
    public string? MauSac { get; set; }
    public int SoLuong { get; set; }
    public decimal DonGia { get; set; }
    public decimal ThanhTien => DonGia * SoLuong;
}

// Ghế đã chọn; loại vé và giá được suy ra từ KhuVuc của ghế.
public class GheDatVeViewModel
{
    public int Id { get; set; }
    public string SoGhe { get; set; } = "";
    public string TenHang { get; set; } = "";
    public string TenKhuVuc { get; set; } = "";
    public string? MauSac { get; set; }
    public byte TrangThai { get; set; }
    public int LoaiVeId { get; set; }
    public string TenLoaiVe { get; set; } = "";
    public decimal GiaBan { get; set; }
    public bool LaKhuDung { get; set; }
}

// Dữ liệu duy nhất mà View ThanhToan cần để hiển thị bản nháp.
public class ThanhToanViewModel
{
    public string Token { get; set; } = "";
    public SuKien SuKien { get; set; } = new();
    public bool CoSoDo { get; set; }
    public List<DongVeThanhToanViewModel> CacLoaiVe { get; set; } = new();
    public List<GheDatVeViewModel> GheDaChon { get; set; } = new();
    public string? MaGiamGia { get; set; }
    public decimal TongTienVe { get; set; }
    public decimal TienGiamGia { get; set; }
    public decimal TongThanhToan => Math.Max(0, TongTienVe - TienGiamGia);
    public int TongSoVe => CacLoaiVe.Sum(x => x.SoLuong);
}

// Màn hình này chỉ xuất hiện sau khi đơn đã được tạo và đang giữ chỗ 10 phút.
public class ChoThanhToanViewModel
{
    public DonHang DonHang { get; set; } = new();
    public SuKien SuKien { get; set; } = new();
    public List<ChiTietDonHang> ChiTiet { get; set; } = new();
    public DateTime HetHanLucUtc { get; set; }
    public int SoPhutGiuCho { get; set; }
}
