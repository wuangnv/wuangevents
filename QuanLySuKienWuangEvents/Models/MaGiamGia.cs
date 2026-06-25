namespace QuanLySuKienWuangEvents.Models;

public class MaGiamGia
{
    public int Id { get; set; }
    public Guid SuKienId { get; set; }
    public string MaCode { get; set; } = "";
    public string? MoTa { get; set; }
    public byte LoaiGiamGia { get; set; }
    public decimal GiaTri { get; set; }
    public decimal? GiamToiDa { get; set; }
    public decimal? DonToiThieu { get; set; }
    public int SoLuongTong { get; set; }
    public int SoLuongDaDung { get; set; }
    public DateTime NgayBatDau { get; set; }
    public DateTime NgayKetThuc { get; set; }
    public bool TrangThai { get; set; }
    public DateTime NgayTao { get; set; }
}
