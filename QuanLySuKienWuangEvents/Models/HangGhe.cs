namespace QuanLySuKienWuangEvents.Models;

// MODEL ánh xạ bảng HangGhe: một hàng nằm trong một KhuVuc.
public class HangGhe
{
    public int Id { get; set; }

    // Khóa ngoại tới KhuVuc.
    public int KhuVucId { get; set; }

    // Tên hàng như A, B, C; SoGhe là số ghế được cấu hình trong hàng.
    public string TenHang { get; set; } = "";
    public int SoGhe { get; set; }
    public int ThuTu { get; set; }
}
