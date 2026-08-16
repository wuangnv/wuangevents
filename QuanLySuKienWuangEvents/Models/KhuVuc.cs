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

    // Tọa độ và kích thước pixel trên canvas: dùng chung cho designer và màn hình mua vé.
    public int? ViTriX { get; set; }
    public int? ViTriY { get; set; }
    public int Rong { get; set; }
    public int Cao { get; set; }

    // seated = khách chọn ghế cụ thể; ga = khu đứng chọn số lượng, không sinh ghế ảo.
    public string LoaiKhuVuc { get; set; } = "seated";
    public int? SucChua { get; set; }

    // Lưu cấu hình đã dùng để tái tạo/kiểm tra sơ đồ, còn HangGhe/ChoNgoi là dữ liệu ghế thực.
    public string TienToHangGhe { get; set; } = "";
    public string KieuDanhSo { get; set; } = "ltr";
    public int SoBatDau { get; set; } = 1;
    public bool BoQuaChuDeNham { get; set; } = true;
    public int ThuTu { get; set; }
}
