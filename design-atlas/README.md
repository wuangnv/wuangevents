# WuangEvents Design Atlas

Prototype giao diện độc lập, được sinh từ nghiệp vụ, route và schema của
WuangEvents. Atlas không được bundle vào ứng dụng ASP.NET Core MVC và không
thay thế source production.

## Nguồn quyết định

1. Controller, authorization và SQL schema quyết định nghiệp vụ.
2. Views/CSS hiện tại quyết định motif và nhận diện WuangEvents.
3. Atlas quyết định bố cục mục tiêu, interaction và trạng thái responsive.

## Chạy Atlas

```powershell
cd design-atlas
node scripts/serve-atlas.cjs
```

Mở `http://127.0.0.1:4180`.

## Nhóm màn hình

| Nhóm | Phạm vi |
|---|---|
| M0 | Nền tảng giao diện và trạng thái dùng chung |
| M1 | Khám phá sự kiện và tài khoản |
| M2 | Đặt vé, thanh toán và vé của tôi |
| M3 | Thiết lập sự kiện của Ban tổ chức |
| M4 | Vận hành, bán hàng và báo cáo sự kiện |
| M5 | Công việc của Nhân viên soát vé |
| M6 | Quản trị hệ thống |

## Nguyên tắc

- Một manifest quản lý toàn bộ màn hình và quyền truy cập.
- Fixture chỉ là dữ liệu minh họa nhưng phải tuân theo schema thật.
- Primitive dùng chung được sửa một lần và cập nhật mọi màn hình.
- Trang công khai và portal dùng chung token nhưng không ép chung một shell.
- Mỗi screen phải vượt kiểm tra console, overflow và viewport trước khi duyệt.
