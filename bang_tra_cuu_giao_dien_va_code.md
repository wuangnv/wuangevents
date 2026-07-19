# BẢNG TRA CỨU TOÀN DIỆN GIAO DIỆN & SOURCE CODE PROJET WUANGEVENTS

Dưới đây là Bảng tra cứu toàn bộ 35+ giao diện và các file Controller, View, Model tương ứng trong dự án **WuangEvents**.

---

## 🚀 PHẦN 1: BẢNG MÁP GIAO DIỆN (UI TO CONTROLLER & VIEW MAPPING)

### 1. PHÂN HỆ DÀNH CHO TẤT CẢ NGƯỜI DÙNG & KHÁCH HÀNG (CUSTOMER)

| Tên màn hình / Giao diện | Quyền | Đường dẫn URL | File Controller & Action | File View tương ứng (`Views/`) | Chức năng chính |
| :--- | :---: | :--- | :--- | :--- | :--- |
| **Trang chủ hệ thống** | Tất cả | `/` hoặc `/Home/Index` | `HomeController.cs` -> `Index()` | `Home/Index.cshtml` | Hiển thị banner, danh sách sự kiện hot, lọc theo danh mục, tỉnh thành. |
| **Danh sách sự kiện** | Tất cả | `/Home/SuKien` | `HomeController.cs` -> `SuKien()` | `Home/SuKien.cshtml` | Trang tìm kiếm nâng cao sự kiện theo từ khóa, tỉnh thành, loại sự kiện. |
| **Chi tiết sự kiện** | Tất cả | `/Home/ChiTiet?id={slug}` | `HomeController.cs` -> `ChiTiet()` | `Home/ChiTiet.cshtml` | Xem nội dung chi tiết sự kiện, bản đồ, thời gian, danh sách loại vé mở bán. |
| **Trang chọn ghế & vé** | User | `/Booking/ThanhToan?id={suKienId}` | `BookingController.cs` -> `ThanhToan()` | `Booking/ThanhToan.cshtml` | Giao diện chọn loại vé, chọn sơ đồ ghế ngồi trực quan, nhập voucher. |
| **Trang thành công / Hóa đơn** | User | `/Booking/ThanhCong?id={donHangId}` | `BookingController.cs` -> `ThanhCong()` | `Booking/ThanhCong.cshtml` | Hiển thị thông tin thanh toán thành công, chi tiết đơn hàng và Mã QR Code. |
| **Danh sách đơn hàng của tôi** | User | `/Booking/DonHangCuaToi` | `BookingController.cs` -> `DonHangCuaToi()` | `Booking/DonHangCuaToi.cshtml` | Xem lại toàn bộ lịch sử mua vé, trạng thái đơn hàng (Đã thanh toán/Chưa/Hủy). |
| **Xem chi tiết vé & Mã QR Code** | User | `/Booking/ChiTietDonHang/{id}` | `BookingController.cs` -> `ChiTietDonHang()` | `Booking/ChiTietDonHang.cshtml` | Hiển thị vé điện tử kèm **Mã QR Code** dùng để đưa cho nhân viên quét tại cổng. |

---

### 2. PHÂN HỆ TÀI KHOẢN & XÁC THỰC (ACCOUNT)

