using Microsoft.Data.SqlClient;
using Dapper;

namespace QuanLySuKienWuangEvents.Models;


public static class Db
{
    private static string _connectionString = "";

    // Lưu connection string lấy từ appsettings.json.
    public static void Init(string connectionString)
    {
        _connectionString = connectionString;
    }

    // Cho phép đọc chuỗi kết nối nhưng không cho code ngoài lớp tự gán lại.
    public static string ConnectionString => _connectionString;

    // Tạo connection thủ công cho nghiệp vụ cần transaction nhiều câu SQL.
    public static SqlConnection TaoKetNoi()
    {
        return new SqlConnection(_connectionString);
    }

    // SELECT nhiều dòng; T là kiểu Model cần nhận, ví dụ DonHang hoặc SuKien.
    public static async Task<List<T>> LayDanhSach<T>(string sql, object? param = null)
    {
        // using var tự đóng/giải phóng connection khi hàm kết thúc hoặc bị lỗi.
        using var connection = new SqlConnection(_connectionString);

        // Dapper chạy SQL và ghép cột kết quả vào property cùng tên của T.
        var result = await connection.QueryAsync<T>(sql, param);
        return result.ToList();
    }

    // SELECT một dòng đầu tiên; trả null nếu SQL không tìm thấy bản ghi.
    public static async Task<T?> LayDonLe<T>(string sql, object? param = null)
    {
        using var connection = new SqlConnection(_connectionString);
        return await connection.QueryFirstOrDefaultAsync<T>(sql, param);
    }

    // Chạy INSERT/UPDATE/DELETE và trả số dòng đã bị tác động.
    public static async Task<int> ThucThi(string sql, object? param = null)
    {
        using var connection = new SqlConnection(_connectionString);
        return await connection.ExecuteAsync(sql, param);
    }

    // Lấy một ô duy nhất như COUNT(*), SUM(...) hoặc một tên/Id.
    public static async Task<T?> LayGiaTri<T>(string sql, object? param = null)
    {
        using var connection = new SqlConnection(_connectionString);
        return await connection.ExecuteScalarAsync<T>(sql, param);
    }

