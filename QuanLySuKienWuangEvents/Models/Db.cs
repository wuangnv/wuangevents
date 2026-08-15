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
}
