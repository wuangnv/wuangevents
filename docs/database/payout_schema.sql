-- =============================================
-- WuangEvents - Escrow & Payout Database Schema
-- Created: 2026-05-30
-- Target Database: SQL Server 2019+
-- =============================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

BEGIN TRY

    -- 1. SoDuOrganizer (Organizer Balance)
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'SoDuOrganizer')
    BEGIN
        CREATE TABLE [dbo].[SoDuOrganizer] (
            [OrganizerId]     UNIQUEIDENTIFIER NOT NULL,
            [SoDuKhaDung]     DECIMAL(18,0)    NOT NULL DEFAULT 0,
            [SoDuDongBang]    DECIMAL(18,0)    NOT NULL DEFAULT 0,
            [CongNo]          DECIMAL(18,0)    NOT NULL DEFAULT 0,
            [NgayCapNhat]     DATETIME2(7)     NOT NULL DEFAULT GETUTCDATE(),

            CONSTRAINT [PK_SoDuOrganizer] PRIMARY KEY CLUSTERED ([OrganizerId]),
            CONSTRAINT [FK_SoDuOrganizer_NguoiDung] FOREIGN KEY ([OrganizerId])
                REFERENCES [dbo].[NguoiDung]([Id]) ON DELETE CASCADE,
            CONSTRAINT [CK_SoDuOrganizer_KhongAm] CHECK ([SoDuKhaDung] >= 0 AND [SoDuDongBang] >= 0 AND [CongNo] >= 0)
        );
        PRINT N'Table SoDuOrganizer created successfully.';
    END

    -- 2. YeuCauRutTien (Payout Request)
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'YeuCauRutTien')
    BEGIN
        CREATE TABLE [dbo].[YeuCauRutTien] (
            [Id]              UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
            [OrganizerId]     UNIQUEIDENTIFIER NOT NULL,
            [SoTien]          DECIMAL(18,0)    NOT NULL,
            [TenNganHang]     NVARCHAR(100)    NOT NULL,
            [SoTaiKhoan]      NVARCHAR(50)     NOT NULL,
            [ChuTaiKhoan]     NVARCHAR(100)    NOT NULL,
            [TrangThai]       TINYINT          NOT NULL DEFAULT 0,  -- 0: ChoDuyet, 1: DaThanhToan, 2: TuChoi
            [GhiChu]          NVARCHAR(500)    NULL,
            [NgayTao]         DATETIME2(7)     NOT NULL DEFAULT GETUTCDATE(),
            [NgayXuLy]        DATETIME2(7)     NULL,

            CONSTRAINT [PK_YeuCauRutTien] PRIMARY KEY CLUSTERED ([Id]),
            CONSTRAINT [FK_YeuCauRutTien_NguoiDung] FOREIGN KEY ([OrganizerId])
                REFERENCES [dbo].[NguoiDung]([Id]) ON DELETE NO ACTION,
            CONSTRAINT [CK_YeuCauRutTien_SoTien] CHECK ([SoTien] > 0)
        );

        CREATE NONCLUSTERED INDEX [IX_YeuCauRutTien_OrganizerId] ON [dbo].[YeuCauRutTien] ([OrganizerId]);
        CREATE NONCLUSTERED INDEX [IX_YeuCauRutTien_TrangThai] ON [dbo].[YeuCauRutTien] ([TrangThai]);
        PRINT N'Table YeuCauRutTien created successfully.';
    END

    -- 3. LichSuSoDu (Balance History)
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'LichSuSoDu')
    BEGIN
        CREATE TABLE [dbo].[LichSuSoDu] (
            [Id]              INT IDENTITY(1,1) NOT NULL,
            [OrganizerId]     UNIQUEIDENTIFIER  NOT NULL,
            [LoaiGiaoDich]    TINYINT           NOT NULL,   -- 0: DoanhThuVe, 1: RutTien, 2: HoanVe, 3: PhiDichVu
            [SoTien]          DECIMAL(18,0)     NOT NULL,
            [SoDuSauGD]       DECIMAL(18,0)     NOT NULL,
            [NoiDung]         NVARCHAR(500)     NOT NULL,
            [NgayTao]         DATETIME2(7)      NOT NULL DEFAULT GETUTCDATE(),

            CONSTRAINT [PK_LichSuSoDu] PRIMARY KEY CLUSTERED ([Id]),
            CONSTRAINT [FK_LichSuSoDu_NguoiDung] FOREIGN KEY ([OrganizerId])
                REFERENCES [dbo].[NguoiDung]([Id]) ON DELETE CASCADE
        );

        CREATE NONCLUSTERED INDEX [IX_LichSuSoDu_OrganizerId] ON [dbo].[LichSuSoDu] ([OrganizerId]);
        PRINT N'Table LichSuSoDu created successfully.';
    END

    COMMIT TRANSACTION;
    PRINT N'Escrow financial tables added successfully.';

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    PRINT N'Error occurred: ' + @ErrorMessage;
    RAISERROR(@ErrorMessage, 16, 1);
END CATCH;
GO
