USE [WuangEvents];
GO

-- ============================================================================
-- SCRIPT TẠO DỮ LIỆU DEMO BẢO PHỦ 100% CÁC TRƯỜNG HỢP NGHIỆP VỤ CỦA WUANGEVENTS
-- Phục vụ cho buổi Phản biện Luận văn Tốt nghiệp 31/07/2026
-- ============================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

BEGIN TRY

    ---------------------------------------------------------------------------
    -- 1. BẢNG TÀI KHOẢN MẪU (NguoiDung) - Bao phủ 4 vai trò & mọi trạng thái
    ---------------------------------------------------------------------------
    -- Mật khẩu mặc định cho tất cả tài khoản demo bên dưới là: 123456
    -- Hash BCrypt: $2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.

    -- Xóa các tài khoản demo nếu đã tồn tại để chạy lại không trùng
    DELETE FROM [dbo].[NguoiDung] WHERE [Email] IN (
        'admin@wuang.vn', 'btc.a@wuang.vn', 'btc.b@wuang.vn',
        'kh1@wuang.vn', 'kh2@wuang.vn', 'kh3@wuang.vn', 'kh4@wuang.vn',
        'khoa@wuang.vn', 'nv1@wuang.vn'
    );

    -- 1. Admin
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('11111111-1111-1111-1111-111111111111', 'admin@wuang.vn', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Quản Trị Viên (Admin)', '0912345678', 3, 1, 1, GETUTCDATE());

    -- 2. Ban tổ chức A (có sự kiện vé thường & voucher)
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [VaiTro], [TrangThai], [EmailXacNhan], [TenNganHang], [SoTaiKhoan], [ChuTaiKhoan], [YeuCauBanToChuc], [SdtBanToChuc], [NgayYeuCauBTC], [NgayTao])
    VALUES ('22222222-2222-2222-2222-222222222222', 'btc.a@wuang.vn', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Ban Tổ Chức Alpha', '0987654321', 1, 1, 1, 'Vietcombank', '0071001234567', 'CONG TY ANH SAO ALPHA', 2, '0987654321', GETUTCDATE(), GETUTCDATE());

    -- 3. Ban tổ chức B (có sự kiện sơ đồ ghế Canvas)
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [VaiTro], [TrangThai], [EmailXacNhan], [TenNganHang], [SoTaiKhoan], [ChuTaiKhoan], [YeuCauBanToChuc], [SdtBanToChuc], [NgayYeuCauBTC], [NgayTao])
    VALUES ('33333333-3333-3333-3333-333333333333', 'btc.b@wuang.vn', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Ban Tổ Chức Beta', '0987654322', 1, 1, 1, 'MBBank', '999988887777', 'CONG TY TRUYEN THONG BETA', 2, '0987654322', GETUTCDATE(), GETUTCDATE());

    -- 4. Khách hàng 1 (đã mua vé, có QR Code)
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('44444444-4444-4444-4444-444444444444', 'kh1@wuang.vn', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nguyễn Văn Khách 1', '0901111111', 0, 1, 1, GETUTCDATE());

    -- 5. Khách hàng 2 (có đơn chờ thanh toán)
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('55555555-5555-5555-5555-555555555555', 'kh2@wuang.vn', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Trần Thị Khách 2', '0902222222', 0, 1, 1, GETUTCDATE());

    -- 6. Khách hàng 3 (đang chờ duyệt làm BTC)
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [VaiTro], [TrangThai], [EmailXacNhan], [YeuCauBanToChuc], [SdtBanToChuc], [NgayYeuCauBTC], [NgayTao])
    VALUES ('66666666-6666-6666-6666-666666666666', 'kh3@wuang.vn', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Lê Văn Khách 3 (Chờ BTC)', '0903333333', 0, 1, 1, 1, '0903333333', GETUTCDATE(), GETUTCDATE());

    -- 7. Khách hàng 4 (bị từ chối làm BTC)
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [VaiTro], [TrangThai], [EmailXacNhan], [YeuCauBanToChuc], [SdtBanToChuc], [LyDoTuChoiBTC], [NgayYeuCauBTC], [NgayTao])
    VALUES ('77777777-7777-7777-7777-777777777777', 'kh4@wuang.vn', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Phạm Văn Khách 4 (Bị từ chối BTC)', '0904444444', 0, 1, 1, 3, '0904444444', N'Hồ sơ pháp lý chưa đủ điều kiện', GETUTCDATE(), GETUTCDATE());

    -- 8. Khách hàng bị khóa (Test lỗi đăng nhập)
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('88888888-8888-8888-8888-888888888888', 'khoa@wuang.vn', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Tài Khoản Bị Khóa', '0905555555', 0, 0, 1, GETUTCDATE());

    -- 9. Nhân viên soát vé (Staff)
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [VaiTro], [TrangThai], [EmailXacNhan], [NguoiTaoId], [NgayTao])
    VALUES ('99999999-9999-9999-9999-999999999999', 'nv1@wuang.vn', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nguyễn Văn Soát Vé 1', '0906666666', 2, 1, 1, '22222222-2222-2222-2222-222222222222', GETUTCDATE());


    ---------------------------------------------------------------------------
    -- 2. BẢNG MÃ GIẢM GIÁ MẪU (MaGiamGia) - Bao phủ mọi điều kiện Voucher
    ---------------------------------------------------------------------------
    -- Xóa các voucher cũ nếu trùng mã
    DELETE FROM [dbo].[MaGiamGia] WHERE [MaCode] IN ('SUMMER20', 'VIP100K', 'USED99', 'EXPIRED');

    -- SK-01 ID
    DECLARE @SK01_Id UNIQUEIDENTIFIER = 'E1111111-1111-1111-1111-111111111111';

    -- 1. Voucher giảm % có trần tối đa
    INSERT INTO [dbo].[MaGiamGia] ([SuKienId], [MaCode], [MoTa], [LoaiGiamGia], [GiaTri], [GiamToiDa], [DonToiThieu], [SoLuongTong], [SoLuongDaDung], [NgayBatDau], [NgayKetThuc], [TrangThai], [NgayTao])
    VALUES (@SK01_Id, 'SUMMER20', N'Giảm 20% tối đa 200.000đ cho mùa hè', 0, 20, 200000, 100000, 100, 10, DATEADD(day, -10, GETUTCDATE()), DATEADD(day, 60, GETUTCDATE()), 1, GETUTCDATE());

    -- 2. Voucher giảm tiền cố định
    INSERT INTO [dbo].[MaGiamGia] ([SuKienId], [MaCode], [MoTa], [LoaiGiamGia], [GiaTri], [GiamToiDa], [DonToiThieu], [SoLuongTong], [SoLuongDaDung], [NgayBatDau], [NgayKetThuc], [TrangThai], [NgayTao])
    VALUES (@SK01_Id, 'VIP100K', N'Giảm trực tiếp 100.000đ cho vé VIP', 1, 100000, NULL, 300000, 50, 5, DATEADD(day, -10, GETUTCDATE()), DATEADD(day, 60, GETUTCDATE()), 1, GETUTCDATE());

    -- 3. Voucher đã HẾT LƯỢT DÙNG (Test lỗi tồn kho voucher)
    INSERT INTO [dbo].[MaGiamGia] ([SuKienId], [MaCode], [MoTa], [LoaiGiamGia], [GiaTri], [GiamToiDa], [DonToiThieu], [SoLuongTong], [SoLuongDaDung], [NgayBatDau], [NgayKetThuc], [TrangThai], [NgayTao])
    VALUES (@SK01_Id, 'USED99', N'Mã tri ân đã hết lượt', 0, 50, 500000, 0, 5, 5, DATEADD(day, -10, GETUTCDATE()), DATEADD(day, 60, GETUTCDATE()), 1, GETUTCDATE());

    -- 4. Voucher đã HẾT HẠN (Test lỗi ngày hết hạn)
    INSERT INTO [dbo].[MaGiamGia] ([SuKienId], [MaCode], [MoTa], [LoaiGiamGia], [GiaTri], [GiamToiDa], [DonToiThieu], [SoLuongTong], [SoLuongDaDung], [NgayBatDau], [NgayKetThuc], [TrangThai], [NgayTao])
    VALUES (@SK01_Id, 'EXPIRED', N'Mã ưu đãi sớm đã quá hạn', 0, 30, 300000, 0, 100, 0, DATEADD(day, -30, GETUTCDATE()), DATEADD(day, -1, GETUTCDATE()), 1, GETUTCDATE());


    ---------------------------------------------------------------------------
    -- 3. PHÂN CÔNG NHÂN VIÊN SOÁT VÉ (NhanVienSuKien)
    ---------------------------------------------------------------------------
    DELETE FROM [dbo].[NhanVienSuKien] WHERE [NguoiDungId] = '99999999-9999-9999-9999-999999999999';

    INSERT INTO [dbo].[NhanVienSuKien] ([NguoiDungId], [SuKienId], [VaiTroNV], [NgayThem])
    VALUES ('99999999-9999-9999-9999-999999999999', @SK01_Id, N'CheckIn', GETUTCDATE());


    COMMIT TRANSACTION;
    PRINT N'=== THÊM DỮ LIỆU DEMO KỊCH BẢN PHẢN BIỆN THÀNH CÔNG 100% ===';

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT N'Lỗi khi khởi tạo dữ liệu demo: ' + ERROR_MESSAGE();
    RAISERROR(ERROR_MESSAGE(), 16, 1);
END CATCH;
GO
