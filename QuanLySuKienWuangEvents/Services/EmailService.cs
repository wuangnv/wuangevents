using System.Net;
using System.Net.Mail;
using Microsoft.Extensions.Configuration;

namespace QuanLySuKienWuangEvents.Services
{
    public class EmailService
    {
        private readonly IConfiguration _config;

        public EmailService(IConfiguration config)
        {
            _config = config;
        }

        private SmtpClient CreateSmtpClient()
        {
            string host = _config["Smtp:Host"] ?? "smtp.gmail.com";
            int port = int.TryParse(_config["Smtp:Port"], out int p) ? p : 587;
            bool enableSsl = bool.TryParse(_config["Smtp:EnableSsl"], out bool ssl) ? ssl : true;
            string username = _config["Smtp:UserName"] ?? "noreply@wuangevents.vn";
            string password = _config["Smtp:Password"] ?? "";

            var client = new SmtpClient(host, port)
            {
                EnableSsl = enableSsl,
                Credentials = new NetworkCredential(username, password)
            };

            return client;
        }

        // 1. GỬI EMAIL XÁC MINH TÀI KHOẢN
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

                // Nếu chưa cấu hình mật khẩu SMTP thực tế, log và trả về thành công giả lập
                string smtpPass = _config["Smtp:Password"] ?? "";
                if (string.IsNullOrEmpty(smtpPass))
                {
                    Console.WriteLine($"[EMAIL STUB] GuiEmailXacMinh -> To: {toEmail}, Link: {callbackUrl}");
                    return true;
                }

                using var client = CreateSmtpClient();
                await client.SendMailAsync(mail);
                return true;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[EMAIL ERROR] GuiEmailXacMinh failed: {ex.Message}");
                return false;
            }
        }

        // 2. GỬI E-TICKET (VÉ ĐIỆN TỬ VÀ MÃ QR) VỀ EMAIL KHI THANH TOÁN THÀNH CÔNG
        public async Task<bool> GuiEmailVeDienTuAsync(string toEmail, string hoTen, string maDonHang, string tenSuKien, string ngayBatDau, string diaDiem, decimal tongTien, List<dynamic> danhSachVe)
        {
            try
            {
                string senderEmail = _config["Smtp:UserName"] ?? "noreply@wuangevents.vn";
                string senderName = _config["Smtp:SenderName"] ?? "WuangEvents Ticketing";

                var mail = new MailMessage
                {
                    From = new MailAddress(senderEmail, senderName),
                    Subject = $"🎟️ Vé điện tử đơn hàng {maDonHang} - {tenSuKien}",
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

                    danhSachVeHtml += $@"
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
                            <h3 style='color:#6b21a8;margin:0 0 8px 0;font-size:16px;'>📍 {WebUtility.HtmlEncode(tenSuKien)}</h3>
                            <p style='margin:4px 0;color:#475569;font-size:13px;'><strong>Thời gian:</strong> {WebUtility.HtmlEncode(ngayBatDau)}</p>
                            <p style='margin:4px 0;color:#475569;font-size:13px;'><strong>Địa điểm:</strong> {WebUtility.HtmlEncode(diaDiem)}</p>
                            <p style='margin:4px 0;color:#475569;font-size:13px;'><strong>Tổng tiền thanh toán:</strong> <span style='color:#059669;font-weight:bold;'>{tongTien:N0} VND</span></p>
                        </div>

                        <h4 style='color:#1e293b;margin:20px 0 10px 0;'>Danh sách vé điện tử ({danhSachVe.Count} vé):</h4>
                        {danhSachVeHtml}

                        <p style='color:#64748b;font-size:13px;line-height:1.5;margin-top:20px;'>
                            💡 <strong>Hướng dẫn soát vé:</strong> Bạn chỉ cần xuất trình mã QR hoặc mã vé này trên điện thoại cho nhân viên soát vé tại cổng sự kiện để check-in.
                        </p>
                        <hr style='border:none;border-top:1px solid #e2e8f0;margin:24px 0;'/>
                        <p style='color:#94a3b8;font-size:12px;text-align:center;margin:0;'>WuangEvents System - Đặt vé sự kiện thông minh</p>
                    </div>
                </div>";

                mail.Body = body;

                string smtpPass = _config["Smtp:Password"] ?? "";
                if (string.IsNullOrEmpty(smtpPass))
                {
                    Console.WriteLine($"[EMAIL STUB] GuiEmailVeDienTu -> To: {toEmail}, Order: {maDonHang}, Event: {tenSuKien}");
                    return true;
                }

                using var client = CreateSmtpClient();
                await client.SendMailAsync(mail);
                return true;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[EMAIL ERROR] GuiEmailVeDienTu failed: {ex.Message}");
                return false;
            }
        }
    }
}