    // Nâng cấp idempotent cho CSDL cũ: không thêm bảng mới, chỉ bổ sung dữ liệu cần thiết
    // để cùng một bố cục được hiển thị chính xác ở Designer và trang chọn ghế.
    public static async Task DamBaoSchemaSoDoChoNgoiStudioAsync()
    {
        const string sql = @"
IF OBJECT_ID(N'dbo.SoDoChoNgoi', N'U') IS NOT NULL
BEGIN
    IF COL_LENGTH(N'dbo.SoDoChoNgoi', N'CanvasRong') IS NULL
        ALTER TABLE dbo.SoDoChoNgoi ADD CanvasRong INT NOT NULL CONSTRAINT DF_SoDoChoNgoi_CanvasRong DEFAULT (960);
    IF COL_LENGTH(N'dbo.SoDoChoNgoi', N'CanvasCao') IS NULL
        ALTER TABLE dbo.SoDoChoNgoi ADD CanvasCao INT NOT NULL CONSTRAINT DF_SoDoChoNgoi_CanvasCao DEFAULT (650);
    IF COL_LENGTH(N'dbo.SoDoChoNgoi', N'SanKhauRong') IS NULL
        ALTER TABLE dbo.SoDoChoNgoi ADD SanKhauRong INT NOT NULL CONSTRAINT DF_SoDoChoNgoi_SanKhauRong DEFAULT (280);
    IF COL_LENGTH(N'dbo.SoDoChoNgoi', N'SanKhauCao') IS NULL
        ALTER TABLE dbo.SoDoChoNgoi ADD SanKhauCao INT NOT NULL CONSTRAINT DF_SoDoChoNgoi_SanKhauCao DEFAULT (44);
    IF COL_LENGTH(N'dbo.SoDoChoNgoi', N'NhanSanKhau') IS NULL
        ALTER TABLE dbo.SoDoChoNgoi ADD NhanSanKhau NVARCHAR(100) NOT NULL CONSTRAINT DF_SoDoChoNgoi_NhanSanKhau DEFAULT (N'SÂN KHẤU');

    IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_SoDoChoNgoi_LoaiSoDo')
        ALTER TABLE dbo.SoDoChoNgoi DROP CONSTRAINT CK_SoDoChoNgoi_LoaiSoDo;
    ALTER TABLE dbo.SoDoChoNgoi ADD CONSTRAINT CK_SoDoChoNgoi_LoaiSoDo
        CHECK (LoaiSoDo IN (N'workshop', N'auditorium', N'concert', N'gala', N'arena', N'custom',
                             N'theatre', N'cinema'));
END;

IF OBJECT_ID(N'dbo.KhuVuc', N'U') IS NOT NULL
BEGIN
    IF COL_LENGTH(N'dbo.KhuVuc', N'Rong') IS NULL
        ALTER TABLE dbo.KhuVuc ADD Rong INT NOT NULL CONSTRAINT DF_KhuVuc_Rong DEFAULT (0);
    IF COL_LENGTH(N'dbo.KhuVuc', N'Cao') IS NULL
        ALTER TABLE dbo.KhuVuc ADD Cao INT NOT NULL CONSTRAINT DF_KhuVuc_Cao DEFAULT (0);
    IF COL_LENGTH(N'dbo.KhuVuc', N'LoaiKhuVuc') IS NULL
        ALTER TABLE dbo.KhuVuc ADD LoaiKhuVuc VARCHAR(10) NOT NULL CONSTRAINT DF_KhuVuc_Loai DEFAULT ('seated');
    IF COL_LENGTH(N'dbo.KhuVuc', N'SucChua') IS NULL
        ALTER TABLE dbo.KhuVuc ADD SucChua INT NULL;
    IF COL_LENGTH(N'dbo.KhuVuc', N'TienToHangGhe') IS NULL
        ALTER TABLE dbo.KhuVuc ADD TienToHangGhe NVARCHAR(10) NOT NULL CONSTRAINT DF_KhuVuc_TienTo DEFAULT (N'');
    IF COL_LENGTH(N'dbo.KhuVuc', N'KieuDanhSo') IS NULL
        ALTER TABLE dbo.KhuVuc ADD KieuDanhSo VARCHAR(10) NOT NULL CONSTRAINT DF_KhuVuc_KieuDanhSo DEFAULT ('ltr');
    IF COL_LENGTH(N'dbo.KhuVuc', N'SoBatDau') IS NULL
        ALTER TABLE dbo.KhuVuc ADD SoBatDau INT NOT NULL CONSTRAINT DF_KhuVuc_SoBatDau DEFAULT (1);
    IF COL_LENGTH(N'dbo.KhuVuc', N'BoQuaChuDeNham') IS NULL
        ALTER TABLE dbo.KhuVuc ADD BoQuaChuDeNham BIT NOT NULL CONSTRAINT DF_KhuVuc_BoQuaChu DEFAULT (1);

    -- CSDL cũ có ràng buộc chỉ gồm seated/ga; phải thay thế để hỗ trợ bàn tiệc (banquet).
    IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_KhuVuc_LoaiKhuVuc')
        ALTER TABLE dbo.KhuVuc DROP CONSTRAINT CK_KhuVuc_LoaiKhuVuc;
    EXEC(N'ALTER TABLE dbo.KhuVuc ADD CONSTRAINT CK_KhuVuc_LoaiKhuVuc CHECK (LoaiKhuVuc IN (''seated'', ''ga'', ''banquet''))');
END;";

        using var connection = new SqlConnection(_connectionString);
        await connection.ExecuteAsync(sql);
    }

