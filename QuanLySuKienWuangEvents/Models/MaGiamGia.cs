namespace QuanLySuKienWuangEvents.Models;

// MODEL ánh xạ bảng MaGiamGia. Mỗi mã thuộc đúng một sự kiện.
public class MaGiamGia
{
    public int Id { get; set; }
    public Guid SuKienId { get; set; }

    // Chuỗi người mua nhập; database đặt UNIQUE để không bị trùng mã.
    public string MaCode { get; set; } = "";
    public string? MoTa { get; set; }

    // 0 = giảm phần trăm; 1 = giảm số tiền cố định.
    public byte LoaiGiamGia { get; set; }
    public decimal GiaTri { get; set; }

    // Có thể null nếu không đặt mức giảm tối đa/đơn tối thiểu.
    public decimal? GiamToiDa { get; set; }
    public decimal? DonToiThieu { get; set; }

    // Mã hết lượt khi SoLuongDaDung đã đạt SoLuongTong.
    public int SoLuongTong { get; set; }
    public int SoLuongDaDung { get; set; }

    // Chỉ dùng trong cửa sổ thời gian và khi TrangThai = true.
    public DateTime NgayBatDau { get; set; }
    public DateTime NgayKetThuc { get; set; }
    public bool TrangThai { get; set; }
    public DateTime NgayTao { get; set; }
}
