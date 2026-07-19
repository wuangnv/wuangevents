-- Thêm cột template ID cho bảng SoDoChoNgoi
IF NOT EXISTS (SELECT 1 FROM sys.columns 
    WHERE object_id = OBJECT_ID('SoDoChoNgoi') AND name = 'MauSoDoId')
BEGIN
    ALTER TABLE [dbo].[SoDoChoNgoi] ADD [MauSoDoId] VARCHAR(50) NULL;
END
