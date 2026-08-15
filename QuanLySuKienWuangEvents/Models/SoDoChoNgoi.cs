namespace QuanLySuKienWuangEvents.Models;

// MODEL ánh xạ bảng SoDoChoNgoi.
// Database đặt UNIQUE SuKienId nên mỗi sự kiện tối đa một sơ đồ.
public class SoDoChoNgoi
{
    public int Id { get; set; }

    // Khóa ngoại tới SuKien.
    public Guid SuKienId { get; set; }
    public string TenSoDo { get; set; } = "";

    // Dùng để dựng lại đúng bố cục đã chọn: auditorium, theatre, cinema, arena hoặc custom.
    public string LoaiSoDo { get; set; } = "custom";

    // Tọa độ sân khấu trên canvas 12 cột; null là sơ đồ cũ, sân khấu mặc định ở phía trên.
    public int? SanKhauX { get; set; }
    public int? SanKhauY { get; set; }
    public DateTime NgayTao { get; set; }
}
