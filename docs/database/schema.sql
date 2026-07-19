-- =============================================
-- WuangEvents - Event Management & Online Ticket Selling System
-- Database Schema Script
-- Created: 2026-05-29
-- Database: SQL Server 2019+
-- =============================================
-- This script is idempotent - safe to run multiple times.
-- All operations are wrapped in a transaction.
-- =============================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

BEGIN TRY

    -- =============================================
    -- 1. NguoiDung (Users)
    -- =============================================
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'NguoiDung')
    BEGIN
        CREATE TABLE [dbo].[NguoiDung] (
            [Id]              UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
            [Email]           NVARCHAR(256)    NOT NULL,
            [MatKhauHash]     NVARCHAR(256)    NOT NULL,
            [HoTen]           NVARCHAR(100)    NOT NULL,
            [SoDienThoai]     NVARCHAR(20)     NULL,
            [AnhDaiDien]      NVARCHAR(500)    NULL,
            [VaiTro]          TINYINT          NOT NULL DEFAULT 0,   -- 0: KhachHang, 1: Organizer, 2: Staff, 3: Admin
            [TrangThai]       TINYINT          NOT NULL DEFAULT 1,   -- 0: Khoa, 1: HoatDong
            [EmailXacNhan]    BIT              NOT NULL DEFAULT 0,
            [TokenXacNhan]    NVARCHAR(256)    NULL,
            [NgayTao]         DATETIME2(7)     NOT NULL DEFAULT GETUTCDATE(),
            [NgayCapNhat]     DATETIME2(7)     NULL,

            CONSTRAINT [PK_NguoiDung] PRIMARY KEY CLUSTERED ([Id]),
            CONSTRAINT [UQ_NguoiDung_Email] UNIQUE ([Email])
        );

        CREATE NONCLUSTERED INDEX [IX_NguoiDung_Email] ON [dbo].[NguoiDung] ([Email]);
        CREATE NONCLUSTERED INDEX [IX_NguoiDung_VaiTro] ON [dbo].[NguoiDung] ([VaiTro]);
        CREATE NONCLUSTERED INDEX [IX_NguoiDung_TrangThai] ON [dbo].[NguoiDung] ([TrangThai]);
    END

    -- =============================================
    -- 2. ThongTinBanToChuc (Organizer Profiles)
    -- =============================================
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ThongTinBanToChuc')
    BEGIN
        CREATE TABLE [dbo].[ThongTinBanToChuc] (
            [Id]              UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
            [NguoiDungId]     UNIQUEIDENTIFIER NOT NULL,
            [TenToChuc]       NVARCHAR(200)    NOT NULL,
            [MoTa]            NVARCHAR(2000)   NULL,
            [Logo]            NVARCHAR(500)    NULL,
            [Website]         NVARCHAR(500)    NULL,
            [DiaChi]          NVARCHAR(500)    NULL,
            [MaSoThue]        NVARCHAR(20)     NULL,
            [TenNganHang]     NVARCHAR(100)    NULL,
            [SoTaiKhoan]      NVARCHAR(50)     NULL,
            [ChuTaiKhoan]     NVARCHAR(100)    NULL,
            [PhiNenTang]      DECIMAL(5,2)     NOT NULL DEFAULT 8.5,
            [ChuKyGiaiNganNgay] INT             NOT NULL DEFAULT 0,
            [DaDuyet]         BIT              NOT NULL DEFAULT 0,
            [TrangThaiDuyet]  TINYINT          NOT NULL DEFAULT 0,  -- 0: ChoDuyet, 1: DaDuyet, 2: TuChoi
            [LyDoTuChoi]      NVARCHAR(1000)   NULL,
            [NgayDuyet]       DATETIME2(7)     NULL,
            [NguoiDuyetId]    UNIQUEIDENTIFIER NULL,
            [NgayTao]         DATETIME2(7)     NOT NULL DEFAULT GETUTCDATE(),

            CONSTRAINT [PK_ThongTinBanToChuc] PRIMARY KEY CLUSTERED ([Id]),
            CONSTRAINT [UQ_ThongTinBanToChuc_NguoiDungId] UNIQUE ([NguoiDungId]),
            CONSTRAINT [CK_ThongTinBanToChuc_TrangThaiDuyet] CHECK ([TrangThaiDuyet] IN (0, 1, 2)),
            CONSTRAINT [FK_ThongTinBanToChuc_NguoiDung] FOREIGN KEY ([NguoiDungId])
                REFERENCES [dbo].[NguoiDung]([Id]) ON DELETE CASCADE,
            CONSTRAINT [FK_ThongTinBanToChuc_NguoiDuyet] FOREIGN KEY ([NguoiDuyetId])
                REFERENCES [dbo].[NguoiDung]([Id]) ON DELETE NO ACTION
        );
    END

    -- =============================================
    -- 3. PhienDangNhap (Sessions)
    -- =============================================
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PhienDangNhap')
    BEGIN
        CREATE TABLE [dbo].[PhienDangNhap] (
            [Id]              UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
            [NguoiDungId]     UNIQUEIDENTIFIER NOT NULL,
            [RefreshToken]    NVARCHAR(500)    NOT NULL,
            [ThoiGianHetHan]  DATETIME2(7)     NOT NULL,
            [DiaChi_IP]       NVARCHAR(50)     NULL,
            [ThietBi]         NVARCHAR(500)    NULL,
            [NgayTao]         DATETIME2(7)     NOT NULL DEFAULT GETUTCDATE(),

            CONSTRAINT [PK_PhienDangNhap] PRIMARY KEY CLUSTERED ([Id]),
            CONSTRAINT [FK_PhienDangNhap_NguoiDung] FOREIGN KEY ([NguoiDungId])
                REFERENCES [dbo].[NguoiDung]([Id]) ON DELETE CASCADE
        );

        CREATE NONCLUSTERED INDEX [IX_PhienDangNhap_NguoiDungId] ON [dbo].[PhienDangNhap] ([NguoiDungId]);
        CREATE NONCLUSTERED INDEX [IX_PhienDangNhap_RefreshToken] ON [dbo].[PhienDangNhap] ([RefreshToken]);
        CREATE NONCLUSTERED INDEX [IX_PhienDangNhap_ThoiGianHetHan] ON [dbo].[PhienDangNhap] ([ThoiGianHetHan]);
    END

    -- =============================================
    -- 4. DanhMuc (Categories)
    -- =============================================
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DanhMuc')
    BEGIN
        CREATE TABLE [dbo].[DanhMuc] (
            [Id]              INT IDENTITY(1,1) NOT NULL,
            [TenDanhMuc]      NVARCHAR(100)     NOT NULL,
            [MoTa]            NVARCHAR(500)     NULL,
            [Icon]            NVARCHAR(100)     NULL,
            [ThuTu]           INT               NOT NULL DEFAULT 0,
            [TrangThai]       BIT               NOT NULL DEFAULT 1,

            CONSTRAINT [PK_DanhMuc] PRIMARY KEY CLUSTERED ([Id])
        );
    END

    -- =============================================
    -- 5. DiaDiem (Venues)
    -- =============================================
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DiaDiem')
    BEGIN
        CREATE TABLE [dbo].[DiaDiem] (
            [Id]              INT IDENTITY(1,1) NOT NULL,
            [TenDiaDiem]      NVARCHAR(200)     NOT NULL,
            [DiaChi]          NVARCHAR(500)     NOT NULL,
            [ThanhPho]        NVARCHAR(100)     NOT NULL,
            [QuanHuyen]       NVARCHAR(100)     NULL,
            [KinhDo]          DECIMAL(11,8)     NULL,
            [ViDo]            DECIMAL(10,8)     NULL,
            [SucChua]         INT               NULL,
            [MoTa]            NVARCHAR(2000)    NULL,
            [HinhAnh]         NVARCHAR(500)     NULL,
            [NgayTao]         DATETIME2(7)      NOT NULL DEFAULT GETUTCDATE(),

            CONSTRAINT [PK_DiaDiem] PRIMARY KEY CLUSTERED ([Id])
        );

        CREATE NONCLUSTERED INDEX [IX_DiaDiem_ThanhPho] ON [dbo].[DiaDiem] ([ThanhPho]);
    END

    -- =============================================
    -- 6. SuKien (Events)
    -- =============================================
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'SuKien')
    BEGIN
        CREATE TABLE [dbo].[SuKien] (
            [Id]              UNIQUEIDENTIFIER  NOT NULL DEFAULT NEWSEQUENTIALID(),
            [NguoiToChucId]   UNIQUEIDENTIFIER  NOT NULL,
            [DanhMucId]       INT               NOT NULL,
            [DiaDiemId]       INT               NULL,
            [TenSuKien]       NVARCHAR(300)     NOT NULL,
            [Slug]            VARCHAR(350)      NOT NULL,
            [MoTaNgan]        NVARCHAR(500)     NULL,
            [MoTaChiTiet]     NVARCHAR(MAX)     NULL,
            [AnhBia]          NVARCHAR(500)     NULL,
            [NgayBatDau]      DATETIME2(7)      NOT NULL,
            [NgayKetThuc]     DATETIME2(7)      NOT NULL,
            [NgayMoBanVe]     DATETIME2(7)      NULL,
            [NgayDongBanVe]   DATETIME2(7)      NULL,
            [LoaiSuKien]      TINYINT           NOT NULL DEFAULT 0,  -- 0: Offline, 1: Online, 2: Hybrid
            [LinkOnline]      NVARCHAR(500)     NULL,
            [CoSoDoChoNgoi]   BIT               NOT NULL DEFAULT 0,
            [TrangThai]       TINYINT           NOT NULL DEFAULT 0,  -- 0: Nhap, 1: ChoDuyet, 2: DaDuyet, 3: DangBan, 4: HetVe, 5: DaKetThuc, 6: DaHuy, 7: TuChoi
            [LyDoTuChoi]      NVARCHAR(1000)    NULL,
            [SoLuotXem]       INT               NOT NULL DEFAULT 0,
            [PhiDichVu]       DECIMAL(5,2)      NOT NULL DEFAULT 8.5,
            [NoiBat]          BIT               NOT NULL DEFAULT 0,
            [HienThiCongKhai] BIT               NOT NULL DEFAULT 1,
            [NgayTao]         DATETIME2(7)      NOT NULL DEFAULT GETUTCDATE(),
            [NgayCapNhat]     DATETIME2(7)      NULL,
            [NgayDuyet]       DATETIME2(7)      NULL,
            [NguoiDuyetId]    UNIQUEIDENTIFIER  NULL,

            CONSTRAINT [PK_SuKien] PRIMARY KEY CLUSTERED ([Id]),
            CONSTRAINT [UQ_SuKien_Slug] UNIQUE ([Slug]),
            CONSTRAINT [FK_SuKien_NguoiToChuc] FOREIGN KEY ([NguoiToChucId])
                REFERENCES [dbo].[NguoiDung]([Id]) ON DELETE NO ACTION,
            CONSTRAINT [FK_SuKien_DanhMuc] FOREIGN KEY ([DanhMucId])
                REFERENCES [dbo].[DanhMuc]([Id]) ON DELETE NO ACTION,
            CONSTRAINT [FK_SuKien_DiaDiem] FOREIGN KEY ([DiaDiemId])
                REFERENCES [dbo].[DiaDiem]([Id]) ON DELETE SET NULL,
            CONSTRAINT [FK_SuKien_NguoiDuyet] FOREIGN KEY ([NguoiDuyetId])
                REFERENCES [dbo].[NguoiDung]([Id]) ON DELETE NO ACTION
        );

        CREATE NONCLUSTERED INDEX [IX_SuKien_NguoiToChucId] ON [dbo].[SuKien] ([NguoiToChucId]);
        CREATE NONCLUSTERED INDEX [IX_SuKien_DanhMucId] ON [dbo].[SuKien] ([DanhMucId]);
        CREATE NONCLUSTERED INDEX [IX_SuKien_DiaDiemId] ON [dbo].[SuKien] ([DiaDiemId]);
        CREATE NONCLUSTERED INDEX [IX_SuKien_TrangThai] ON [dbo].[SuKien] ([TrangThai]);
        CREATE NONCLUSTERED INDEX [IX_SuKien_NgayBatDau] ON [dbo].[SuKien] ([NgayBatDau]);
        CREATE NONCLUSTERED INDEX [IX_SuKien_NoiBat] ON [dbo].[SuKien] ([NoiBat]) WHERE [NoiBat] = 1;
        CREATE NONCLUSTERED INDEX [IX_SuKien_Slug] ON [dbo].[SuKien] ([Slug]);
        CREATE NONCLUSTERED INDEX [IX_SuKien_TrangThai_NgayBatDau] ON [dbo].[SuKien] ([TrangThai], [NgayBatDau]) INCLUDE ([TenSuKien], [Slug], [AnhBia], [MoTaNgan]);
    END

    -- =============================================
    -- 7. HinhAnhSuKien (Event Images)
    -- =============================================
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'HinhAnhSuKien')
    BEGIN
        CREATE TABLE [dbo].[HinhAnhSuKien] (
            [Id]              INT IDENTITY(1,1) NOT NULL,
            [SuKienId]        UNIQUEIDENTIFIER  NOT NULL,
            [DuongDanAnh]     NVARCHAR(500)     NOT NULL,
            [ThuTu]           INT               NOT NULL DEFAULT 0,
            [MoTa]            NVARCHAR(200)     NULL,

            CONSTRAINT [PK_HinhAnhSuKien] PRIMARY KEY CLUSTERED ([Id]),
            CONSTRAINT [FK_HinhAnhSuKien_SuKien] FOREIGN KEY ([SuKienId])
                REFERENCES [dbo].[SuKien]([Id]) ON DELETE CASCADE
        );

        CREATE NONCLUSTERED INDEX [IX_HinhAnhSuKien_SuKienId] ON [dbo].[HinhAnhSuKien] ([SuKienId]);
    END

    -- =============================================
    -- 8. NhanVienSuKien (Event Staff)
    -- =============================================
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'NhanVienSuKien')
    BEGIN
        CREATE TABLE [dbo].[NhanVienSuKien] (
            [Id]              INT IDENTITY(1,1) NOT NULL,
            [SuKienId]        UNIQUEIDENTIFIER  NOT NULL,
            [NguoiDungId]     UNIQUEIDENTIFIER  NOT NULL,
            [VaiTro]          TINYINT           NOT NULL DEFAULT 0,  -- 0: CheckIn, 1: QuanLy
            [NgayThem]        DATETIME2(7)      NOT NULL DEFAULT GETUTCDATE(),

            CONSTRAINT [PK_NhanVienSuKien] PRIMARY KEY CLUSTERED ([Id]),
            CONSTRAINT [FK_NhanVienSuKien_SuKien] FOREIGN KEY ([SuKienId])
                REFERENCES [dbo].[SuKien]([Id]) ON DELETE CASCADE,
            CONSTRAINT [FK_NhanVienSuKien_NguoiDung] FOREIGN KEY ([NguoiDungId])
                REFERENCES [dbo].[NguoiDung]([Id]) ON DELETE NO ACTION,
            CONSTRAINT [UQ_NhanVienSuKien_SuKien_NguoiDung] UNIQUE ([SuKienId], [NguoiDungId])
        );

        CREATE NONCLUSTERED INDEX [IX_NhanVienSuKien_SuKienId] ON [dbo].[NhanVienSuKien] ([SuKienId]);
        CREATE NONCLUSTERED INDEX [IX_NhanVienSuKien_NguoiDungId] ON [dbo].[NhanVienSuKien] ([NguoiDungId]);
    END

    -- =============================================
    -- 9. LoaiVe (Ticket Types)
    -- =============================================
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'LoaiVe')
    BEGIN
        CREATE TABLE [dbo].[LoaiVe] (
            [Id]              INT IDENTITY(1,1) NOT NULL,
            [SuKienId]        UNIQUEIDENTIFIER  NOT NULL,
            [TenLoaiVe]       NVARCHAR(100)     NOT NULL,
            [MoTa]            NVARCHAR(1000)    NULL,
            [GiaGoc]          DECIMAL(18,0)     NOT NULL,
            [GiaBan]          DECIMAL(18,0)     NOT NULL,
            [SoLuongTong]     INT               NOT NULL,
            [SoLuongDaBan]    INT               NOT NULL DEFAULT 0,
            [SoLuongGiuCho]   INT               NOT NULL DEFAULT 0,
            [GioiHanMoiDon]   INT               NOT NULL DEFAULT 10,
            [NgayBatDauBan]   DATETIME2(7)      NULL,
            [NgayKetThucBan]  DATETIME2(7)      NULL,
            [ThuTuHienThi]    INT               NOT NULL DEFAULT 0,
            [MauSac]          VARCHAR(7)        NULL,
            [TrangThai]       BIT               NOT NULL DEFAULT 1,

            CONSTRAINT [PK_LoaiVe] PRIMARY KEY CLUSTERED ([Id]),
            CONSTRAINT [FK_LoaiVe_SuKien] FOREIGN KEY ([SuKienId])
                REFERENCES [dbo].[SuKien]([Id]) ON DELETE CASCADE,
            CONSTRAINT [CK_LoaiVe_GiaBan] CHECK ([GiaBan] >= 0),
            CONSTRAINT [CK_LoaiVe_GiaGoc] CHECK ([GiaGoc] >= 0),
            CONSTRAINT [CK_LoaiVe_SoLuong] CHECK ([SoLuongTong] > 0),
            CONSTRAINT [CK_LoaiVe_SoLuongDaBan] CHECK ([SoLuongDaBan] >= 0 AND [SoLuongDaBan] <= [SoLuongTong]),
            CONSTRAINT [CK_LoaiVe_SoLuongGiuCho] CHECK ([SoLuongGiuCho] >= 0 AND [SoLuongDaBan] + [SoLuongGiuCho] <= [SoLuongTong]),
            CONSTRAINT [CK_LoaiVe_GioiHanMoiDon] CHECK ([GioiHanMoiDon] > 0),
            CONSTRAINT [CK_LoaiVe_ThoiGianBan] CHECK ([NgayBatDauBan] IS NULL OR [NgayKetThucBan] IS NULL OR [NgayBatDauBan] <= [NgayKetThucBan])
        );

        CREATE NONCLUSTERED INDEX [IX_LoaiVe_SuKienId] ON [dbo].[LoaiVe] ([SuKienId]);
    END

    -- =============================================
    -- 10. SoDoChoNgoi (Seating Map)
    -- =============================================
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'SoDoChoNgoi')
    BEGIN
        CREATE TABLE [dbo].[SoDoChoNgoi] (
            [Id]              INT IDENTITY(1,1) NOT NULL,
            [SuKienId]        UNIQUEIDENTIFIER  NOT NULL,
            [TenSoDo]         NVARCHAR(200)     NOT NULL,
            [ChieuRong]       INT               NOT NULL,
            [ChieuCao]        INT               NOT NULL,
            [HinhNen]         NVARCHAR(500)     NULL,
            [CauHinhJSON]     NVARCHAR(MAX)     NULL,
            [NgayTao]         DATETIME2(7)      NOT NULL DEFAULT GETUTCDATE(),

            CONSTRAINT [PK_SoDoChoNgoi] PRIMARY KEY CLUSTERED ([Id]),
            CONSTRAINT [UQ_SoDoChoNgoi_SuKienId] UNIQUE ([SuKienId]),
            CONSTRAINT [FK_SoDoChoNgoi_SuKien] FOREIGN KEY ([SuKienId])
                REFERENCES [dbo].[SuKien]([Id]) ON DELETE CASCADE
        );
    END

    -- =============================================
    -- 11. KhuVuc (Zones)
    -- =============================================
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'KhuVuc')
    BEGIN
        CREATE TABLE [dbo].[KhuVuc] (
            [Id]              INT IDENTITY(1,1) NOT NULL,
            [SoDoChoNgoiId]   INT               NOT NULL,
            [LoaiVeId]        INT               NOT NULL,
            [TenKhuVuc]       NVARCHAR(100)     NOT NULL,
            [MauSac]          VARCHAR(7)        NULL,
            [ViTriX]          INT               NULL,
            [ViTriY]          INT               NULL,
            [ThuTu]           INT               NOT NULL DEFAULT 0,

            CONSTRAINT [PK_KhuVuc] PRIMARY KEY CLUSTERED ([Id]),
            CONSTRAINT [FK_KhuVuc_SoDoChoNgoi] FOREIGN KEY ([SoDoChoNgoiId])
                REFERENCES [dbo].[SoDoChoNgoi]([Id]) ON DELETE CASCADE,
            CONSTRAINT [FK_KhuVuc_LoaiVe] FOREIGN KEY ([LoaiVeId])
                REFERENCES [dbo].[LoaiVe]([Id]) ON DELETE NO ACTION
        );

        CREATE NONCLUSTERED INDEX [IX_KhuVuc_SoDoChoNgoiId] ON [dbo].[KhuVuc] ([SoDoChoNgoiId]);
    END

    -- =============================================
    -- 12. HangGhe (Rows)
    -- =============================================
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'HangGhe')
    BEGIN
        CREATE TABLE [dbo].[HangGhe] (
            [Id]              INT IDENTITY(1,1) NOT NULL,
            [KhuVucId]        INT               NOT NULL,
            [TenHang]         NVARCHAR(10)      NOT NULL,
            [SoGhe]           INT               NOT NULL,
            [ThuTu]           INT               NOT NULL DEFAULT 0,

            CONSTRAINT [PK_HangGhe] PRIMARY KEY CLUSTERED ([Id]),
            CONSTRAINT [FK_HangGhe_KhuVuc] FOREIGN KEY ([KhuVucId])
                REFERENCES [dbo].[KhuVuc]([Id]) ON DELETE CASCADE
        );

        CREATE NONCLUSTERED INDEX [IX_HangGhe_KhuVucId] ON [dbo].[HangGhe] ([KhuVucId]);
    END

    -- =============================================
    -- 13. ChoNgoi (Seats)
    -- =============================================
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ChoNgoi')
    BEGIN
        CREATE TABLE [dbo].[ChoNgoi] (
            [Id]              INT IDENTITY(1,1) NOT NULL,
            [HangGheId]       INT               NOT NULL,
            [SoGhe]           NVARCHAR(10)      NOT NULL,
            [ViTriX]          INT               NULL,
            [ViTriY]          INT               NULL,
            [TrangThai]       TINYINT           NOT NULL DEFAULT 0,  -- 0: Trong, 1: DangGiu, 2: DaBan, 3: Khoa

            CONSTRAINT [PK_ChoNgoi] PRIMARY KEY CLUSTERED ([Id]),
            CONSTRAINT [FK_ChoNgoi_HangGhe] FOREIGN KEY ([HangGheId])
                REFERENCES [dbo].[HangGhe]([Id]) ON DELETE CASCADE
        );

        CREATE NONCLUSTERED INDEX [IX_ChoNgoi_HangGheId] ON [dbo].[ChoNgoi] ([HangGheId]);
        CREATE NONCLUSTERED INDEX [IX_ChoNgoi_TrangThai] ON [dbo].[ChoNgoi] ([TrangThai]);
    END

    -- =============================================
    -- 14. MaGiamGia (Discount Codes)
    -- Created before DonHang because DonHang references MaGiamGia
    -- =============================================
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'MaGiamGia')
    BEGIN
        CREATE TABLE [dbo].[MaGiamGia] (
            [Id]              INT IDENTITY(1,1) NOT NULL,
            [SuKienId]        UNIQUEIDENTIFIER  NOT NULL,
            [MaCode]          VARCHAR(50)       NOT NULL,
            [MoTa]            NVARCHAR(500)     NULL,
            [LoaiGiamGia]     TINYINT           NOT NULL DEFAULT 0,  -- 0: PhanTram, 1: SoTienCoDinh
            [GiaTri]          DECIMAL(18,2)     NOT NULL,
            [GiamToiDa]       DECIMAL(18,0)     NULL,
            [DonToiThieu]     DECIMAL(18,0)     NULL DEFAULT 0,
            [SoLuongTong]     INT               NOT NULL,
            [SoLuongDaDung]   INT               NOT NULL DEFAULT 0,
            [GioiHanMoiNguoi] INT               NOT NULL DEFAULT 1,
            [NgayBatDau]      DATETIME2(7)      NOT NULL,
            [NgayKetThuc]     DATETIME2(7)      NOT NULL,
            [TrangThai]       BIT               NOT NULL DEFAULT 1,
            [NgayTao]         DATETIME2(7)      NOT NULL DEFAULT GETUTCDATE(),

            CONSTRAINT [PK_MaGiamGia] PRIMARY KEY CLUSTERED ([Id]),
            CONSTRAINT [UQ_MaGiamGia_MaCode] UNIQUE ([MaCode]),
            CONSTRAINT [FK_MaGiamGia_SuKien] FOREIGN KEY ([SuKienId])
                REFERENCES [dbo].[SuKien]([Id]) ON DELETE CASCADE,
            CONSTRAINT [CK_MaGiamGia_GiaTri] CHECK ([GiaTri] > 0 AND ([LoaiGiamGia] <> 0 OR [GiaTri] <= 100)),
            CONSTRAINT [CK_MaGiamGia_Loai] CHECK ([LoaiGiamGia] IN (0, 1)),
            CONSTRAINT [CK_MaGiamGia_SoLuong] CHECK ([SoLuongTong] > 0 AND [SoLuongDaDung] >= 0 AND [SoLuongDaDung] <= [SoLuongTong]),
            CONSTRAINT [CK_MaGiamGia_GioiHan] CHECK ([GioiHanMoiNguoi] > 0),
            CONSTRAINT [CK_MaGiamGia_ThoiGian] CHECK ([NgayBatDau] <= [NgayKetThuc])
        );

        CREATE NONCLUSTERED INDEX [IX_MaGiamGia_SuKienId] ON [dbo].[MaGiamGia] ([SuKienId]);
        CREATE NONCLUSTERED INDEX [IX_MaGiamGia_MaCode] ON [dbo].[MaGiamGia] ([MaCode]);
    END

    -- =============================================
    -- 15. DonHang (Orders)
    -- =============================================
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DonHang')
    BEGIN
        CREATE TABLE [dbo].[DonHang] (
            [Id]              UNIQUEIDENTIFIER  NOT NULL DEFAULT NEWSEQUENTIALID(),
            [MaDonHang]       VARCHAR(20)       NOT NULL,
            [NguoiMuaId]      UNIQUEIDENTIFIER  NOT NULL,
            [SuKienId]        UNIQUEIDENTIFIER  NOT NULL,
            [MaGiamGiaId]     INT               NULL,
            [HoTenNguoiMua]   NVARCHAR(100)     NOT NULL,
            [EmailNguoiMua]   NVARCHAR(256)     NOT NULL,
            [SdtNguoiMua]     NVARCHAR(20)      NULL,
            [TongTienVe]      DECIMAL(18,0)     NOT NULL DEFAULT 0,
            [TienGiamGia]     DECIMAL(18,0)     NOT NULL DEFAULT 0,
            [PhiDichVu]       DECIMAL(18,0)     NOT NULL DEFAULT 0,
            [TongThanhToan]   DECIMAL(18,0)     NOT NULL DEFAULT 0,
            [TrangThai]       TINYINT           NOT NULL DEFAULT 0,  -- 0: ChoThanhToan, 1: DaThanhToan, 2: DaHuy, 3: HoanTien, 4: HetHan
            [GhiChu]          NVARCHAR(1000)    NULL,
            [ThoiGianGiuCho]  DATETIME2(7)      NOT NULL,
            [NgayTao]         DATETIME2(7)      NOT NULL DEFAULT GETUTCDATE(),
            [NgayCapNhat]     DATETIME2(7)      NULL,

            CONSTRAINT [PK_DonHang] PRIMARY KEY CLUSTERED ([Id]),
            CONSTRAINT [UQ_DonHang_MaDonHang] UNIQUE ([MaDonHang]),
            CONSTRAINT [FK_DonHang_NguoiMua] FOREIGN KEY ([NguoiMuaId])
                REFERENCES [dbo].[NguoiDung]([Id]) ON DELETE NO ACTION,
            CONSTRAINT [FK_DonHang_SuKien] FOREIGN KEY ([SuKienId])
                REFERENCES [dbo].[SuKien]([Id]) ON DELETE NO ACTION,
            CONSTRAINT [FK_DonHang_MaGiamGia] FOREIGN KEY ([MaGiamGiaId])
                REFERENCES [dbo].[MaGiamGia]([Id]) ON DELETE SET NULL
        );

        CREATE NONCLUSTERED INDEX [IX_DonHang_NguoiMuaId] ON [dbo].[DonHang] ([NguoiMuaId]);
        CREATE NONCLUSTERED INDEX [IX_DonHang_SuKienId] ON [dbo].[DonHang] ([SuKienId]);
        CREATE NONCLUSTERED INDEX [IX_DonHang_MaDonHang] ON [dbo].[DonHang] ([MaDonHang]);
        CREATE NONCLUSTERED INDEX [IX_DonHang_TrangThai] ON [dbo].[DonHang] ([TrangThai]);
        CREATE NONCLUSTERED INDEX [IX_DonHang_NgayTao] ON [dbo].[DonHang] ([NgayTao] DESC);
        CREATE NONCLUSTERED INDEX [IX_DonHang_ThoiGianGiuCho] ON [dbo].[DonHang] ([ThoiGianGiuCho]) WHERE [TrangThai] = 0;
    END

    -- =============================================
    -- 16. ChiTietDonHang (Order Details)
    -- =============================================
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ChiTietDonHang')
    BEGIN
        CREATE TABLE [dbo].[ChiTietDonHang] (
            [Id]              INT IDENTITY(1,1) NOT NULL,
            [DonHangId]       UNIQUEIDENTIFIER  NOT NULL,
            [LoaiVeId]        INT               NOT NULL,
            [ChoNgoiId]       INT               NULL,
            [GiaVe]           DECIMAL(18,0)     NOT NULL,
            [TenNguoiThamDu]  NVARCHAR(100)     NULL,
            [EmailNguoiThamDu] NVARCHAR(256)    NULL,

            CONSTRAINT [PK_ChiTietDonHang] PRIMARY KEY CLUSTERED ([Id]),
            CONSTRAINT [FK_ChiTietDonHang_DonHang] FOREIGN KEY ([DonHangId])
                REFERENCES [dbo].[DonHang]([Id]) ON DELETE CASCADE,
            CONSTRAINT [FK_ChiTietDonHang_LoaiVe] FOREIGN KEY ([LoaiVeId])
                REFERENCES [dbo].[LoaiVe]([Id]) ON DELETE NO ACTION,
            CONSTRAINT [FK_ChiTietDonHang_ChoNgoi] FOREIGN KEY ([ChoNgoiId])
                REFERENCES [dbo].[ChoNgoi]([Id]) ON DELETE SET NULL
        );

        CREATE NONCLUSTERED INDEX [IX_ChiTietDonHang_DonHangId] ON [dbo].[ChiTietDonHang] ([DonHangId]);
        CREATE NONCLUSTERED INDEX [IX_ChiTietDonHang_LoaiVeId] ON [dbo].[ChiTietDonHang] ([LoaiVeId]);
    END

    -- =============================================
    -- 17. ThanhToan (Payments)
    -- =============================================
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ThanhToan')
    BEGIN
        CREATE TABLE [dbo].[ThanhToan] (
            [Id]              UNIQUEIDENTIFIER  NOT NULL DEFAULT NEWSEQUENTIALID(),
            [DonHangId]       UNIQUEIDENTIFIER  NOT NULL,
            [MaGiaoDich]      VARCHAR(100)      NOT NULL,
            [PhuongThuc]      TINYINT           NOT NULL DEFAULT 0,  -- 0: VNPay, 1: ChuyenKhoan
            [SoTien]          DECIMAL(18,0)     NOT NULL,
            [TrangThai]       TINYINT           NOT NULL DEFAULT 0,  -- 0: ChoXuLy, 1: ThanhCong, 2: ThatBai, 3: HoanTien
            [MaPhanHoiVnPay]  NVARCHAR(50)      NULL,
            [ThongTinBank]    NVARCHAR(200)     NULL,
            [NgayThanhToan]   DATETIME2(7)      NULL,
            [RawResponse]     NVARCHAR(MAX)     NULL,
            [NgayTao]         DATETIME2(7)      NOT NULL DEFAULT GETUTCDATE(),

            CONSTRAINT [PK_ThanhToan] PRIMARY KEY CLUSTERED ([Id]),
            CONSTRAINT [UQ_ThanhToan_MaGiaoDich] UNIQUE ([MaGiaoDich]),
            CONSTRAINT [UQ_ThanhToan_DonHangId] UNIQUE ([DonHangId]),
            CONSTRAINT [FK_ThanhToan_DonHang] FOREIGN KEY ([DonHangId])
                REFERENCES [dbo].[DonHang]([Id]) ON DELETE CASCADE
        );

        CREATE NONCLUSTERED INDEX [IX_ThanhToan_DonHangId] ON [dbo].[ThanhToan] ([DonHangId]);
        CREATE NONCLUSTERED INDEX [IX_ThanhToan_MaGiaoDich] ON [dbo].[ThanhToan] ([MaGiaoDich]);
        CREATE NONCLUSTERED INDEX [IX_ThanhToan_TrangThai] ON [dbo].[ThanhToan] ([TrangThai]);
    END

    -- =============================================
    -- 18. VeDienTu (E-Tickets)
    -- =============================================
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'VeDienTu')
    BEGIN
        CREATE TABLE [dbo].[VeDienTu] (
            [Id]              UNIQUEIDENTIFIER  NOT NULL DEFAULT NEWSEQUENTIALID(),
            [ChiTietDonHangId] INT              NOT NULL,
            [MaVe]            VARCHAR(20)       NOT NULL,
            [MaQRCode]        VARCHAR(100)      NOT NULL,
            [DuongDanQR]      NVARCHAR(500)     NULL,
            [TrangThai]       TINYINT           NOT NULL DEFAULT 0,  -- 0: ChuaSuDung, 1: DaSuDung, 2: DaHuy
            [NgayCheckin]     DATETIME2(7)      NULL,
            [NguoiCheckinId]  UNIQUEIDENTIFIER  NULL,
            [NgayTao]         DATETIME2(7)      NOT NULL DEFAULT GETUTCDATE(),

            CONSTRAINT [PK_VeDienTu] PRIMARY KEY CLUSTERED ([Id]),
            CONSTRAINT [UQ_VeDienTu_ChiTietDonHangId] UNIQUE ([ChiTietDonHangId]),
            CONSTRAINT [UQ_VeDienTu_MaVe] UNIQUE ([MaVe]),
            CONSTRAINT [UQ_VeDienTu_MaQRCode] UNIQUE ([MaQRCode]),
            CONSTRAINT [FK_VeDienTu_ChiTietDonHang] FOREIGN KEY ([ChiTietDonHangId])
                REFERENCES [dbo].[ChiTietDonHang]([Id]) ON DELETE CASCADE,
            CONSTRAINT [FK_VeDienTu_NguoiCheckin] FOREIGN KEY ([NguoiCheckinId])
                REFERENCES [dbo].[NguoiDung]([Id]) ON DELETE NO ACTION
        );

        CREATE NONCLUSTERED INDEX [IX_VeDienTu_MaVe] ON [dbo].[VeDienTu] ([MaVe]);
        CREATE NONCLUSTERED INDEX [IX_VeDienTu_MaQRCode] ON [dbo].[VeDienTu] ([MaQRCode]);
        CREATE NONCLUSTERED INDEX [IX_VeDienTu_TrangThai] ON [dbo].[VeDienTu] ([TrangThai]);
    END

    -- =============================================
    -- 19. LichSuCheckin (Check-in History)
    -- =============================================
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'LichSuCheckin')
    BEGIN
        CREATE TABLE [dbo].[LichSuCheckin] (
            [Id]              INT IDENTITY(1,1) NOT NULL,
            [VeDienTuId]      UNIQUEIDENTIFIER  NOT NULL,
            [NguoiCheckinId]  UNIQUEIDENTIFIER  NOT NULL,
            [KetQua]          TINYINT           NOT NULL DEFAULT 1,  -- 1: ThanhCong, 2: ThatBai, 3: DaCheckin
            [GhiChu]          NVARCHAR(500)     NULL,
            [ThoiGian]        DATETIME2(7)      NOT NULL DEFAULT GETUTCDATE(),

            CONSTRAINT [PK_LichSuCheckin] PRIMARY KEY CLUSTERED ([Id]),
            CONSTRAINT [FK_LichSuCheckin_VeDienTu] FOREIGN KEY ([VeDienTuId])
                REFERENCES [dbo].[VeDienTu]([Id]) ON DELETE CASCADE,
            CONSTRAINT [FK_LichSuCheckin_NguoiCheckin] FOREIGN KEY ([NguoiCheckinId])
                REFERENCES [dbo].[NguoiDung]([Id]) ON DELETE NO ACTION
        );

        CREATE NONCLUSTERED INDEX [IX_LichSuCheckin_VeDienTuId] ON [dbo].[LichSuCheckin] ([VeDienTuId]);
        CREATE NONCLUSTERED INDEX [IX_LichSuCheckin_NguoiCheckinId] ON [dbo].[LichSuCheckin] ([NguoiCheckinId]);
    END

    -- =============================================
    -- 20. LichSuMaGiamGia (Discount Usage History)
    -- =============================================
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'LichSuMaGiamGia')
    BEGIN
        CREATE TABLE [dbo].[LichSuMaGiamGia] (
            [Id]              INT IDENTITY(1,1) NOT NULL,
            [MaGiamGiaId]     INT               NOT NULL,
            [DonHangId]       UNIQUEIDENTIFIER  NOT NULL,
            [NguoiDungId]     UNIQUEIDENTIFIER  NOT NULL,
            [SoTienGiam]      DECIMAL(18,0)     NOT NULL,
            [NgaySuDung]      DATETIME2(7)      NOT NULL DEFAULT GETUTCDATE(),

            CONSTRAINT [PK_LichSuMaGiamGia] PRIMARY KEY CLUSTERED ([Id]),
            CONSTRAINT [FK_LichSuMaGiamGia_MaGiamGia] FOREIGN KEY ([MaGiamGiaId])
                REFERENCES [dbo].[MaGiamGia]([Id]) ON DELETE NO ACTION,
            CONSTRAINT [FK_LichSuMaGiamGia_DonHang] FOREIGN KEY ([DonHangId])
                REFERENCES [dbo].[DonHang]([Id]) ON DELETE NO ACTION,
            CONSTRAINT [FK_LichSuMaGiamGia_NguoiDung] FOREIGN KEY ([NguoiDungId])
                REFERENCES [dbo].[NguoiDung]([Id]) ON DELETE NO ACTION,
            CONSTRAINT [UQ_LichSuMaGiamGia_DonHangId] UNIQUE ([DonHangId])
        );

        CREATE NONCLUSTERED INDEX [IX_LichSuMaGiamGia_MaGiamGiaId] ON [dbo].[LichSuMaGiamGia] ([MaGiamGiaId]);
        CREATE NONCLUSTERED INDEX [IX_LichSuMaGiamGia_DonHangId] ON [dbo].[LichSuMaGiamGia] ([DonHangId]);
        CREATE NONCLUSTERED INDEX [IX_LichSuMaGiamGia_NguoiDungId] ON [dbo].[LichSuMaGiamGia] ([NguoiDungId]);
    END

    -- =============================================
    -- 21. ThongBao (Notifications)
    -- =============================================
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ThongBao')
    BEGIN
        CREATE TABLE [dbo].[ThongBao] (
            [Id]              INT IDENTITY(1,1) NOT NULL,
            [NguoiNhanId]     UNIQUEIDENTIFIER  NOT NULL,
            [TieuDe]          NVARCHAR(200)     NOT NULL,
            [NoiDung]         NVARCHAR(MAX)     NULL,
            [LoaiThongBao]    TINYINT           NOT NULL DEFAULT 1,  -- 1: HeThong, 2: DonHang, 3: SuKien, 4: KhuyenMai
            [DuongDan]        NVARCHAR(500)     NULL,
            [DaDoc]           BIT               NOT NULL DEFAULT 0,
            [NgayTao]         DATETIME2(7)      NOT NULL DEFAULT GETUTCDATE(),

            CONSTRAINT [PK_ThongBao] PRIMARY KEY CLUSTERED ([Id]),
            CONSTRAINT [FK_ThongBao_NguoiNhan] FOREIGN KEY ([NguoiNhanId])
                REFERENCES [dbo].[NguoiDung]([Id]) ON DELETE CASCADE
        );

        CREATE NONCLUSTERED INDEX [IX_ThongBao_NguoiNhanId] ON [dbo].[ThongBao] ([NguoiNhanId]);
        CREATE NONCLUSTERED INDEX [IX_ThongBao_NguoiNhanId_DaDoc] ON [dbo].[ThongBao] ([NguoiNhanId], [DaDoc]) WHERE [DaDoc] = 0;
        CREATE NONCLUSTERED INDEX [IX_ThongBao_NgayTao] ON [dbo].[ThongBao] ([NgayTao] DESC);
    END

    -- =============================================
    -- 22. LichSuEmail (Email Log)
    -- =============================================
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'LichSuEmail')
    BEGIN
        CREATE TABLE [dbo].[LichSuEmail] (
            [Id]              INT IDENTITY(1,1) NOT NULL,
            [NguoiNhanEmail]  NVARCHAR(256)     NOT NULL,
            [TieuDe]          NVARCHAR(200)     NOT NULL,
            [NoiDung]         NVARCHAR(MAX)     NULL,
            [LoaiEmail]       TINYINT           NOT NULL DEFAULT 1,  -- 1: XacNhan, 2: VeDienTu, 3: DatLaiMatKhau, 4: ThongBao
            [TrangThai]       TINYINT           NOT NULL DEFAULT 0,  -- 0: ChoGui, 1: DaGui, 2: ThatBai
            [LanThu]          INT               NOT NULL DEFAULT 1,
            [NgayTao]         DATETIME2(7)      NOT NULL DEFAULT GETUTCDATE(),
            [NgayGui]         DATETIME2(7)      NULL,

            CONSTRAINT [PK_LichSuEmail] PRIMARY KEY CLUSTERED ([Id])
        );

        CREATE NONCLUSTERED INDEX [IX_LichSuEmail_TrangThai] ON [dbo].[LichSuEmail] ([TrangThai]);
        CREATE NONCLUSTERED INDEX [IX_LichSuEmail_NgayTao] ON [dbo].[LichSuEmail] ([NgayTao] DESC);
    END

    -- =============================================
    -- 23. CauHinhHeThong (System Configuration)
    -- =============================================
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'CauHinhHeThong')
    BEGIN
        CREATE TABLE [dbo].[CauHinhHeThong] (
            [Id]              INT IDENTITY(1,1) NOT NULL,
            [MaCauHinh]       VARCHAR(100)      NOT NULL,
            [GiaTri]          NVARCHAR(MAX)     NULL,
            [MoTa]            NVARCHAR(500)     NULL,
            [NgayCapNhat]     DATETIME2(7)      NOT NULL DEFAULT GETUTCDATE(),

            CONSTRAINT [PK_CauHinhHeThong] PRIMARY KEY CLUSTERED ([Id]),
            CONSTRAINT [UQ_CauHinhHeThong_MaCauHinh] UNIQUE ([MaCauHinh])
        );
    END

    -- =============================================
    -- 24. NhatKyHeThong (System Logs)
    -- =============================================
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'NhatKyHeThong')
    BEGIN
        CREATE TABLE [dbo].[NhatKyHeThong] (
            [Id]              BIGINT IDENTITY(1,1) NOT NULL,
            [NguoiDungId]     UNIQUEIDENTIFIER     NULL,
            [HanhDong]        NVARCHAR(100)        NOT NULL,
            [DoiTuong]        NVARCHAR(100)        NULL,
            [DoiTuongId]      NVARCHAR(50)         NULL,
            [ChiTiet]         NVARCHAR(MAX)        NULL,
            [DiaChi_IP]       NVARCHAR(50)         NULL,
            [NgayTao]         DATETIME2(7)         NOT NULL DEFAULT GETUTCDATE(),

            CONSTRAINT [PK_NhatKyHeThong] PRIMARY KEY CLUSTERED ([Id]),
            CONSTRAINT [FK_NhatKyHeThong_NguoiDung] FOREIGN KEY ([NguoiDungId])
                REFERENCES [dbo].[NguoiDung]([Id]) ON DELETE SET NULL
        );

        CREATE NONCLUSTERED INDEX [IX_NhatKyHeThong_NguoiDungId] ON [dbo].[NhatKyHeThong] ([NguoiDungId]);
        CREATE NONCLUSTERED INDEX [IX_NhatKyHeThong_HanhDong] ON [dbo].[NhatKyHeThong] ([HanhDong]);
        CREATE NONCLUSTERED INDEX [IX_NhatKyHeThong_NgayTao] ON [dbo].[NhatKyHeThong] ([NgayTao] DESC);
        CREATE NONCLUSTERED INDEX [IX_NhatKyHeThong_DoiTuong] ON [dbo].[NhatKyHeThong] ([DoiTuong], [DoiTuongId]);
    END

    -- =============================================
    -- 25. LichSuHoanTien (Refund History)
    -- =============================================
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'LichSuHoanTien')
    BEGIN
        CREATE TABLE [dbo].[LichSuHoanTien] (
            [Id]              BIGINT IDENTITY(1,1) NOT NULL,
            [DonHangId]       UNIQUEIDENTIFIER     NOT NULL,
            [VeDienTuId]      UNIQUEIDENTIFIER     NULL,
            [SoTien]          DECIMAL(18,0)        NOT NULL,
            [LyDo]            NVARCHAR(1000)       NOT NULL,
            [NguoiXuLyId]     UNIQUEIDENTIFIER     NOT NULL,
            [NgayTao]         DATETIME2(7)         NOT NULL DEFAULT GETUTCDATE(),

            CONSTRAINT [PK_LichSuHoanTien] PRIMARY KEY CLUSTERED ([Id]),
            CONSTRAINT [FK_LichSuHoanTien_DonHang] FOREIGN KEY ([DonHangId])
                REFERENCES [dbo].[DonHang]([Id]) ON DELETE NO ACTION,
            CONSTRAINT [FK_LichSuHoanTien_VeDienTu] FOREIGN KEY ([VeDienTuId])
                REFERENCES [dbo].[VeDienTu]([Id]) ON DELETE NO ACTION,
            CONSTRAINT [FK_LichSuHoanTien_NguoiXuLy] FOREIGN KEY ([NguoiXuLyId])
                REFERENCES [dbo].[NguoiDung]([Id]) ON DELETE NO ACTION,
            CONSTRAINT [CK_LichSuHoanTien_SoTien] CHECK ([SoTien] > 0)
        );

        CREATE NONCLUSTERED INDEX [IX_LichSuHoanTien_DonHangId] ON [dbo].[LichSuHoanTien] ([DonHangId]);
    END

    -- =============================================
    -- SEED DATA: DanhMuc (Categories)
    -- =============================================
    IF NOT EXISTS (SELECT 1 FROM [dbo].[DanhMuc] WHERE [TenDanhMuc] = N'Nhac song')
        INSERT INTO [dbo].[DanhMuc] ([TenDanhMuc], [MoTa], [Icon], [ThuTu], [TrangThai])
        VALUES (N'Nhac song', N'Live Music - Cac buoi bieu dien am nhac truc tiep', N'🎵', 1, 1);

    IF NOT EXISTS (SELECT 1 FROM [dbo].[DanhMuc] WHERE [TenDanhMuc] = N'San khau & Nghe thuat')
        INSERT INTO [dbo].[DanhMuc] ([TenDanhMuc], [MoTa], [Icon], [ThuTu], [TrangThai])
        VALUES (N'San khau & Nghe thuat', N'Kich, nhac kich, mua va cac loai hinh nghe thuat bieu dien', N'🎭', 2, 1);

    IF NOT EXISTS (SELECT 1 FROM [dbo].[DanhMuc] WHERE [TenDanhMuc] = N'The thao')
        INSERT INTO [dbo].[DanhMuc] ([TenDanhMuc], [MoTa], [Icon], [ThuTu], [TrangThai])
        VALUES (N'The thao', N'Cac su kien the thao, giai dau, thi dau', N'⚽', 3, 1);

    IF NOT EXISTS (SELECT 1 FROM [dbo].[DanhMuc] WHERE [TenDanhMuc] = N'Hoi thao & Workshop')
        INSERT INTO [dbo].[DanhMuc] ([TenDanhMuc], [MoTa], [Icon], [ThuTu], [TrangThai])
        VALUES (N'Hoi thao & Workshop', N'Hoi nghi, hoi thao, workshop va cac khoa hoc', N'📚', 4, 1);

    IF NOT EXISTS (SELECT 1 FROM [dbo].[DanhMuc] WHERE [TenDanhMuc] = N'Tham quan & Trai nghiem')
        INSERT INTO [dbo].[DanhMuc] ([TenDanhMuc], [MoTa], [Icon], [ThuTu], [TrangThai])
        VALUES (N'Tham quan & Trai nghiem', N'Tour tham quan, trai nghiem van hoa, am thuc', N'🗺️', 5, 1);

    IF NOT EXISTS (SELECT 1 FROM [dbo].[DanhMuc] WHERE [TenDanhMuc] = N'Khac')
        INSERT INTO [dbo].[DanhMuc] ([TenDanhMuc], [MoTa], [Icon], [ThuTu], [TrangThai])
        VALUES (N'Khac', N'Cac su kien khac khong thuoc danh muc cu the', N'🎪', 6, 1);

    -- =============================================
    -- SEED DATA: CauHinhHeThong (System Configuration)
    -- =============================================
    IF NOT EXISTS (SELECT 1 FROM [dbo].[CauHinhHeThong] WHERE [MaCauHinh] = 'VNPay_TmnCode')
        INSERT INTO [dbo].[CauHinhHeThong] ([MaCauHinh], [GiaTri], [MoTa])
        VALUES ('VNPay_TmnCode', '', N'Ma terminal VNPay');

    IF NOT EXISTS (SELECT 1 FROM [dbo].[CauHinhHeThong] WHERE [MaCauHinh] = 'VNPay_HashSecret')
        INSERT INTO [dbo].[CauHinhHeThong] ([MaCauHinh], [GiaTri], [MoTa])
        VALUES ('VNPay_HashSecret', '', N'Secret key VNPay');

    IF NOT EXISTS (SELECT 1 FROM [dbo].[CauHinhHeThong] WHERE [MaCauHinh] = 'VNPay_Url')
        INSERT INTO [dbo].[CauHinhHeThong] ([MaCauHinh], [GiaTri], [MoTa])
        VALUES ('VNPay_Url', 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html', N'URL thanh toan VNPay');

    IF NOT EXISTS (SELECT 1 FROM [dbo].[CauHinhHeThong] WHERE [MaCauHinh] = 'VNPay_ReturnUrl')
        INSERT INTO [dbo].[CauHinhHeThong] ([MaCauHinh], [GiaTri], [MoTa])
        VALUES ('VNPay_ReturnUrl', 'http://localhost:5127/Booking/PaymentReturn', N'URL tra ve sau thanh toan VNPay');

    IF NOT EXISTS (SELECT 1 FROM [dbo].[CauHinhHeThong] WHERE [MaCauHinh] = 'Email_SmtpHost')
        INSERT INTO [dbo].[CauHinhHeThong] ([MaCauHinh], [GiaTri], [MoTa])
        VALUES ('Email_SmtpHost', 'smtp.gmail.com', N'SMTP host gui email');

    IF NOT EXISTS (SELECT 1 FROM [dbo].[CauHinhHeThong] WHERE [MaCauHinh] = 'Email_SmtpPort')
        INSERT INTO [dbo].[CauHinhHeThong] ([MaCauHinh], [GiaTri], [MoTa])
        VALUES ('Email_SmtpPort', '587', N'SMTP port gui email');

    IF NOT EXISTS (SELECT 1 FROM [dbo].[CauHinhHeThong] WHERE [MaCauHinh] = 'Email_Username')
        INSERT INTO [dbo].[CauHinhHeThong] ([MaCauHinh], [GiaTri], [MoTa])
        VALUES ('Email_Username', '', N'Email dung de gui');

    IF NOT EXISTS (SELECT 1 FROM [dbo].[CauHinhHeThong] WHERE [MaCauHinh] = 'Email_Password')
        INSERT INTO [dbo].[CauHinhHeThong] ([MaCauHinh], [GiaTri], [MoTa])
        VALUES ('Email_Password', '', N'Mat khau email gui');

    IF NOT EXISTS (SELECT 1 FROM [dbo].[CauHinhHeThong] WHERE [MaCauHinh] = 'PhiDichVu_MacDinh')
        INSERT INTO [dbo].[CauHinhHeThong] ([MaCauHinh], [GiaTri], [MoTa])
        VALUES ('PhiDichVu_MacDinh', '8.5', N'Phi dich vu mac dinh (%) ap dung cho moi su kien');

    IF NOT EXISTS (SELECT 1 FROM [dbo].[CauHinhHeThong] WHERE [MaCauHinh] = 'ThoiGianGiuCho_Phut')
        INSERT INTO [dbo].[CauHinhHeThong] ([MaCauHinh], [GiaTri], [MoTa])
        VALUES ('ThoiGianGiuCho_Phut', '15', N'Thoi gian giu cho don hang (phut) truoc khi tu dong huy');

    -- Provision the first admin account through a controlled deployment step.

    -- =============================================
    -- COMMIT TRANSACTION
    -- =============================================
    COMMIT TRANSACTION;
    PRINT N'WuangEvents database schema created/updated successfully.';

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();
    DECLARE @ErrorLine INT = ERROR_LINE();

    PRINT N'Error occurred at line ' + CAST(@ErrorLine AS NVARCHAR(10)) + N': ' + @ErrorMessage;

    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
END CATCH;
GO
