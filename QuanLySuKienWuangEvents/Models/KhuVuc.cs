namespace QuanLySuKienWuangEvents.Models;

// MODEL ánh xạ bảng KhuVuc: SoDoChoNgoi -> KhuVuc -> HangGhe -> ChoNgoi.
public class KhuVuc
{
    public int Id { get; set; }

    // Khu vực thuộc sơ đồ nào và dùng giá của loại vé nào.
    public int SoDoChoNgoiId { get; set; }
    public int LoaiVeId { get; set; }
    public string TenKhuVuc { get; set; } = "";

    // Mã màu CSS dạng #RRGGBB, ví dụ #7C3AED.
    public string? MauSac { get; set; }

    // Tọa độ lưới của khu trên sơ đồ: dùng để hiển thị đúng vị trí đã cấu hình.
    public int? ViTriX { get; set; }
    public int? ViTriY { get; set; }
    public int ThuTu { get; set; }
}
