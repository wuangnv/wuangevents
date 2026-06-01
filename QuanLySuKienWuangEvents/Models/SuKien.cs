namespace QuanLySuKienWuangEvents.Models;

public class SuKien
{
    public Guid Id { get; set; }
    public Guid NguoiToChucId { get; set; }
    public int DanhMucId { get; set; }
    public string TenSuKien { get; set; } = "";
    public string Slug { get; set; } = "";
    public string? MoTaNgan { get; set; }
    public string? MoTaChiTiet { get; set; }
    public string? AnhBia { get; set; }
    public string? AnhThumbnail { get; set; }
    public DateTime NgayBatDau { get; set; }
    public DateTime NgayKetThuc { get; set; }
    public byte LoaiSuKien { get; set; }
    public string? LinkOnline { get; set; }
    public bool CoSoDoChoNgoi { get; set; }
    public byte TrangThai { get; set; }
    public string? LyDoTuChoi { get; set; }
    public bool HienThiCongKhai { get; set; }
    public DateTime NgayTao { get; set; }
    public DateTime? NgayCapNhat { get; set; }
    public DateTime? BatDauCheckIn { get; set; }
    public DateTime? KetThucCheckIn { get; set; }

    // Thông tin địa điểm được gộp trực tiếp vào sự kiện
    public string? TenDiaDiem { get; set; }
    public string? DiaChiDiaDiem { get; set; }
    public string? ThanhPhoDiaDiem { get; set; }
    public string? QuanHuyenDiaDiem { get; set; }
    public int? SucChuaDiaDiem { get; set; }

    // Thông tin thống kê bổ sung (không lưu DB)
    public int VeDaBan { get; set; }
    public decimal DoanhThu { get; set; }
    public int TongVe { get; set; }

    // Danh sách 30 ảnh banner thực tế có sẵn trong wwwroot/uploads/banners/professional/
    private static readonly string[] BannersThucTe = new string[]
    {
        "/uploads/banners/professional/vinhverse-concert.jpg",
        "/uploads/banners/professional/ben-thanh-concert-phuong-linh-x-phan-manh-quynh.jpg",
        "/uploads/banners/professional/gama-music-racing-festival.jpg",
        "/uploads/banners/professional/saigon-midnight-run-2026.jpg",
        "/uploads/banners/professional/vietnam-game-connect-2026.jpg",
        "/uploads/banners/professional/metashow-cham-vao-anh-sang.jpg",
        "/uploads/banners/professional/chef-s-table-modern-vietnamese-dinner.jpg",
        "/uploads/banners/professional/ai-va-future-business-strategy.jpg",
        "/uploads/banners/professional/chao-show-am-sac-viet-nam.jpg",
        "/uploads/banners/professional/le-hieu-va-vu-acoustic-night.jpg",
        "/uploads/banners/professional/sketch-a-rose-visual-concert-experience.jpg",
        "/uploads/banners/professional/anh-tu-special-guest-dong-nhi.jpg",
        "/uploads/banners/professional/cong-dien-mua-he.jpg",
        "/uploads/banners/professional/gitex-vietnam-2026.jpg",
        "/uploads/banners/professional/power-bi-from-data-to-insights.jpg",
        "/uploads/banners/professional/build-better-hcmc-2026.jpg",
        "/uploads/banners/professional/asian-sky-forum-2026-ho-chi-minh-city.jpg",
        "/uploads/banners/professional/charity-gala-one-night-for-children.jpg",
        "/uploads/banners/professional/ho-tram-beach-triathlon.jpg",
        "/uploads/banners/professional/city-yoga-va-wellness-day.jpg",
        "/uploads/banners/professional/dalat-coffee-farm-experience.jpg",
        "/uploads/banners/professional/saigon-street-food-night-walk.jpg",
        "/uploads/banners/professional/hue-100-flavors-michelin-starred-chefs-united.jpg",
        "/uploads/banners/professional/the-viet-margarita-festival-2026.jpg",
        "/uploads/banners/professional/a-o-show-saigon-opera-house.jpg",
        "/uploads/banners/professional/teh-dar-the-highlands-story.jpg",
        "/uploads/banners/professional/art-jamming-va-natural-wine.jpg",
        "/uploads/banners/professional/candle-lab-scent-design-workshop.jpg",
        "/uploads/banners/professional/flower-1969-craft-weekend.jpg",
        "/uploads/banners/professional/the-alma-show-tinh-hoa-viet-nam.jpg"
    };

    public string LayAnhBiaHienThi
    {
        get
        {
            if (!string.IsNullOrWhiteSpace(AnhBia) && 
                !AnhBia.Contains("unsplash") && 
                !AnhBia.Equals("/images/default-event.svg", StringComparison.OrdinalIgnoreCase))
            {
                return AnhBia;
            }

            int index = Math.Abs(Id.GetHashCode()) % BannersThucTe.Length;
            return BannersThucTe[index];
        }
    }
}

