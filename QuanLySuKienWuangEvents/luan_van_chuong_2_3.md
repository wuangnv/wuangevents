# CHƯƠNG 2 & CHƯƠNG 3: PHƯƠNG PHÁP THỰC HIỆN VÀ THIẾT KẾ HỆ THỐNG WUANGEVENTS
*(Tài liệu được chuẩn hóa 100% bám sát phong cách mẫu GoEvent: Bảng 2 cột Thành phần - Nội dung chi tiết, các Include/Extend gọn gàng, chia rẽ nhánh rõ ràng)*

---

## CHƯƠNG 2. PHƯƠNG PHÁP THỰC HIỆN VÀ CÔNG NGHỆ SỬ DỤNG

### 2.1 CÁC HỆ THỐNG TƯƠNG TỰ
Khảo sát hai nền tảng tiêu biểu: **Ticketbox.vn** và **Eventbrite.com**.

### 2.2 CÔNG NGHỆ SỬ DỤNG
- **Hệ thống xử lý (Back-end)**: Nền tảng web ASP.NET Core MVC 9.0, công cụ truy vấn dữ liệu hiệu năng cao Dapper, Cơ sở dữ liệu SQL Server, Mã hóa bảo mật mật khẩu BCrypt, Bộ sinh mã QR Code vé điện tử, Các cổng thanh toán điện tử VNPAY, MoMo, ZaloPay.
- **Giao diện người dùng (Front-end)**: Trang web Razor Views (.cshtml), HTML5/CSS3/JavaScript, Dữ liệu địa chỉ Tỉnh/Thành phố động, Công cụ quét mã QR bằng camera trình duyệt.

### 2.3 PHÂN TÍCH YÊU CẦU NGHIỆP VỤ

#### 2.3.1 Các quy trình nghiệp vụ chính
1. **Quy trình đăng ký trở thành Ban tổ chức**: Khách hàng gửi hồ sơ thông tin ngân hàng -> Quản trị viên xem xét phê duyệt -> Nâng cấp tài khoản thành Ban tổ chức.
2. **Quy trình tạo và duyệt sự kiện**: Ban tổ chức nhập thông tin sự kiện và địa điểm -> Cấu hình phòng vé -> Quản trị viên phê duyệt mở bán công khai.
3. **Quy trình mua vé**: Khách hàng chọn vé hoặc vị trí ghế -> Giữ chỗ 15 phút -> Thanh toán tự động hoặc Chuyển khoản -> Nhận vé QR Code qua email.
4. **Quy trình soát vé tại sự kiện**: Nhân viên mở cổng check-in -> Quét mã QR bằng camera điện thoại -> Hệ thống đối chiếu xác minh và thông báo kết quả.

#### 2.3.2 Sơ đồ chức năng hệ thống
![Sơ đồ chức năng hệ thống](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/01_Cay_phan_cap_module.drawio)
*Hình 2-1. Sơ đồ chức năng hệ thống WuangEvents*

#### 2.3.3 Sơ đồ Use Case tổng quát hệ thống
![Sơ đồ Use Case tổng quát hệ thống](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/02_Use_case_tong_quat_he_thong.drawio)
*Hình 2-2. Sơ đồ Use Case tổng quát hệ thống WuangEvents*

---

## CHƯƠNG 3. THIẾT KẾ HỆ THỐNG

### 3.1 MÔ HÌNH DỮ LIỆU CHUẨN HÓA (12 BẢNG CSDL THỰC TẾ)

#### 3.1.1 Mức ý niệm (ERD)
12 thực thể chính lưu trữ dữ liệu hệ thống: NguoiDung, DanhMuc, SuKien, LoaiVe, MaGiamGia, DonHang, ChiTietDonHang, SoDoChoNgoi, KhuVuc, HangGhe, ChoNgoi, NhanVienSuKien.

---

### 3.2 MÔ HÌNH XỬ LÝ NGHIỆP VỤ (PHÂN THEO 4 VAI TRÒ VÀ FULL CÁC MODULE)

#### 3.2.1 PHÂN HỆ VAI TRÒ 1: KHÁCH HÀNG

### 3.2.1.1 Quản lý tra cứu sự kiện

![Sơ đồ use-case chức năng Quản lý tra cứu sự kiện](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/07_UC_chi_tiet_Tra_cuu_su_kien.drawio)

*Hình 3-1. Use case của quy trình Quản lý tra cứu sự kiện*

| Thành phần | Nội dung chi tiết |
| :--- | :--- |
| Tên Use case | Quản lý tra cứu sự kiện |
| Actor | Khách hàng |
| Mô tả | Khách hàng thực hiện tra cứu danh sách sự kiện mở bán trên trang chủ, tìm kiếm, lọc theo thể loại/tỉnh thành, xem chi tiết và đính kèm Google Calendar. |
| Pre-conditions | Khách hàng truy cập vào hệ thống. |
| Post-conditions | Success: Danh sách sự kiện hoặc chi tiết sự kiện hiển thị.<br>Fail: Báo không tìm thấy kết quả. |
| Luồng sự kiện chính | Actor truy cập giao diện chức năng.<br>Include Use Case Xem danh sách sự kiện.<br>Extend Use Case Tìm kiếm và lọc sự kiện.<br>Extend Use Case Xem chi tiết sự kiện.<br>Extend Use Case Đồng bộ Google Calendar.<br>Kết thúc Use case. |
| Luồng sự kiện phụ | Không có. |
| <Include Use Case Xem danh sách sự kiện> | 1. Hệ thống tự động tải và hiển thị danh sách các sự kiện đang mở bán ở trang chủ. |
| <Extend Use Case Tìm kiếm và lọc sự kiện> | 1. Actor nhập từ khóa, chọn Tỉnh/Thành phố hoặc Danh mục.<br>2. Hệ thống lọc danh sách sự kiện khớp với điều kiện. |
| <Extend Use Case Xem chi tiết sự kiện> | 1. Actor chọn một thẻ sự kiện.<br>2. Hệ thống hiển thị thông tin mô tả, lịch diễn ra và bảng giá vé. |
| <Extend Use Case Đồng bộ Google Calendar> | 1. Actor nhấn nút 'Thêm vào Google Calendar'.<br>2. Hệ thống chuyển hướng mở tab đồng bộ lịch cá nhân. |

*Bảng 3-1. Mô tả use case chức năng Quản lý tra cứu sự kiện.*


### 3.2.1.2 Quản lý tài khoản

![Sơ đồ use-case chức năng Quản lý tài khoản](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/08_UC_chi_tiet_Quan_ly_tai_khoan.drawio)

*Hình 3-2. Use case của quy trình Quản lý tài khoản*

