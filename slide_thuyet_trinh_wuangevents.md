# SLIDE THUYẾT TRÌNH BÁO CÁO LUẬN VĂN TỐT NGHIỆP
## ĐỀ TÀI: HỆ THỐNG QUẢN LÝ SỰ KIỆN VÀ ĐẶT VÉ TRỰC TUYẾN - WUANGEVENTS

---

## 📌 SLIDE 1: TRANG TIÊU ĐỀ (TITLE SLIDE)
* **Tiêu đề báo cáo**: HỆ THỐNG QUẢN LÝ SỰ KIỆN VÀ ĐẶT VÉ TRỰC TUYẾN (WUANGEVENTS)
* **Loại hình**: Báo cáo Luận văn Tốt nghiệp ĐH / Đồ án Tốt nghiệp
* **Sinh viên thực hiện**: Nguyễn Vinh Quang
* **Mã số sinh viên**: DH52201310
* **Công nghệ sử dụng**: ASP.NET Core 9.0 MVC, SQL Server, Dapper ORM, VNPay API, QRCoder Library.
* **Thời gian thực hiện**: 05/2026 - 07/2026

---

## 📌 SLIDE 2: LÝ DO CHỌN ĐỀ TÀI & TÍNH CẤP THIẾT
* **Bối cảnh thực tế**: 
  * Ngành công nghiệp giải trí, âm nhạc và sự kiện tại Việt Nam phát triển bùng nổ.
  * Nhu cầu đặt vé trực tuyến nhanh chóng, tiện lợi của người dùng ngày càng cao.
* **Vấn đề của phương thức truyền thống**:
  * Xếp hàng mua vé giấy tốn thời gian, dễ thất lạc.
  * Tình trạng ve vé, vé giả, hoặc gian lận thanh toán.
  * Ban tổ chức khó quản lý sơ đồ chỗ ngồi và doanh thu theo thời gian thực.
* **Giải pháp WuangEvents**:
  * Nền tảng web tập trung kết nối **4 đối tượng**: Khách hàng, Ban tổ chức, Quản trị viên và Nhân viên soát vé.

---

## 📌 SLIDE 3: MỤC TIÊU CỦA HỆ THỐNG
* **Đối với Khách hàng**:
  * Tìm kiếm sự kiện dễ dàng theo từ khóa, danh mục, địa điểm.
  * Chọn ghế trực quan trên sơ đồ chỗ ngồi.
  * Thanh toán trực tuyến an toàn qua **VNPay** và nhận ngay vé điện tử chứa **Mã QR Code**.
* **Đối với Ban tổ chức (Organizer)**:
  * Đăng bán sự kiện, thiết lập các loại vé (VIP, Thường...) và sơ đồ ghế.
  * Theo dõi danh sách đơn hàng và báo cáo doanh thu minh bạch.
* **Đối với Quản trị viên (Admin) & Nhân viên (Staff)**:
  * Admin kiểm duyệt sự kiện trước khi công khai.
  * Staff quét mã QR Code trên vé điện tử tại cổng để soát vé (Check-in) nhanh chóng.

---

## 📌 SLIDE 4: KIẾN TRÚC HỆ THỐNG VÀ CÔNG NGHỆ (TECH STACK)
* **Mô hình kiến trúc**: **ASP.NET Core MVC** (Model - View - Controller).
* **Tương tác Cơ sở dữ liệu**:
  * Sử dụng **Dapper ORM** kết hợp lớp tĩnh custom **`Db.cs`**.
  * Tối ưu hiệu năng truy vấn SQL trực tiếp, phản hồi dữ liệu cực nhanh.
* **Xác thực & Phân quyền**:
  * **Cookie Authentication & Claims**: Phân quyền 4 vai trò (*Quản trị viên, Ban tổ chức, Nhân viên, Khách hàng*).
  * Mã hóa mật khẩu an toàn tuyệt đối bằng thuật toán **BCrypt**.
* **Tích hợp dịch vụ bên thứ ba**:
  * Cổng thanh toán **VNPay API** (Xác thực chữ ký số **HMACSHA512**).
  * Thư viện **QRCoder**: Sinh mã QR Code động cho vé điện tử.

---

## 📌 SLIDE 5: THIẾT KẾ CƠ SỞ DỮ LIỆU (DATABASE SCHEMA)
* **Các bảng thực thể chính**:
  * `NguoiDung`: Lưu tài khoản, vai trò và thông tin cá nhân.
  * `SuKien`: Thông tin sự kiện, thời gian, địa điểm, trạng thái phê duyệt.
  * `LoaiVe`: Định nghĩa vé VIP, vé Thường, số lượng, giá tiền.
  * `KhuVuc`, `HangGhe`, `ChoNgoi`: Lưu thông tin sơ đồ chỗ ngồi động.
  * `DonHang`, `ChiTietDonHang`: Thông tin mua vé, mã đơn hàng, trạng thái thanh toán.
  * `MaGiamGia`: Quản lý mã ưu đãi/voucher.