| Tên màn hình / Giao diện | Quyền | Đường dẫn URL | File Controller & Action | File View tương ứng (`Views/`) | Chức năng chính |
| :--- | :---: | :--- | :--- | :--- | :--- |
| **Đăng nhập** | Guest | `/Account/DangNhap` | `AccountController.cs` -> `DangNhap()` | `Account/DangNhap.cshtml` | Form đăng nhập (Email + Mật khẩu), xử lý xác thực Cookie Auth. |
| **Đăng ký tài khoản** | Guest | `/Account/DangKy` | `AccountController.cs` -> `DangKy()` | `Account/DangKy.cshtml` | Form đăng ký người dùng mới / đăng ký làm Ban tổ chức. |
| **Quên mật khẩu** | Guest | `/Account/QuenMatKhau` | `AccountController.cs` -> `QuenMatKhau()` | `Account/QuenMatKhau.cshtml` | Nhập email yêu cầu khôi phục mật khẩu. |
| **Đặt lại mật khẩu** | Guest | `/Account/DatLaiMatKhau` | `AccountController.cs` -> `DatLaiMatKhau()` | `Account/DatLaiMatKhau.cshtml` | Nhập mật khẩu mới sau khi được xác nhận token. |
| **Hồ sơ cá nhân** | User | `/Account/HoSo` | `AccountController.cs` -> `HoSo()` | `Account/HoSo.cshtml` | Cập nhật họ tên, số điện thoại, ảnh đại diện, đổi mật khẩu. |
| **Yêu cầu làm Đối tác/BTC** | User | `/Account/YeuCauBanToChuc` | `AccountController.cs` -> `YeuCauBanToChuc()` | `Account/YeuCauBanToChuc.cshtml` | Gửi thông tin doanh nghiệp/tổ chức xin nâng cấp quyền Ban tổ chức. |
| **Từ chối truy cập (403)** | Tất cả | `/Account/TuChoiTruyCap` | `AccountController.cs` -> `TuChoiTruyCap()` | `Account/TuChoiTruyCap.cshtml` | Hiển thị khi người dùng vào trang vượt quá phân quyền của mình. |

---

### 3. PHÂN HỆ BAN TỔ CHỨC SỰ KIỆN (ORGANIZER)

| Tên màn hình / Giao diện | Quyền | Đường dẫn URL | File Controller & Action | File View tương ứng (`Views/`) | Chức năng chính |
| :--- | :---: | :--- | :--- | :--- | :--- |
| **Tổng quan Dashboard BTC** | BTC | `/Organizer/Index` | `OrganizerController.cs` -> `Index()` | `Organizer/Index.cshtml` | Thống kê nhanh tổng sự kiện, tổng số vé bán ra, tổng doanh thu. |
| **Danh sách sự kiện của tôi** | BTC | `/Organizer/SuKien` | `OrganizerController.cs` -> `SuKien()` | `Organizer/SuKien.cshtml` | Danh sách sự kiện do BTC này tạo (Nháp, Chờ duyệt, Đang bán, Đã kết thúc). |
| **Tạo mới sự kiện** | BTC | `/Organizer/TaoMoiSuKien` | `OrganizerController.cs` -> `TaoMoiSuKien()` | `Organizer/TaoMoiSuKien.cshtml` | Form nhập tên, thời gian, địa điểm, mô tả, upload ảnh poster sự kiện. |
| **Chỉnh sửa sự kiện** | BTC | `/Organizer/ChinhSuaSuKien/{id}` | `OrganizerController.cs` -> `ChinhSuaSuKien()` | `Organizer/ChinhSuaSuKien.cshtml` | Cập nhật lại thông tin sự kiện đã tạo. |
| **Chi tiết sự kiện (BTC)** | BTC | `/Organizer/ChiTietSuKien/{id}` | `OrganizerController.cs` -> `ChiTietSuKien()` | `Organizer/ChiTietSuKien.cshtml` | Xem chi tiết sự kiện góc nhìn quản trị viên sự kiện. |
| **Quản lý Loại vé** | BTC | `/Organizer/LoaiVe/{suKienId}` | `OrganizerController.cs` -> `LoaiVe()` | `Organizer/LoaiVe.cshtml` | Thêm/Sửa/Xóa các loại vé (VIP, Standard, Early Bird) & giá tiền. |
| **Quản lý Sơ đồ chỗ ngồi** | BTC | `/Organizer/SoDoChoNgoi/{id}` | `OrganizerController.cs` -> `SoDoChoNgoi()` | `Organizer/SoDoChoNgoi.cshtml` | Cấu hình khu vực (A, B, C), hàng ghế, số lượng chỗ ngồi trực quan. |
| **Quản lý Mã giảm giá** | BTC | `/Organizer/MaGiamGia/{id}` | `OrganizerController.cs` -> `MaGiamGia()` | `Organizer/MaGiamGia.cshtml` | Tạo voucher giảm giá theo %, giảm số tiền cố định, giới hạn lượt dùng. |
| **Danh sách Đơn hàng bán** | BTC | `/Organizer/DonHang/{id}` | `OrganizerController.cs` -> `DonHang()` | `Organizer/DonHang.cshtml` | Xem tất cả các đơn hàng mua vé của sự kiện này. |
| **Danh sách Khách tham dự** | BTC | `/Organizer/KhachThamDu/{id}` | `OrganizerController.cs` -> `KhachThamDu()` | `Organizer/KhachThamDu.cshtml` | Danh sách danh tính khách hàng đã mua vé và trạng thái check-in. |
| **Quản lý Nhân viên Staff** | BTC | `/Organizer/QuanLyStaff/{id}` | `OrganizerController.cs` -> `QuanLyStaff()` | `Organizer/QuanLyStaff.cshtml` | Phân công tài khoản nhân viên chịu trách nhiệm soát vé cho sự kiện. |
| **Màn hình Soát vé (BTC)** | BTC | `/Organizer/CheckIn/{id}` | `OrganizerController.cs` -> `CheckIn()` | `Organizer/CheckIn.cshtml` | Màn hình cho phép BTC trực tiếp check-in vé khách hàng. |
| **Báo cáo doanh thu** | BTC | `/Organizer/BaoCao` | `OrganizerController.cs` -> `BaoCao()` | `Organizer/BaoCao.cshtml` | Biểu đồ & bảng báo cáo doanh thu chi tiết từng sự kiện. |

