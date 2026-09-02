# Hoàn nguyên trình chỉnh sơ đồ kéo-thả

Chức năng kéo-thả không thay đổi cấu trúc cơ sở dữ liệu và không thêm bảng.

Để trở về giao diện cấu hình dạng danh sách/lưới trước đó, trong `appsettings.json` đổi:

```json
"SeatMapEditor": {
  "EnableDragDrop": false
}
```

Sau đó dừng và chạy lại ứng dụng. Dữ liệu sơ đồ, các đơn hàng, ghế đã bán và luồng thanh toán giữ nguyên.

Đổi giá trị thành `true` để bật lại trình kéo-thả.
