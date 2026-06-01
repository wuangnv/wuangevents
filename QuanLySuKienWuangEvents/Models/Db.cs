using System.Data;
using Microsoft.Data.SqlClient;
using Dapper;

namespace QuanLySuKienWuangEvents.Models;

/// <summary>
/// Lớp hỗ trợ kết nối và truy vấn Cơ sở dữ liệu sử dụng Dapper.
/// Giúp rút gọn code trong các Controller từ hàng chục dòng xuống còn 1 dòng duy nhất.
/// </summary>
public static class Db
{
    private static string _connectionString = "";

    /// <summary>
    /// Khởi tạo Chuỗi kết nối từ Program.cs
    /// </summary>
    public static void Init(string connectionString)
    {
        _connectionString = connectionString;   
    }

    /// <summary>
    /// Lấy chuỗi kết nối cơ sở dữ liệu hiện tại
    /// </summary>
    public static string ConnectionString => _connectionString;

    /// <summary>
    /// Tạo một kết nối mới (dùng khi cần quản lý transaction thủ công)
    /// </summary>
    public static SqlConnection TaoKetNoi()
    {
        return new SqlConnection(_connectionString);
    }

    /// <summary>
    /// Lấy danh sách dòng dữ liệu ánh xạ vào danh sách Model (ví dụ: List<SuKien>)
    /// </summary>
    public static async Task<List<T>> LayDanhSach<T>(string sql, object? param = null)
    {
        using var connection = new SqlConnection(_connectionString);
        var result = await connection.QueryAsync<T>(sql, param);
        return result.ToList();
    }

    /// <summary>
    /// Lấy một dòng dữ liệu duy nhất hoặc null nếu không tìm thấy (ánh xạ vào Model đơn lẻ)
    /// </summary>
    public static async Task<T?> LayDonLe<T>(string sql, object? param = null)
    {
        using var connection = new SqlConnection(_connectionString);
        return await connection.QueryFirstOrDefaultAsync<T>(sql, param);
    }

    /// <summary>
    /// Thực thi lệnh SQL không trả về dữ liệu (như INSERT, UPDATE, DELETE)
    /// Trả về số dòng bị ảnh hưởng.
    /// </summary>
    public static async Task<int> ThucThi(string sql, object? param = null)
    {
        using var connection = new SqlConnection(_connectionString);
        return await connection.ExecuteAsync(sql, param);
    }

    /// <summary>
    /// Lấy một giá trị đơn duy nhất (ví dụ: lấy COUNT(*), SUM(GiaVe), hoặc lấy ra 1 chuỗi/số lẻ)
    /// </summary>
    public static async Task<T?> LayGiaTri<T>(string sql, object? param = null)
    {
        using var connection = new SqlConnection(_connectionString);
        return await connection.ExecuteScalarAsync<T>(sql, param);
    }
}
