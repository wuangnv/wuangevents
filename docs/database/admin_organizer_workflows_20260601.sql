-- WuangEvents Admin and Organizer workflow migration
-- Created: 2026-06-01
-- Safe to run repeatedly after schema.sql and payout_schema.sql.

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

BEGIN TRY
    IF COL_LENGTH('dbo.ThongTinBanToChuc', 'PhiNenTang') IS NULL
        ALTER TABLE dbo.ThongTinBanToChuc
        ADD PhiNenTang DECIMAL(5,2) NOT NULL
            CONSTRAINT DF_ThongTinBanToChuc_PhiNenTang DEFAULT 8.5 WITH VALUES;

    IF COL_LENGTH('dbo.ThongTinBanToChuc', 'ChuKyGiaiNganNgay') IS NULL
        ALTER TABLE dbo.ThongTinBanToChuc
        ADD ChuKyGiaiNganNgay INT NOT NULL
            CONSTRAINT DF_ThongTinBanToChuc_ChuKyGiaiNganNgay DEFAULT 0 WITH VALUES;

    IF COL_LENGTH('dbo.ThongTinBanToChuc', 'TrangThaiDuyet') IS NULL
        ALTER TABLE dbo.ThongTinBanToChuc
        ADD TrangThaiDuyet TINYINT NOT NULL
            CONSTRAINT DF_ThongTinBanToChuc_TrangThaiDuyet DEFAULT 0 WITH VALUES;

    IF COL_LENGTH('dbo.ThongTinBanToChuc', 'LyDoTuChoi') IS NULL
        ALTER TABLE dbo.ThongTinBanToChuc ADD LyDoTuChoi NVARCHAR(1000) NULL;

    IF COL_LENGTH('dbo.ThongTinBanToChuc', 'NgayDuyet') IS NULL
        ALTER TABLE dbo.ThongTinBanToChuc ADD NgayDuyet DATETIME2(7) NULL;

    IF COL_LENGTH('dbo.ThongTinBanToChuc', 'NguoiDuyetId') IS NULL
        ALTER TABLE dbo.ThongTinBanToChuc ADD NguoiDuyetId UNIQUEIDENTIFIER NULL;

    EXEC sys.sp_executesql N'
        UPDATE dbo.ThongTinBanToChuc
        SET TrangThaiDuyet = 1
        WHERE DaDuyet = 1 AND TrangThaiDuyet = 0;';

    IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_ThongTinBanToChuc_TrangThaiDuyet')
        EXEC sys.sp_executesql N'
            ALTER TABLE dbo.ThongTinBanToChuc WITH CHECK
            ADD CONSTRAINT CK_ThongTinBanToChuc_TrangThaiDuyet CHECK (TrangThaiDuyet IN (0, 1, 2));';

    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ThongTinBanToChuc_NguoiDuyet')
        ALTER TABLE dbo.ThongTinBanToChuc WITH CHECK
        ADD CONSTRAINT FK_ThongTinBanToChuc_NguoiDuyet FOREIGN KEY (NguoiDuyetId)
        REFERENCES dbo.NguoiDung (Id);

    IF COL_LENGTH('dbo.SuKien', 'HienThiCongKhai') IS NULL
        ALTER TABLE dbo.SuKien
        ADD HienThiCongKhai BIT NOT NULL
            CONSTRAINT DF_SuKien_HienThiCongKhai DEFAULT 1 WITH VALUES;

    IF OBJECT_ID('dbo.SoDuOrganizer') IS NOT NULL
       AND COL_LENGTH('dbo.SoDuOrganizer', 'CongNo') IS NULL
        ALTER TABLE dbo.SoDuOrganizer
        ADD CongNo DECIMAL(18,0) NOT NULL
            CONSTRAINT DF_SoDuOrganizer_CongNo DEFAULT 0 WITH VALUES;

    IF OBJECT_ID('dbo.SoDuOrganizer') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_SoDuOrganizer_CongNo')
        EXEC sys.sp_executesql N'
            ALTER TABLE dbo.SoDuOrganizer WITH CHECK
            ADD CONSTRAINT CK_SoDuOrganizer_CongNo CHECK (CongNo >= 0);';

    IF OBJECT_ID('dbo.LichSuHoanTien') IS NULL
    BEGIN
        CREATE TABLE dbo.LichSuHoanTien (
            Id BIGINT IDENTITY(1,1) NOT NULL,
            DonHangId UNIQUEIDENTIFIER NOT NULL,
            VeDienTuId UNIQUEIDENTIFIER NULL,
            SoTien DECIMAL(18,0) NOT NULL,
            LyDo NVARCHAR(1000) NOT NULL,
            NguoiXuLyId UNIQUEIDENTIFIER NOT NULL,
            NgayTao DATETIME2(7) NOT NULL CONSTRAINT DF_LichSuHoanTien_NgayTao DEFAULT GETUTCDATE(),
            CONSTRAINT PK_LichSuHoanTien PRIMARY KEY CLUSTERED (Id),
            CONSTRAINT FK_LichSuHoanTien_DonHang FOREIGN KEY (DonHangId) REFERENCES dbo.DonHang (Id),
            CONSTRAINT FK_LichSuHoanTien_VeDienTu FOREIGN KEY (VeDienTuId) REFERENCES dbo.VeDienTu (Id),
            CONSTRAINT FK_LichSuHoanTien_NguoiXuLy FOREIGN KEY (NguoiXuLyId) REFERENCES dbo.NguoiDung (Id),
            CONSTRAINT CK_LichSuHoanTien_SoTien CHECK (SoTien > 0)
        );

        CREATE NONCLUSTERED INDEX IX_LichSuHoanTien_DonHangId ON dbo.LichSuHoanTien (DonHangId);
    END

    COMMIT TRANSACTION;
    PRINT N'Admin and Organizer workflow migration completed.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    THROW;
END CATCH;
GO
