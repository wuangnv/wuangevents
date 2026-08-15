using System.Net;
using System.Net.Mail;
using Microsoft.Extensions.Configuration;

namespace QuanLySuKienWuangEvents.Services
{
    // Service gửi email xác minh/vé; Controller nhận qua dependency injection.
    public class EmailService
    {
        private readonly IConfiguration _config;
        private readonly ILogger<EmailService> _logger;

        public EmailService(IConfiguration config, ILogger<EmailService> logger)
        {
            _config = config;
            _logger = logger;
        }

        // Đọc cấu hình Smtp:* từ IConfiguration/appsettings và dựng SMTP client.
        private SmtpClient CreateSmtpClient()
        {
            // ?? cung cấp giá trị mặc định khi khóa cấu hình không tồn tại.
            string host = _config["Smtp:Host"] ?? "smtp.gmail.com";
            int port = int.TryParse(_config["Smtp:Port"], out int p) ? p : 587;
            bool enableSsl = bool.TryParse(_config["Smtp:EnableSsl"], out bool ssl) ? ssl : true;
            string username = _config["Smtp:UserName"] ?? "noreply@wuangevents.vn";
            string password = _config["Smtp:Password"] ?? "";

            // Object initializer gán nhiều property ngay khi new SmtpClient.
            var client = new SmtpClient(host, port)
            {
                EnableSsl = enableSsl,
                Credentials = new NetworkCredential(username, password)
            };

            return client;
        }

        // 1. GỬI EMAIL XÁC MINH TÀI KHOẢN
        // Trả true nếu gửi được (hoặc đang chạy stub), false nếu có Exception.
        public async Task<bool> GuiEmailXacMinhAsync(string toEmail, string hoTen, string token, string callbackUrl)
        {
            try
            {
                string senderEmail = _config["Smtp:UserName"] ?? "noreply@wuangevents.vn";
                string senderName = _config["Smtp:SenderName"] ?? "WuangEvents System";

                var mail = new MailMessage
                {
                    From = new MailAddress(senderEmail, senderName),
                    Subject = "🎯 Xác minh tài khoản WuangEvents của bạn",
                    IsBodyHtml = true
                };

                mail.To.Add(new MailAddress(toEmail, hoTen));

                // $@ tạo chuỗi HTML nhiều dòng có thể chèn biến bằng {tenBien}.
                // HtmlEncode dữ liệu người dùng trước khi ghép vào HTML email.
                string body = $@"
                <div style='font-family:Arial,sans-serif;max-width:600px;margin:0 auto;padding:20px;background:#f8fafc;border-radius:12px;'>
                    <div style='background:#7c3aed;padding:24px;border-radius:12px 12px 0 0;text-align:center;'>
                        <h1 style='color:#fff;margin:0;font-size:24px;'>WuangEvents</h1>
                        <p style='color:#ddd6fe;margin:5px 0 0 0;'>Nền tảng quản lý sự kiện & bán vé hàng đầu</p>
                    </div>
                    <div style='background:#fff;padding:24px;border-radius:0 0 12px 12px;box-shadow:0 4px 6px rgba(0,0,0,0.05);'>
                        <h2 style='color:#1e293b;margin-top:0;'>Xin chào {WebUtility.HtmlEncode(hoTen)},</h2>
                        <p style='color:#475569;line-height:1.6;'>Cảm ơn bạn đã đăng ký tài khoản tại WuangEvents. Để kích hoạt tài khoản và tiếp tục đặt vé sự kiện, vui lòng nhấp vào nút xác minh bên dưới:</p>
                        <div style='text-align:center;margin:30px 0;'>
                            <a href='{callbackUrl}' style='background:#7c3aed;color:#fff;text-decoration:none;padding:14px 28px;border-radius:8px;font-weight:bold;display:inline-block;'>Xác Minh Email Ngay</a>
                        </div>
                        <p style='color:#94a3b8;font-size:13px;line-height:1.5;'>Nếu nút bấm trên không hoạt động, bạn có thể copy liên kết sau vào trình duyệt:<br/><a href='{callbackUrl}' style='color:#7c3aed;'>{callbackUrl}</a></p>
                        <hr style='border:none;border-top:1px solid #e2e8f0;margin:24px 0;'/>
                        <p style='color:#94a3b8;font-size:12px;text-align:center;margin:0;'>Trân trọng,<br/>Đội ngũ WuangEvents</p>
                    </div>
                </div>";

                mail.Body = body;

                // Không báo gửi thành công khi server chưa có thông tin đăng nhập SMTP.
                string smtpPass = _config["Smtp:Password"] ?? "";
                if (string.IsNullOrEmpty(smtpPass))
                {
                    _logger.LogWarning("SMTP chưa cấu hình; không gửi email xác minh tới {Email}", toEmail);
                    return false;
                }

                using var client = CreateSmtpClient();
                await client.SendMailAsync(mail);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Không gửi được email xác minh tới {Email}", toEmail);
                return false;
            }
        }