| Thành phần | Nội dung chi tiết |
| :--- | :--- |
| Tên Use case | Quản lý tài khoản |
| Actor | Người dùng |
| Mô tả | Người dùng xem thông tin tài khoản cá nhân, thực hiện đăng ký tài khoản mới, đăng nhập vào hệ thống hoặc cập nhật hồ sơ cá nhân. |
| Pre-conditions | Người dùng đã truy cập vào hệ thống. |
| Post-conditions | Success: Đăng ký/Đăng nhập thành công hoặc hồ sơ được cập nhật.<br>Fail: Báo lỗi thông tin không hợp lệ. |
| Luồng sự kiện chính | Actor truy cập giao diện chức năng.<br>Include Use Case Xem thông tin tài khoản.<br>Extend Use Case Đăng ký.<br>Extend Use Case Đăng nhập.<br>Extend Use Case Cập nhật hồ sơ.<br>Kết thúc Use case. |
| Luồng sự kiện phụ | Không có. |
| <Include Use Case Xem thông tin tài khoản> | 1. Hệ thống hiển thị thông tin trạng thái phiên làm việc hiện tại của người dùng. |
| <Extend Use Case Đăng ký> | 1. Actor nhấn chọn Đăng ký.<br>2. Actor nhập Họ tên, Email, Mật khẩu, SĐT và nhấn Đăng ký.<br>3. Hệ thống lưu tài khoản mới vào CSDL. |
| <Extend Use Case Đăng nhập> | 1. Actor nhấn chọn Đăng nhập.<br>2. Actor nhập Email, Mật khẩu và nhấn Đăng nhập.<br>3. Hệ thống xác thực và tạo Cookie phiên. |
| <Extend Use Case Cập nhật hồ sơ> | 1. Actor truy cập trang Hồ sơ.<br>2. Actor thay đổi Họ tên, SĐT hoặc Mật khẩu.<br>3. Hệ thống lưu thông tin mới vào CSDL. |

*Bảng 3-2. Mô tả use case chức năng Quản lý tài khoản.*


### 3.2.1.3 Quản lý giao dịch mua vé

![Sơ đồ use-case chức năng Quản lý giao dịch mua vé](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/09_UC_chi_tiet_Giao_dich_mua_ve.drawio)

*Hình 3-3. Use case của quy trình Quản lý giao dịch mua vé*

| Thành phần | Nội dung chi tiết |
| :--- | :--- |
| Tên Use case | Quản lý giao dịch mua vé |
| Actor | Khách hàng |
| Mô tả | Khách hàng thực hiện quy trình mua vé bắt buộc 3 bước: Chọn vé (hoặc ghế Canvas) -> Thanh toán trực tuyến -> Nhận vé QR Code đính kèm email, có thể nhập Voucher mã giảm giá. |
| Pre-conditions | Khách hàng đã đăng nhập và đang ở trang chi tiết sự kiện mở bán. |
| Post-conditions | Success: Đơn hàng hoàn tất, vé điện tử QR Code được gửi email.<br>Fail: Hủy đơn hoặc hết thời gian giữ chỗ. |
| Luồng sự kiện chính | Actor truy cập giao diện chức năng.<br>Include Use Case Chọn vé.<br>Include Use Case Thanh toán.<br>Include Use Case Nhận vé.<br>Extend Use Case Áp dụng mã giảm giá.<br>Kết thúc Use case. |
| Luồng sự kiện phụ | Không có. |
| <Include Use Case Chọn vé> | 1. Actor chọn số lượng vé hoặc vị trí ghế sơ đồ Canvas.<br>2. Hệ thống khóa giữ chỗ 15 phút. |
| <Include Use Case Thanh toán> | 1. Actor chọn cổng thanh toán VNPAY/MoMo/ZaloPay/Banking.<br>2. Hệ thống xử lý giao dịch. |
| <Include Use Case Nhận vé> | 1. Hệ thống sinh mã QR Code cho từng vé.<br>2. Hệ thống gửi email đính kèm vé cho khách. |
| <Extend Use Case Áp dụng mã giảm giá> | 1. Actor nhập mã Voucher vào ô khuyến mãi.<br>2. Hệ thống trừ tiền giảm giá vào tổng đơn. |

*Bảng 3-3. Mô tả use case chức năng Quản lý giao dịch mua vé.*


### 3.2.1.4 Quản lý vé mua

![Sơ đồ use-case chức năng Quản lý vé mua](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/10_UC_chi_tiet_Quan_ly_ve_mua.drawio)

*Hình 3-4. Use case của quy trình Quản lý vé mua*

| Thành phần | Nội dung chi tiết |
| :--- | :--- |
| Tên Use case | Quản lý vé mua |
| Actor | Khách hàng |
| Mô tả | Khách hàng truy cập danh sách vé đã mua, xem chi tiết cuống vé QR Code để check-in hoặc thực hiện hủy đơn hàng đang chờ thanh toán. |
| Pre-conditions | Khách hàng đã đăng nhập tài khoản. |
| Post-conditions | Success: Danh sách và cuống vé QR hiển thị chính xác. |
| Luồng sự kiện chính | Actor truy cập giao diện chức năng.<br>Include Use Case Xem danh sách vé đã mua.<br>Extend Use Case Xem cuống vé QR Code.<br>Extend Use Case Hủy đơn hàng.<br>Kết thúc Use case. |
| Luồng sự kiện phụ | Không có. |
| <Include Use Case Xem danh sách vé đã mua> | 1. Hệ thống truy vấn CSDL và hiển thị danh sách các đơn hàng đã đặt của Actor. |
| <Extend Use Case Xem cuống vé QR Code> | 1. Actor chọn một đơn hàng.<br>2. Hệ thống hiển thị chi tiết cuống vé điện tử chứa mã QR Code. |
| <Extend Use Case Hủy đơn hàng> | 1. Actor chọn đơn hàng đang chờ thanh toán và bấm Hủy.<br>2. Hệ thống hủy đơn và giải phóng ghế. |

*Bảng 3-4. Mô tả use case chức năng Quản lý vé mua.*


### 3.2.1.5 Quản lý yêu cầu làm ban tổ chức

![Sơ đồ use-case chức năng Quản lý yêu cầu làm ban tổ chức](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/11_UC_chi_tiet_Yeu_cau_lam_doi_tac.drawio)

*Hình 3-5. Use case của quy trình Quản lý yêu cầu làm ban tổ chức*

| Thành phần | Nội dung chi tiết |
| :--- | :--- |
| Tên Use case | Quản lý yêu cầu làm ban tổ chức |
| Actor | Khách hàng |
| Mô tả | Khách hàng mở giao diện nộp đơn xin nâng cấp vai trò Ban tổ chức, điền thông tin liên hệ và theo dõi trạng thái xét duyệt. |
| Pre-conditions | Khách hàng đã đăng nhập. |
| Post-conditions | Success: Yêu cầu nâng cấp được gửi đến Admin. |
| Luồng sự kiện chính | Actor truy cập giao diện chức năng.<br>Include Use Case Xem giao diện đăng ký đối tác.<br>Extend Use Case Gửi yêu cầu nâng cấp.<br>Extend Use Case Xem trạng thái hồ sơ.<br>Kết thúc Use case. |
| Luồng sự kiện phụ | Không có. |
| <Include Use Case Xem giao diện đăng ký đối tác> | 1. Hệ thống hiển thị biểu mẫu đăng ký làm Ban tổ chức và trạng thái hiện tại. |
| <Extend Use Case Gửi yêu cầu nâng cấp> | 1. Actor điền Họ tên tổ chức, SĐT và nhấn Gửi.<br>2. Hệ thống ghi nhận trạng thái Chờ duyệt. |
| <Extend Use Case Xem trạng thái hồ sơ> | 1. Actor kiểm tra kết quả phê duyệt hoặc lý do từ chối từ Admin. |

*Bảng 3-5. Mô tả use case chức năng Đăng ký làm Ban tổ chức.*



