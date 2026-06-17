namespace QuanLySuKienWuangEvents.Models;

public class LoaiVe
{
    public int Id { get; set; }
    public Guid SuKienId { get; set; }
    public string TenLoaiVe { get; set; } = "";
    public string? MoTa { get; set; }
    public decimal GiaBan { get; set; }
    public int SoLuongTong { get; set; }
    public int SoLuongDaBan { get; set; }
    public int SoLuongGiuCho { get; set; }
    public int GioiHanMoiDon { get; set; }
    public DateTime? NgayBatDauBan { get; set; }
    public DateTime? NgayKetThucBan { get; set; }
    public int ThuTuHienThi { get; set; }
    public string? MauSac { get; set; }
    public bool TrangThai { get; set; }
}
