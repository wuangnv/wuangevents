namespace QuanLySuKienWuangEvents.Models;

// MODEL ánh xạ bảng ChoNgoi: một ghế cụ thể nằm trong một HangGhe.
public class ChoNgoi
{
    public int Id { get; set; }

    // Khóa ngoại tới HangGhe.
    public int HangGheId { get; set; }

    // Nhãn con người đọc như A01 hoặc VIP-05.
    public string SoGhe { get; set; } = "";

    // Tọa độ tùy chọn để View/JavaScript bố trí ghế.
    public int? ViTriX { get; set; }
    public int? ViTriY { get; set; }

    // Schema: 0 trống, 1 đang giữ trong lúc thanh toán, 2 đã bán, 3 khóa.
    public byte TrangThai { get; set; }
}