---

#### 3.2.2 PHÂN HỆ VAI TRÒ 2: BAN TỔ CHỨC

### 3.2.1.6 Quản lý thống kê hoạt động

![Sơ đồ use-case chức năng Quản lý thống kê hoạt động](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/12_UC_chi_tiet_Thong_ke_hoat_dong.drawio)

*Hình 3-6. Use case của quy trình Quản lý thống kê hoạt động*

| Thành phần | Nội dung chi tiết |
| :--- | :--- |
| Tên Use case | Quản lý thống kê hoạt động |
| Actor | Ban tổ chức |
| Mô tả | Ban tổ chức truy cập Dashboard xem tổng quan số liệu KPI hoạt động và thực hiện lọc biểu đồ theo khoảng thời gian. |
| Pre-conditions | Ban tổ chức đã đăng nhập. |
| Post-conditions | Success: Thống kê hiển thị chính xác. |
| Luồng sự kiện chính | Actor truy cập giao diện chức năng.<br>Include Use Case Xem Dashboard KPI.<br>Extend Use Case Lọc biểu đồ doanh thu.<br>Kết thúc Use case. |
| Luồng sự kiện phụ | Không có. |
| <Include Use Case Xem Dashboard KPI> | 1. Hệ thống tự động tổng hợp tổng sự kiện, tổng đơn hàng và tổng doanh thu hiển thị trên giao diện. |
| <Extend Use Case Lọc biểu đồ doanh thu> | 1. Actor chọn mốc thời gian lọc (Tuần/Tháng/Năm).<br>2. Hệ thống cập nhật lại biểu đồ doanh số. |

*Bảng 3-6. Mô tả use case chức năng Xem thống kê hoạt động.*



##### 3.2.1.7 Quản lý sự kiện (Module trung tâm Ban tổ chức - Nấc 1)
### 3.2.1.7 Quản lý sự kiện

![Sơ đồ use-case chức năng Quản lý sự kiện](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/13_UC_chi_tiet_Quan_ly_su_kien.drawio)

*Hình 3-7. Use case của quy trình Quản lý sự kiện*

| Thành phần | Nội dung chi tiết |
| :--- | :--- |
| Tên Use case | Quản lý sự kiện |
| Actor | Ban tổ chức |
| Mô tả | Ban tổ chức truy cập trang quản lý sự kiện, xem danh sách sự kiện và mở rộng thao tác quản lý các module con hoặc nhân bản sự kiện. |
| Pre-conditions | Ban tổ chức đã đăng nhập. |
| Post-conditions | Success: Sự kiện được điều phối thành công. |
| Luồng sự kiện chính | Actor truy cập giao diện chức năng.<br>Include Use Case Xem danh sách sự kiện.<br>Extend Use Case Quản lý loại vé.<br>Extend Use Case Quản lý sơ đồ chỗ ngồi.<br>Extend Use Case Quản lý mã giảm giá.<br>Extend Use Case Quản lý đơn hàng ban tổ chức.<br>Extend Use Case Quản lý phân công soát vé.<br>Extend Use Case Quản lý báo cáo doanh thu.<br>Extend Use Case Nhân bản sự kiện.<br>Kết thúc Use case. |
| Luồng sự kiện phụ | Không có. |
| <Include Use Case Xem danh sách sự kiện> | 1. Hệ thống hiển thị danh sách tất cả các sự kiện do Ban tổ chức khởi tạo. |
| <Extend Use Case Quản lý loại vé> | Cấu hình các hạng vé và giá bán. |
| <Extend Use Case Quản lý sơ đồ chỗ ngồi> | Cấu hình sơ đồ ghế Canvas. |
| <Extend Use Case Quản lý mã giảm giá> | Cấu hình voucher khuyến mãi. |
| <Extend Use Case Quản lý đơn hàng ban tổ chức> | Xem và duyệt đơn hàng. |
| <Extend Use Case Quản lý phân công soát vé> | Gán quyền cho nhân viên Staff. |
| <Extend Use Case Quản lý báo cáo doanh thu> | Xem báo cáo doanh số. |
| <Extend Use Case Nhân bản sự kiện> | Sao chép nhanh sự kiện cũ thành bản nháp mới. |

*Bảng 3-7. Mô tả use case chức năng Quản lý sự kiện.*



---

##### CHI TIẾT NẤC 2: 6 CHỨC NĂNG CON THUỘC MODULE QUẢN LÝ SỰ KIỆN

###### 3.2.1.7.1 Quản lý loại vé (Chức năng con 1)
### 3.2.1.7.1 Quản lý loại vé

![Sơ đồ use-case chức năng Quản lý loại vé](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/14_UC_chi_tiet_Cau_hinh_loai_ve.drawio)

*Hình 3-7.1. Use case của quy trình Quản lý loại vé*

| Thành phần | Nội dung chi tiết |
| :--- | :--- |
| Tên Use case | Quản lý loại vé |
| Actor | Ban tổ chức |
| Mô tả | Ban tổ chức xem danh sách loại vé của sự kiện và chọn thao tác tạo loại vé mới hoặc chỉnh sửa loại vé hiện có. |
| Pre-conditions | Ban tổ chức đang ở trang quản lý sự kiện. |
| Post-conditions | Success: Loại vé được tạo hoặc chỉnh sửa thành công. |
| Luồng sự kiện chính | Actor truy cập giao diện chức năng.<br>Include Use Case Xem danh sách loại vé.<br>Extend Use Case Tạo loại vé.<br>Extend Use Case Chỉnh sửa loại vé.<br>Kết thúc Use case. |
| Luồng sự kiện phụ | Không có. |
| <Include Use Case Xem danh sách loại vé> | 1. Hệ thống hiển thị danh sách các hạng vé hiện tại của sự kiện. |
| <Extend Use Case Tạo loại vé> | 1. Actor nhấn Thêm loại vé, nhập Tên, Giá, Số lượng và bấm Lưu. |
| <Extend Use Case Chỉnh sửa loại vé> | 1. Actor nhấn Sửa loại vé và cập nhật thông tin cho phép. |

*Bảng 3-7.1. Mô tả use case chức năng Quản lý loại vé.*



###### 3.2.1.7.2 Quản lý sơ đồ chỗ ngồi (Chức năng con 2)
### 3.2.1.7.2 Quản lý sơ đồ chỗ ngồi

![Sơ đồ use-case chức năng Quản lý sơ đồ chỗ ngồi](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/14b_UC_chi_tiet_Quan_ly_so_do_cho_ngoi.drawio)

*Hình 3-7.2. Use case của quy trình Quản lý sơ đồ chỗ ngồi*

| Thành phần | Nội dung chi tiết |
| :--- | :--- |
| Tên Use case | Quản lý sơ đồ chỗ ngồi |
| Actor | Ban tổ chức |
| Mô tả | Ban tổ chức xem ma trận sơ đồ ghế Canvas và chọn tạo mới sơ đồ hoặc đổi trạng thái từng vị trí ghế. |
| Pre-conditions | Ban tổ chức đang quản lý sự kiện. |
| Post-conditions | Success: Sơ đồ ghế được cấu hình chính xác. |
| Luồng sự kiện chính | Actor truy cập giao diện chức năng.<br>Include Use Case Xem sơ đồ ghế Canvas.<br>Extend Use Case Tạo sơ đồ ghế.<br>Extend Use Case Đổi trạng thái ghế.<br>Kết thúc Use case. |
| Luồng sự kiện phụ | Không có. |
| <Include Use Case Xem sơ đồ ghế Canvas> | 1. Hệ thống tải và hiển thị sơ đồ phân khu ghế Canvas hiện tại. |
| <Extend Use Case Tạo sơ đồ ghế> | 1. Actor nhập số Khu vực, Hàng, Ghế và nhấn Sinh sơ đồ. |
| <Extend Use Case Đổi trạng thái ghế> | 1. Actor click vào từng ghế trên sơ đồ để Khóa/Mở khóa. |

