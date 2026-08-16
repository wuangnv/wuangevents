namespace QuanLySuKienWuangEvents.Models;

// MODEL ánh xạ bảng SoDoChoNgoi.
// Database đặt UNIQUE SuKienId nên mỗi sự kiện tối đa một sơ đồ.
public class SoDoChoNgoi
{
    public int Id { get; set; }

    // Khóa ngoại tới SuKien.
    public Guid SuKienId { get; set; }
    public string TenSoDo { get; set; } = "";

    // Dùng để dựng lại đúng bố cục đã chọn: concert, auditorium, theatre, arena hoặc custom.
    public string LoaiSoDo { get; set; } = "custom";

    // Kích thước bản vẽ dùng chung cho BTC thiết kế và khách mua xem sơ đồ.
    public int CanvasRong { get; set; } = 960;
    public int CanvasCao { get; set; } = 650;

    // Tọa độ/kích thước sân khấu theo pixel trên canvas; null chỉ dùng cho sơ đồ cũ.
    public int? SanKhauX { get; set; }
    public int? SanKhauY { get; set; }
    public int SanKhauRong { get; set; } = 280;
    public int SanKhauCao { get; set; } = 44;
    public string NhanSanKhau { get; set; } = "SÂN KHẤU";
    public DateTime NgayTao { get; set; }
}
