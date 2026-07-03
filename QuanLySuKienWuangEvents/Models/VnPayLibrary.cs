// VNPAY LIBRARY — Thư viện xử lý thanh toán VNPAY
// Chức năng:
//   - Thu thập thông tin giao dịch (AddRequestData)
//   - Sắp xếp và mã hóa tham số theo chuẩn API VNPAY 2.1.0
//   - Tạo chữ ký bảo mật HMAC-SHA512 (vnp_SecureHash)
//   - Xác thực chữ ký nhận về từ VNPAY để tránh hack/giao dịch ảo

using System.Globalization;
using System.Net;
using System.Security.Cryptography;
using System.Text;
using System.Web;

namespace QuanLySuKienWuangEvents.Models;

public class VnPayLibrary
{
    // Chứa dữ liệu gửi đi (Request)
    private readonly SortedList<string, string> _requestData = new SortedList<string, string>(new VnPayCompare());
    
    // Chứa dữ liệu phản hồi về (Response)
    private readonly SortedList<string, string> _responseData = new SortedList<string, string>(new VnPayCompare());

    // Thêm dữ liệu gửi đi
    public void AddRequestData(string key, string value)
    {
        if (!string.IsNullOrEmpty(value))
        {
            _requestData.Add(key, value);
        }
    }

    // Thêm dữ liệu nhận về từ VNPAY callback
    public void AddResponseData(string key, string value)
    {
        if (!string.IsNullOrEmpty(value))
        {
            _responseData.Add(key, value);
        }
    }

    // Lấy giá trị phản hồi theo key
    public string GetResponseData(string key)
    {
        return _responseData.TryGetValue(key, out var val) ? val : string.Empty;
    }

    // Tạo URL thanh toán hoàn chỉnh gửi sang VNPAY
    public string CreateRequestUrl(string baseUrl, string hashSecret)
    {
        var stringBuilder = new StringBuilder();
        
        // Nối chuỗi tham số: key1=value1&key2=value2...
        foreach (var keyValuePair in _requestData)
        {
            if (!string.IsNullOrEmpty(keyValuePair.Value))
            {
                stringBuilder.Append(WebUtility.UrlEncode(keyValuePair.Key) + "=" + WebUtility.UrlEncode(keyValuePair.Value) + "&");
            }
        }

        string query = stringBuilder.ToString();
        string url = baseUrl + "?" + query;

        // Tạo chuỗi ký (Sign Data)
        var signBuilder = new StringBuilder();
        foreach (var keyValuePair in _requestData)
        {
            if (!string.IsNullOrEmpty(keyValuePair.Value))
            {
                signBuilder.Append(keyValuePair.Key + "=" + WebUtility.UrlEncode(keyValuePair.Value) + "&");
            }
        }

        string rawData = signBuilder.ToString();
        // Cắt bỏ ký tự '&' cuối cùng
        if (rawData.EndsWith("&"))
        {
            rawData = rawData.Remove(rawData.Length - 1);
        }

        // Tạo mã băm SecureHash bằng thuật toán HMAC-SHA512
        string secureHash = HmacSha512(hashSecret, rawData);
        url += "vnp_SecureHash=" + secureHash;

        return url;
    }

    // Xác thực chữ ký phản hồi từ VNPAY có hợp lệ không
    public bool ValidateSignature(string inputHash, string secretKey)
    {
        var signBuilder = new StringBuilder();
        
        // Duyệt qua tất cả tham số phản hồi, loại bỏ vnp_SecureHash và vnp_SecureHashType
        foreach (var keyValuePair in _responseData)
        {
            if (!string.IsNullOrEmpty(keyValuePair.Value) && keyValuePair.Key != "vnp_SecureHash" && keyValuePair.Key != "vnp_SecureHashType")
            {
                signBuilder.Append(keyValuePair.Key + "=" + WebUtility.UrlEncode(keyValuePair.Value) + "&");
            }
        }

        string rawData = signBuilder.ToString();
        if (rawData.EndsWith("&"))
        {
            rawData = rawData.Remove(rawData.Length - 1);
        }

        // Tính toán mã băm mới và so sánh với SecureHash nhận được
        string myChecksum = HmacSha512(secretKey, rawData);
        return myChecksum.Equals(inputHash, StringComparison.InvariantCultureIgnoreCase);
    }

    // Hàm băm HMAC-SHA512
    private static string HmacSha512(string key, string inputData)
    {
        var hash = new StringBuilder();
        byte[] keyBytes = Encoding.UTF8.GetBytes(key);
        byte[] inputBytes = Encoding.UTF8.GetBytes(inputData);
        
        using (var hmac = new HMACSHA512(keyBytes))
        {
            byte[] hashValue = hmac.ComputeHash(inputBytes);
            foreach (byte theByte in hashValue)
            {
                hash.Append(theByte.ToString("x2"));
            }
        }
        return hash.ToString();
    }
}

// Lớp so sánh chuỗi theo chuẩn tăng dần bảng chữ cái của VNPAY
public class VnPayCompare : IComparer<string>
{
    public int Compare(string? x, string? y)
    {
        if (x == y) return 0;
        if (x == null) return -1;
        if (y == null) return 1;
        
        var vnpCompare = CompareInfo.GetCompareInfo("en-US");
        return vnpCompare.Compare(x, y, CompareOptions.Ordinal);
    }
}