*Bảng 3-7.2. Mô tả use case chức năng Quản lý sơ đồ chỗ ngồi.*



###### 3.2.1.7.3 Quản lý mã giảm giá (Chức năng con 3)
### 3.2.1.7.3 Quản lý mã giảm giá

![Sơ đồ use-case chức năng Quản lý mã giảm giá](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/15_UC_chi_tiet_Quan_ly_khuyen_mai.drawio)

*Hình 3-7.3. Use case của quy trình Quản lý mã giảm giá*

| Thành phần | Nội dung chi tiết |
| :--- | :--- |
| Tên Use case | Quản lý mã giảm giá |
| Actor | Ban tổ chức |
| Mô tả | Ban tổ chức xem danh sách mã giảm giá Voucher của sự kiện và thực hiện tạo mới hoặc chỉnh sửa Voucher. |
| Pre-conditions | Ban tổ chức đang quản lý sự kiện. |
| Post-conditions | Success: Mã giảm giá được lưu thành công. |
| Luồng sự kiện chính | Actor truy cập giao diện chức năng.<br>Include Use Case Xem danh sách Voucher.<br>Extend Use Case Tạo mã giảm giá.<br>Extend Use Case Chỉnh sửa mã giảm giá.<br>Kết thúc Use case. |
| Luồng sự kiện phụ | Không có. |
| <Include Use Case Xem danh sách Voucher> | 1. Hệ thống hiển thị danh sách các mã giảm giá hiện có. |
| <Extend Use Case Tạo mã giảm giá> | 1. Actor nhập Mã Code, Mức giảm, Số lượng và nhấn Tạo. |
| <Extend Use Case Chỉnh sửa mã giảm giá> | 1. Actor chọn Sửa Voucher và cập nhật số lượng mã. |

*Bảng 3-7.3. Mô tả use case chức năng Quản lý mã giảm giá.*



###### 3.2.1.7.4 Quản lý đơn hàng ban tổ chức (Chức năng con 4)
### 3.2.1.7.4 Quản lý đơn hàng ban tổ chức

![Sơ đồ use-case chức năng Quản lý đơn hàng ban tổ chức](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/16_UC_chi_tiet_Quan_ly_don_hang.drawio)

*Hình 3-7.4. Use case của quy trình Quản lý đơn hàng ban tổ chức*

| Thành phần | Nội dung chi tiết |
| :--- | :--- |
| Tên Use case | Quản lý đơn hàng ban tổ chức |
| Actor | Ban tổ chức |
| Mô tả | Ban tổ chức xem danh sách đơn hàng mua vé và thực hiện xác nhận thanh toán chuyển khoản thủ công hoặc xem/tải danh sách khách tham dự. |
| Pre-conditions | Sự kiện đã phát sinh đơn hàng. |
| Post-conditions | Success: Đơn hàng được cập nhật trạng thái. |
| Luồng sự kiện chính | Actor truy cập giao diện chức năng.<br>Include Use Case Xem danh sách đơn hàng.<br>Extend Use Case Xác nhận thanh toán thủ công.<br>Extend Use Case Xem khách tham dự.<br>Kết thúc Use case. |
| Luồng sự kiện phụ | Không có. |
| <Include Use Case Xem danh sách đơn hàng> | 1. Hệ thống hiển thị danh sách đơn mua vé của sự kiện. |
| <Extend Use Case Xác nhận thanh toán thủ công> | 1. Actor chọn đơn chuyển khoản và bấm Xác nhận đã nhận tiền. |
| <Extend Use Case Xem khách tham dự> | 1. Actor chọn tab Khách tham dự và bấm Xuất CSV. |

*Bảng 3-7.4. Mô tả use case chức năng Quản lý đơn hàng ban tổ chức.*



###### 3.2.1.7.5 Quản lý phân công soát vé (Chức năng con 5)
### 3.2.1.7.5 Quản lý phân công soát vé

![Sơ đồ use-case chức năng Quản lý phân công soát vé](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/18_UC_chi_tiet_Phan_cong_soat_ve.drawio)

*Hình 3-7.5. Use case của quy trình Quản lý phân công soát vé*

| Thành phần | Nội dung chi tiết |
| :--- | :--- |
| Tên Use case | Quản lý phân công soát vé |
| Actor | Ban tổ chức |
| Mô tả | Ban tổ chức xem danh sách nhân viên Staff và chọn gán quyền soát vé hoặc gỡ phân công soát vé cho sự kiện. |
| Pre-conditions | Ban tổ chức đã có tài khoản Staff. |
| Post-conditions | Success: Phân công nhân viên được cập nhật. |
| Luồng sự kiện chính | Actor truy cập giao diện chức năng.<br>Include Use Case Xem danh sách nhân viên Staff.<br>Extend Use Case Thêm nhân viên soát vé.<br>Extend Use Case Gỡ phân công soát vé.<br>Kết thúc Use case. |
| Luồng sự kiện phụ | Không có. |
| <Include Use Case Xem danh sách nhân viên Staff> | 1. Hệ thống hiển thị danh sách nhân viên thuộc quyền quản lý. |
| <Extend Use Case Thêm nhân viên soát vé> | 1. Actor chọn nhân viên và nhấn Thêm vào sự kiện. |
| <Extend Use Case Gỡ phân công soát vé> | 1. Actor chọn nhân viên đã gán và nhấn Gỡ. |

*Bảng 3-7.5. Mô tả use case chức năng Phân công nhân viên soát vé.*



###### 3.2.1.7.6 Quản lý báo cáo doanh thu (Chức năng con 6)
### 3.2.1.7.6 Quản lý báo cáo doanh thu

![Sơ đồ use-case chức năng Quản lý báo cáo doanh thu](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/18b_UC_chi_tiet_Quan_ly_bao_cao_doanh_thu.drawio)

*Hình 3-7.6. Use case của quy trình Quản lý báo cáo doanh thu*

| Thành phần | Nội dung chi tiết |
| :--- | :--- |
| Tên Use case | Quản lý báo cáo doanh thu |
| Actor | Ban tổ chức |
| Mô tả | Ban tổ chức xem báo cáo số liệu doanh thu, tỷ lệ lấp đầy phòng vé và bấm xuất file CSV dữ liệu báo cáo. |
| Pre-conditions | Ban tổ chức đang xem thông tin sự kiện. |
| Post-conditions | Success: Báo cáo hiển thị chính xác. |
| Luồng sự kiện chính | Actor truy cập giao diện chức năng.<br>Include Use Case Xem báo cáo doanh thu.<br>Extend Use Case Xuất file CSV báo cáo.<br>Kết thúc Use case. |
| Luồng sự kiện phụ | Không có. |
| <Include Use Case Xem báo cáo doanh thu> | 1. Hệ thống tính toán tổng doanh thu, số vé đã bán và hiển thị bảng báo cáo. |
| <Extend Use Case Xuất file CSV báo cáo> | 1. Actor nhấn Xuất CSV để tải file dữ liệu về máy. |

