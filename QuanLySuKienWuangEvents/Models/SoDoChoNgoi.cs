namespace QuanLySuKienWuangEvents.Models;

public class SoDoChoNgoi
{
    public int Id { get; set; }
    public Guid SuKienId { get; set; }
    public string TenSoDo { get; set; } = "";
    public DateTime NgayTao { get; set; }
}