---

### 4. PHÂN HỆ QUẢN TRỊ VIÊN HỆ THỐNG (ADMIN)

| Tên màn hình / Giao diện | Quyền | Đường dẫn URL | File Controller & Action | File View tương ứng (`Views/`) | Chức năng chính |
| :--- | :---: | :--- | :--- | :--- | :--- |
| **Dashboard Admin** | Admin | `/Admin/Index` | `AdminController.cs` -> `Index()` | `Admin/Index.cshtml` | Bảng điều khiển toàn hệ thống: Thống kê user, doanh thu toàn sàn, sự kiện. |
| **Duyệt Sự kiện** | Admin | `/Admin/SuKien` | `AdminController.cs` -> `SuKien()` | `Admin/SuKien.cshtml` | Xem danh sách sự kiện chờ duyệt -> Bấm **Phê duyệt** hoặc **Từ chối**. |
| **Duyệt Đăng ký BTC** | Admin | `/Admin/DuyetBTCList` | `AdminController.cs` -> `DuyetBTCList()` | `Admin/DuyetBTCList.cshtml` | Duyệt đơn xin nâng cấp tài khoản thành Ban tổ chức. |
| **Quản lý Người dùng** | Admin | `/Admin/NguoiDung` | `AdminController.cs` -> `NguoiDung()` | `Admin/NguoiDung.cshtml` | Danh sách tất cả tài khoản -> Thực hiện **Khóa** hoặc **Mở khóa**. |
| **Quản lý Danh mục** | Admin | `/Admin/DanhMuc` | `AdminController.cs` -> `DanhMuc()` | `Admin/DanhMuc.cshtml` | Quản lý các thể loại sự kiện (Âm nhạc, Thể thao, Hội thảo...). |
| **Quản lý Đơn hàng sàn** | Admin | `/Admin/DonHang` | `AdminController.cs` -> `DonHang()` | `Admin/DonHang.cshtml` | Giám sát tất cả các đơn hàng mua vé diễn ra trên toàn hệ thống. |

---

### 5. PHÂN HỆ NHÂN VIÊN SOÁT VÉ (STAFF)