*Bảng 3-7.6. Mô tả use case chức năng Xem báo cáo doanh thu.*



### 3.2.1.8 Quản lý nhân viên soát vé

![Sơ đồ use-case chức năng Quản lý nhân viên soát vé](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/17_UC_chi_tiet_Quan_ly_nhan_vien_Staff.drawio)

*Hình 3-8. Use case của quy trình Quản lý nhân viên soát vé*

| Thành phần | Nội dung chi tiết |
| :--- | :--- |
| Tên Use case | Quản lý nhân viên soát vé |
| Actor | Ban tổ chức |
| Mô tả | Ban tổ chức xem danh sách tài khoản Staff do mình khởi tạo và bấm tạo mới tài khoản hoặc chỉnh sửa thông tin Staff. |
| Pre-conditions | Ban tổ chức đã đăng nhập. |
| Post-conditions | Success: Tài khoản Staff được cập nhật. |
| Luồng sự kiện chính | Actor truy cập giao diện chức năng.<br>Include Use Case Xem danh sách tài khoản Staff.<br>Extend Use Case Tạo tài khoản nhân viên.<br>Extend Use Case Chỉnh sửa tài khoản nhân viên.<br>Kết thúc Use case. |
| Luồng sự kiện phụ | Không có. |
| <Include Use Case Xem danh sách tài khoản Staff> | 1. Hệ thống hiển thị danh sách các tài khoản Staff. |
| <Extend Use Case Tạo tài khoản nhân viên> | 1. Actor nhập Họ tên, Email, Mật khẩu và nhấn Lưu. |
| <Extend Use Case Chỉnh sửa tài khoản nhân viên> | 1. Actor chọn Sửa Staff và cập nhật thông tin/mật khẩu. |

*Bảng 3-8. Mô tả use case chức năng Quản lý nhân viên soát vé.*



---

#### 3.2.3 PHÂN HỆ VAI TRÒ 3: NHÂN VIÊN SOÁT VÉ

### 3.2.1.9 Quản lý soát vé check-in

![Sơ đồ use-case chức năng Quản lý soát vé check-in](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/19_UC_chi_tiet_Soat_ve_Check_in.drawio)

*Hình 3-9. Use case của quy trình Quản lý soát vé check-in*

| Thành phần | Nội dung chi tiết |
| :--- | :--- |
| Tên Use case | Quản lý soát vé check-in |
| Actor | Nhân viên soát vé |
| Mô tả | Nhân viên soát vé thực hiện quy trình soát vé bắt buộc: Quét mã QR -> Xác nhận vé hợp lệ, có thể nhập mã thủ công nếu camera mờ. |
| Pre-conditions | Nhân viên đã mở cổng check-in. |
| Post-conditions | Success: Vé đổi trạng thái Đã check-in. |
| Luồng sự kiện chính | Actor truy cập giao diện chức năng.<br>Include Use Case Quét mã QR.<br>Include Use Case Xác nhận vé hợp lệ.<br>Extend Use Case Nhập mã vé thủ công.<br>Kết thúc Use case. |
| Luồng sự kiện phụ | Không có. |
| <Include Use Case Quét mã QR> | 1. Actor hướng camera thiết bị vào mã QR trên vé. |
| <Include Use Case Xác nhận vé hợp lệ> | 1. Hệ thống đối chiếu CSDL, cập nhật Đã check-in và báo XANH/ĐỎ. |
| <Extend Use Case Nhập mã vé thủ công> | 1. Actor nhập chuỗi mã vé vào ô tìm kiếm khi camera không đọc được. |

*Bảng 3-9. Mô tả use case chức năng Quản lý soát vé check-in.*



---

#### 3.2.4 PHÂN HỆ VAI TRÒ 4: QUẢN TRỊ VIÊN (ADMIN)

### 3.2.1.10 Quản lý danh mục

![Sơ đồ use-case chức năng Quản lý danh mục](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/24_UC_chi_tiet_Quan_ly_danh_muc.drawio)

*Hình 3-10. Use case của quy trình Quản lý danh mục*

| Thành phần | Nội dung chi tiết |
| :--- | :--- |
| Tên Use case | Quản lý danh mục |
| Actor | Quản trị viên |
| Mô tả | Quản trị viên xem danh sách thể loại sự kiện toàn hệ thống và chọn thêm mới danh mục hoặc chỉnh sửa danh mục hiện có. |
| Pre-conditions | Quản trị viên đã đăng nhập Admin. |
| Post-conditions | Success: Danh mục được lưu vào CSDL. |
| Luồng sự kiện chính | Actor truy cập giao diện chức năng.<br>Include Use Case Xem danh sách danh mục.<br>Extend Use Case Thêm danh mục.<br>Extend Use Case Chỉnh sửa danh mục.<br>Kết thúc Use case. |
| Luồng sự kiện phụ | Không có. |
| <Include Use Case Xem danh sách danh mục> | 1. Hệ thống hiển thị danh sách các thể loại sự kiện. |
| <Extend Use Case Thêm danh mục> | 1. Actor nhập Tên danh mục, Mô tả và nhấn Lưu. |
| <Extend Use Case Chỉnh sửa danh mục> | 1. Actor chọn Sửa danh mục và cập nhật thông tin. |

*Bảng 3-10. Mô tả use case chức năng Quản lý danh mục.*


### 3.2.1.11 Quản lý thống kê hệ thống

![Sơ đồ use-case chức năng Quản lý thống kê hệ thống](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/20_UC_chi_tiet_Thong_ke_he_thong.drawio)

*Hình 3-11. Use case của quy trình Quản lý thống kê hệ thống*

| Thành phần | Nội dung chi tiết |
| :--- | :--- |
| Tên Use case | Quản lý thống kê hệ thống |
| Actor | Quản trị viên |
| Mô tả | Quản trị viên xem Dashboard KPI toàn sàn và thực hiện lọc số liệu báo cáo theo khoảng thời gian. |
| Pre-conditions | Quản trị viên đã đăng nhập. |
| Post-conditions | Success: Chỉ số KPI hiển thị chính xác. |
| Luồng sự kiện chính | Actor truy cập giao diện chức năng.<br>Include Use Case Xem Dashboard Admin.<br>Extend Use Case Lọc số liệu KPI.<br>Kết thúc Use case. |
| Luồng sự kiện phụ | Không có. |
| <Include Use Case Xem Dashboard Admin> | 1. Hệ thống tổng hợp tổng người dùng, tổng sự kiện và tổng doanh thu toàn sàn. |
| <Extend Use Case Lọc số liệu KPI> | 1. Actor chọn bộ lọc thời gian để tải lại biểu đồ. |

*Bảng 3-11. Mô tả use case chức năng Quản lý thống kê hệ thống.*


### 3.2.1.12 Quản lý người dùng

![Sơ đồ use-case chức năng Quản lý người dùng](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/21_UC_chi_tiet_Quan_ly_tai_khoan_admin.drawio)

*Hình 3-12. Use case của quy trình Quản lý người dùng*

