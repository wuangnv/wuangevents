-- WuangEvents database hardening migration
-- Created: 2026-06-01
-- Safe to run repeatedly on an existing WuangEvents database.
-- Run: dotnet run --project tools\WuangEvents.DatabaseMigrator -- docs\database\hardening_20260601.sql

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

BEGIN TRY
    -- Normalize legacy ticket counters before adding stricter constraints.
    UPDATE dbo.LoaiVe
    SET SoLuongTong = CASE WHEN SoLuongTong < 1 THEN 1 ELSE SoLuongTong END;

    UPDATE dbo.LoaiVe
    SET SoLuongDaBan = CASE
        WHEN SoLuongDaBan < 0 THEN 0
        WHEN SoLuongDaBan > SoLuongTong THEN SoLuongTong
        ELSE SoLuongDaBan
    END;

    UPDATE dbo.LoaiVe
    SET SoLuongGiuCho = CASE
        WHEN SoLuongGiuCho < 0 THEN 0
        WHEN SoLuongDaBan + SoLuongGiuCho > SoLuongTong THEN SoLuongTong - SoLuongDaBan
        ELSE SoLuongGiuCho
    END,
    GioiHanMoiDon = CASE WHEN GioiHanMoiDon < 1 THEN 1 ELSE GioiHanMoiDon END;

    IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_LoaiVe_SoLuongGiuCho')
        ALTER TABLE dbo.LoaiVe WITH CHECK
        ADD CONSTRAINT CK_LoaiVe_SoLuongGiuCho
        CHECK (SoLuongGiuCho >= 0 AND SoLuongDaBan + SoLuongGiuCho <= SoLuongTong);

    IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_LoaiVe_GioiHanMoiDon')
        ALTER TABLE dbo.LoaiVe WITH CHECK
        ADD CONSTRAINT CK_LoaiVe_GioiHanMoiDon CHECK (GioiHanMoiDon > 0);

    IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_LoaiVe_ThoiGianBan')
        ALTER TABLE dbo.LoaiVe WITH CHECK
        ADD CONSTRAINT CK_LoaiVe_ThoiGianBan
        CHECK (NgayBatDauBan IS NULL OR NgayKetThucBan IS NULL OR NgayBatDauBan <= NgayKetThucBan);

    UPDATE dbo.MaGiamGia
    SET GioiHanMoiNguoi = CASE WHEN GioiHanMoiNguoi < 1 THEN 1 ELSE GioiHanMoiNguoi END;

    IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_MaGiamGia_Hardening')
        ALTER TABLE dbo.MaGiamGia WITH CHECK
        ADD CONSTRAINT CK_MaGiamGia_Hardening
        CHECK (
            LoaiGiamGia IN (0, 1)
            AND GiaTri > 0
            AND (LoaiGiamGia <> 0 OR GiaTri <= 100)
            AND SoLuongTong > 0
            AND SoLuongDaDung >= 0
            AND SoLuongDaDung <= SoLuongTong
            AND GioiHanMoiNguoi > 0
            AND NgayBatDau <= NgayKetThuc
        );

    UPDATE dbo.DonHang
    SET ThoiGianGiuCho = COALESCE(NgayCapNhat, NgayTao, GETUTCDATE())
    WHERE ThoiGianGiuCho IS NULL;

    IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_DonHang_ThoiGianGiuCho' AND object_id = OBJECT_ID('dbo.DonHang'))
        DROP INDEX IX_DonHang_ThoiGianGiuCho ON dbo.DonHang;

    ALTER TABLE dbo.DonHang ALTER COLUMN ThoiGianGiuCho DATETIME2(7) NOT NULL;

    CREATE NONCLUSTERED INDEX IX_DonHang_ThoiGianGiuCho
        ON dbo.DonHang (ThoiGianGiuCho)
        WHERE TrangThai = 0;

    -- Keep the most reliable payment row before enforcing one payment per order.
    ;WITH RankedPayments AS (
        SELECT Id,
               ROW_NUMBER() OVER (
                   PARTITION BY DonHangId
                   ORDER BY CASE WHEN TrangThai = 1 THEN 0 ELSE 1 END, NgayTao DESC, Id DESC
               ) AS RowNumber
        FROM dbo.ThanhToan
    )
    DELETE FROM RankedPayments WHERE RowNumber > 1;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_ThanhToan_DonHangId' AND object_id = OBJECT_ID('dbo.ThanhToan'))
        CREATE UNIQUE NONCLUSTERED INDEX UX_ThanhToan_DonHangId ON dbo.ThanhToan (DonHangId);

    -- A voucher reservation belongs to one order. Remove duplicate legacy rows conservatively.
    ;WITH RankedVoucherReservations AS (
        SELECT Id,
               ROW_NUMBER() OVER (PARTITION BY DonHangId ORDER BY NgaySuDung DESC, Id DESC) AS RowNumber
        FROM dbo.LichSuMaGiamGia
    )
    DELETE FROM RankedVoucherReservations WHERE RowNumber > 1;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_LichSuMaGiamGia_DonHangId' AND object_id = OBJECT_ID('dbo.LichSuMaGiamGia'))
        CREATE UNIQUE NONCLUSTERED INDEX UX_LichSuMaGiamGia_DonHangId ON dbo.LichSuMaGiamGia (DonHangId);

    IF OBJECT_ID('dbo.SoDuOrganizer') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM dbo.SoDuOrganizer WHERE SoDuKhaDung < 0 OR SoDuDongBang < 0)
       AND NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_SoDuOrganizer_KhongAm')
        ALTER TABLE dbo.SoDuOrganizer WITH CHECK
        ADD CONSTRAINT CK_SoDuOrganizer_KhongAm CHECK (SoDuKhaDung >= 0 AND SoDuDongBang >= 0);

    IF OBJECT_ID('dbo.YeuCauRutTien') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM dbo.YeuCauRutTien WHERE SoTien <= 0)
       AND NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_YeuCauRutTien_SoTien')
        ALTER TABLE dbo.YeuCauRutTien WITH CHECK
        ADD CONSTRAINT CK_YeuCauRutTien_SoTien CHECK (SoTien > 0);

    UPDATE dbo.CauHinhHeThong
    SET GiaTri = 'http://localhost:5127/Booking/PaymentReturn',
        NgayCapNhat = GETUTCDATE()
    WHERE MaCauHinh = 'VNPay_ReturnUrl'
      AND GiaTri LIKE '%/thanh-toan/ket-qua';

    COMMIT TRANSACTION;
    PRINT N'WuangEvents database hardening completed.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    THROW;
END CATCH;
GO
