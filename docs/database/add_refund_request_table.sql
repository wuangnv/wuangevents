-- =============================================
-- WuangEvents - Refund Proposal Schema (Escrow)
-- Created: 2026-06-22
-- =============================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

BEGIN TRY

    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'YeuCauHoanTien')
    BEGIN
        CREATE TABLE [dbo].[YeuCauHoanTien] (
            [Id]              UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
            [DonHangId]       UNIQUEIDENTIFIER NOT NULL,
            [VeDienTuId]      UNIQUEIDENTIFIER NULL,
            [SoTien]          DECIMAL(18,0)    NOT NULL,
            [LyDo]            NVARCHAR(500)    NOT NULL,
            [NguoiYeuCauId]   UNIQUEIDENTIFIER NOT NULL,
            [TrangThai]       TINYINT          NOT NULL DEFAULT 0, -- 0: ChoOrganizerDuyet, 1: DaDuyet, 2: TuChoi
            [GhiChuOrganizer] NVARCHAR(500)    NULL,
            [NgayTao]         DATETIME2(7)     NOT NULL DEFAULT GETUTCDATE(),
            [NgayXuLy]        DATETIME2(7)     NULL,

            CONSTRAINT [PK_YeuCauHoanTien] PRIMARY KEY CLUSTERED ([Id]),
            CONSTRAINT [FK_YeuCauHoanTien_DonHang] FOREIGN KEY ([DonHangId]) REFERENCES [dbo].[DonHang]([Id]) ON DELETE CASCADE,
            CONSTRAINT [FK_YeuCauHoanTien_VeDienTu] FOREIGN KEY ([VeDienTuId]) REFERENCES [dbo].[VeDienTu]([Id]) ON DELETE NO ACTION,
            CONSTRAINT [CK_YeuCauHoanTien_SoTien] CHECK ([SoTien] > 0)
        );

        CREATE NONCLUSTERED INDEX [IX_YeuCauHoanTien_DonHangId] ON [dbo].[YeuCauHoanTien] ([DonHangId]);
        CREATE NONCLUSTERED INDEX [IX_YeuCauHoanTien_TrangThai] ON [dbo].[YeuCauHoanTien] ([TrangThai]);
        PRINT N'Table YeuCauHoanTien created successfully.';
    END

    COMMIT TRANSACTION;
    PRINT N'Refund proposal schema added successfully.';

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    PRINT N'Error occurred: ' + @ErrorMessage;
    RAISERROR(@ErrorMessage, 16, 1);
END CATCH;
GO