    // Các sơ đồ tạo trước Studio chỉ có hàng/ghế, chưa có kích thước/toạ độ tuyệt đối.
    // Tự bổ sung bố cục dạng flow để không bị chồng, cắt hoặc xuất hiện thanh cuộn bên trong khu.
    public static async Task ChuanHoaBoCucSoDoCuAsync()
    {
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();
        var mapIds = (await connection.QueryAsync<int>(@"
            SELECT DISTINCT sd.Id
            FROM SoDoChoNgoi sd
            JOIN KhuVuc k ON k.SoDoChoNgoiId = sd.Id
            WHERE ISNULL(k.Rong, 0) = 0 OR ISNULL(k.Cao, 0) = 0")).ToList();

        foreach (int mapId in mapIds)
        {
            var zones = (await connection.QueryAsync<LegacyZoneLayout>(@"
                SELECT k.Id, k.LoaiKhuVuc, k.SucChua, k.ThuTu,
                       COUNT(DISTINCT h.Id) AS SoHang,
                       ISNULL(MAX(h.SoGhe), 0) AS SoGheMoiHang
                FROM KhuVuc k
                LEFT JOIN HangGhe h ON h.KhuVucId = k.Id
                WHERE k.SoDoChoNgoiId = @mapId
                GROUP BY k.Id, k.LoaiKhuVuc, k.SucChua, k.ThuTu
                ORDER BY k.ThuTu, k.Id", new { mapId })).ToList();

            const int canvasWidth = 1500;
            const int margin = 50;
            const int gap = 36;
            int x = margin, y = 150, rowHeight = 0;
            var placements = new List<(int id, int x, int y, int width, int height)>();

            foreach (var zone in zones)
            {
                bool isGa = string.Equals(zone.LoaiKhuVuc, "ga", StringComparison.OrdinalIgnoreCase);
                int width = isGa ? 240 : Math.Clamp(50 + Math.Max(1, zone.SoGheMoiHang) * 32, 180, 1100);
                int height = isGa ? 130 : Math.Clamp(56 + Math.Max(1, zone.SoHang) * 30, 112, 850);
                if (x + width > canvasWidth - margin && x > margin)
                {
                    x = margin;
                    y += rowHeight + gap;
                    rowHeight = 0;
                }
                placements.Add((zone.Id, x, y, width, height));
                x += width + gap;
                rowHeight = Math.Max(rowHeight, height);
            }

            int canvasHeight = Math.Clamp(y + rowHeight + margin, 650, 1100);
            using var transaction = connection.BeginTransaction();
            try
            {
                await connection.ExecuteAsync(@"
                    UPDATE SoDoChoNgoi
                    SET CanvasRong = @canvasWidth, CanvasCao = @canvasHeight,
                        SanKhauX = @stageX, SanKhauY = 36,
                        SanKhauRong = 360, SanKhauCao = 48,
                        NhanSanKhau = N'SÂN KHẤU'
                    WHERE Id = @mapId", new
                {
                    mapId,
                    canvasWidth,
                    canvasHeight,
                    stageX = (canvasWidth - 360) / 2
                }, transaction);
                foreach (var placement in placements)
                {
                    await connection.ExecuteAsync(@"
                        UPDATE KhuVuc
                        SET ViTriX = @x, ViTriY = @y, Rong = @width, Cao = @height,
                            LoaiKhuVuc = ISNULL(NULLIF(LoaiKhuVuc, ''), 'seated')
                        WHERE Id = @id", new
                    {
                        id = placement.id,
                        x = placement.x,
                        y = placement.y,
                        width = placement.width,
                        height = placement.height
                    }, transaction);
                }
                await transaction.CommitAsync();
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        }
    }

    private sealed class LegacyZoneLayout
    {
        public int Id { get; set; }
        public string? LoaiKhuVuc { get; set; }
        public int? SucChua { get; set; }
        public int ThuTu { get; set; }
        public int SoHang { get; set; }
        public int SoGheMoiHang { get; set; }
    }
}
