# Quy tắc chỉnh sửa một sự kiện

## 1. Các trạng thái sự kiện

| Mã | Trạng thái | Ý nghĩa |
|---:|---|---|
| 0 | Bản nháp | BTC đang chuẩn bị, chưa gửi quản trị viên duyệt. |
| 1 | Chờ duyệt | Đã gửi quản trị viên nhưng chưa được duyệt. |
| 2 | Tạm dừng | Sự kiện từng mở bán nhưng BTC đã tạm dừng để xử lý hoặc chỉnh sửa. |
| 3 | Đang mở bán | Khách có thể xem và đặt vé. |
| 4 | Đã bán hết | Không còn vé để bán. |
| 5 | Đã kết thúc | Sự kiện đã qua thời gian kết thúc. |
| 6 | Đã hủy | Sự kiện không còn được vận hành. |
| 7 | Bị từ chối | Quản trị viên từ chối; BTC được sửa và gửi duyệt lại. |

Luồng thường dùng:

`Bản nháp → Chờ duyệt → Đang mở bán → Kết thúc`

Nếu cần sửa cấu trúc khi đang bán:

`Đang mở bán → Tạm dừng → Chỉnh sửa → Gửi duyệt lại`

## 2. Bảng quyền chỉnh sửa

| Mục quản lý | Khi được sửa | Ràng buộc bổ sung |
|---|---|---|
| Thông tin sự kiện | Bản nháp, chờ duyệt, tạm dừng, bị từ chối | Đang mở bán phải tạm dừng trước. Thời gian kết thúc phải sau thời gian bắt đầu. Link sự kiện online phải là URL hợp lệ. |
| Loại vé | Bản nháp, tạm dừng, bị từ chối | Không được giảm tổng số vé thấp hơn số đã bán. Loại vé đã bán giữ nguyên tên và giá để vé cũ không đổi nghĩa. |
| Sơ đồ chỗ ngồi | Bản nháp, tạm dừng, bị từ chối | Không tạo lại hoặc xóa khi đã có đơn giữ chỗ/vé đã thanh toán. Mỗi khu phải gắn với một loại vé của sự kiện. |
| Mã giảm giá | Bản nháp, tạm dừng, đang mở bán, bán hết, bị từ chối | Không sửa khi chờ duyệt, đã hủy hoặc kết thúc. Tổng lượt dùng không được nhỏ hơn lượt đã dùng; mã đã dùng không được xóa. |
| Phân công soát vé | Bản nháp, tạm dừng, đang mở bán, bán hết, bị từ chối | Không đổi khi chờ duyệt, hủy hoặc kết thúc. Chỉ tài khoản Staff do BTC đó tạo mới được phân công. |
| Đơn hàng | Chỉ xem/lọc trong sự kiện đang quản lý | BTC chỉ hủy được đơn đang chờ thanh toán; đơn đã thanh toán không được sửa thủ công. |
| Khách tham dự | Chỉ đọc | Chỉ lấy người từ đơn đã thanh toán. |
| Báo cáo | Chỉ đọc | Doanh thu và vé bán chỉ tính đơn đã thanh toán. |
| Check-in | Trong khung giờ check-in của sự kiện trực tiếp | Chỉ vé thuộc đơn đã thanh toán; một vé không được check-in hai lần. Sự kiện online không dùng QR check-in. |

Ngoài trạng thái, các trang cấu hình còn khóa khi thời gian kết thúc sự kiện đã qua.

## 3. Vì sao phải tạm dừng trước khi sửa vé hoặc sơ đồ?

Khi sự kiện đang mở bán, khách có thể đồng thời chọn vé và giữ ghế. Nếu BTC đổi loại vé hoặc xóa sơ đồ đúng lúc đó, đơn hàng có thể tham chiếu đến loại vé/ghế không còn tồn tại. Vì vậy hệ thống buộc BTC tạm dừng trước, rồi mới cho đổi cấu trúc.

Mã giảm giá và nhân sự không làm thay đổi cấu trúc của vé đã đặt nên vẫn được phép quản lý trong lúc mở bán.

## 4. Các lớp bảo vệ trong code

Một nút bị vô hiệu hóa trên View chỉ giúp người dùng hiểu trạng thái; đó chưa phải bảo mật. Controller vẫn kiểm tra lại toàn bộ điều kiện:

1. `LaSuKienCuaToi(id)` kiểm tra sự kiện có thuộc BTC đang đăng nhập không.
2. `LaCauHinhVeHoacSoDoBiKhoa(id)` khóa cấu trúc vé/ghế nếu trạng thái không phù hợp.
3. `LaNghiepVuVanHanhBiKhoa(id)` khóa voucher/nhân sự khi chờ duyệt, hủy hoặc kết thúc.
4. Câu SQL có `WHERE NguoiToChucId = @organizerId` để người dùng không thể sửa sự kiện của BTC khác bằng cách đổi ID trên URL.
5. Các phép `UPDATE` có thêm điều kiện số lượng và trạng thái; nếu không có dòng nào được cập nhật, Controller báo lỗi thay vì báo thành công giả.

Code chính nằm tại:

- `Controllers/OrganizerController.cs`: nhận request, kiểm tra ràng buộc, chạy SQL và chọn View/redirect.
- `Views/Organizer/*.cshtml`: hiển thị dữ liệu, form và trạng thái khóa/mở của nút.
- `Models/*.cs`: mô tả dữ liệu mà Dapper ánh xạ từ cột SQL sang object C#.
- `Models/Db.cs`: mở kết nối SQL Server và cung cấp các hàm Dapper dùng chung.

## 5. Sơ đồ tùy chỉnh hoạt động thế nào?

Khi chọn **Tùy chỉnh**, View bắt đầu bằng một khu vực. BTC được:

- đổi tên khu;
- chọn loại vé cho khu;
- nhập số hàng từ 1 đến 50;
- nhập số ghế mỗi hàng từ 1 đến 60;
- chọn màu và thêm tối đa 20 khu vực.

Controller kiểm tra tổng sơ đồ tối đa 5.000 ghế. Tổng số ghế của các khu cùng một loại vé không được lớn hơn `SoLuongTong` của loại vé đó. Sau khi hợp lệ, Controller lần lượt tạo `SoDoChoNgoi → KhuVuc → HangGhe → ChoNgoi`.

## 6. Dữ liệu dùng lúc phản biện ngày 06/08/2026

| Nội dung demo | Sự kiện | Thời gian Việt Nam |
|---|---|---|
| Check-in trực tiếp | Đêm Jazz Sài Gòn: Thanh Âm Mùa Hạ | Check-in 10:00–11:30; diễn ra 11:00–13:00 |
| Mua vé theo sơ đồ ghế | WuangEvents Live 2026: Âm Sắc Thành Phố | 14:00–17:00 |
| Đăng ký vé miễn phí | Ngày Hội Yoga Và Sống Khỏe | 15:00–17:00 |
| Vé sự kiện trực tuyến | Kết Nối Ngành Game Việt 2026 | 16:00–18:00 |
| Tạo sơ đồ tùy chỉnh | Triển Lãm Cưới Việt Nam 2026 | Bản nháp, chưa có sơ đồ |

Ngay trước khi trình diễn đơn chờ thanh toán, chạy `CHUAN_BI_DON_CHO_DEMO.cmd`. File này căn lại giờ sự kiện và làm mới đơn demo để bộ đếm còn khoảng 9 phút.
