-- Migration: Add AiChiuPhi column to SuKien table
-- Date: 2026-06-07

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.SuKien') AND name = 'AiChiuPhi')
BEGIN
    ALTER TABLE [dbo].[SuKien] ADD [AiChiuPhi] TINYINT NOT NULL DEFAULT 0;
END
GO