| Thành phần | Nội dung chi tiết |
| :--- | :--- |
| Tên Use case | Quản lý người dùng |
| Actor | Quản trị viên |
| Mô tả | Quản trị viên xem danh sách tài khoản thành viên hệ thống và chọn khóa/mở khóa tài khoản hoặc xem chi tiết người dùng. |
| Pre-conditions | Quản trị viên đã đăng nhập. |
| Post-conditions | Success: Trạng thái người dùng được cập nhật. |
| Luồng sự kiện chính | Actor truy cập giao diện chức năng.<br>Include Use Case Xem danh sách người dùng.<br>Extend Use Case Khóa tài khoản.<br>Extend Use Case Xem chi tiết người dùng.<br>Kết thúc Use case. |
| Luồng sự kiện phụ | Không có. |
| <Include Use Case Xem danh sách người dùng> | 1. Hệ thống hiển thị toàn bộ danh sách tài khoản thành viên. |
| <Extend Use Case Khóa tài khoản> | 1. Actor chọn người dùng và nhấn Khóa/Mở khóa. |
| <Extend Use Case Xem chi tiết người dùng> | 1. Actor chọn Xem chi tiết để xem hồ sơ và lịch sử mua vé. |

*Bảng 3-12. Mô tả use case chức năng Quản lý người dùng.*


### 3.2.1.13 Quản lý phê duyệt ban tổ chức

![Sơ đồ use-case chức năng Quản lý phê duyệt ban tổ chức](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/22_UC_chi_tiet_Phe_duyet_doi_tac.drawio)

*Hình 3-13. Use case của quy trình Quản lý phê duyệt ban tổ chức*

| Thành phần | Nội dung chi tiết |
| :--- | :--- |
| Tên Use case | Quản lý phê duyệt ban tổ chức |
| Actor | Quản trị viên |
| Mô tả | Quản trị viên xem danh sách đơn đăng ký đối tác chờ duyệt và bấm chọn Phê duyệt đối tác hoặc Từ chối kèm lý do. |
| Pre-conditions | Quản trị viên đã đăng nhập. |
| Post-conditions | Success: Hồ sơ được xử lý phê duyệt hoặc từ chối. |
| Luồng sự kiện chính | Actor truy cập giao diện chức năng.<br>Include Use Case Xem danh sách hồ sơ chờ duyệt.<br>Extend Use Case Phê duyệt đối tác.<br>Extend Use Case Từ chối hồ sơ đối tác.<br>Kết thúc Use case. |
| Luồng sự kiện phụ | Không có. |
| <Include Use Case Xem danh sách hồ sơ chờ duyệt> | 1. Hệ thống hiển thị danh sách các yêu cầu nâng cấp Ban tổ chức. |
| <Extend Use Case Phê duyệt đối tác> | 1. Actor kiểm tra thông tin và nhấn Phê duyệt. |
| <Extend Use Case Từ chối hồ sơ đối tác> | 1. Actor nhấn Từ chối, nhập lý do và bấm Xác nhận. |

*Bảng 3-13. Mô tả use case chức năng Quản lý phê duyệt ban tổ chức.*


### 3.2.1.14 Quản lý phê duyệt sự kiện

![Sơ đồ use-case chức năng Quản lý phê duyệt sự kiện](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/23_UC_chi_tiet_Phe_duyet_su_kien.drawio)

*Hình 3-14. Use case của quy trình Quản lý phê duyệt sự kiện*

| Thành phần | Nội dung chi tiết |
| :--- | :--- |
| Tên Use case | Quản lý phê duyệt sự kiện |
| Actor | Quản trị viên |
| Mô tả | Quản trị viên xem danh sách sự kiện chờ duyệt mở bán và chọn Phê duyệt để lên Trang chủ hoặc Từ chối kèm lý do. |
| Pre-conditions | Quản trị viên đã đăng nhập. |
| Post-conditions | Success: Trạng thái sự kiện được cập nhật. |
| Luồng sự kiện chính | Actor truy cập giao diện chức năng.<br>Include Use Case Xem danh sách sự kiện chờ.<br>Extend Use Case Phê duyệt sự kiện.<br>Extend Use Case Từ chối mở bán sự kiện.<br>Kết thúc Use case. |
| Luồng sự kiện phụ | Không có. |
| <Include Use Case Xem danh sách sự kiện chờ> | 1. Hệ thống hiển thị danh sách các sự kiện chờ duyệt. |
| <Extend Use Case Phê duyệt sự kiện> | 1. Actor kiểm tra nội dung và nhấn Phê duyệt. |
| <Extend Use Case Từ chối mở bán sự kiện> | 1. Actor nhấn Từ chối, nhập lý do phản hồi cho BTC. |

*Bảng 3-14. Mô tả use case chức năng Phê duyệt sự kiện.*


### 3.2.1.15 Quản lý giám sát giao dịch

![Sơ đồ use-case chức năng Quản lý giám sát giao dịch](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/25_UC_chi_tiet_Giam_sat_don_hang.drawio)

*Hình 3-15. Use case của quy trình Quản lý giám sát giao dịch*

| Thành phần | Nội dung chi tiết |
| :--- | :--- |
| Tên Use case | Quản lý giám sát giao dịch |
| Actor | Quản trị viên |
| Mô tả | Quản trị viên xem danh sách nhật ký đơn hàng toàn hệ thống và bấm xem chi tiết thông tin đơn hàng. |
| Pre-conditions | Quản trị viên đã đăng nhập. |
| Post-conditions | Success: Nhật ký giao dịch hiển thị đầy đủ. |
| Luồng sự kiện chính | Actor truy cập giao diện chức năng.<br>Include Use Case Xem danh sách đơn toàn sàn.<br>Extend Use Case Xem chi tiết đơn hàng.<br>Kết thúc Use case. |
| Luồng sự kiện phụ | Không có. |
| <Include Use Case Xem danh sách đơn toàn sàn> | 1. Hệ thống hiển thị danh sách tất cả các đơn hàng mua vé toàn hệ thống. |
| <Extend Use Case Xem chi tiết đơn hàng> | 1. Actor chọn một đơn hàng và bấm Xem chi tiết. |

*Bảng 3-15. Mô tả use case chức năng Quản lý giám sát giao dịch.*



---

### 3.2.5 SƠ ĐỒ TUẦN TỰ (SEQUENCE DIAGRAMS - BẢO PHỦ THEO 4 VAI TRÒ)

#### 1. PHÂN HỆ VAI TRÒ 1: KHÁCH HÀNG
##### a. Luồng Mua vé và Thanh toán trực tuyến
![Sơ đồ tuần tự Mua vé và Thanh toán](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/SQ_KhachHang_DatVeThanhToan.drawio)
*Hình 3-21a. Sơ đồ tuần tự quy trình Mua vé và Thanh toán trực tuyến của Khách hàng*

---

#### 2. PHÂN HỆ VAI TRÒ 2: BAN TỔ CHỨC
##### a. Luồng Khởi tạo và Gửi duyệt sự kiện mới
![Sơ đồ tuần tự Tạo sự kiện](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/SQ_BanToChuc_TaoSuKien.drawio)
*Hình 3-21b. Sơ đồ tuần tự quy trình Khởi tạo và Gửi duyệt sự kiện của Ban tổ chức*

---