| Tên màn hình / Giao diện | Quyền | Đường dẫn URL | File Controller & Action | File View tương ứng (`Views/`) | Chức năng chính |
| :--- | :---: | :--- | :--- | :--- | :--- |
| **Danh sách sự kiện phân công**| Staff | `/Staff/Index` | `StaffController.cs` -> `Index()` | `Staff/Index.cshtml` | Xem các sự kiện mình được Ban tổ chức phân công làm nhiệm vụ soát vé. |
| **Màn hình Quét QR Code** | Staff | `/Staff/CheckIn/{suKienId}`| `StaffController.cs` -> `CheckIn()` | `Staff/CheckIn.cshtml` | Màn hình camera/nhập mã vé để **Quét QR Code** check-in cho khách tại cổng. |

---

## 🗺️ PHẦN 2: BẢN ĐỒ TÌM KIẾM CODE NHANH TRONG DỰ ÁN

Khi mở bất kỳ file Controller nào trong Visual Studio / VS Code, hãy nhấn **`Ctrl + F`** và gõ các từ khóa comment bên dưới để lướt ngay đến đoạn code xử lý tính năng đó:

### 🔍 1. Mở file `Controllers/AccountController.cs`:
- Gõ `DangNhap` $\rightarrow$ Nhảy đến đoạn code Xử lý Đăng nhập & Tạo Cookie Authentication.
- Gõ `DangKy` $\rightarrow$ Nhảy đến đoạn code Xử lý Đăng ký & Mã hóa mật khẩu BCrypt.
- Gõ `HoSo` $\rightarrow$ Nhảy đến đoạn code Cập nhật hồ sơ & đổi mật khẩu.

### 🔍 2. Mở file `Controllers/HomeController.cs`:
- Gõ `Index` $\rightarrow$ Nhảy đến đoạn code Lấy danh sách sự kiện công khai & Lọc từ khóa/thành phố.
- Gõ `ChiTiet` $\rightarrow$ Nhảy đến đoạn code Lấy chi tiết sự kiện + Tự động giải phóng vé quá hạn 15 phút.

### 🔍 3. Mở file `Controllers/BookingController.cs`:
- Gõ `DatVe` $\rightarrow$ Nhảy đến đoạn code Kiểm tra số lượng vé & Tạo đơn hàng tạm thời.
- Gõ `VnPayReturn` $\rightarrow$ Nhảy đến đoạn code Nhận kết quả phản hồi từ VNPay & Cập nhật `DaThanhToan`.
- Gõ `QRCoder` hoặc `ChiTietDonHang` $\rightarrow$ Nhảy đến đoạn code Sinh ảnh QR Code bằng C#.
- Gõ `GiaiPhongDonHangHetHan` $\rightarrow$ Nhảy đến đoạn code SQL nhả vé sau 15 phút.

### 🔍 4. Mở file `Controllers/OrganizerController.cs`:
- Gõ `TaoMoiSuKien` $\rightarrow$ Nhảy đến đoạn code Lưu thông tin sự kiện & Upload ảnh poster vào `wwwroot/uploads`.
- Gõ `LoaiVe` $\rightarrow$ Nhảy đến đoạn code Thêm/Sửa/Xóa giá vé.
- Gõ `SoDoChoNgoi` $\rightarrow$ Nhảy đến đoạn code Tạo sơ đồ khu vực & ghế ngồi.

### 🔍 5. Mở file `Controllers/AdminController.cs`:
- Gõ `SuKien` hoặc `Duyet` $\rightarrow$ Nhảy đến đoạn code Phê duyệt / Từ chối sự kiện.
- Gõ `NguoiDung` $\rightarrow$ Nhảy đến đoạn code Khóa / Mở khóa tài khoản user.

### 🔍 6. Mở file `Controllers/StaffController.cs`:
- Gõ `CheckIn` $\rightarrow$ Nhảy đến đoạn code Quét QR Code & Cập nhật trạng thái vé thành "Đã Check-in".