* **Cơ chế tự động hóa CSDL**:
  * Hàm `GiaiPhongDonHangHetHan()`: Tự động nhả ghế/vé của các đơn hàng quá 15 phút chưa thanh toán.

---

## 📌 SLIDE 6: PHÂN HỆ KHÁCH HÀNG (CUSTOMER MODULE)
* **Khám phá sự kiện**:
  * Trang chủ linh hoạt: Tìm kiếm theo từ khóa, lọc theo Danh mục (Âm nhạc, Thể thao...) và Tỉnh/Thành phố.
  * Trang Chi tiết sự kiện hiển thị đầy đủ thông tin, thời gian, mô tả và bảng giá vé.
* **Quy trình Đặt vé & Thanh toán**:
  * Chọn số lượng vé / vị trí ghế mong muốn.
  * Nhập mã giảm giá (nếu có).
  * Chuyển hướng sang VNPay thanh toán qua Thẻ ATM / QR Banking.
  * Trả về kết quả giao diện kèm **Mã QR Code vé điện tử độc bản**.

---

## 📌 SLIDE 7: PHÂN HỆ BAN TỔ CHỨC (ORGANIZER MODULE)
* **Tạo & Quản lý Sự kiện**:
  * Đăng ký trở thành Nhà tổ chức sự kiện.
  * Tạo mới sự kiện: Nhập thông tin, thời gian, địa điểm, upload poster ảnh.
* **Thiết lập Vé & Sơ đồ vị trí**:
  * Tạo các loại vé khác nhau với mức giá riêng biệt.
  * Thiết lập sơ đồ khu vực (Khu VVIP, VIP, Standard) và số lượng chỗ ngồi.
* **Quản lý Bán vé**:
  * Xem danh sách đơn hàng đã đặt của sự kiện.
  * Theo dõi biểu đồ và con số thống kê doanh thu theo thời gian thực.

---

## 📌 SLIDE 8: PHÂN HỆ QUẢN TRỊ VIÊN & NHÂN VIÊN (ADMIN & STAFF)
* **Chức năng Quản trị viên (Admin)**:
  * Duyệt hoặc Từ chối các sự kiện do Ban tổ chức gửi lên (chỉ sự kiện được duyệt mới xuất hiện trên trang chủ).
  * Quản lý người dùng: Khóa / Mở khóa tài khoản vi phạm.
  * Quản lý danh mục sự kiện hệ thống.
* **Chức năng Nhân viên soát vé (Staff)**:
  * Giao diện tối ưu cho thiết bị di động.
  * Quét mã **QR Code** trên điện thoại khách hàng để soát vé tại cổng.
  * Cập nhật trạng thái vé thành "Đã Check-in" ngay lập tức, chống vé dùng lại.

---

## 📌 SLIDE 9: CÁC ĐIỂM NỔI BẬT & ĐÓNG GÓP KỸ THUẬT
1. **Hiệu năng cao với Dapper**:
   * Xây dựng helper `Db.cs` bọc Dapper giúp tối ưu tốc độ đọc CSDL gấp 5-10 lần so với EF Core thông thường.
2. **Cơ chế nhả vé thông minh (15-min Ticket Hold Release)**:
   * Giúp hệ thống tránh tình trạng ngâm đơn hàng hoặc giữ chỗ ảo.
3. **Bảo mật thanh toán an toàn**:
   * Kiểm tra mã hóa chữ ký HMACSHA512 2 chiều giữa Hệ thống và VNPay.
4. **Trải nghiệm người dùng tốt**:
   * Giao diện hiện đại, responsive thích ứng trên cả máy tính và điện thoại.

---

## 📌 SLIDE 10: KẾT QUẢ ĐẠT ĐƯỢC VÀ HƯỚNG PHÁT TRIỂN
* **Kết quả đạt được**:
  * Xây dựng hoàn chỉnh hệ thống web WuangEvents đạt 100% các mục tiêu đề ra.
  * Đã kiểm thử và chạy thực tế các luồng: Đăng ký -> Tạo sự kiện -> Duyệt sự kiện -> Đặt vé -> Thanh toán VNPay -> Soát vé QR Code.
* **Hướng phát triển trong tương lai**:
  * Tích hợp thêm các cổng thanh toán MoMo, ZaloPay.
  * Phát triển ứng dụng di động Mobile App bằng Flutter cho Nhân viên soát vé.
  * Ứng dụng AI để gợi ý sự kiện phù hợp với sở thích cá nhân từng người dùng.

---

## 📌 SLIDE 11: TRANG KẾT THÚC & Q&A
* **Lời cảm ơn**:
  * Em xin chân thành cảm ơn Hội đồng Phản biện và Thầy/Cô Hướng dẫn đã lắng nghe bài báo cáo!
* **Q&A**:
  * Em xin sẵn sàng nhận ý kiến đóng góp và trả lời các câu hỏi từ Hội đồng Phản biện.
