namespace QuanLySuKienWuangEvents.Models;

public class DanhMuc
{
    public int Id { get; set; }
    public string TenDanhMuc { get; set; } = "";
    public string? MoTa { get; set; }
    public string? Icon { get; set; }
    public int ThuTu { get; set; }
    public bool TrangThai { get; set; }
}
