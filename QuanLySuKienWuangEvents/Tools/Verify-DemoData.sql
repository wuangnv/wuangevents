USE [WuangEvents];
GO

SET NOCOUNT ON;

-- Kiểm tra nhanh sau khi seed. Có lỗi thì sqlcmd trả mã lỗi khác 0 để file CMD dừng lại.
DECLARE @NowVietnam DATETIME2(7) = DATEADD(hour, 7, GETUTCDATE());
DECLARE @OrganizerId UNIQUEIDENTIFIER = '5B5CE913-3124-448A-812B-85B5A4AB1A03';
DECLARE @BuyerId UNIQUEIDENTIFIER = '77EDA4D0-64A0-4CD8-9BC0-C4B56C3DBA52';
DECLARE @DraftEventId UNIQUEIDENTIFIER = 'E0000000-0000-0000-0000-000000000051';
DECLARE @PausedEditorEventId UNIQUEIDENTIFIER = 'E0000000-0000-0000-0000-000000000054';

IF (SELECT COUNT(*) FROM dbo.NguoiDung
    WHERE Email IN ('admin@gmail.com', 'organizer1@gmail.com', 'battlegrounds2004@gmail.com', 'staff1@gmail.com')) <> 4
    THROW 51001, N'Thiếu tài khoản demo chính.', 1;

IF EXISTS (
    SELECT TrangThai FROM (VALUES (0), (1), (2), (3), (5), (6), (7)) AS Required(TrangThai)
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.SuKien sk
        WHERE sk.NguoiToChucId = @OrganizerId AND sk.TrangThai = Required.TrangThai))
    THROW 51002, N'Tài khoản organizer1 chưa có đủ các trạng thái sự kiện để demo.', 1;

IF NOT EXISTS (SELECT 1 FROM dbo.SuKien WHERE LoaiSuKien = 1 AND TrangThai = 3)
    THROW 51003, N'Thiếu sự kiện trực tuyến đang mở bán.', 1;

IF NOT EXISTS (SELECT 1 FROM dbo.SuKien WHERE LoaiSuKien = 0 AND CoSoDoChoNgoi = 1)
    THROW 51004, N'Thiếu sự kiện trực tiếp có sơ đồ ghế.', 1;

IF NOT EXISTS (SELECT 1 FROM dbo.LoaiVe WHERE GiaBan = 0)
   OR NOT EXISTS (SELECT 1 FROM dbo.LoaiVe WHERE GiaBan BETWEEN 50000 AND 100000)
   OR NOT EXISTS (SELECT 1 FROM dbo.LoaiVe WHERE GiaBan > 100000)
    THROW 51005, N'Chưa có đủ nhóm vé miễn phí, phổ thông và vé demo giá cao.', 1;

-- Sự kiện miễn phí chỉ có duy nhất một loại vé để giao diện mua vé rõ ràng, không có VIP/Vé thường cùng giá 0đ.
IF EXISTS (
    SELECT 1
    FROM dbo.SuKien sk
    JOIN dbo.LoaiVe lv ON lv.SuKienId = sk.Id AND lv.TrangThai = 1
    GROUP BY sk.Id
    HAVING MAX(lv.GiaBan) = 0
       AND (COUNT(*) <> 1 OR MAX(lv.TenLoaiVe) <> N'Vé miễn phí'))
    THROW 51014, N'Sự kiện miễn phí phải chỉ có một loại Vé miễn phí.', 1;

IF EXISTS (
    SELECT 1
    FROM dbo.SuKien sk
    WHERE sk.TrangThai = 3
      AND sk.NgayKetThuc > @NowVietnam
      AND NOT EXISTS (
          SELECT 1 FROM dbo.LoaiVe lv
          WHERE lv.SuKienId = sk.Id
            AND lv.TrangThai = 1
            AND (lv.NgayBatDauBan IS NULL OR lv.NgayBatDauBan <= @NowVietnam)
             AND (lv.NgayKetThucBan IS NULL OR lv.NgayKetThucBan >= @NowVietnam)))
    THROW 51012, N'Có sự kiện đang bán nhưng không có loại vé mở bán ngay.', 1;

