/*
  Nâng cấp CSDL đang dùng sang Seat Map Studio.
  File này an toàn khi chạy lặp lại và không thêm bảng mới.
  Ứng dụng cũng tự kiểm tra/cập nhật cùng các cột này lúc khởi động.
*/
USE [WuangEvents];
GO

IF COL_LENGTH(N'dbo.SoDoChoNgoi', N'CanvasRong') IS NULL
    ALTER TABLE dbo.SoDoChoNgoi ADD CanvasRong INT NOT NULL CONSTRAINT DF_SoDoChoNgoi_CanvasRong DEFAULT (960);
IF COL_LENGTH(N'dbo.SoDoChoNgoi', N'CanvasCao') IS NULL
    ALTER TABLE dbo.SoDoChoNgoi ADD CanvasCao INT NOT NULL CONSTRAINT DF_SoDoChoNgoi_CanvasCao DEFAULT (650);
IF COL_LENGTH(N'dbo.SoDoChoNgoi', N'SanKhauRong') IS NULL
    ALTER TABLE dbo.SoDoChoNgoi ADD SanKhauRong INT NOT NULL CONSTRAINT DF_SoDoChoNgoi_SanKhauRong DEFAULT (280);
IF COL_LENGTH(N'dbo.SoDoChoNgoi', N'SanKhauCao') IS NULL
    ALTER TABLE dbo.SoDoChoNgoi ADD SanKhauCao INT NOT NULL CONSTRAINT DF_SoDoChoNgoi_SanKhauCao DEFAULT (44);
IF COL_LENGTH(N'dbo.SoDoChoNgoi', N'NhanSanKhau') IS NULL
    ALTER TABLE dbo.SoDoChoNgoi ADD NhanSanKhau NVARCHAR(100) NOT NULL CONSTRAINT DF_SoDoChoNgoi_NhanSanKhau DEFAULT (N'SÂN KHẤU');
GO

IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_SoDoChoNgoi_LoaiSoDo')
    ALTER TABLE dbo.SoDoChoNgoi DROP CONSTRAINT CK_SoDoChoNgoi_LoaiSoDo;
ALTER TABLE dbo.SoDoChoNgoi ADD CONSTRAINT CK_SoDoChoNgoi_LoaiSoDo
    CHECK (LoaiSoDo IN (N'concert', N'auditorium', N'theatre', N'cinema', N'arena', N'custom'));
GO

IF COL_LENGTH(N'dbo.KhuVuc', N'Rong') IS NULL
    ALTER TABLE dbo.KhuVuc ADD Rong INT NOT NULL CONSTRAINT DF_KhuVuc_Rong DEFAULT (0);
IF COL_LENGTH(N'dbo.KhuVuc', N'Cao') IS NULL
    ALTER TABLE dbo.KhuVuc ADD Cao INT NOT NULL CONSTRAINT DF_KhuVuc_Cao DEFAULT (0);
IF COL_LENGTH(N'dbo.KhuVuc', N'LoaiKhuVuc') IS NULL
    ALTER TABLE dbo.KhuVuc ADD LoaiKhuVuc VARCHAR(10) NOT NULL CONSTRAINT DF_KhuVuc_Loai DEFAULT ('seated');
IF COL_LENGTH(N'dbo.KhuVuc', N'SucChua') IS NULL
    ALTER TABLE dbo.KhuVuc ADD SucChua INT NULL;
IF COL_LENGTH(N'dbo.KhuVuc', N'TienToHangGhe') IS NULL
    ALTER TABLE dbo.KhuVuc ADD TienToHangGhe NVARCHAR(10) NOT NULL CONSTRAINT DF_KhuVuc_TienTo DEFAULT (N'');
IF COL_LENGTH(N'dbo.KhuVuc', N'KieuDanhSo') IS NULL
    ALTER TABLE dbo.KhuVuc ADD KieuDanhSo VARCHAR(10) NOT NULL CONSTRAINT DF_KhuVuc_KieuDanhSo DEFAULT ('ltr');
IF COL_LENGTH(N'dbo.KhuVuc', N'SoBatDau') IS NULL
    ALTER TABLE dbo.KhuVuc ADD SoBatDau INT NOT NULL CONSTRAINT DF_KhuVuc_SoBatDau DEFAULT (1);
IF COL_LENGTH(N'dbo.KhuVuc', N'BoQuaChuDeNham') IS NULL
    ALTER TABLE dbo.KhuVuc ADD BoQuaChuDeNham BIT NOT NULL CONSTRAINT DF_KhuVuc_BoQuaChu DEFAULT (1);
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_KhuVuc_LoaiKhuVuc')
    EXEC(N'ALTER TABLE dbo.KhuVuc ADD CONSTRAINT CK_KhuVuc_LoaiKhuVuc CHECK (LoaiKhuVuc IN (''seated'', ''ga''))');
GO