        public async Task<bool> GuiEmailDatLaiMatKhauAsync(
            string toEmail, string hoTen, string callbackUrl)
        {
            try
            {
                string senderEmail = _config["Smtp:UserName"] ?? "noreply@wuangevents.vn";
                string senderName = _config["Smtp:SenderName"] ?? "WuangEvents System";
                string smtpPass = _config["Smtp:Password"] ?? "";
                if (string.IsNullOrWhiteSpace(smtpPass))
                {
                    _logger.LogWarning("SMTP chưa cấu hình; không gửi email đặt lại mật khẩu tới {Email}", toEmail);
                    return false;
                }

                using var mail = new MailMessage
                {
                    From = new MailAddress(senderEmail, senderName),
                    Subject = "Đặt lại mật khẩu WuangEvents",
                    IsBodyHtml = true,
                    Body = $@"
                    <div style='font-family:Arial,sans-serif;max-width:600px;margin:auto;padding:24px;background:#f8fafc'>
                      <div style='background:#fff;padding:28px;border-radius:12px;border:1px solid #e2e8f0'>
                        <h2 style='color:#1e293b;margin-top:0'>Đặt lại mật khẩu</h2>
                        <p>Xin chào <strong>{WebUtility.HtmlEncode(hoTen)}</strong>,</p>
                        <p style='color:#475569'>Liên kết này có hiệu lực trong 30 phút và chỉ dùng được một lần.</p>
                        <p style='text-align:center;margin:28px 0'>
                          <a href='{WebUtility.HtmlEncode(callbackUrl)}' style='background:#7c3aed;color:#fff;text-decoration:none;padding:13px 24px;border-radius:8px;font-weight:bold'>Đặt lại mật khẩu</a>
                        </p>
                        <p style='color:#64748b;font-size:13px'>Nếu bạn không yêu cầu thao tác này, hãy bỏ qua email.</p>
                      </div>
                    </div>"
                };
                mail.To.Add(new MailAddress(toEmail, hoTen));
                using var client = CreateSmtpClient();
                await client.SendMailAsync(mail);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Không gửi được email đặt lại mật khẩu tới {Email}", toEmail);
                return false;
            }
        }

