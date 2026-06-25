namespace QuanLySuKienWuangEvents.Models;

public class ChoNgoi
{
    public int Id { get; set; }
    public int HangGheId { get; set; }
    public string SoGhe { get; set; } = "";
    public int? ViTriX { get; set; }
    public int? ViTriY { get; set; }
    public byte TrangThai { get; set; }
}