#### 3. PHÂN HỆ VAI TRÒ 3: NHÂN VIÊN SOÁT VÉ
##### a. Luồng Soát vé Check in tại cổng sự kiện
![Sơ đồ tuần tự Soát vé Check in](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/SQ_NhanVien_CheckIn.drawio)
*Hình 3-21c. Sơ đồ tuần tự quy trình Soát vé Check in của Nhân viên*

---

#### 4. PHÂN HỆ VAI TRÒ 4: QUẢN TRỊ VIÊN (ADMIN)
##### a. Luồng Phê duyệt mở bán sự kiện
![Sơ đồ tuần tự Phê duyệt sự kiện](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/SQ_Admin_PheDuyetSuKien.drawio)
*Hình 3-21d. Sơ đồ tuần tự quy trình Phê duyệt sự kiện của Quản trị viên*

---

### 3.2.6 SƠ ĐỒ HOẠT ĐỘNG (ACTIVITY DIAGRAMS - BẢO PHỦ THEO 4 VAI TRÒ)

#### 1. PHÂN HỆ VAI TRÒ 1: KHÁCH HÀNG
##### a. Quy trình Mua vé và Thanh toán
![Sơ đồ hoạt động Mua vé và Thanh toán](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/ACT_KhachHang_DatVeThanhToan.drawio)
*Hình 3-22a. Sơ đồ hoạt động quy trình Mua vé và Thanh toán của Khách hàng*

---

#### 2. PHÂN HỆ VAI TRÒ 2: BAN TỔ CHỨC
##### a. Quy trình Vòng đời sự kiện từ Khởi tạo đến Tổng kết
![Sơ đồ hoạt động Vòng đời sự kiện](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/ACT_BanToChuc_VongDoiSuKien.drawio)
*Hình 3-22b. Sơ đồ hoạt động quy trình Vòng đời sự kiện của Ban tổ chức*

---

#### 3. PHÂN HỆ VAI TRÒ 3: NHÂN VIÊN SOÁT VÉ
##### a. Quy trình Soát vé Check in tại cổng
![Sơ đồ hoạt động Soát vé Check in](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/ACT_NhanVien_CheckIn.drawio)
*Hình 3-22c. Sơ đồ hoạt động quy trình Soát vé Check in của Nhân viên*

---

#### 4. PHÂN HỆ VAI TRÒ 4: QUẢN TRỊ VIÊN (ADMIN)
##### a. Quy trình Thẩm định và Phê duyệt mở bán sự kiện
![Sơ đồ hoạt động Phê duyệt sự kiện](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/ACT_Admin_PheDuyetSuKien.drawio)
*Hình 3-22d. Sơ đồ hoạt động quy trình Phê duyệt sự kiện của Quản trị viên*


---

### 3.3 HỆ THỐNG MÀN HÌNH GIAO DIỆN HỆ THỐNG (BẢO PHỦ THEO 4 VAI TRÒ DỰA TRÊN VIEWS THỰC TẾ)

#### 3.3.1 PHÂN HỆ VAI TRÒ 1: KHÁCH HÀNG

##### 3.3.1.1 Giao diện Trang chủ và Tìm kiếm sự kiện
Giao diện trang chủ hiển thị các banner sự kiện nổi bật, thanh tìm kiếm từ khóa, bộ lọc lựa chọn Tỉnh/Thành phố và các thẻ thể loại danh mục sự kiện trực quan.
![Giao diện Trang chủ và Tìm kiếm sự kiện](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/UI_KhachHang_TrangChu.drawio)
*Hình 3-23a. Giao diện màn hình Trang chủ và Tìm kiếm sự kiện của Khách hàng*

##### 3.3.1.2 Giao diện Trang Chi tiết sự kiện và Tờ lịch xé
Màn hình hiển thị thông tin chi tiết sự kiện bao gồm ảnh bìa, mô tả nội dung, địa điểm diễn ra, bảng giá các loại vé, Tờ lịch xé điện tử, Lưới lịch tháng khoanh tròn ngày diễn ra và nút đồng bộ vào Google Calendar.
![Giao diện Chi tiết sự kiện và Tờ lịch xé](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/UI_KhachHang_ChiTietSuKien.drawio)
*Hình 3-23b. Giao diện màn hình Chi tiết sự kiện và Tờ lịch xé điện tử*

##### 3.3.1.3 Giao diện Màn hình Đặt vé và Sơ đồ chỗ ngồi Canvas
Màn hình cho phép Khách hàng chọn số lượng từng loại vé hoặc chọn trực tiếp các vị trí ghế ngồi trên sơ đồ phân khu Canvas theo màu sắc loại vé, đồng thời hiển thị đồng hồ đếm ngược 15 phút giữ chỗ.
![Giao diện Đặt vé và Sơ đồ chỗ ngồi Canvas](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/UI_KhachHang_DatVeSoDoCanvas.drawio)
*Hình 3-23c. Giao diện màn hình Đặt vé và Sơ đồ chỗ ngồi Canvas*

##### 3.3.1.4 Giao diện Thanh toán và Áp dụng Mã giảm giá
Màn hình cho phép Khách hàng nhập mã giảm giá Voucher, xem tổng số tiền cần thanh toán và lựa chọn phương thức thanh toán tự động (VNPAY, MoMo, ZaloPay, PayPal) hoặc Chuyển khoản ngân hàng.
![Giao diện Thanh toán và Mã giảm giá](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/UI_KhachHang_ThanhToanVoucher.drawio)
*Hình 3-23d. Giao diện màn hình Thanh toán và Áp dụng Mã giảm giá*

##### 3.3.1.5 Giao diện Vé của tôi và Cuống vé điện tử QR Code
Màn hình danh sách đơn hàng đã mua và chi tiết cuống vé điện tử hiển thị mã QR Code duy nhất dùng để quét check-in tại sự kiện.
![Giao diện Vé của tôi và Cuống vé QR Code](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/UI_KhachHang_VeCuaToiQRCode.drawio)
*Hình 3-23e. Giao diện màn hình Vé của tôi và Cuống vé điện tử QR Code*

##### 3.3.1.6 Giao diện Đăng ký làm Ban tổ chức
Màn hình biểu mẫu cho phép Khách hàng nhập thông tin liên hệ và số tài khoản ngân hàng để nộp hồ sơ xin nâng cấp vai trò Ban tổ chức.
![Giao diện Đăng ký làm Ban tổ chức](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/UI_KhachHang_DangKyBanToChuc.drawio)
*Hình 3-23f. Giao diện màn hình Đăng ký nâng cấp tài khoản Ban tổ chức*

---

#### 3.3.2 PHÂN HỆ VAI TRÒ 2: BAN TỔ CHỨC

##### 3.3.2.1 Giao diện Dashboard Thống kê hoạt động
Dashboard tổng quan hiển thị các chỉ số thống kê KPI về tổng số sự kiện, tổng số vé đã bán, tổng doanh thu và biểu đồ doanh số trực quan.
![Giao diện Dashboard Ban tổ chức](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/UI_BanToChuc_Dashboard.drawio)
*Hình 3-24a. Giao diện màn hình Dashboard Thống kê hoạt động Ban tổ chức*