        // 2. Gửi vé QR cho sự kiện trực tiếp hoặc quyền tham dự cho sự kiện trực tuyến.
        // Sau thanh toán, BookingController truyền danh sách vé động để dựng email.
        public async Task<bool> GuiEmailVeDienTuAsync(
            string toEmail, string hoTen, string maDonHang, string tenSuKien,
            string ngayBatDau, string diaDiem, decimal tongTien, List<dynamic> danhSachVe,
            bool laTrucTuyen, string? linkOnline)
        {
            try
            {
                string senderEmail = _config["Smtp:UserName"] ?? "noreply@wuangevents.vn";
                string senderName = _config["Smtp:SenderName"] ?? "WuangEvents Ticketing";

                var mail = new MailMessage
                {
                    From = new MailAddress(senderEmail, senderName),
                    Subject = laTrucTuyen
                        ? $"💻 Xác nhận tham dự trực tuyến {maDonHang} - {tenSuKien}"
                        : $"🎟️ Vé điện tử đơn hàng {maDonHang} - {tenSuKien}",
                    IsBodyHtml = true
                };

                mail.To.Add(new MailAddress(toEmail, hoTen));

                string danhSachVeHtml = "";
                foreach (var ve in danhSachVe)
                {
                    string maVe = ve.MaVe ?? "VE-" + Random.Shared.Next(1000, 9999);
                    string loaiVe = ve.TenLoaiVe ?? "Vé tham dự";
                    string choNgoi = ve.SoGhe ?? "Vé tự do";
                    string maQr = ve.MaQRCode ?? maVe;

                    danhSachVeHtml += laTrucTuyen ? $@"
                    <div style='background:#f8fafc;border:1px solid #c4b5fd;border-radius:10px;padding:16px;margin-bottom:12px;'>
                        <div style='font-size:12px;color:#64748b;text-transform:uppercase;font-weight:bold;'>Người tham dự</div>
                        <div style='font-size:16px;color:#1e293b;font-weight:800;margin-top:3px;'>{WebUtility.HtmlEncode((string)(ve.TenNguoiThamDu ?? hoTen))}</div>
                        <div style='font-size:13px;color:#475569;margin-top:5px;'>Loại đăng ký: <strong>{WebUtility.HtmlEncode(loaiVe)}</strong></div>
                        <div style='font-size:12px;color:#7c3aed;margin-top:5px;'>Mã đăng ký: {WebUtility.HtmlEncode(maVe)}</div>
                    </div>" : $@"
                    <div style='background:#f8fafc;border:1px dashed #cbd5e1;border-radius:8px;padding:16px;margin-bottom:12px;'>
                        <div style='display:flex;justify-content:space-between;align-items:center;'>
                            <div>
                                <div style='font-size:12px;color:#64748b;text-transform:uppercase;font-weight:bold;'>Mã Vé</div>
                                <div style='font-size:18px;color:#7c3aed;font-weight:900;'>{WebUtility.HtmlEncode(maVe)}</div>
                                <div style='font-size:14px;color:#1e293b;margin-top:4px;'>Loại vé: <strong>{WebUtility.HtmlEncode(loaiVe)}</strong> | Ghế: <strong>{WebUtility.HtmlEncode(choNgoi)}</strong></div>
                            </div>
                            <div style='text-align:right;'>
                                <div style='font-size:11px;color:#059669;background:#d1fae5;padding:4px 8px;border-radius:4px;font-weight:bold;display:inline-block;'>VÉ HỢP LỆ</div>
                                <div style='font-size:11px;color:#64748b;margin-top:6px;'>Mã QR: {WebUtility.HtmlEncode(maQr)}</div>
                            </div>
                        </div>
                    </div>";
                }

                string thamGiaHtml = laTrucTuyen && !string.IsNullOrWhiteSpace(linkOnline)
                    ? $@"<div style='text-align:center;margin:22px 0;'>
                            <a href='{WebUtility.HtmlEncode(linkOnline)}' style='display:inline-block;background:#7c3aed;color:#fff;text-decoration:none;font-weight:bold;padding:13px 24px;border-radius:10px;'>Vào phòng trực tuyến</a>
                         </div>"
                    : "";
                string huongDan = laTrucTuyen
                    ? "Quyền tham dự được gắn với đơn hàng đã thanh toán. Hãy dùng đúng email đăng ký khi vào phòng; sự kiện trực tuyến không cần xuất trình QR để check-in tại cổng."
                    : "Bạn chỉ cần xuất trình mã QR hoặc mã vé này trên điện thoại cho nhân viên soát vé tại cổng sự kiện.";

                string body = $@"
                <div style='font-family:Arial,sans-serif;max-width:640px;margin:0 auto;padding:20px;background:#f1f5f9;border-radius:12px;'>
                    <div style='background:linear-gradient(135deg, #7c3aed 0%, #4f46e5 100%);padding:24px;border-radius:12px 12px 0 0;color:#fff;text-align:center;'>
                        <h1 style='margin:0;font-size:22px;'>🎉 THANH TOÁN THÀNH CÔNG!</h1>
                        <p style='margin:6px 0 0 0;color:#e0e7ff;font-size:14px;'>Cảm ơn bạn đã đặt vé tại WuangEvents</p>
                    </div>
                    <div style='background:#fff;padding:24px;border-radius:0 0 12px 12px;'>
                        <p style='color:#334155;margin-top:0;'>Xin chào <strong>{WebUtility.HtmlEncode(hoTen)}</strong>,</p>
                        <p style='color:#475569;font-size:14px;'>Đơn hàng <strong>#{WebUtility.HtmlEncode(maDonHang)}</strong> của bạn đã được thanh toán thành công. Dưới đây là thông tin vé điện tử của bạn:</p>

                        <div style='background:#faf5ff;border:1px solid #e9d5ff;border-radius:10px;padding:16px;margin:20px 0;'>
                            <h3 style='color:#6b21a8;margin:0 0 8px 0;font-size:16px;'>{(laTrucTuyen ? "💻" : "📍")} {WebUtility.HtmlEncode(tenSuKien)}</h3>
                            <p style='margin:4px 0;color:#475569;font-size:13px;'><strong>Thời gian:</strong> {WebUtility.HtmlEncode(ngayBatDau)}</p>
                            <p style='margin:4px 0;color:#475569;font-size:13px;'><strong>{(laTrucTuyen ? "Hình thức" : "Địa điểm")}:</strong> {WebUtility.HtmlEncode(diaDiem)}</p>
                            <p style='margin:4px 0;color:#475569;font-size:13px;'><strong>Tổng tiền thanh toán:</strong> <span style='color:#059669;font-weight:bold;'>{tongTien:N0} VND</span></p>
                        </div>

                        <h4 style='color:#1e293b;margin:20px 0 10px 0;'>{(laTrucTuyen ? "Danh sách người tham dự" : "Danh sách vé điện tử")} ({danhSachVe.Count}):</h4>
                        {danhSachVeHtml}
                        {thamGiaHtml}

                        <p style='color:#64748b;font-size:13px;line-height:1.5;margin-top:20px;'>
                            💡 <strong>Thông tin tham dự:</strong> {WebUtility.HtmlEncode(huongDan)}
                        </p>
                        <hr style='border:none;border-top:1px solid #e2e8f0;margin:24px 0;'/>
                        <p style='color:#94a3b8;font-size:12px;text-align:center;margin:0;'>WuangEvents System - Đặt vé sự kiện thông minh</p>
                    </div>
                </div>";

                mail.Body = body;

                string smtpPass = _config["Smtp:Password"] ?? "";
                if (string.IsNullOrEmpty(smtpPass))
                {
                    _logger.LogWarning("SMTP chưa cấu hình; không gửi email vé của đơn {OrderCode}", maDonHang);
                    return true;
                }

                using var client = CreateSmtpClient();
                await client.SendMailAsync(mail);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Không gửi được email vé của đơn {OrderCode}", maDonHang);
                return false;
            }
        }
    }
}