IF EXISTS (
    SELECT TrangThai FROM (VALUES (0), (1), (2), (4)) AS Required(TrangThai)
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.DonHang dh
        WHERE dh.NguoiMuaId = @BuyerId AND dh.TrangThai = Required.TrangThai))
    THROW 51006, N'buyer1 chưa có đủ các trạng thái đơn hàng để demo.', 1;

IF EXISTS (
    SELECT 1
    FROM dbo.DonHang dh
    JOIN dbo.ChiTietDonHang ct ON ct.DonHangId = dh.Id
    JOIN dbo.SuKien sk ON sk.Id = dh.SuKienId
    WHERE sk.LoaiSuKien = 1
      AND (ct.MaQRCode IS NOT NULL OR ct.TrangThaiCheckin <> 0 OR ct.NgayCheckin IS NOT NULL))
    THROW 51007, N'Ve trực tuyến không được có QR hoặc trạng thái check-in tại cổng.', 1;

IF EXISTS (
    SELECT 1
    FROM dbo.DonHang dh
    JOIN dbo.ChiTietDonHang ct ON ct.DonHangId = dh.Id
    JOIN dbo.SuKien sk ON sk.Id = dh.SuKienId
    WHERE sk.LoaiSuKien = 0
      AND sk.NgayBatDau > @NowVietnam
      AND ct.TrangThaiCheckin <> 0)
    THROW 51008, N'Có vé trực tiếp được check-in trước giờ bắt đầu.', 1;

IF EXISTS (SELECT 1 FROM dbo.DonHang WHERE SuKienId = @DraftEventId)
   OR EXISTS (SELECT 1 FROM dbo.SoDoChoNgoi WHERE SuKienId = @DraftEventId)
    THROW 51009, N'Sự kiện nháp cấu hình sơ đồ phải không có đơn hàng hoặc sơ đồ cũ.', 1;

IF NOT EXISTS (
        SELECT 1
        FROM dbo.SuKien
        WHERE Id = @PausedEditorEventId
          AND NguoiToChucId = @OrganizerId
          AND TrangThai = 2
          AND CoSoDoChoNgoi = 0)
   OR EXISTS (SELECT 1 FROM dbo.DonHang WHERE SuKienId = @PausedEditorEventId)
   OR EXISTS (SELECT 1 FROM dbo.SoDoChoNgoi WHERE SuKienId = @PausedEditorEventId)
    THROW 51013, N'Sự kiện tạm dừng dùng để chỉnh sơ đồ phải không có đơn hàng hoặc sơ đồ cũ.', 1;

IF NOT EXISTS (
    SELECT 1 FROM dbo.NhanVienSuKien
    WHERE NguoiDungId = '55F02A90-5841-4563-A735-C12B9717BB96')
    THROW 51010, N'staff1 chưa được phân công sự kiện.', 1;

IF NOT EXISTS (
    SELECT 1 FROM dbo.DonHang
    WHERE NguoiMuaId = @BuyerId
      AND TrangThai = 0
      AND NgayTao >= DATEADD(minute, -9, GETUTCDATE()))
    THROW 51011, N'Không tạo được đơn chờ thanh toán mới để demo đồng hồ đếm ngược.', 1;

PRINT N'KIEM_TRA_DEMO: DAT';
SELECT
    (SELECT COUNT(*) FROM dbo.SuKien) AS SoSuKien,
    (SELECT COUNT(*) FROM dbo.LoaiVe) AS SoLoaiVe,
    (SELECT COUNT(*) FROM dbo.DonHang) AS SoDonHang,
    (SELECT COUNT(*) FROM dbo.ChoNgoi) AS SoGhe,
    CONVERT(varchar(19), @NowVietnam, 120) AS ThoiGianVietNam;
GO
