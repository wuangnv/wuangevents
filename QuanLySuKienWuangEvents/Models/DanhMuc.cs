namespace QuanLySuKienWuangEvents.Models;

// MODEL ánh xạ với bảng DanhMuc.
// Một dòng DanhMuc dùng để phân nhóm nhiều sự kiện, ví dụ Âm nhạc hoặc Thể thao.
public class DanhMuc
{
    // INT IDENTITY trong SQL: khóa chính tự tăng.
    public int Id { get; set; }

    // = "" tạo chuỗi rỗng mặc định để property bắt buộc không bị null trong C#.
    public string TenDanhMuc { get; set; } = "";

    // Dấu ? cho phép cột/property không có giá trị.
    public string? MoTa { get; set; }

    // Tên lớp biểu tượng Font Awesome mà View đưa vào thẻ <i>.
    public string? Icon { get; set; }

    // Số nhỏ đứng trước khi SQL ORDER BY ThuTu.
    public int ThuTu { get; set; }

    // BIT trong SQL: true đang hiển thị, false đang ẩn.
    public bool TrangThai { get; set; }
}