##### 3.3.2.2 Giao diện Quản lý danh sách sự kiện
Màn hình danh sách các sự kiện do Ban tổ chức khởi tạo, hỗ trợ các thao tác Tạo mới, Chỉnh sửa, Nhân bản, Tạm dừng bán vé, Hủy sự kiện và Gửi duyệt mở bán.
![Giao diện Quản lý danh sách sự kiện](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/UI_BanToChuc_DanhSachSuKien.drawio)
*Hình 3-24b. Giao diện màn hình Quản lý danh sách sự kiện của Ban tổ chức*

##### 3.3.2.3 Giao diện Tạo mới và Chỉnh sửa sự kiện
Biểu mẫu cho phép Ban tổ chức nhập tên sự kiện, chọn danh mục, tải ảnh banner và lựa chọn địa điểm theo 3 cấp hành chính động (Tỉnh/Thành phố -> Quận/Huyện -> Phường/Xã).
![Giao diện Tạo mới và Chỉnh sửa sự kiện](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/UI_BanToChuc_TaoMoiSuKien.drawio)
*Hình 3-24c. Giao diện màn hình Tạo mới và Chỉnh sửa thông tin sự kiện*

##### 3.3.2.4 Giao diện Cấu hình Loại vé
Màn hình thiết lập các hạng vé (VIP, Thường...), giá bán, số lượng phát hành và giới hạn số lượng vé được mua trên mỗi đơn hàng.
![Giao diện Cấu hình Loại vé](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/UI_BanToChuc_CauHinhLoaiVe.drawio)
*Hình 3-24d. Giao diện màn hình Cấu hình Loại vé và Giá bán*

##### 3.3.2.5 Giao diện Thiết lập Sơ đồ chỗ ngồi Canvas
Màn hình thiết lập sơ đồ ghế trực quan cho phép Ban tổ chức cấu hình phân khu, sinh hàng ghế và thay đổi trạng thái từng vị trí ghế (Trống, Khóa, VIP).
![Giao diện Thiết lập Sơ đồ chỗ ngồi Canvas](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/UI_BanToChuc_SoDoChoNgoiCanvas.drawio)
*Hình 3-24e. Giao diện màn hình Thiết lập Sơ đồ chỗ ngồi Canvas*

##### 3.3.2.6 Giao diện Quản lý Đơn hàng và Duyệt chuyển khoản thủ công
Màn hình danh sách đơn hàng mua vé của sự kiện, cho phép Ban tổ chức kiểm tra và bấm xác nhận đã nhận tiền đối với các đơn thanh toán chuyển khoản ngân hàng.
![Giao diện Quản lý Đơn hàng và Duyệt chuyển khoản](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/UI_BanToChuc_QuanLyDonHang.drawio)
*Hình 3-24f. Giao diện màn hình Quản lý Đơn hàng và Duyệt chuyển khoản thủ công*

##### 3.3.2.7 Giao diện Quản lý và Phân công Nhân viên soát vé
Màn hình tạo tài khoản nhân viên Staff mới và gán quyền cho phép nhân viên thực hiện soát vé check-in tại sự kiện được chọn.
![Giao diện Quản lý và Phân công Nhân viên](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/UI_BanToChuc_QuanLyNhanVien.drawio)
*Hình 3-24g. Giao diện màn hình Quản lý và Phân công Nhân viên soát vé*

---

#### 3.3.3 PHÂN HỆ VAI TRÒ 3: NHÂN VIÊN SOÁT VÉ

##### 3.3.3.1 Giao diện Cổng Soát vé Check in bằng Camera QR WebRTC
Giao diện di động dành cho Nhân viên soát vé tích hợp camera quét mã QR Code trên vé điện tử, tự động nhận diện và hiển thị thông báo kết quả XANH (Check-in thành công) hoặc ĐỎ (Cảnh báo vé giả/vé đã sử dụng).
![Giao diện Cổng Soát vé Check in QR Code](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/UI_NhanVien_SoatVeCheckInQR.drawio)
*Hình 3-25a. Giao diện màn hình Cổng Soát vé Check in bằng Camera QR Code WebRTC*

---

#### 3.3.4 PHÂN HỆ VAI TRÒ 4: QUẢN TRỊ VIÊN (ADMIN)

##### 3.3.4.1 Giao diện Dashboard Thống kê hệ thống
Màn hình quản trị hiển thị các chỉ số KPI toàn hệ thống: Tổng số người dùng, Tổng số đối tác Ban tổ chức, Tổng số sự kiện và Tổng doanh thu giao dịch toàn sàn.
![Giao diện Dashboard Admin](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/UI_Admin_DashboardThongKe.drawio)
*Hình 3-26a. Giao diện màn hình Dashboard Thống kê hệ thống Quản trị viên*

##### 3.3.4.2 Giao diện Phê duyệt Yêu cầu làm Ban tổ chức
Màn hình danh sách đơn xin nâng cấp vai trò Ban tổ chức, cho phép Quản trị viên thẩm định thông tin ngân hàng và bấm Phê duyệt hoặc Từ chối kèm lý do.
![Giao diện Phê duyệt Yêu cầu Ban tổ chức](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/UI_Admin_PheDuyetBanToChuc.drawio)
*Hình 3-26b. Giao diện màn hình Phê duyệt Yêu cầu nâng cấp Ban tổ chức*

##### 3.3.4.3 Giao diện Kiểm định và Phê duyệt mở bán sự kiện
Màn hình danh sách các sự kiện mới tạo đang chờ duyệt, cho phép Quản trị viên kiểm tra nội dung và bấm Phê duyệt mở bán công khai trên Trang chủ hoặc Từ chối kèm lý do.
![Giao diện Phê duyệt mở bán sự kiện](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/UI_Admin_PheDuyetSuKien.drawio)
*Hình 3-26c. Giao diện màn hình Kiểm định và Phê duyệt mở bán sự kiện*

##### 3.3.4.4 Giao diện Quản lý Người dùng và Khóa mở khóa tài khoản
Màn hình quản lý toàn bộ danh sách tài khoản thành viên hệ thống, hỗ trợ xem chi tiết thông tin, xuất file CSV và thực hiện Khóa hoặc Mở khóa tài khoản.
![Giao diện Quản lý Người dùng](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/UI_Admin_QuanLyNguoiDung.drawio)
*Hình 3-26d. Giao diện màn hình Quản lý Người dùng và Khóa mở khóa tài khoản*

##### 3.3.4.5 Giao diện Quản lý Danh mục thể loại
Màn hình danh sách các danh mục thể loại sự kiện cho phép Quản trị viên Thêm mới, Chỉnh sửa, Xóa danh mục và gán biểu tượng Icon đại diện.
![Giao diện Quản lý Danh mục](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/UI_Admin_QuanLyDanhMuc.drawio)
*Hình 3-26e. Giao diện màn hình Quản lý Danh mục thể loại sự kiện*

##### 3.3.4.6 Giao diện Giám sát giao dịch đơn hàng toàn sàn
Màn hình cho phép Quản trị viên giám sát nhật ký tất cả các đơn hàng mua vé toàn sàn, tìm kiếm theo mã đơn hoặc khoảng thời gian.
![Giao diện Giám sát giao dịch](file:///c:/Users/Wuang/Desktop/Vibe/docs/drawio/UI_Admin_GiamSatGiaoDich.drawio)
*Hình 3-26f. Giao diện màn hình Giám sát giao dịch đơn hàng toàn sàn*

