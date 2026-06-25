namespace QuanLySuKienWuangEvents.Models;

public class KhuVuc
{
    public int Id { get; set; }
    public int SoDoChoNgoiId { get; set; }
    public int LoaiVeId { get; set; }
    public string TenKhuVuc { get; set; } = "";
    public string? MauSac { get; set; }
    public int ThuTu { get; set; }
}
