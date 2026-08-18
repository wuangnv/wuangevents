-- File seed demo: có thể chạy từ database master. Nếu chưa có thì tự tạo WuangEvents.
-- Lưu ý: các bảng của WuangEvents sẽ bị xóa và dựng lại, chỉ dùng cho dữ liệu demo.
USE [master];
GO

IF DB_ID(N'WuangEvents') IS NULL
BEGIN
    CREATE DATABASE [WuangEvents];
END
GO

USE [WuangEvents];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
GO

-- Dựng lại database demo: DROP dữ liệu cũ, CREATE bảng rồi INSERT seed; không chạy trên dữ liệu thật.
-- Toàn bộ dùng transaction: thành công COMMIT, lỗi thì XACT_ABORT/CATCH ROLLBACK.

-- === WuangEvents demo schema 2NF: có thể chạy lại để dựng dữ liệu từ đầu ===

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

BEGIN TRY

    -- Drop constraints first to avoid dependency conflicts
    IF OBJECT_ID('[dbo].[ThongBao]', 'U') IS NOT NULL ALTER TABLE [dbo].[ThongBao] DROP CONSTRAINT IF EXISTS [FK_ThongBao_NguoiDung];
    IF OBJECT_ID('[dbo].[NhanVienSuKien]', 'U') IS NOT NULL ALTER TABLE [dbo].[NhanVienSuKien] DROP CONSTRAINT IF EXISTS [FK_NhanVienSuKien_NguoiDung];
    IF OBJECT_ID('[dbo].[NhanVienSuKien]', 'U') IS NOT NULL ALTER TABLE [dbo].[NhanVienSuKien] DROP CONSTRAINT IF EXISTS [FK_NhanVienSuKien_SuKien];
    IF OBJECT_ID('[dbo].[ChoNgoi]', 'U') IS NOT NULL ALTER TABLE [dbo].[ChoNgoi] DROP CONSTRAINT IF EXISTS [FK_ChoNgoi_HangGhe];
    IF OBJECT_ID('[dbo].[HangGhe]', 'U') IS NOT NULL ALTER TABLE [dbo].[HangGhe] DROP CONSTRAINT IF EXISTS [FK_HangGhe_KhuVuc];
    IF OBJECT_ID('[dbo].[KhuVuc]', 'U') IS NOT NULL ALTER TABLE [dbo].[KhuVuc] DROP CONSTRAINT IF EXISTS [FK_KhuVuc_LoaiVe];
    IF OBJECT_ID('[dbo].[KhuVuc]', 'U') IS NOT NULL ALTER TABLE [dbo].[KhuVuc] DROP CONSTRAINT IF EXISTS [FK_KhuVuc_SoDoChoNgoi];
    IF OBJECT_ID('[dbo].[SoDoChoNgoi]', 'U') IS NOT NULL ALTER TABLE [dbo].[SoDoChoNgoi] DROP CONSTRAINT IF EXISTS [FK_SoDoChoNgoi_SuKien];
    IF OBJECT_ID('[dbo].[ChiTietDonHang]', 'U') IS NOT NULL ALTER TABLE [dbo].[ChiTietDonHang] DROP CONSTRAINT IF EXISTS [FK_ChiTietDonHang_ChoNgoi];
    IF OBJECT_ID('[dbo].[ChiTietDonHang]', 'U') IS NOT NULL ALTER TABLE [dbo].[ChiTietDonHang] DROP CONSTRAINT IF EXISTS [FK_ChiTietDonHang_LoaiVe];
    IF OBJECT_ID('[dbo].[ChiTietDonHang]', 'U') IS NOT NULL ALTER TABLE [dbo].[ChiTietDonHang] DROP CONSTRAINT IF EXISTS [FK_ChiTietDonHang_DonHang];
    IF OBJECT_ID('[dbo].[DonHang]', 'U') IS NOT NULL ALTER TABLE [dbo].[DonHang] DROP CONSTRAINT IF EXISTS [FK_DonHang_MaGiamGia];
    IF OBJECT_ID('[dbo].[DonHang]', 'U') IS NOT NULL ALTER TABLE [dbo].[DonHang] DROP CONSTRAINT IF EXISTS [FK_DonHang_SuKien];
    IF OBJECT_ID('[dbo].[DonHang]', 'U') IS NOT NULL ALTER TABLE [dbo].[DonHang] DROP CONSTRAINT IF EXISTS [FK_DonHang_NguoiMua];
    IF OBJECT_ID('[dbo].[MaGiamGia]', 'U') IS NOT NULL ALTER TABLE [dbo].[MaGiamGia] DROP CONSTRAINT IF EXISTS [FK_MaGiamGia_SuKien];
    IF OBJECT_ID('[dbo].[LoaiVe]', 'U') IS NOT NULL ALTER TABLE [dbo].[LoaiVe] DROP CONSTRAINT IF EXISTS [FK_LoaiVe_SuKien];
    IF OBJECT_ID('[dbo].[SuKien]', 'U') IS NOT NULL ALTER TABLE [dbo].[SuKien] DROP CONSTRAINT IF EXISTS [FK_SuKien_DanhMuc];
    IF OBJECT_ID('[dbo].[SuKien]', 'U') IS NOT NULL ALTER TABLE [dbo].[SuKien] DROP CONSTRAINT IF EXISTS [FK_SuKien_NguoiToChuc];
    IF OBJECT_ID('[dbo].[NguoiDung]', 'U') IS NOT NULL ALTER TABLE [dbo].[NguoiDung] DROP CONSTRAINT IF EXISTS [FK_NguoiDung_NguoiTao];

    -- Drop tables if they exist (in dependency order)
    DROP TABLE IF EXISTS [dbo].[NhanVienSuKien];
    DROP TABLE IF EXISTS [dbo].[ChoNgoi];
    DROP TABLE IF EXISTS [dbo].[HangGhe];
    DROP TABLE IF EXISTS [dbo].[KhuVuc];
    DROP TABLE IF EXISTS [dbo].[SoDoChoNgoi];
    DROP TABLE IF EXISTS [dbo].[ChiTietDonHang];
    DROP TABLE IF EXISTS [dbo].[DonHang];
    DROP TABLE IF EXISTS [dbo].[MaGiamGia];
    DROP TABLE IF EXISTS [dbo].[LoaiVe];
    DROP TABLE IF EXISTS [dbo].[SuKien];
    DROP TABLE IF EXISTS [dbo].[DanhMuc];
    DROP TABLE IF EXISTS [dbo].[ThongBao];
    DROP TABLE IF EXISTS [dbo].[ThongTinBanToChuc];
    DROP TABLE IF EXISTS [dbo].[DiaDiem];
    DROP TABLE IF EXISTS [dbo].[NguoiDung];

    -- 1. NguoiDung
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
        [TokenXacNhan]    NVARCHAR(100)    NULL,
        [NgayTao]         DATETIME2(7)     NOT NULL DEFAULT GETUTCDATE(),
        [NgayCapNhat]     DATETIME2(7)     NULL,
        
        -- Bank info
        [TenNganHang]     NVARCHAR(100)    NULL,
        [SoTaiKhoan]      NVARCHAR(50)     NULL,
        [ChuTaiKhoan]     NVARCHAR(100)    NULL,

        -- Organizer approval columns
        [YeuCauBanToChuc] TINYINT          NOT NULL DEFAULT 0,   -- 0: ChuaGui, 1: ChoDuyet, 2: DaDuyet, 3: TuChoi
        [SdtBanToChuc]    NVARCHAR(20)     NULL,
        [TenToChuc]       NVARCHAR(150)    NULL,
        [LoaiChuTheBTC]   TINYINT          NULL,                 -- 0: CaNhan, 1: DoanhNghiepDonVi
        [MoTaYeuCauBTC]   NVARCHAR(1000)   NULL,
        [DaDongYDieuKhoanBTC] BIT          NOT NULL DEFAULT 0,
        [LyDoTuChoiBTC]   NVARCHAR(1000)   NULL,
        [NgayYeuCauBTC]   DATETIME2(7)     NULL,

        -- Staff relationship column
        [NguoiTaoId]      UNIQUEIDENTIFIER NULL,

        CONSTRAINT [PK_NguoiDung] PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT [UQ_NguoiDung_Email] UNIQUE ([Email]),
        CONSTRAINT [FK_NguoiDung_NguoiTao] FOREIGN KEY ([NguoiTaoId]) REFERENCES [dbo].[NguoiDung]([Id]),
        CONSTRAINT [CK_NguoiDung_YeuCauBTC] CHECK ([YeuCauBanToChuc] IN (0, 1, 2, 3)),
        CONSTRAINT [CK_NguoiDung_LoaiChuTheBTC] CHECK ([LoaiChuTheBTC] IS NULL OR [LoaiChuTheBTC] IN (0, 1))
    );

    -- Bảng thông báo được OrganizerController sử dụng khi gửi thông báo cho người mua vé.
    CREATE TABLE [dbo].[ThongBao] (
        [Id]              INT IDENTITY(1,1) NOT NULL,
        [NguoiNhanId]     UNIQUEIDENTIFIER  NOT NULL,
        [TieuDe]          NVARCHAR(200)     NOT NULL,
        [NoiDung]         NVARCHAR(MAX)     NOT NULL,
        [LoaiThongBao]    TINYINT           NOT NULL DEFAULT 0,
        [DuongDan]        NVARCHAR(500)     NULL,
        [DaDoc]           BIT               NOT NULL DEFAULT 0,
        [NgayTao]         DATETIME2(7)      NOT NULL DEFAULT GETUTCDATE(),

        CONSTRAINT [PK_ThongBao] PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT [FK_ThongBao_NguoiDung] FOREIGN KEY ([NguoiNhanId]) REFERENCES [dbo].[NguoiDung]([Id]) ON DELETE CASCADE
    );

    -- 2. DanhMuc
    CREATE TABLE [dbo].[DanhMuc] (
        [Id]              INT IDENTITY(1,1) NOT NULL,
        [TenDanhMuc]      NVARCHAR(100)     NOT NULL,
        [MoTa]            NVARCHAR(500)     NULL,
        [Icon]            NVARCHAR(100)     NULL,
        [ThuTu]           INT               NOT NULL DEFAULT 0,
        [TrangThai]       BIT               NOT NULL DEFAULT 1,
        CONSTRAINT [PK_DanhMuc] PRIMARY KEY CLUSTERED ([Id])
    );

    -- 3. SuKien
    CREATE TABLE [dbo].[SuKien] (
        [Id]              UNIQUEIDENTIFIER  NOT NULL DEFAULT NEWSEQUENTIALID(),
        [NguoiToChucId]   UNIQUEIDENTIFIER  NOT NULL,
        [DanhMucId]       INT               NOT NULL,
        [TenSuKien]       NVARCHAR(300)     NOT NULL,
        [Slug]            VARCHAR(350)      NOT NULL,
        [MoTaNgan]        NVARCHAR(500)     NULL,
        [MoTaChiTiet]     NVARCHAR(MAX)     NULL,
        [AnhBia]          NVARCHAR(500)     NULL,
        [AnhThumbnail]    NVARCHAR(500)     NULL,
        [NgayBatDau]      DATETIME2(7)      NOT NULL,
        [NgayKetThuc]     DATETIME2(7)      NOT NULL,
        [LoaiSuKien]      TINYINT           NOT NULL DEFAULT 0,  -- 0: Offline, 1: Online
        [LinkOnline]      NVARCHAR(500)     NULL,
        [CoSoDoChoNgoi]   BIT               NOT NULL DEFAULT 0,
        [TrangThai]       TINYINT           NOT NULL DEFAULT 0,  -- 0: Nhap, 1: ChoDuyet, 3: DangBan, 6: DaHuy, 7: TuChoi
        [LyDoTuChoi]      NVARCHAR(1000)    NULL,
        [NoiBat]          BIT               NOT NULL DEFAULT 0,
        [HienThiCongKhai] BIT               NOT NULL DEFAULT 1,
        [NgayTao]         DATETIME2(7)      NOT NULL DEFAULT GETUTCDATE(),
        [NgayCapNhat]     DATETIME2(7)      NULL,
        [BatDauCheckIn]   DATETIME2(7)      NULL,
        [KetThucCheckIn]  DATETIME2(7)      NULL,

        -- Location columns merged directly into SuKien
        [TenDiaDiem]      NVARCHAR(255)     NULL,
        [DiaChiDiaDiem]   NVARCHAR(255)     NULL,
        [ThanhPhoDiaDiem] NVARCHAR(100)     NULL,
        [QuanHuyenDiaDiem] NVARCHAR(100)    NULL,
        [SucChuaDiaDiem]  INT               NULL,

        CONSTRAINT [PK_SuKien] PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT [UQ_SuKien_Slug] UNIQUE ([Slug]),
        CONSTRAINT [FK_SuKien_NguoiToChuc] FOREIGN KEY ([NguoiToChucId]) REFERENCES [dbo].[NguoiDung]([Id]),
        CONSTRAINT [FK_SuKien_DanhMuc] FOREIGN KEY ([DanhMucId]) REFERENCES [dbo].[DanhMuc]([Id]),
        CONSTRAINT [CK_SuKien_ThoiGian] CHECK ([NgayKetThuc] > [NgayBatDau]),
        CONSTRAINT [CK_SuKien_Loai] CHECK ([LoaiSuKien] IN (0, 1)),
        CONSTRAINT [CK_SuKien_TrangThai] CHECK ([TrangThai] BETWEEN 0 AND 7),
        CONSTRAINT [CK_SuKien_SucChua] CHECK ([SucChuaDiaDiem] IS NULL OR [SucChuaDiaDiem] > 0)
    );

    -- 4. LoaiVe
    CREATE TABLE [dbo].[LoaiVe] (
        [Id]              INT IDENTITY(1,1) NOT NULL,
        [SuKienId]        UNIQUEIDENTIFIER  NOT NULL,
        [TenLoaiVe]       NVARCHAR(100)     NOT NULL,
        [MoTa]            NVARCHAR(1000)    NULL,
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
        CONSTRAINT [UQ_LoaiVe_SuKien_Ten] UNIQUE ([SuKienId], [TenLoaiVe]),
        CONSTRAINT [FK_LoaiVe_SuKien] FOREIGN KEY ([SuKienId]) REFERENCES [dbo].[SuKien]([Id]) ON DELETE CASCADE,
        CONSTRAINT [CK_LoaiVe_Gia] CHECK ([GiaBan] >= 0),
        CONSTRAINT [CK_LoaiVe_SoLuong] CHECK ([SoLuongTong] > 0 AND [SoLuongDaBan] >= 0 AND [SoLuongGiuCho] >= 0 AND [SoLuongDaBan] + [SoLuongGiuCho] <= [SoLuongTong]),
        CONSTRAINT [CK_LoaiVe_GioiHan] CHECK ([GioiHanMoiDon] BETWEEN 1 AND 20),
        CONSTRAINT [CK_LoaiVe_ThoiGianBan] CHECK ([NgayBatDauBan] IS NULL OR [NgayKetThucBan] IS NULL OR [NgayKetThucBan] > [NgayBatDauBan])
    );

    -- 5. MaGiamGia
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
        [NgayBatDau]      DATETIME2(7)      NOT NULL,
        [NgayKetThuc]     DATETIME2(7)      NOT NULL,
        [TrangThai]       BIT               NOT NULL DEFAULT 1,
        [NgayTao]         DATETIME2(7)      NOT NULL DEFAULT GETUTCDATE(),

        CONSTRAINT [PK_MaGiamGia] PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT [UQ_MaGiamGia_SuKien_Code] UNIQUE ([SuKienId], [MaCode]),
        CONSTRAINT [FK_MaGiamGia_SuKien] FOREIGN KEY ([SuKienId]) REFERENCES [dbo].[SuKien]([Id]) ON DELETE CASCADE,
        CONSTRAINT [CK_MaGiamGia_Loai] CHECK ([LoaiGiamGia] IN (0, 1)),
        CONSTRAINT [CK_MaGiamGia_GiaTri] CHECK ([GiaTri] > 0 AND ([LoaiGiamGia] <> 0 OR [GiaTri] <= 100)),
        CONSTRAINT [CK_MaGiamGia_SoLuong] CHECK ([SoLuongTong] > 0 AND [SoLuongDaDung] >= 0 AND [SoLuongDaDung] <= [SoLuongTong]),
        CONSTRAINT [CK_MaGiamGia_ThoiGian] CHECK ([NgayKetThuc] > [NgayBatDau])
    );

    -- 6. DonHang
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
        [TongThanhToan]   DECIMAL(18,0)     NOT NULL DEFAULT 0,
        [TrangThai]       TINYINT           NOT NULL DEFAULT 0,  -- 0: ChoThanhToan, 1: DaThanhToan, 2: DaHuy, 4: HetHan
        [NgayTao]         DATETIME2(7)      NOT NULL DEFAULT GETUTCDATE(),
        [NgayCapNhat]     DATETIME2(7)      NULL,
        
        -- Payment merged columns
        [MaGiaoDich]      VARCHAR(100)      NULL,
        [PhuongThucThanhToan] TINYINT       NULL,                -- 1: MienPhi, 2: VNPAY, 3: MoMo, 4: ZaloPay
        [NgayThanhToan]   DATETIME2(7)      NULL,

        CONSTRAINT [PK_DonHang] PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT [UQ_DonHang_MaDonHang] UNIQUE ([MaDonHang]),
        CONSTRAINT [FK_DonHang_NguoiMua] FOREIGN KEY ([NguoiMuaId]) REFERENCES [dbo].[NguoiDung]([Id]),
        CONSTRAINT [FK_DonHang_SuKien] FOREIGN KEY ([SuKienId]) REFERENCES [dbo].[SuKien]([Id]),
        CONSTRAINT [FK_DonHang_MaGiamGia] FOREIGN KEY ([MaGiamGiaId]) REFERENCES [dbo].[MaGiamGia]([Id]) ON DELETE SET NULL,
        CONSTRAINT [CK_DonHang_TrangThai] CHECK ([TrangThai] IN (0, 1, 2, 4)),
        CONSTRAINT [CK_DonHang_SoTien] CHECK ([TongTienVe] >= 0 AND [TienGiamGia] >= 0 AND [TienGiamGia] <= [TongTienVe] AND [TongThanhToan] = [TongTienVe] - [TienGiamGia]),
        CONSTRAINT [CK_DonHang_PhuongThuc] CHECK ([PhuongThucThanhToan] IS NULL OR [PhuongThucThanhToan] IN (1, 2, 3, 4))
    );

    -- 7. ChiTietDonHang
    CREATE TABLE [dbo].[ChiTietDonHang] (
        [Id]              INT IDENTITY(1,1) NOT NULL,
        [DonHangId]       UNIQUEIDENTIFIER  NOT NULL,
        [LoaiVeId]        INT               NOT NULL,
        [ChoNgoiId]       INT               NULL,
        [GiaVe]           DECIMAL(18,0)     NOT NULL,
        [TenNguoiThamDu]  NVARCHAR(100)     NULL,
        [EmailNguoiThamDu] NVARCHAR(256)    NULL,
        
        -- Ticket QR/Check-in merged columns
        [MaVe]            VARCHAR(20)       NULL,
        [MaQRCode]        VARCHAR(100)      NULL,
        [TrangThaiCheckin] TINYINT          NOT NULL DEFAULT 0,  -- 0: ChuaCheckin, 1: DaCheckin, 2: DaHuy
        [NgayCheckin]     DATETIME2(7)      NULL,
        [NguoiCheckinId]  UNIQUEIDENTIFIER  NULL,

        CONSTRAINT [PK_ChiTietDonHang] PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT [FK_ChiTietDonHang_DonHang] FOREIGN KEY ([DonHangId]) REFERENCES [dbo].[DonHang]([Id]) ON DELETE CASCADE,
        CONSTRAINT [FK_ChiTietDonHang_LoaiVe] FOREIGN KEY ([LoaiVeId]) REFERENCES [dbo].[LoaiVe]([Id]),
        CONSTRAINT [CK_ChiTietDonHang_GiaVe] CHECK ([GiaVe] >= 0),
        CONSTRAINT [CK_ChiTietDonHang_Checkin] CHECK ([TrangThaiCheckin] IN (0, 1, 2))
    );

    -- Đơn chờ chưa có mã vé/QR; chỉ kiểm tra trùng với các mã đã được sinh sau thanh toán.
    CREATE UNIQUE INDEX [UQ_ChiTietDonHang_MaVe]
        ON [dbo].[ChiTietDonHang]([MaVe]) WHERE [MaVe] IS NOT NULL;
    CREATE UNIQUE INDEX [UQ_ChiTietDonHang_MaQRCode]
        ON [dbo].[ChiTietDonHang]([MaQRCode]) WHERE [MaQRCode] IS NOT NULL;

    -- 8. SoDoChoNgoi
    CREATE TABLE [dbo].[SoDoChoNgoi] (
        [Id]              INT IDENTITY(1,1) NOT NULL,
        [SuKienId]        UNIQUEIDENTIFIER  NOT NULL,
        [TenSoDo]         NVARCHAR(200)     NOT NULL,
        [LoaiSoDo]        NVARCHAR(30)      NOT NULL DEFAULT N'custom',
        [CanvasRong]      INT               NOT NULL DEFAULT 960,
        [CanvasCao]       INT               NOT NULL DEFAULT 650,
        [SanKhauX]        INT               NULL,
        [SanKhauY]        INT               NULL,
        [SanKhauRong]     INT               NOT NULL DEFAULT 280,
        [SanKhauCao]      INT               NOT NULL DEFAULT 44,
        [NhanSanKhau]     NVARCHAR(100)     NOT NULL DEFAULT N'SÂN KHẤU',
        [NgayTao]         DATETIME2(7)      NOT NULL DEFAULT GETUTCDATE(),

        CONSTRAINT [PK_SoDoChoNgoi] PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT [UQ_SoDoChoNgoi_SuKienId] UNIQUE ([SuKienId]),
        CONSTRAINT [CK_SoDoChoNgoi_LoaiSoDo] CHECK ([LoaiSoDo] IN (N'workshop', N'auditorium', N'concert', N'gala', N'arena', N'custom', N'theatre', N'cinema')),
        CONSTRAINT [FK_SoDoChoNgoi_SuKien] FOREIGN KEY ([SuKienId]) REFERENCES [dbo].[SuKien]([Id]) ON DELETE CASCADE
    );

    -- 9. KhuVuc
    CREATE TABLE [dbo].[KhuVuc] (
        [Id]              INT IDENTITY(1,1) NOT NULL,
        [SoDoChoNgoiId]   INT               NOT NULL,
        [LoaiVeId]        INT               NOT NULL,
        [TenKhuVuc]       NVARCHAR(100)     NOT NULL,
        [MauSac]          VARCHAR(7)        NULL,
        [ViTriX]          INT               NULL,
        [ViTriY]          INT               NULL,
        [Rong]            INT               NOT NULL DEFAULT 0,
        [Cao]             INT               NOT NULL DEFAULT 0,
        [LoaiKhuVuc]      VARCHAR(10)       NOT NULL DEFAULT 'seated',
        [SucChua]         INT               NULL,
        [TienToHangGhe]   NVARCHAR(10)      NOT NULL DEFAULT N'',
        [KieuDanhSo]      VARCHAR(10)       NOT NULL DEFAULT 'ltr',
        [SoBatDau]        INT               NOT NULL DEFAULT 1,
        [BoQuaChuDeNham]  BIT               NOT NULL DEFAULT 1,
        [ThuTu]           INT               NOT NULL DEFAULT 0,

        CONSTRAINT [PK_KhuVuc] PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT [UQ_KhuVuc_SoDo_Ten] UNIQUE ([SoDoChoNgoiId], [TenKhuVuc]),
        CONSTRAINT [FK_KhuVuc_SoDoChoNgoi] FOREIGN KEY ([SoDoChoNgoiId]) REFERENCES [dbo].[SoDoChoNgoi]([Id]) ON DELETE CASCADE,
        CONSTRAINT [FK_KhuVuc_LoaiVe] FOREIGN KEY ([LoaiVeId]) REFERENCES [dbo].[LoaiVe]([Id]),
        CONSTRAINT [CK_KhuVuc_LoaiKhuVuc] CHECK ([LoaiKhuVuc] IN ('seated', 'ga', 'banquet'))
    );

    -- 10. HangGhe
    CREATE TABLE [dbo].[HangGhe] (
        [Id]              INT IDENTITY(1,1) NOT NULL,
        [KhuVucId]        INT               NOT NULL,
        [TenHang]         NVARCHAR(10)      NOT NULL,
        [SoGhe]           INT               NOT NULL,
        [ThuTu]           INT               NOT NULL DEFAULT 0,

        CONSTRAINT [PK_HangGhe] PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT [UQ_HangGhe_KhuVuc_Ten] UNIQUE ([KhuVucId], [TenHang]),
        CONSTRAINT [FK_HangGhe_KhuVuc] FOREIGN KEY ([KhuVucId]) REFERENCES [dbo].[KhuVuc]([Id]) ON DELETE CASCADE,
        CONSTRAINT [CK_HangGhe_SoGhe] CHECK ([SoGhe] > 0)
    );

    -- 11. ChoNgoi
    CREATE TABLE [dbo].[ChoNgoi] (
        [Id]              INT IDENTITY(1,1) NOT NULL,
        [HangGheId]       INT               NOT NULL,
        [SoGhe]           NVARCHAR(10)      NOT NULL,
        [ViTriX]          INT               NULL,
        [ViTriY]          INT               NULL,
        [TrangThai]       TINYINT           NOT NULL DEFAULT 0,  -- 0: Trong, 1: DangGiu, 2: DaBan, 3: Khoa

        CONSTRAINT [PK_ChoNgoi] PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT [UQ_ChoNgoi_Hang_SoGhe] UNIQUE ([HangGheId], [SoGhe]),
        CONSTRAINT [FK_ChoNgoi_HangGhe] FOREIGN KEY ([HangGheId]) REFERENCES [dbo].[HangGhe]([Id]) ON DELETE CASCADE,
        CONSTRAINT [CK_ChoNgoi_TrangThai] CHECK ([TrangThai] IN (0, 1, 2, 3))
    );

    -- 12. NhanVienSuKien
    CREATE TABLE [dbo].[NhanVienSuKien] (
        [Id]              INT IDENTITY(1,1) NOT NULL,
        [NguoiDungId]     UNIQUEIDENTIFIER  NOT NULL,
        [SuKienId]        UNIQUEIDENTIFIER  NOT NULL,
        [VaiTroNV]        NVARCHAR(50)      NOT NULL DEFAULT N'CheckIn',
        [NgayThem]        DATETIME2(7)      NOT NULL DEFAULT GETUTCDATE(),

        CONSTRAINT [PK_NhanVienSuKien] PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT [UQ_NhanVienSuKien] UNIQUE ([NguoiDungId], [SuKienId]),
        CONSTRAINT [FK_NhanVienSuKien_NguoiDung] FOREIGN KEY ([NguoiDungId]) REFERENCES [dbo].[NguoiDung]([Id]) ON DELETE CASCADE,
        CONSTRAINT [FK_NhanVienSuKien_SuKien] FOREIGN KEY ([SuKienId]) REFERENCES [dbo].[SuKien]([Id]) ON DELETE CASCADE
    );

    -- Add back the constraint for ChiTietDonHang referencing ChoNgoi
    ALTER TABLE [dbo].[ChiTietDonHang] ADD CONSTRAINT [FK_ChiTietDonHang_ChoNgoi] FOREIGN KEY ([ChoNgoiId]) REFERENCES [dbo].[ChoNgoi]([Id]) ON DELETE SET NULL;
    ALTER TABLE [dbo].[ChiTietDonHang] ADD CONSTRAINT [FK_ChiTietDonHang_NguoiCheckin] FOREIGN KEY ([NguoiCheckinId]) REFERENCES [dbo].[NguoiDung]([Id]);

    -- =============================================
    -- SEED DATA:

    -- =============================================
    -- SEED DATA: DanhMuc (6)
    -- =============================================
    INSERT INTO [dbo].[DanhMuc] ([TenDanhMuc], [MoTa], [Icon], [ThuTu], [TrangThai])
    VALUES (N'Âm nhạc & Concert', N'Các đêm nhạc Liveshow, Acoustic, EDM, Giao hưởng thính phòng sôi động.', 'fas fa-music', 0, 1);
    INSERT INTO [dbo].[DanhMuc] ([TenDanhMuc], [MoTa], [Icon], [ThuTu], [TrangThai])
    VALUES (N'Kịch nói & Nghệ thuật', N'Kịch nói tâm lý, kịch tương tác, triển lãm hội họa đương đại.', 'fas fa-theater-masks', 1, 1);
    INSERT INTO [dbo].[DanhMuc] ([TenDanhMuc], [MoTa], [Icon], [ThuTu], [TrangThai])
    VALUES (N'Hội thảo & Giáo dục', N'Hội thảo chuyên môn, workshop kỹ năng, diễn đàn công nghệ.', 'fas fa-graduation-cap', 2, 1);
    INSERT INTO [dbo].[DanhMuc] ([TenDanhMuc], [MoTa], [Icon], [ThuTu], [TrangThai])
    VALUES (N'Thể thao & Giải trí', N'Giải chạy cộng đồng, thi đấu thể thao, trò chơi vận động.', 'fas fa-running', 3, 1);
    INSERT INTO [dbo].[DanhMuc] ([TenDanhMuc], [MoTa], [Icon], [ThuTu], [TrangThai])
    VALUES (N'Ẩm thực & Du lịch', N'Lễ hội ẩm thực đường phố, ngày hội văn hóa, tour trải nghiệm.', 'fas fa-utensils', 4, 1);
    INSERT INTO [dbo].[DanhMuc] ([TenDanhMuc], [MoTa], [Icon], [ThuTu], [TrangThai])
    VALUES (N'Triển lãm & Hội chợ', N'Triển lãm sản phẩm nghệ thuật, ngày hội giao thương, hội chợ sách.', 'fas fa-images', 5, 1);


    -- =============================================
    -- SEED DATA: NguoiDung (Admin, Organizers, Buyers, Staff)
    -- =============================================

    -- Admin (1)
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('F1784A22-D111-4E6D-ABFF-EE1C04F0906D', 'admin@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Quản Trị Viên Hệ Thống', '0912345678', NULL, 3, 1, 1, GETUTCDATE());

    -- Organizer 1
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [TenNganHang], [SoTaiKhoan], [ChuTaiKhoan], [YeuCauBanToChuc], [SdtBanToChuc], [NgayYeuCauBTC], [NgayTao])
    VALUES ('5B5CE913-3124-448A-812B-85B5A4AB1A03', 'organizer1@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhà Tổ Chức 1', '0987654301', NULL, 1, 1, 1, 'Vietcombank', '0071001234001', 'NGUYEN VAN BTC 1', 2, '0987654301', GETUTCDATE(), GETUTCDATE());

    -- Organizer 2
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [TenNganHang], [SoTaiKhoan], [ChuTaiKhoan], [YeuCauBanToChuc], [SdtBanToChuc], [NgayYeuCauBTC], [NgayTao])
    VALUES ('C6D443D8-3015-4677-8BE2-D3C92C777062', 'organizer2@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhà Tổ Chức 2', '0987654302', NULL, 1, 1, 1, 'Vietcombank', '0071001234002', 'NGUYEN VAN BTC 2', 2, '0987654302', GETUTCDATE(), GETUTCDATE());

    -- Organizer 3
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [TenNganHang], [SoTaiKhoan], [ChuTaiKhoan], [YeuCauBanToChuc], [SdtBanToChuc], [NgayYeuCauBTC], [NgayTao])
    VALUES ('3A1B89A7-7E53-4A33-ACAE-FE4A71DC7BE4', 'organizer3@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhà Tổ Chức 3', '0987654303', NULL, 1, 1, 1, 'Vietcombank', '0071001234003', 'NGUYEN VAN BTC 3', 2, '0987654303', GETUTCDATE(), GETUTCDATE());

    -- Organizer 4
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [TenNganHang], [SoTaiKhoan], [ChuTaiKhoan], [YeuCauBanToChuc], [SdtBanToChuc], [NgayYeuCauBTC], [NgayTao])
    VALUES ('DF63CB1F-67FF-4CB5-8BA2-6C30FBF1F240', 'organizer4@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhà Tổ Chức 4', '0987654304', NULL, 1, 1, 1, 'Vietcombank', '0071001234004', 'NGUYEN VAN BTC 4', 2, '0987654304', GETUTCDATE(), GETUTCDATE());

    -- Organizer 5
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [TenNganHang], [SoTaiKhoan], [ChuTaiKhoan], [YeuCauBanToChuc], [SdtBanToChuc], [NgayYeuCauBTC], [NgayTao])
    VALUES ('C7C46C00-D517-46AF-8121-7FADE6992FFA', 'organizer5@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhà Tổ Chức 5', '0987654305', NULL, 1, 1, 1, 'Vietcombank', '0071001234005', 'NGUYEN VAN BTC 5', 2, '0987654305', GETUTCDATE(), GETUTCDATE());

    -- Organizer 6
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [TenNganHang], [SoTaiKhoan], [ChuTaiKhoan], [YeuCauBanToChuc], [SdtBanToChuc], [NgayYeuCauBTC], [NgayTao])
    VALUES ('5146EDFE-FC06-44CD-AAB4-C4B6BC9AD765', 'organizer6@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhà Tổ Chức 6', '0987654306', NULL, 1, 1, 1, 'Vietcombank', '0071001234006', 'NGUYEN VAN BTC 6', 2, '0987654306', GETUTCDATE(), GETUTCDATE());

    -- Organizer 7
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [TenNganHang], [SoTaiKhoan], [ChuTaiKhoan], [YeuCauBanToChuc], [SdtBanToChuc], [NgayYeuCauBTC], [NgayTao])
    VALUES ('95F1339E-2245-4449-A2B9-85C046A2D1DD', 'organizer7@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhà Tổ Chức 7', '0987654307', NULL, 1, 1, 1, 'Vietcombank', '0071001234007', 'NGUYEN VAN BTC 7', 2, '0987654307', GETUTCDATE(), GETUTCDATE());

    -- Organizer 8
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [TenNganHang], [SoTaiKhoan], [ChuTaiKhoan], [YeuCauBanToChuc], [SdtBanToChuc], [NgayYeuCauBTC], [NgayTao])
    VALUES ('1EFB3BD4-1BFD-4F1F-BD98-B17BA7B72074', 'organizer8@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhà Tổ Chức 8', '0987654308', NULL, 1, 1, 1, 'Vietcombank', '0071001234008', 'NGUYEN VAN BTC 8', 2, '0987654308', GETUTCDATE(), GETUTCDATE());

    -- Organizer 9
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [TenNganHang], [SoTaiKhoan], [ChuTaiKhoan], [YeuCauBanToChuc], [SdtBanToChuc], [NgayYeuCauBTC], [NgayTao])
    VALUES ('725DCDFC-12B8-48F7-A427-805527F0112C', 'organizer9@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhà Tổ Chức 9', '0987654309', NULL, 1, 1, 1, 'Vietcombank', '0071001234009', 'NGUYEN VAN BTC 9', 2, '0987654309', GETUTCDATE(), GETUTCDATE());

    -- Organizer 10
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [TenNganHang], [SoTaiKhoan], [ChuTaiKhoan], [YeuCauBanToChuc], [SdtBanToChuc], [NgayYeuCauBTC], [NgayTao])
    VALUES ('50075312-F374-48A9-8B2C-48F109BF34E9', 'organizer10@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhà Tổ Chức 10', '0987654310', NULL, 1, 1, 1, 'Vietcombank', '0071001234010', 'NGUYEN VAN BTC 10', 2, '0987654310', GETUTCDATE(), GETUTCDATE());

    -- Buyer 1
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('77EDA4D0-64A0-4CD8-9BC0-C4B56C3DBA52', 'battlegrounds2004@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 1', '0901234501', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 2
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('DB847C61-CC0B-41F5-9BEB-F6132B0E5BF2', 'buyer2@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 2', '0901234502', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 3
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('B46BD4B0-EAC9-4C87-A500-785131A97B4A', 'buyer3@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 3', '0901234503', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 4
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('FE3E3726-2435-43B9-9688-308CA7D1F34A', 'buyer4@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 4', '0901234504', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 5
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('06BF864B-30A7-4413-B9C4-321686732721', 'buyer5@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 5', '0901234505', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 6
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('42F528B2-7107-4672-B7FC-3D49A10F63F6', 'buyer6@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 6', '0901234506', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 7
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('3C416A14-C60B-48F9-9FA5-7CFE1FFCD5E7', 'buyer7@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 7', '0901234507', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 8
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('F5E77535-E905-43E7-907C-108141C0485F', 'buyer8@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 8', '0901234508', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 9
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('00858E32-C188-44CC-8A26-21A599A2F73C', 'buyer9@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 9', '0901234509', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 10
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('CB31862C-E0C2-4590-A9F6-A0AB45513214', 'buyer10@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 10', '0901234510', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 11
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000011', 'buyer11@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 11', '0901234511', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 12
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000012', 'buyer12@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 12', '0901234512', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 13
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000013', 'buyer13@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 13', '0901234513', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 14
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000014', 'buyer14@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 14', '0901234514', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 15
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000015', 'buyer15@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 15', '0901234515', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 16
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000016', 'buyer16@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 16', '0901234516', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 17
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000017', 'buyer17@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 17', '0901234517', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 18
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000018', 'buyer18@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 18', '0901234518', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 19
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000019', 'buyer19@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 19', '0901234519', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 20
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000020', 'buyer20@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 20', '0901234520', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 21
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000021', 'buyer21@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 21', '0901234521', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 22
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000022', 'buyer22@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 22', '0901234522', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 23
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000023', 'buyer23@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 23', '0901234523', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 24
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000024', 'buyer24@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 24', '0901234524', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 25
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000025', 'buyer25@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 25', '0901234525', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 26
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000026', 'buyer26@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 26', '0901234526', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 27
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000027', 'buyer27@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 27', '0901234527', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 28
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000028', 'buyer28@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 28', '0901234528', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 29
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000029', 'buyer29@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 29', '0901234529', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 30
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000030', 'buyer30@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 30', '0901234530', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 31
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000031', 'buyer31@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 31', '0901234531', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 32
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000032', 'buyer32@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 32', '0901234532', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 33
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000033', 'buyer33@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 33', '0901234533', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 34
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000034', 'buyer34@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 34', '0901234534', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 35
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000035', 'buyer35@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 35', '0901234535', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 36
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000036', 'buyer36@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 36', '0901234536', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 37
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000037', 'buyer37@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 37', '0901234537', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 38
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000038', 'buyer38@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 38', '0901234538', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 39
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000039', 'buyer39@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 39', '0901234539', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 40
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000040', 'buyer40@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 40', '0901234540', NULL, 0, 1, 1, GETUTCDATE());

    -- Staff 1 (Quản lý bởi Organizer 1)
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NguoiTaoId], [NgayTao])
    VALUES ('55F02A90-5841-4563-A735-C12B9717BB96', 'staff1@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhân Viên Soát Vé 1', '0971234501', NULL, 2, 1, 1, '5B5CE913-3124-448A-812B-85B5A4AB1A03', GETUTCDATE());

    -- Staff 2 (Quản lý bởi Organizer 2)
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NguoiTaoId], [NgayTao])
    VALUES ('308F7B86-4503-4DB4-87F1-A66A56C7A3BF', 'staff2@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhân Viên Soát Vé 2', '0971234502', NULL, 2, 1, 1, 'C6D443D8-3015-4677-8BE2-D3C92C777062', GETUTCDATE());

    -- Staff 3 (Quản lý bởi Organizer 3)
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NguoiTaoId], [NgayTao])
    VALUES ('73E06548-F2B9-4768-837D-1A942636A27F', 'staff3@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhân Viên Soát Vé 3', '0971234503', NULL, 2, 1, 1, '3A1B89A7-7E53-4A33-ACAE-FE4A71DC7BE4', GETUTCDATE());

    -- Staff 4 (Quản lý bởi Organizer 4)
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NguoiTaoId], [NgayTao])
    VALUES ('706BEA74-E775-460F-8E3B-74BBFA81A5CF', 'staff4@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhân Viên Soát Vé 4', '0971234504', NULL, 2, 1, 1, 'DF63CB1F-67FF-4CB5-8BA2-6C30FBF1F240', GETUTCDATE());

    -- Staff 5 (Quản lý bởi Organizer 5)
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NguoiTaoId], [NgayTao])
    VALUES ('5EA93981-1208-4862-AE9C-7E14FEFB596B', 'staff5@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhân Viên Soát Vé 5', '0971234505', NULL, 2, 1, 1, 'C7C46C00-D517-46AF-8121-7FADE6992FFA', GETUTCDATE());

    -- Staff 6 (Quản lý bởi Organizer 6)
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NguoiTaoId], [NgayTao])
    VALUES ('FC115C36-482E-4648-A580-A4AF9E50D33D', 'staff6@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhân Viên Soát Vé 6', '0971234506', NULL, 2, 1, 1, '5146EDFE-FC06-44CD-AAB4-C4B6BC9AD765', GETUTCDATE());

    -- Staff 7 (Quản lý bởi Organizer 7)
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NguoiTaoId], [NgayTao])
    VALUES ('817AC6A9-9F7E-40F3-A119-D4D31FD01C74', 'staff7@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhân Viên Soát Vé 7', '0971234507', NULL, 2, 1, 1, '95F1339E-2245-4449-A2B9-85C046A2D1DD', GETUTCDATE());

    -- Staff 8 (Quản lý bởi Organizer 8)
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NguoiTaoId], [NgayTao])
    VALUES ('71D84E61-3BC1-4270-8E01-5738E4D673FF', 'staff8@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhân Viên Soát Vé 8', '0971234508', NULL, 2, 1, 1, '1EFB3BD4-1BFD-4F1F-BD98-B17BA7B72074', GETUTCDATE());

    -- Staff 9 (Quản lý bởi Organizer 9)
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NguoiTaoId], [NgayTao])
    VALUES ('16DE5824-396A-49AB-9D33-6850ADA72500', 'staff9@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhân Viên Soát Vé 9', '0971234509', NULL, 2, 1, 1, '725DCDFC-12B8-48F7-A427-805527F0112C', GETUTCDATE());

    -- Staff 10 (Quản lý bởi Organizer 10)
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NguoiTaoId], [NgayTao])
    VALUES ('59443B1B-7793-40DE-B0E2-11ACD1C16FDF', 'staff10@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhân Viên Soát Vé 10', '0971234510', NULL, 2, 1, 1, '50075312-F374-48A9-8B2C-48F109BF34E9', GETUTCDATE());

    -- Staff 11 (Quản lý bởi Organizer 1)
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NguoiTaoId], [NgayTao])
    VALUES ('B0000000-0000-0000-0000-000000000011', 'staff11@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhân Viên Soát Vé 11', '0971234511', NULL, 2, 1, 1, '5B5CE913-3124-448A-812B-85B5A4AB1A03', GETUTCDATE());

    -- Staff 12 (Quản lý bởi Organizer 2)
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NguoiTaoId], [NgayTao])
    VALUES ('B0000000-0000-0000-0000-000000000012', 'staff12@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhân Viên Soát Vé 12', '0971234512', NULL, 2, 1, 1, 'C6D443D8-3015-4677-8BE2-D3C92C777062', GETUTCDATE());

    -- Staff 13 (Quản lý bởi Organizer 3)
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NguoiTaoId], [NgayTao])
    VALUES ('B0000000-0000-0000-0000-000000000013', 'staff13@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhân Viên Soát Vé 13', '0971234513', NULL, 2, 1, 1, '3A1B89A7-7E53-4A33-ACAE-FE4A71DC7BE4', GETUTCDATE());

    -- Staff 14 (Quản lý bởi Organizer 4)
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NguoiTaoId], [NgayTao])
    VALUES ('B0000000-0000-0000-0000-000000000014', 'staff14@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhân Viên Soát Vé 14', '0971234514', NULL, 2, 1, 1, 'DF63CB1F-67FF-4CB5-8BA2-6C30FBF1F240', GETUTCDATE());

    -- Staff 15 (Quản lý bởi Organizer 5)
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NguoiTaoId], [NgayTao])
    VALUES ('B0000000-0000-0000-0000-000000000015', 'staff15@gmail.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhân Viên Soát Vé 15', '0971234515', NULL, 2, 1, 1, 'C7C46C00-D517-46AF-8121-7FADE6992FFA', GETUTCDATE());


    -- =============================================
    -- SEED DATA: SuKien (60)
    -- =============================================

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('D3C3FBCE-4FFF-4F33-A4AF-0A2750C9E94E', '5B5CE913-3124-448A-812B-85B5A4AB1A03', 1, N'Đại nhạc hội WuangEvents Live 2026', 'dai-nhac-hoi-wuangevents-live-2026-01', N'Đại nhạc hội bùng nổ của cộng đồng sinh viên toàn thành phố.', N'Mô tả chi tiết của sự kiện Đại nhạc hội WuangEvents Live 2026.', '/uploads/banners/professional/ai-va-future-business-strategy.jpg', DATEADD(day, 3, GETUTCDATE()), DATEADD(day, 3, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 1, 3, NULL, 1, 1, GETUTCDATE(), N'Sân vận động Phú Thọ', N'Địa chỉ chi tiết của Sân vận động Phú Thọ', N'Hồ Chí Minh', N'Quận 1', 15000);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E20875EC-36DB-45EB-85D1-A706DC9B62D2', 'C6D443D8-3015-4677-8BE2-D3C92C777062', 1, N'Đêm nhạc Jazz cổ điển Sài Gòn', 'dem-nhac-jazz-co-dien-sai-gon-02', N'Những giai điệu Jazz ấm áp trong lòng thành phố nhộn nhịp.', N'Mô tả chi tiết của sự kiện Đêm nhạc Jazz cổ điển Sài Gòn.', '/uploads/banners/professional/art-jamming-va-natural-wine.jpg', DATEADD(minute, 30, GETUTCDATE()), DATEADD(hour, 3, GETUTCDATE()), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Nhà hát lớn Bến Thành', N'Địa chỉ chi tiết của Nhà hát lớn Bến Thành', N'Hồ Chí Minh', N'Quận 1', 1000);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('D2C252F2-7FD4-4A02-86CB-3D9DE7415795', '3A1B89A7-7E53-4A33-ACAE-FE4A71DC7BE4', 1, N'Rock Storm - Bùng cháy đam mê', 'rock-storm-bung-chay-dam-me-03', N'Đêm nhạc Rock đầy nhiệt huyết của thế hệ trẻ học đường.', N'Mô tả chi tiết của sự kiện Rock Storm - Bùng cháy đam mê.', '/uploads/banners/professional/automotive-mobility-solutions-conference.jpg', DATEADD(day, 1, GETUTCDATE()), DATEADD(day, 1, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Trung tâm Hội nghị GEM Center', N'Địa chỉ chi tiết của Trung tâm Hội nghị GEM Center', N'Hồ Chí Minh', N'Quận 1', 2000);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('5BC842AD-6166-406A-AD93-EB3ECACFBF7E', 'DF63CB1F-67FF-4CB5-8BA2-6C30FBF1F240', 1, N'Acoustic Sunset - Giai điệu hoàng hôn', 'acoustic-sunset-giai-dieu-hoang-hon-04', N'Lắng đọng cùng những bản acoustic mộc mạc lúc chiều tà.', N'Mô tả chi tiết của sự kiện Acoustic Sunset - Giai điệu hoàng hôn.', '/uploads/banners/professional/board-game-va-coffee-social.jpg', DATEADD(day, -2, GETUTCDATE()), DATEADD(day, -2, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Sân vận động Quân khu 7', N'Địa chỉ chi tiết của Sân vận động Quân khu 7', N'Hồ Chí Minh', N'Quận 1', 20000);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('9B265F0B-613C-4094-9DC8-4B74E1F42E65', 'C7C46C00-D517-46AF-8121-7FADE6992FFA', 1, N'EDM Soundwave Festival 2026', 'edm-soundwave-festival-2026-05', N'Lễ hội âm nhạc điện tử sôi động cùng các DJ tên tuổi.', N'Mô tả chi tiết của sự kiện EDM Soundwave Festival 2026.', '/uploads/banners/professional/build-better-hcmc-2026.jpg', DATEADD(day, 15, GETUTCDATE()), DATEADD(day, 15, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 2, NULL, 1, 1, GETUTCDATE(), N'Nhà thi đấu Nguyễn Du', N'Địa chỉ chi tiết của Nhà thi đấu Nguyễn Du', N'Hồ Chí Minh', N'Quận 1', 3000);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('A0A26D2F-FF2E-4175-B318-C3FCE0BA23FB', '5146EDFE-FC06-44CD-AAB4-C4B6BC9AD765', 1, N'Hòa nhạc thính phòng Giai điệu Mùa xuân', 'hoa-nhac-thinh-phong-giai-dieu-mua-xuan-06', N'Không gian âm nhạc giao hưởng cổ điển tinh tế.', N'Mô tả chi tiết của sự kiện Hòa nhạc thính phòng Giai điệu Mùa xuân.', '/uploads/banners/professional/chao-show-am-sac-viet-nam.jpg', DATEADD(day, 18, GETUTCDATE()), DATEADD(day, 18, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 1, NULL, 1, 1, GETUTCDATE(), N'Phố đi bộ Nguyễn Huệ', N'Địa chỉ chi tiết của Phố đi bộ Nguyễn Huệ', N'Hồ Chí Minh', N'Quận 1', 50000);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000007', '1EFB3BD4-1BFD-4F1F-BD98-B17BA7B72074', 1, N'Concert JustaTee: Hành Trình Mới', 'concert-justatee-hanh-trinh-moi-7', N'Đêm nhạc liveshow hoành tráng quy tụ các ngôi sao hàng đầu.', N'Mô tả chi tiết của sự kiện Concert JustaTee: Hành Trình Mới.', '/uploads/banners/professional/chef-s-table-modern-vietnamese-dinner.jpg', DATEADD(day, 11, GETUTCDATE()), DATEADD(day, 11, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Nhà thi đấu Quân khu 7', N'Địa chỉ chi tiết của Nhà thi đấu Quân khu 7', N'Hồ Chí Minh', N'Quận 1', 5000);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000008', '95F1339E-2245-4449-A2B9-85C046A2D1DD', 1, N'Concert Vũ: Vũ Trụ Song Song', 'concert-vu-vu-tru-song-song-8', N'Đêm nhạc liveshow hoành tráng quy tụ các ngôi sao hàng đầu.', N'Mô tả chi tiết của sự kiện Concert Vũ: Vũ Trụ Song Song.', '/uploads/banners/professional/city-yoga-va-wellness-day.jpg', DATEADD(day, 11, GETUTCDATE()), DATEADD(day, 11, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Nhà thi đấu Quân khu 7', N'Địa chỉ chi tiết của Nhà thi đấu Quân khu 7', N'Hồ Chí Minh', N'Quận 1', 5000);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000009', '50075312-F374-48A9-8B2C-48F109BF34E9', 1, N'Concert Soobin: Vũ Trụ Song Song', 'concert-soobin-vu-tru-song-song-9', N'Đêm nhạc liveshow hoành tráng quy tụ các ngôi sao hàng đầu.', N'Mô tả chi tiết của sự kiện Concert Soobin: Vũ Trụ Song Song.', '/uploads/banners/professional/cu-chi-tunnels-history-tour.jpg', DATEADD(minute, 60, GETUTCDATE()), DATEADD(hour, 4, GETUTCDATE()), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Nhà thi đấu Quân khu 7', N'Địa chỉ chi tiết của Nhà thi đấu Quân khu 7', N'Hồ Chí Minh', N'Quận 1', 5000);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000010', '5146EDFE-FC06-44CD-AAB4-C4B6BC9AD765', 1, N'Concert Đen Vâu: Chân Trời Mực Rỡ', 'concert-den-vau-chan-troi-muc-ro-10', N'Đêm nhạc liveshow hoành tráng quy tụ các ngôi sao hàng đầu.', N'Mô tả chi tiết của sự kiện Concert Đen Vâu: Chân Trời Mực Rỡ.', '/uploads/banners/professional/dalat-coffee-farm-experience.jpg', DATEADD(day, 12, GETUTCDATE()), DATEADD(day, 12, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Nhà thi đấu Quân khu 7', N'Địa chỉ chi tiết của Nhà thi đấu Quân khu 7', N'Hồ Chí Minh', N'Quận 1', 5000);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000011', 'C7C46C00-D517-46AF-8121-7FADE6992FFA', 2, N'Kịch nói: Đời Cô Lựu', 'kich-noi-doi-co-luu-11', N'Vở kịch đặc sắc được đầu tư công phu với dàn diễn viên gạo cội.', N'Mô tả chi tiết của sự kiện Kịch nói: Đời Cô Lựu.', '/uploads/banners/professional/de-garden-kokedama-workshop.jpg', DATEADD(day, 9, GETUTCDATE()), DATEADD(day, 9, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Sân khấu kịch Idecaf', N'Địa chỉ chi tiết của Sân khấu kịch Idecaf', N'Hồ Chí Minh', N'Quận 1', 500);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000012', 'C6D443D8-3015-4677-8BE2-D3C92C777062', 2, N'Kịch nói: Tô Ánh Nguyệt', 'kich-noi-to-anh-nguyet-12', N'Vở kịch đặc sắc được đầu tư công phu với dàn diễn viên gạo cội.', N'Mô tả chi tiết của sự kiện Kịch nói: Tô Ánh Nguyệt.', '/uploads/banners/professional/family-science-day.jpg', DATEADD(day, 55, GETUTCDATE()), DATEADD(day, 55, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Sân khấu kịch Idecaf', N'Địa chỉ chi tiết của Sân khấu kịch Idecaf', N'Hồ Chí Minh', N'Quận 1', 500);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000013', 'C7C46C00-D517-46AF-8121-7FADE6992FFA', 2, N'Triển lãm nghệ thuật: Sắc Màu Thời Gian', 'trien-lam-nghe-thuat-sac-mau-thoi-gian-13', N'Không gian nghệ thuật thị giác độc đáo trưng bày hàng trăm tác phẩm tuyển chọn.', N'Mô tả chi tiết của sự kiện Triển lãm nghệ thuật: Sắc Màu Thời Gian.', '/uploads/banners/professional/gama-music-racing-festival.jpg', DATEADD(day, 58, GETUTCDATE()), DATEADD(day, 58, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Bảo tàng Mỹ thuật TP.HCM', N'Địa chỉ chi tiết của Bảo tàng Mỹ thuật TP.HCM', N'Hồ Chí Minh', N'Quận 1', 800);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000014', '50075312-F374-48A9-8B2C-48F109BF34E9', 2, N'Triển lãm nghệ thuật: Sắc Màu Thời Gian', 'trien-lam-nghe-thuat-sac-mau-thoi-gian-14', N'Không gian nghệ thuật thị giác độc đáo trưng bày hàng trăm tác phẩm tuyển chọn.', N'Mô tả chi tiết của sự kiện Triển lãm nghệ thuật: Sắc Màu Thời Gian.', '/uploads/banners/professional/gitex-vietnam-2026.jpg', DATEADD(day, 29, GETUTCDATE()), DATEADD(day, 29, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Bảo tàng Mỹ thuật TP.HCM', N'Địa chỉ chi tiết của Bảo tàng Mỹ thuật TP.HCM', N'Hồ Chí Minh', N'Quận 1', 800);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000015', '725DCDFC-12B8-48F7-A427-805527F0112C', 2, N'Kịch nói: Bóng Ma Nhà Hát', 'kich-noi-bong-ma-nha-hat-15', N'Vở kịch đặc sắc được đầu tư công phu với dàn diễn viên gạo cội.', N'Mô tả chi tiết của sự kiện Kịch nói: Bóng Ma Nhà Hát.', '/uploads/banners/professional/hanoi-climbing-cup.jpg', DATEADD(day, 9, GETUTCDATE()), DATEADD(day, 9, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Sân khấu kịch Idecaf', N'Địa chỉ chi tiết của Sân khấu kịch Idecaf', N'Hồ Chí Minh', N'Quận 1', 500);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000016', '725DCDFC-12B8-48F7-A427-805527F0112C', 2, N'Triển lãm nghệ thuật: Nét Vẽ Tự Do', 'trien-lam-nghe-thuat-net-ve-tu-do-16', N'Không gian nghệ thuật thị giác độc đáo trưng bày hàng trăm tác phẩm tuyển chọn.', N'Mô tả chi tiết của sự kiện Triển lãm nghệ thuật: Nét Vẽ Tự Do.', '/uploads/banners/professional/ho-tram-beach-triathlon.jpg', DATEADD(day, 23, GETUTCDATE()), DATEADD(day, 23, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 2, NULL, 1, 1, GETUTCDATE(), N'Bảo tàng Mỹ thuật TP.HCM', N'Địa chỉ chi tiết của Bảo tàng Mỹ thuật TP.HCM', N'Hồ Chí Minh', N'Quận 1', 800);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000017', '50075312-F374-48A9-8B2C-48F109BF34E9', 2, N'Kịch nói: Bóng Ma Nhà Hát', 'kich-noi-bong-ma-nha-hat-17', N'Vở kịch đặc sắc được đầu tư công phu với dàn diễn viên gạo cội.', N'Mô tả chi tiết của sự kiện Kịch nói: Bóng Ma Nhà Hát.', '/uploads/banners/professional/hon-viet-dan-nhac-duong-dai.jpg', DATEADD(minute, 60, GETUTCDATE()), DATEADD(hour, 4, GETUTCDATE()), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Sân khấu kịch Idecaf', N'Địa chỉ chi tiết của Sân khấu kịch Idecaf', N'Hồ Chí Minh', N'Quận 1', 500);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000018', '3A1B89A7-7E53-4A33-ACAE-FE4A71DC7BE4', 2, N'Triển lãm nghệ thuật: Khoảng Trống Tâm Hồn', 'trien-lam-nghe-thuat-khoang-trong-tam-hon-18', N'Không gian nghệ thuật thị giác độc đáo trưng bày hàng trăm tác phẩm tuyển chọn.', N'Mô tả chi tiết của sự kiện Triển lãm nghệ thuật: Khoảng Trống Tâm Hồn.', '/uploads/banners/professional/indie-film-weekend.jpg', DATEADD(minute, 60, GETUTCDATE()), DATEADD(hour, 4, GETUTCDATE()), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Bảo tàng Mỹ thuật TP.HCM', N'Địa chỉ chi tiết của Bảo tàng Mỹ thuật TP.HCM', N'Hồ Chí Minh', N'Quận 1', 800);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000019', 'C7C46C00-D517-46AF-8121-7FADE6992FFA', 2, N'Kịch nói: Sân Khấu Cuộc Đời', 'kich-noi-san-khau-cuoc-doi-19', N'Vở kịch đặc sắc được đầu tư công phu với dàn diễn viên gạo cội.', N'Mô tả chi tiết của sự kiện Kịch nói: Sân Khấu Cuộc Đời.', '/uploads/banners/professional/k-pulse-hanoi-2026.jpg', DATEADD(minute, 60, GETUTCDATE()), DATEADD(hour, 4, GETUTCDATE()), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Sân khấu kịch Idecaf', N'Địa chỉ chi tiết của Sân khấu kịch Idecaf', N'Hồ Chí Minh', N'Quận 1', 500);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000020', 'DF63CB1F-67FF-4CB5-8BA2-6C30FBF1F240', 2, N'Kịch nói: Đêm Lạnh Chùa Hoang', 'kich-noi-dem-lanh-chua-hoang-20', N'Vở kịch đặc sắc được đầu tư công phu với dàn diễn viên gạo cội.', N'Mô tả chi tiết của sự kiện Kịch nói: Đêm Lạnh Chùa Hoang.', '/uploads/banners/professional/lion-championship-33.jpg', DATEADD(day, 5, GETUTCDATE()), DATEADD(day, 5, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Sân khấu kịch Idecaf', N'Địa chỉ chi tiết của Sân khấu kịch Idecaf', N'Hồ Chí Minh', N'Quận 1', 500);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000021', '5B5CE913-3124-448A-812B-85B5A4AB1A03', 3, N'Hội thảo: Lập Trình Web Hiện Đại', 'hoi-thao-lap-trinh-web-hien-dai-21', N'Chia sẻ kiến thức chuyên môn từ các chuyên gia hàng đầu trong ngành công nghệ.', N'Mô tả chi tiết của sự kiện Hội thảo: Lập Trình Web Hiện Đại.', '/uploads/banners/professional/may-saigon-livestage-trung-quan-va-siu-black.jpg', DATEADD(day, 41, GETUTCDATE()), DATEADD(day, 41, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Tòa nhà Dreamplex Nguyễn Trung Ngạn', N'Địa chỉ chi tiết của Tòa nhà Dreamplex Nguyễn Trung Ngạn', N'Hồ Chí Minh', N'Quận 1', 300);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000022', '50075312-F374-48A9-8B2C-48F109BF34E9', 3, N'Workshop: Làm Chủ MS Excel & SQL', 'workshop-lam-chu-ms-excel-sql-22', N'Khóa đào tạo ngắn hạn tương tác cao giúp nâng cao kỹ năng thực chiến.', N'Mô tả chi tiết của sự kiện Workshop: Làm Chủ MS Excel & SQL.', '/uploads/banners/professional/metashow-cham-vao-anh-sang.jpg', DATEADD(day, 34, GETUTCDATE()), DATEADD(day, 34, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 2, NULL, 1, 1, GETUTCDATE(), N'Trung tâm Đào tạo Kyna', N'Địa chỉ chi tiết của Trung tâm Đào tạo Kyna', N'Hồ Chí Minh', N'Quận 1', 100);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000023', 'C6D443D8-3015-4677-8BE2-D3C92C777062', 3, N'Hội thảo: Kiến Trúc Hệ Thống Cloud', 'hoi-thao-kien-truc-he-thong-cloud-23', N'Chia sẻ kiến thức chuyên môn từ các chuyên gia hàng đầu trong ngành công nghệ.', N'Mô tả chi tiết của sự kiện Hội thảo: Kiến Trúc Hệ Thống Cloud.', '/uploads/banners/professional/power-bi-from-data-to-insights.jpg', DATEADD(day, 15, GETUTCDATE()), DATEADD(day, 15, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Tòa nhà Dreamplex Nguyễn Trung Ngạn', N'Địa chỉ chi tiết của Tòa nhà Dreamplex Nguyễn Trung Ngạn', N'Hồ Chí Minh', N'Quận 1', 300);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000024', 'DF63CB1F-67FF-4CB5-8BA2-6C30FBF1F240', 3, N'Workshop: Nghệ Thuật Giao Tiếp Đỉnh Cao', 'workshop-nghe-thuat-giao-tiep-dinh-cao-24', N'Khóa đào tạo ngắn hạn tương tác cao giúp nâng cao kỹ năng thực chiến.', N'Mô tả chi tiết của sự kiện Workshop: Nghệ Thuật Giao Tiếp Đỉnh Cao.', '/uploads/banners/professional/saigon-midnight-run-2026.jpg', DATEADD(day, 24, GETUTCDATE()), DATEADD(day, 24, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Trung tâm Đào tạo Kyna', N'Địa chỉ chi tiết của Trung tâm Đào tạo Kyna', N'Hồ Chí Minh', N'Quận 1', 100);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000025', '50075312-F374-48A9-8B2C-48F109BF34E9', 3, N'Hội thảo: Trí Tuệ Nhân Tạo & Tương Lai', 'hoi-thao-tri-tue-nhan-tao-tuong-lai-25', N'Chia sẻ kiến thức chuyên môn từ các chuyên gia hàng đầu trong ngành công nghệ.', N'Mô tả chi tiết của sự kiện Hội thảo: Trí Tuệ Nhân Tạo & Tương Lai.', '/uploads/banners/professional/saigon-soul-pool-party.jpg', DATEADD(day, 12, GETUTCDATE()), DATEADD(day, 12, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Tòa nhà Dreamplex Nguyễn Trung Ngạn', N'Địa chỉ chi tiết của Tòa nhà Dreamplex Nguyễn Trung Ngạn', N'Hồ Chí Minh', N'Quận 1', 300);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000026', '725DCDFC-12B8-48F7-A427-805527F0112C', 3, N'Hội thảo: Lập Trình Web Hiện Đại', 'hoi-thao-lap-trinh-web-hien-dai-26', N'Chia sẻ kiến thức chuyên môn từ các chuyên gia hàng đầu trong ngành công nghệ.', N'Mô tả chi tiết của sự kiện Hội thảo: Lập Trình Web Hiện Đại.', '/uploads/banners/professional/saigon-vintage-market.jpg', DATEADD(day, -9, GETUTCDATE()), DATEADD(day, -9, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Tòa nhà Dreamplex Nguyễn Trung Ngạn', N'Địa chỉ chi tiết của Tòa nhà Dreamplex Nguyễn Trung Ngạn', N'Hồ Chí Minh', N'Quận 1', 300);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000027', '1EFB3BD4-1BFD-4F1F-BD98-B17BA7B72074', 3, N'Hội thảo: Lập Trình Web Hiện Đại', 'hoi-thao-lap-trinh-web-hien-dai-27', N'Chia sẻ kiến thức chuyên môn từ các chuyên gia hàng đầu trong ngành công nghệ.', N'Mô tả chi tiết của sự kiện Hội thảo: Lập Trình Web Hiện Đại.', '/uploads/banners/professional/startup-networking-night.jpg', DATEADD(day, 32, GETUTCDATE()), DATEADD(day, 32, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Tòa nhà Dreamplex Nguyễn Trung Ngạn', N'Địa chỉ chi tiết của Tòa nhà Dreamplex Nguyễn Trung Ngạn', N'Hồ Chí Minh', N'Quận 1', 300);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000028', 'C6D443D8-3015-4677-8BE2-D3C92C777062', 3, N'Hội thảo: DevOps & CI/CD Mastery', 'hoi-thao-devops-ci-cd-mastery-28', N'Chia sẻ kiến thức chuyên môn từ các chuyên gia hàng đầu trong ngành công nghệ.', N'Mô tả chi tiết của sự kiện Hội thảo: DevOps & CI/CD Mastery.', '/uploads/banners/professional/teh-dar-the-highlands-story.jpg', DATEADD(day, 57, GETUTCDATE()), DATEADD(day, 57, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Tòa nhà Dreamplex Nguyễn Trung Ngạn', N'Địa chỉ chi tiết của Tòa nhà Dreamplex Nguyễn Trung Ngạn', N'Hồ Chí Minh', N'Quận 1', 300);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000029', '725DCDFC-12B8-48F7-A427-805527F0112C', 3, N'Hội thảo: DevOps & CI/CD Mastery', 'hoi-thao-devops-ci-cd-mastery-29', N'Chia sẻ kiến thức chuyên môn từ các chuyên gia hàng đầu trong ngành công nghệ.', N'Mô tả chi tiết của sự kiện Hội thảo: DevOps & CI/CD Mastery.', '/uploads/banners/professional/the-aristocrats-the-defrost-tour-live-in-vietnam.jpg', DATEADD(day, 56, GETUTCDATE()), DATEADD(day, 56, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Tòa nhà Dreamplex Nguyễn Trung Ngạn', N'Địa chỉ chi tiết của Tòa nhà Dreamplex Nguyễn Trung Ngạn', N'Hồ Chí Minh', N'Quận 1', 300);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000030', '725DCDFC-12B8-48F7-A427-805527F0112C', 3, N'Workshop: Nghệ Thuật Giao Tiếp Đỉnh Cao', 'workshop-nghe-thuat-giao-tiep-dinh-cao-30', N'Khóa đào tạo ngắn hạn tương tác cao giúp nâng cao kỹ năng thực chiến.', N'Mô tả chi tiết của sự kiện Workshop: Nghệ Thuật Giao Tiếp Đỉnh Cao.', '/uploads/banners/professional/the-viet-margarita-festival-2026.jpg', DATEADD(day, 39, GETUTCDATE()), DATEADD(day, 39, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Trung tâm Đào tạo Kyna', N'Địa chỉ chi tiết của Trung tâm Đào tạo Kyna', N'Hồ Chí Minh', N'Quận 1', 100);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000031', '5B5CE913-3124-448A-812B-85B5A4AB1A03', 4, N'Giải chạy: Đồng Hành Vì Cộng Đồng 2026', 'giai-chay-dong-hanh-vi-cong-dong-2026-31', N'Sự kiện thể thao nâng cao sức khỏe cộng đồng và gây quỹ từ thiện.', N'Mô tả chi tiết của sự kiện Giải chạy: Đồng Hành Vì Cộng Đồng 2026.', '/uploads/banners/professional/tokyo-girls-collection-vietnam-2026-concert.jpg', DATEADD(day, 43, GETUTCDATE()), DATEADD(day, 43, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Khu đô thị Phú Mỹ Hưng', N'Địa chỉ chi tiết của Khu đô thị Phú Mỹ Hưng', N'Hồ Chí Minh', N'Quận 1', 3000);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000032', 'C7C46C00-D517-46AF-8121-7FADE6992FFA', 4, N'Giải chạy: Chạy Vì Trẻ Em Nghèo 2026', 'giai-chay-chay-vi-tre-em-ngheo-2026-32', N'Sự kiện thể thao nâng cao sức khỏe cộng đồng và gây quỹ từ thiện.', N'Mô tả chi tiết của sự kiện Giải chạy: Chạy Vì Trẻ Em Nghèo 2026.', '/uploads/banners/professional/vba-2026-saigon-heat-vs-ho-chi-minh-city-wings.jpg', DATEADD(day, 58, GETUTCDATE()), DATEADD(day, 58, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Khu đô thị Phú Mỹ Hưng', N'Địa chỉ chi tiết của Khu đô thị Phú Mỹ Hưng', N'Hồ Chí Minh', N'Quận 1', 3000);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000033', '95F1339E-2245-4449-A2B9-85C046A2D1DD', 4, N'Giải chạy: Chạy Vì Trẻ Em Nghèo 2026', 'giai-chay-chay-vi-tre-em-ngheo-2026-33', N'Sự kiện thể thao nâng cao sức khỏe cộng đồng và gây quỹ từ thiện.', N'Mô tả chi tiết của sự kiện Giải chạy: Chạy Vì Trẻ Em Nghèo 2026.', '/uploads/banners/professional/vct-pacific-stage-1-finals-ho-chi-minh.jpg', DATEADD(day, 42, GETUTCDATE()), DATEADD(day, 42, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 1, NULL, 1, 1, GETUTCDATE(), N'Khu đô thị Phú Mỹ Hưng', N'Địa chỉ chi tiết của Khu đô thị Phú Mỹ Hưng', N'Hồ Chí Minh', N'Quận 1', 3000);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000034', '1EFB3BD4-1BFD-4F1F-BD98-B17BA7B72074', 4, N'Giải chạy: Chạy Vì Trẻ Em Nghèo 2026', 'giai-chay-chay-vi-tre-em-ngheo-2026-34', N'Sự kiện thể thao nâng cao sức khỏe cộng đồng và gây quỹ từ thiện.', N'Mô tả chi tiết của sự kiện Giải chạy: Chạy Vì Trẻ Em Nghèo 2026.', '/uploads/banners/professional/vietnam-pickleball-open.jpg', DATEADD(day, 14, GETUTCDATE()), DATEADD(day, 14, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Khu đô thị Phú Mỹ Hưng', N'Địa chỉ chi tiết của Khu đô thị Phú Mỹ Hưng', N'Hồ Chí Minh', N'Quận 1', 3000);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000035', '1EFB3BD4-1BFD-4F1F-BD98-B17BA7B72074', 4, N'Giải chạy: Đồng Hành Vì Cộng Đồng 2026', 'giai-chay-dong-hanh-vi-cong-dong-2026-35', N'Sự kiện thể thao nâng cao sức khỏe cộng đồng và gây quỹ từ thiện.', N'Mô tả chi tiết của sự kiện Giải chạy: Đồng Hành Vì Cộng Đồng 2026.', '/uploads/banners/professional/vietnam-wedding-showcase.jpg', DATEADD(day, 14, GETUTCDATE()), DATEADD(day, 14, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Khu đô thị Phú Mỹ Hưng', N'Địa chỉ chi tiết của Khu đô thị Phú Mỹ Hưng', N'Hồ Chí Minh', N'Quận 1', 3000);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000036', '50075312-F374-48A9-8B2C-48F109BF34E9', 4, N'Giải chạy: Vibe Marathon Ho Chi Minh 2026', 'giai-chay-vibe-marathon-ho-chi-minh-2026-36', N'Sự kiện thể thao nâng cao sức khỏe cộng đồng và gây quỹ từ thiện.', N'Mô tả chi tiết của sự kiện Giải chạy: Vibe Marathon Ho Chi Minh 2026.', '/uploads/banners/professional/vinhverse-concert.jpg', DATEADD(day, 13, GETUTCDATE()), DATEADD(day, 13, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Khu đô thị Phú Mỹ Hưng', N'Địa chỉ chi tiết của Khu đô thị Phú Mỹ Hưng', N'Hồ Chí Minh', N'Quận 1', 3000);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000037', '3A1B89A7-7E53-4A33-ACAE-FE4A71DC7BE4', 4, N'Giải chạy: Sải Bước Khỏe Mạnh 2026', 'giai-chay-sai-buoc-khoe-manh-2026-37', N'Sự kiện thể thao nâng cao sức khỏe cộng đồng và gây quỹ từ thiện.', N'Mô tả chi tiết của sự kiện Giải chạy: Sải Bước Khỏe Mạnh 2026.', '/uploads/banners/professional/ai-va-future-business-strategy.jpg', DATEADD(day, 34, GETUTCDATE()), DATEADD(day, 34, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Khu đô thị Phú Mỹ Hưng', N'Địa chỉ chi tiết của Khu đô thị Phú Mỹ Hưng', N'Hồ Chí Minh', N'Quận 1', 3000);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000038', 'DF63CB1F-67FF-4CB5-8BA2-6C30FBF1F240', 4, N'Giải chạy: Vibe Marathon Ho Chi Minh 2026', 'giai-chay-vibe-marathon-ho-chi-minh-2026-38', N'Sự kiện thể thao nâng cao sức khỏe cộng đồng và gây quỹ từ thiện.', N'Mô tả chi tiết của sự kiện Giải chạy: Vibe Marathon Ho Chi Minh 2026.', '/uploads/banners/professional/art-jamming-va-natural-wine.jpg', DATEADD(day, 26, GETUTCDATE()), DATEADD(day, 26, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Khu đô thị Phú Mỹ Hưng', N'Địa chỉ chi tiết của Khu đô thị Phú Mỹ Hưng', N'Hồ Chí Minh', N'Quận 1', 3000);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000039', 'DF63CB1F-67FF-4CB5-8BA2-6C30FBF1F240', 4, N'Giải chạy: Sải Bước Khỏe Mạnh 2026', 'giai-chay-sai-buoc-khoe-manh-2026-39', N'Sự kiện thể thao nâng cao sức khỏe cộng đồng và gây quỹ từ thiện.', N'Mô tả chi tiết của sự kiện Giải chạy: Sải Bước Khỏe Mạnh 2026.', '/uploads/banners/professional/automotive-mobility-solutions-conference.jpg', DATEADD(day, 41, GETUTCDATE()), DATEADD(day, 41, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Khu đô thị Phú Mỹ Hưng', N'Địa chỉ chi tiết của Khu đô thị Phú Mỹ Hưng', N'Hồ Chí Minh', N'Quận 1', 3000);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000040', '5B5CE913-3124-448A-812B-85B5A4AB1A03', 4, N'Giải chạy: Chạy Vì Trẻ Em Nghèo 2026', 'giai-chay-chay-vi-tre-em-ngheo-2026-40', N'Sự kiện thể thao nâng cao sức khỏe cộng đồng và gây quỹ từ thiện.', N'Mô tả chi tiết của sự kiện Giải chạy: Chạy Vì Trẻ Em Nghèo 2026.', '/uploads/banners/professional/board-game-va-coffee-social.jpg', DATEADD(day, 28, GETUTCDATE()), DATEADD(day, 28, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Khu đô thị Phú Mỹ Hưng', N'Địa chỉ chi tiết của Khu đô thị Phú Mỹ Hưng', N'Hồ Chí Minh', N'Quận 1', 3000);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000041', 'C6D443D8-3015-4677-8BE2-D3C92C777062', 5, N'Coffee & Tea Festival', 'coffee-tea-festival-41', N'Khám phá thế giới ẩm thực phong phú cùng các chương trình biểu diễn nghệ thuật.', N'Mô tả chi tiết của sự kiện Coffee & Tea Festival.', '/uploads/banners/professional/build-better-hcmc-2026.jpg', DATEADD(day, -9, GETUTCDATE()), DATEADD(day, -9, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Công viên Tao Đàn', N'Địa chỉ chi tiết của Công viên Tao Đàn', N'Hồ Chí Minh', N'Quận 1', 10000);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000042', '5146EDFE-FC06-44CD-AAB4-C4B6BC9AD765', 5, N'Ngày Hội Ẩm Thực Đường Phố', 'ngay-hoi-am-thuc-duong-pho-42', N'Khám phá thế giới ẩm thực phong phú cùng các chương trình biểu diễn nghệ thuật.', N'Mô tả chi tiết của sự kiện Ngày Hội Ẩm Thực Đường Phố.', '/uploads/banners/professional/chao-show-am-sac-viet-nam.jpg', DATEADD(day, 31, GETUTCDATE()), DATEADD(day, 31, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Công viên Tao Đàn', N'Địa chỉ chi tiết của Công viên Tao Đàn', N'Hồ Chí Minh', N'Quận 1', 10000);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000043', '5B5CE913-3124-448A-812B-85B5A4AB1A03', 5, N'Coffee & Tea Festival', 'coffee-tea-festival-43', N'Khám phá thế giới ẩm thực phong phú cùng các chương trình biểu diễn nghệ thuật.', N'Mô tả chi tiết của sự kiện Coffee & Tea Festival.', '/uploads/banners/professional/chef-s-table-modern-vietnamese-dinner.jpg', DATEADD(day, 7, GETUTCDATE()), DATEADD(day, 7, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Công viên Tao Đàn', N'Địa chỉ chi tiết của Công viên Tao Đàn', N'Hồ Chí Minh', N'Quận 1', 10000);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000044', '95F1339E-2245-4449-A2B9-85C046A2D1DD', 5, N'Lễ Hội Bánh Xèo Nam Bộ', 'le-hoi-banh-xeo-nam-bo-44', N'Khám phá thế giới ẩm thực phong phú cùng các chương trình biểu diễn nghệ thuật.', N'Mô tả chi tiết của sự kiện Lễ Hội Bánh Xèo Nam Bộ.', '/uploads/banners/professional/city-yoga-va-wellness-day.jpg', DATEADD(day, 33, GETUTCDATE()), DATEADD(day, 33, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Công viên Tao Đàn', N'Địa chỉ chi tiết của Công viên Tao Đàn', N'Hồ Chí Minh', N'Quận 1', 10000);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000045', '1EFB3BD4-1BFD-4F1F-BD98-B17BA7B72074', 5, N'Coffee & Tea Festival', 'coffee-tea-festival-45', N'Khám phá thế giới ẩm thực phong phú cùng các chương trình biểu diễn nghệ thuật.', N'Mô tả chi tiết của sự kiện Coffee & Tea Festival.', '/uploads/banners/professional/cu-chi-tunnels-history-tour.jpg', DATEADD(day, 7, GETUTCDATE()), DATEADD(day, 7, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Công viên Tao Đàn', N'Địa chỉ chi tiết của Công viên Tao Đàn', N'Hồ Chí Minh', N'Quận 1', 10000);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000046', '5146EDFE-FC06-44CD-AAB4-C4B6BC9AD765', 5, N'Lễ Hội Bia Thủ Công', 'le-hoi-bia-thu-cong-46', N'Khám phá thế giới ẩm thực phong phú cùng các chương trình biểu diễn nghệ thuật.', N'Mô tả chi tiết của sự kiện Lễ Hội Bia Thủ Công.', '/uploads/banners/professional/dalat-coffee-farm-experience.jpg', DATEADD(minute, 60, GETUTCDATE()), DATEADD(hour, 4, GETUTCDATE()), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Công viên Tao Đàn', N'Địa chỉ chi tiết của Công viên Tao Đàn', N'Hồ Chí Minh', N'Quận 1', 10000);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000047', 'C6D443D8-3015-4677-8BE2-D3C92C777062', 5, N'Hương Vị Việt Nam', 'huong-vi-viet-nam-47', N'Khám phá thế giới ẩm thực phong phú cùng các chương trình biểu diễn nghệ thuật.', N'Mô tả chi tiết của sự kiện Hương Vị Việt Nam.', '/uploads/banners/professional/de-garden-kokedama-workshop.jpg', DATEADD(day, 28, GETUTCDATE()), DATEADD(day, 28, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Công viên Tao Đàn', N'Địa chỉ chi tiết của Công viên Tao Đàn', N'Hồ Chí Minh', N'Quận 1', 10000);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000048', '3A1B89A7-7E53-4A33-ACAE-FE4A71DC7BE4', 5, N'Hương Vị Việt Nam', 'huong-vi-viet-nam-48', N'Khám phá thế giới ẩm thực phong phú cùng các chương trình biểu diễn nghệ thuật.', N'Mô tả chi tiết của sự kiện Hương Vị Việt Nam.', '/uploads/banners/professional/family-science-day.jpg', DATEADD(day, 28, GETUTCDATE()), DATEADD(day, 28, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Công viên Tao Đàn', N'Địa chỉ chi tiết của Công viên Tao Đàn', N'Hồ Chí Minh', N'Quận 1', 10000);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000049', '725DCDFC-12B8-48F7-A427-805527F0112C', 5, N'Lễ Hội Bánh Xèo Nam Bộ', 'le-hoi-banh-xeo-nam-bo-49', N'Khám phá thế giới ẩm thực phong phú cùng các chương trình biểu diễn nghệ thuật.', N'Mô tả chi tiết của sự kiện Lễ Hội Bánh Xèo Nam Bộ.', '/uploads/banners/professional/gama-music-racing-festival.jpg', DATEADD(day, -10, GETUTCDATE()), DATEADD(day, -10, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Công viên Tao Đàn', N'Địa chỉ chi tiết của Công viên Tao Đàn', N'Hồ Chí Minh', N'Quận 1', 10000);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000050', '5146EDFE-FC06-44CD-AAB4-C4B6BC9AD765', 5, N'Lễ Hội Bánh Xèo Nam Bộ', 'le-hoi-banh-xeo-nam-bo-50', N'Khám phá thế giới ẩm thực phong phú cùng các chương trình biểu diễn nghệ thuật.', N'Mô tả chi tiết của sự kiện Lễ Hội Bánh Xèo Nam Bộ.', '/uploads/banners/professional/gitex-vietnam-2026.jpg', DATEADD(day, 51, GETUTCDATE()), DATEADD(day, 51, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Công viên Tao Đàn', N'Địa chỉ chi tiết của Công viên Tao Đàn', N'Hồ Chí Minh', N'Quận 1', 10000);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000051', '3A1B89A7-7E53-4A33-ACAE-FE4A71DC7BE4', 6, N'Hội chợ Triển lãm Thương mại 2027', 'hoi-cho-trien-lam-thuong-mai-2027-51', N'Cơ hội giao thương, kết nối doanh nghiệp và trải nghiệm các sản phẩm dịch vụ mới.', N'Mô tả chi tiết của sự kiện Hội chợ Triển lãm Thương mại 2027.', '/uploads/banners/professional/hanoi-climbing-cup.jpg', DATEADD(day, -6, GETUTCDATE()), DATEADD(day, -6, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Trung tâm Triển lãm SECC', N'Địa chỉ chi tiết của Trung tâm Triển lãm SECC', N'Hồ Chí Minh', N'Quận 1', 5000);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000052', 'C6D443D8-3015-4677-8BE2-D3C92C777062', 6, N'Hội chợ Triển lãm Thương mại 2026', 'hoi-cho-trien-lam-thuong-mai-2026-52', N'Cơ hội giao thương, kết nối doanh nghiệp và trải nghiệm các sản phẩm dịch vụ mới.', N'Mô tả chi tiết của sự kiện Hội chợ Triển lãm Thương mại 2026.', '/uploads/banners/professional/ho-tram-beach-triathlon.jpg', DATEADD(day, -5, GETUTCDATE()), DATEADD(day, -5, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Trung tâm Triển lãm SECC', N'Địa chỉ chi tiết của Trung tâm Triển lãm SECC', N'Hồ Chí Minh', N'Quận 1', 5000);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000053', '5146EDFE-FC06-44CD-AAB4-C4B6BC9AD765', 6, N'Hội chợ Triển lãm Thương mại 2026', 'hoi-cho-trien-lam-thuong-mai-2026-53', N'Cơ hội giao thương, kết nối doanh nghiệp và trải nghiệm các sản phẩm dịch vụ mới.', N'Mô tả chi tiết của sự kiện Hội chợ Triển lãm Thương mại 2026.', '/uploads/banners/professional/hon-viet-dan-nhac-duong-dai.jpg', DATEADD(day, 28, GETUTCDATE()), DATEADD(day, 28, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Trung tâm Triển lãm SECC', N'Địa chỉ chi tiết của Trung tâm Triển lãm SECC', N'Hồ Chí Minh', N'Quận 1', 5000);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000054', '725DCDFC-12B8-48F7-A427-805527F0112C', 6, N'Hội chợ Triển lãm Thương mại 2027', 'hoi-cho-trien-lam-thuong-mai-2027-54', N'Cơ hội giao thương, kết nối doanh nghiệp và trải nghiệm các sản phẩm dịch vụ mới.', N'Mô tả chi tiết của sự kiện Hội chợ Triển lãm Thương mại 2027.', '/uploads/banners/professional/indie-film-weekend.jpg', DATEADD(minute, 60, GETUTCDATE()), DATEADD(hour, 4, GETUTCDATE()), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Trung tâm Triển lãm SECC', N'Địa chỉ chi tiết của Trung tâm Triển lãm SECC', N'Hồ Chí Minh', N'Quận 1', 5000);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000055', '95F1339E-2245-4449-A2B9-85C046A2D1DD', 6, N'Hội chợ Triển lãm Thương mại 2027', 'hoi-cho-trien-lam-thuong-mai-2027-55', N'Cơ hội giao thương, kết nối doanh nghiệp và trải nghiệm các sản phẩm dịch vụ mới.', N'Mô tả chi tiết của sự kiện Hội chợ Triển lãm Thương mại 2027.', '/uploads/banners/professional/k-pulse-hanoi-2026.jpg', DATEADD(day, 13, GETUTCDATE()), DATEADD(day, 13, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Trung tâm Triển lãm SECC', N'Địa chỉ chi tiết của Trung tâm Triển lãm SECC', N'Hồ Chí Minh', N'Quận 1', 5000);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000056', 'DF63CB1F-67FF-4CB5-8BA2-6C30FBF1F240', 6, N'Hội chợ Triển lãm Thương mại 2027', 'hoi-cho-trien-lam-thuong-mai-2027-56', N'Cơ hội giao thương, kết nối doanh nghiệp và trải nghiệm các sản phẩm dịch vụ mới.', N'Mô tả chi tiết của sự kiện Hội chợ Triển lãm Thương mại 2027.', '/uploads/banners/professional/lion-championship-33.jpg', DATEADD(day, 6, GETUTCDATE()), DATEADD(day, 6, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Trung tâm Triển lãm SECC', N'Địa chỉ chi tiết của Trung tâm Triển lãm SECC', N'Hồ Chí Minh', N'Quận 1', 5000);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000057', 'C6D443D8-3015-4677-8BE2-D3C92C777062', 6, N'Hội chợ Triển lãm Thương mại 2027', 'hoi-cho-trien-lam-thuong-mai-2027-57', N'Cơ hội giao thương, kết nối doanh nghiệp và trải nghiệm các sản phẩm dịch vụ mới.', N'Mô tả chi tiết của sự kiện Hội chợ Triển lãm Thương mại 2027.', '/uploads/banners/professional/may-saigon-livestage-trung-quan-va-siu-black.jpg', DATEADD(day, 12, GETUTCDATE()), DATEADD(day, 12, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Trung tâm Triển lãm SECC', N'Địa chỉ chi tiết của Trung tâm Triển lãm SECC', N'Hồ Chí Minh', N'Quận 1', 5000);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000058', '3A1B89A7-7E53-4A33-ACAE-FE4A71DC7BE4', 6, N'Hội chợ Triển lãm Thương mại 2027', 'hoi-cho-trien-lam-thuong-mai-2027-58', N'Cơ hội giao thương, kết nối doanh nghiệp và trải nghiệm các sản phẩm dịch vụ mới.', N'Mô tả chi tiết của sự kiện Hội chợ Triển lãm Thương mại 2027.', '/uploads/banners/professional/metashow-cham-vao-anh-sang.jpg', DATEADD(day, 4, GETUTCDATE()), DATEADD(day, 4, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Trung tâm Triển lãm SECC', N'Địa chỉ chi tiết của Trung tâm Triển lãm SECC', N'Hồ Chí Minh', N'Quận 1', 5000);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000059', 'C6D443D8-3015-4677-8BE2-D3C92C777062', 6, N'Hội chợ Triển lãm Thương mại 2027', 'hoi-cho-trien-lam-thuong-mai-2027-59', N'Cơ hội giao thương, kết nối doanh nghiệp và trải nghiệm các sản phẩm dịch vụ mới.', N'Mô tả chi tiết của sự kiện Hội chợ Triển lãm Thương mại 2027.', '/uploads/banners/professional/power-bi-from-data-to-insights.jpg', DATEADD(day, 36, GETUTCDATE()), DATEADD(day, 36, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Trung tâm Triển lãm SECC', N'Địa chỉ chi tiết của Trung tâm Triển lãm SECC', N'Hồ Chí Minh', N'Quận 1', 5000);

    INSERT INTO [dbo].[SuKien] ([Id], [NguoiToChucId], [DanhMucId], [TenSuKien], [Slug], [MoTaNgan], [MoTaChiTiet], [AnhBia], [NgayBatDau], [NgayKetThuc], [LoaiSuKien], [LinkOnline], [CoSoDoChoNgoi], [TrangThai], [LyDoTuChoi], [NoiBat], [HienThiCongKhai], [NgayTao], [TenDiaDiem], [DiaChiDiaDiem], [ThanhPhoDiaDiem], [QuanHuyenDiaDiem], [SucChuaDiaDiem])
    VALUES ('E0000000-0000-0000-0000-000000000060', '3A1B89A7-7E53-4A33-ACAE-FE4A71DC7BE4', 6, N'Hội chợ Triển lãm Thương mại 2027', 'hoi-cho-trien-lam-thuong-mai-2027-60', N'Cơ hội giao thương, kết nối doanh nghiệp và trải nghiệm các sản phẩm dịch vụ mới.', N'Mô tả chi tiết của sự kiện Hội chợ Triển lãm Thương mại 2027.', '/uploads/banners/professional/saigon-midnight-run-2026.jpg', DATEADD(day, 2, GETUTCDATE()), DATEADD(day, 2, DATEADD(hour, 4, GETUTCDATE())), 0, NULL, 0, 3, NULL, 1, 1, GETUTCDATE(), N'Trung tâm Triển lãm SECC', N'Địa chỉ chi tiết của Trung tâm Triển lãm SECC', N'Hồ Chí Minh', N'Quận 1', 5000);


    -- =============================================
    -- SEED DATA: LoaiVe (Mapped for all 60 events)
    -- =============================================

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('D3C3FBCE-4FFF-4F33-A4AF-0A2750C9E94E', N'Vé VIP', N'Khu vực hàng ghế đầu tiên VIP A, nước uống miễn phí.', 500000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 3, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('D3C3FBCE-4FFF-4F33-A4AF-0A2750C9E94E', N'Vé Thường', N'Khu vực khán đài B, góc quan sát tốt.', 150000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 3, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E20875EC-36DB-45EB-85D1-A706DC9B62D2', N'Vé VIP', N'Hàng ghế sát sân khấu, tặng CD của ca sĩ.', 600000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 6, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E20875EC-36DB-45EB-85D1-A706DC9B62D2', N'Vé Thường', N'Ghế ngồi tiêu chuẩn, tầm nhìn bao quát.', 200000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 6, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('D2C252F2-7FD4-4A02-86CB-3D9DE7415795', N'Vé VIP', N'Vé khu vực đứng Fanzone sát sân khấu nhất.', 700000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 9, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('D2C252F2-7FD4-4A02-86CB-3D9DE7415795', N'Vé Thường', N'Vé khu vực đứng Standard sau Fanzone.', 250000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 9, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('5BC842AD-6166-406A-AD93-EB3ECACFBF7E', N'Vé VIP', N'Khu vực thảm cỏ VIP, tặng đồ uống và quà kỷ niệm.', 800000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 12, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('5BC842AD-6166-406A-AD93-EB3ECACFBF7E', N'Vé Thường', N'Khu vực thảm cỏ chung Standard.', 300000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 12, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('9B265F0B-613C-4094-9DC8-4B74E1F42E65', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 1200000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('9B265F0B-613C-4094-9DC8-4B74E1F42E65', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 150000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('A0A26D2F-FF2E-4175-B318-C3FCE0BA23FB', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 500000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('A0A26D2F-FF2E-4175-B318-C3FCE0BA23FB', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 300000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000007', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 800000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000007', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 250000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000008', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 600000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000008', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 250000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000009', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 1200000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000009', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 150000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000010', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 800000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000010', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 150000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000011', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 600000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000011', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 300000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000012', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 500000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000012', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 250000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000013', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 1200000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000013', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 100000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000014', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 600000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000014', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 300000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000015', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 1200000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000015', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 150000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000016', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 800000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000016', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 300000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000017', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 800000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000017', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 200000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000018', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 500000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000018', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 200000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000019', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 500000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000019', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 100000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000020', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 1000000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000020', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 200000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000021', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 500000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000021', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 150000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000022', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 1000000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000022', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 250000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000023', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 1200000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000023', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 150000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000024', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 1000000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000024', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 250000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000025', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 600000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000025', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 150000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000026', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 500000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000026', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 150000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000027', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 600000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000027', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 100000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000028', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 600000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000028', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 100000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000029', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 800000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000029', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 300000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000030', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 1200000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000030', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 100000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000031', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 500000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000031', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 300000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000032', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 500000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000032', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 300000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000033', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 800000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000033', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 200000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000034', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 600000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000034', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 250000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000035', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 1200000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000035', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 200000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000036', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 600000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000036', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 300000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000037', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 600000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000037', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 150000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000038', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 800000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000038', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 250000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000039', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 1000000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000039', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 250000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000040', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 500000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000040', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 200000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000041', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 1000000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000041', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 150000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000042', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 1000000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000042', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 100000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000043', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 1200000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000043', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 200000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000044', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 1200000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000044', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 150000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000045', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 1200000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000045', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 150000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000046', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 500000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000046', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 300000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000047', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 600000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000047', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 300000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000048', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 1200000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000048', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 300000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000049', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 500000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000049', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 250000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000050', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 500000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000050', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 200000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000051', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 800000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000051', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 250000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000052', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 800000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000052', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 150000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000053', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 1000000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000053', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 150000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000054', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 500000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000054', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 200000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000055', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 800000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000055', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 300000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000056', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 1200000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000056', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 250000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000057', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 600000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000057', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 300000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000058', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 1000000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000058', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 150000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000059', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 1200000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000059', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 100000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);

    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000060', N'Vé VIP', N'Gói VIP cao cấp với nhiều đặc quyền hấp dẫn.', 1200000, 50, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#FFD700', 1);
    INSERT INTO [dbo].[LoaiVe] ([SuKienId], [TenLoaiVe], [MoTa], [GiaBan], [SoLuongTong], [SoLuongDaBan], [SoLuongGiuCho], [GioiHanMoiDon], [NgayBatDauBan], [NgayKetThucBan], [ThuTuHienThi], [MauSac], [TrangThai])
    VALUES ('E0000000-0000-0000-0000-000000000060', N'Vé Thường', N'Vé phổ thông tiêu chuẩn tham gia sự kiện.', 250000, 200, 0, 0, 10, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, '#1E90FF', 1);


    -- =============================================
    -- SEED DATA: SoDoChoNgoi / KhuVuc / HangGhe / ChoNgoi for Event 1
    -- =============================================
    INSERT INTO [dbo].[SoDoChoNgoi] ([SuKienId], [TenSoDo], [LoaiSoDo], [NgayTao])
    VALUES ('D3C3FBCE-4FFF-4F33-A4AF-0A2750C9E94E', N'Sơ đồ khán đài Sân vận động Phú Thọ', N'arena', GETUTCDATE());
 
    INSERT INTO [dbo].[KhuVuc] ([SoDoChoNgoiId], [LoaiVeId], [TenKhuVuc], [MauSac], [ViTriX], [ViTriY], [ThuTu])
    VALUES (1, 1, N'Khu VIP A', '#FFD700', 10, 10, 0);
 
    INSERT INTO [dbo].[KhuVuc] ([SoDoChoNgoiId], [LoaiVeId], [TenKhuVuc], [MauSac], [ViTriX], [ViTriY], [ThuTu])
    VALUES (1, 2, N'Khu Thường B', '#1E90FF', 10, 60, 1);
 
    INSERT INTO [dbo].[HangGhe] ([KhuVucId], [TenHang], [SoGhe], [ThuTu])
    VALUES (1, N'A', 5, 0);
    INSERT INTO [dbo].[HangGhe] ([KhuVucId], [TenHang], [SoGhe], [ThuTu])
    VALUES (1, N'B', 5, 1);
 
    INSERT INTO [dbo].[HangGhe] ([KhuVucId], [TenHang], [SoGhe], [ThuTu])
    VALUES (2, N'C', 5, 0);
 
    -- ChoNgoi for Event 1 (A1, A2: TrangThai = 2 [DaBan], A3: TrangThai = 1 [GiuCho])
    INSERT INTO [dbo].[ChoNgoi] ([HangGheId], [SoGhe], [ViTriX], [ViTriY], [TrangThai]) VALUES (1, N'A1', 20, 20, 2);
    INSERT INTO [dbo].[ChoNgoi] ([HangGheId], [SoGhe], [ViTriX], [ViTriY], [TrangThai]) VALUES (1, N'A2', 40, 20, 2);
    INSERT INTO [dbo].[ChoNgoi] ([HangGheId], [SoGhe], [ViTriX], [ViTriY], [TrangThai]) VALUES (1, N'A3', 60, 20, 1);
    INSERT INTO [dbo].[ChoNgoi] ([HangGheId], [SoGhe], [ViTriX], [ViTriY], [TrangThai]) VALUES (1, N'A4', 80, 20, 0);
    INSERT INTO [dbo].[ChoNgoi] ([HangGheId], [SoGhe], [ViTriX], [ViTriY], [TrangThai]) VALUES (1, N'A5', 100, 20, 0);
 
    INSERT INTO [dbo].[ChoNgoi] ([HangGheId], [SoGhe], [ViTriX], [ViTriY], [TrangThai]) VALUES (2, N'B1', 20, 40, 0);
    INSERT INTO [dbo].[ChoNgoi] ([HangGheId], [SoGhe], [ViTriX], [ViTriY], [TrangThai]) VALUES (2, N'B2', 40, 40, 0);
    INSERT INTO [dbo].[ChoNgoi] ([HangGheId], [SoGhe], [ViTriX], [ViTriY], [TrangThai]) VALUES (2, N'B3', 60, 40, 0);
    INSERT INTO [dbo].[ChoNgoi] ([HangGheId], [SoGhe], [ViTriX], [ViTriY], [TrangThai]) VALUES (2, N'B4', 80, 40, 0);
    INSERT INTO [dbo].[ChoNgoi] ([HangGheId], [SoGhe], [ViTriX], [ViTriY], [TrangThai]) VALUES (2, N'B5', 100, 40, 0);
 
    INSERT INTO [dbo].[ChoNgoi] ([HangGheId], [SoGhe], [ViTriX], [ViTriY], [TrangThai]) VALUES (3, N'C1', 20, 80, 0);
    INSERT INTO [dbo].[ChoNgoi] ([HangGheId], [SoGhe], [ViTriX], [ViTriY], [TrangThai]) VALUES (3, N'C2', 40, 80, 0);
    INSERT INTO [dbo].[ChoNgoi] ([HangGheId], [SoGhe], [ViTriX], [ViTriY], [TrangThai]) VALUES (3, N'C3', 60, 80, 0);
    INSERT INTO [dbo].[ChoNgoi] ([HangGheId], [SoGhe], [ViTriX], [ViTriY], [TrangThai]) VALUES (3, N'C4', 80, 80, 0);
    INSERT INTO [dbo].[ChoNgoi] ([HangGheId], [SoGhe], [ViTriX], [ViTriY], [TrangThai]) VALUES (3, N'C5', 100, 80, 0);


    -- =============================================
    -- SEED DATA: NhanVienSuKien
    -- =============================================

    INSERT INTO [dbo].[NhanVienSuKien] ([NguoiDungId], [SuKienId], [VaiTroNV], [NgayThem]) VALUES ('55F02A90-5841-4563-A735-C12B9717BB96', 'D3C3FBCE-4FFF-4F33-A4AF-0A2750C9E94E', N'CheckIn', GETUTCDATE());

    INSERT INTO [dbo].[NhanVienSuKien] ([NguoiDungId], [SuKienId], [VaiTroNV], [NgayThem]) VALUES ('308F7B86-4503-4DB4-87F1-A66A56C7A3BF', 'E20875EC-36DB-45EB-85D1-A706DC9B62D2', N'CheckIn', GETUTCDATE());

    INSERT INTO [dbo].[NhanVienSuKien] ([NguoiDungId], [SuKienId], [VaiTroNV], [NgayThem]) VALUES ('73E06548-F2B9-4768-837D-1A942636A27F', 'D2C252F2-7FD4-4A02-86CB-3D9DE7415795', N'CheckIn', GETUTCDATE());

    INSERT INTO [dbo].[NhanVienSuKien] ([NguoiDungId], [SuKienId], [VaiTroNV], [NgayThem]) VALUES ('706BEA74-E775-460F-8E3B-74BBFA81A5CF', '5BC842AD-6166-406A-AD93-EB3ECACFBF7E', N'CheckIn', GETUTCDATE());

    INSERT INTO [dbo].[NhanVienSuKien] ([NguoiDungId], [SuKienId], [VaiTroNV], [NgayThem]) VALUES ('5EA93981-1208-4862-AE9C-7E14FEFB596B', '9B265F0B-613C-4094-9DC8-4B74E1F42E65', N'CheckIn', GETUTCDATE());

    INSERT INTO [dbo].[NhanVienSuKien] ([NguoiDungId], [SuKienId], [VaiTroNV], [NgayThem]) VALUES ('FC115C36-482E-4648-A580-A4AF9E50D33D', 'A0A26D2F-FF2E-4175-B318-C3FCE0BA23FB', N'CheckIn', GETUTCDATE());

    INSERT INTO [dbo].[NhanVienSuKien] ([NguoiDungId], [SuKienId], [VaiTroNV], [NgayThem]) VALUES ('817AC6A9-9F7E-40F3-A119-D4D31FD01C74', 'E0000000-0000-0000-0000-000000000007', N'CheckIn', GETUTCDATE());

    INSERT INTO [dbo].[NhanVienSuKien] ([NguoiDungId], [SuKienId], [VaiTroNV], [NgayThem]) VALUES ('71D84E61-3BC1-4270-8E01-5738E4D673FF', 'E0000000-0000-0000-0000-000000000008', N'CheckIn', GETUTCDATE());

    INSERT INTO [dbo].[NhanVienSuKien] ([NguoiDungId], [SuKienId], [VaiTroNV], [NgayThem]) VALUES ('16DE5824-396A-49AB-9D33-6850ADA72500', 'E0000000-0000-0000-0000-000000000009', N'CheckIn', GETUTCDATE());

    INSERT INTO [dbo].[NhanVienSuKien] ([NguoiDungId], [SuKienId], [VaiTroNV], [NgayThem]) VALUES ('59443B1B-7793-40DE-B0E2-11ACD1C16FDF', 'E0000000-0000-0000-0000-000000000010', N'CheckIn', GETUTCDATE());

    INSERT INTO [dbo].[NhanVienSuKien] ([NguoiDungId], [SuKienId], [VaiTroNV], [NgayThem]) VALUES ('55F02A90-5841-4563-A735-C12B9717BB96', 'E20875EC-36DB-45EB-85D1-A706DC9B62D2', N'CheckIn', GETUTCDATE());


    -- =============================================
    -- SEED DATA: MaGiamGia (for various events)
    -- =============================================

    -- Event 1 discount codes
    INSERT INTO [dbo].[MaGiamGia] ([SuKienId], [MaCode], [MoTa], [LoaiGiamGia], [GiaTri], [GiamToiDa], [DonToiThieu], [SoLuongTong], [SoLuongDaDung], [NgayBatDau], [NgayKetThuc], [TrangThai], [NgayTao])
    VALUES ('D3C3FBCE-4FFF-4F33-A4AF-0A2750C9E94E', 'WUANG50', N'Mã giảm giá 50% đặc biệt cho sự kiện liveshow đầu tiên.', 0, 50.00, 100000, 100000, 100, 0, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, GETUTCDATE());
    INSERT INTO [dbo].[MaGiamGia] ([SuKienId], [MaCode], [MoTa], [LoaiGiamGia], [GiaTri], [GiamToiDa], [DonToiThieu], [SoLuongTong], [SoLuongDaDung], [NgayBatDau], [NgayKetThuc], [TrangThai], [NgayTao])
    VALUES ('D3C3FBCE-4FFF-4F33-A4AF-0A2750C9E94E', 'EXPIRED50', N'Mã đã hết hạn sử dụng', 0, 50.00, 100000, 100000, 100, 0, DATEADD(day, -30, GETUTCDATE()), DATEADD(day, -5, GETUTCDATE()), 1, GETUTCDATE());
    INSERT INTO [dbo].[MaGiamGia] ([SuKienId], [MaCode], [MoTa], [LoaiGiamGia], [GiaTri], [GiamToiDa], [DonToiThieu], [SoLuongTong], [SoLuongDaDung], [NgayBatDau], [NgayKetThuc], [TrangThai], [NgayTao])
    VALUES ('D3C3FBCE-4FFF-4F33-A4AF-0A2750C9E94E', 'OUTOFSTOCK', N'Mã đã dùng hết lượt cho phép', 0, 50.00, 100000, 100000, 5, 5, DATEADD(day, -5, GETUTCDATE()), DATEADD(day, 30, GETUTCDATE()), 1, GETUTCDATE());
    INSERT INTO [dbo].[MaGiamGia] ([SuKienId], [MaCode], [MoTa], [LoaiGiamGia], [GiaTri], [GiamToiDa], [DonToiThieu], [SoLuongTong], [SoLuongDaDung], [NgayBatDau], [NgayKetThuc], [TrangThai], [NgayTao])
    VALUES ('D3C3FBCE-4FFF-4F33-A4AF-0A2750C9E94E', 'INACTIVE', N'Mã chưa kích hoạt sử dụng', 0, 50.00, 100000, 100000, 100, 0, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, GETUTCDATE());

    INSERT INTO [dbo].[MaGiamGia] ([SuKienId], [MaCode], [MoTa], [LoaiGiamGia], [GiaTri], [GiamToiDa], [DonToiThieu], [SoLuongTong], [SoLuongDaDung], [NgayBatDau], [NgayKetThuc], [TrangThai], [NgayTao])
    VALUES ('E20875EC-36DB-45EB-85D1-A706DC9B62D2', 'PROMO01', N'Mã giảm giá 5% sự kiện.', 0, 5.0, 50000, 50000, 100, 0, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, GETUTCDATE());

    INSERT INTO [dbo].[MaGiamGia] ([SuKienId], [MaCode], [MoTa], [LoaiGiamGia], [GiaTri], [GiamToiDa], [DonToiThieu], [SoLuongTong], [SoLuongDaDung], [NgayBatDau], [NgayKetThuc], [TrangThai], [NgayTao])
    VALUES ('D2C252F2-7FD4-4A02-86CB-3D9DE7415795', 'PROMO02', N'Mã giảm giá 10% sự kiện.', 0, 10.0, 50000, 50000, 100, 0, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, GETUTCDATE());

    INSERT INTO [dbo].[MaGiamGia] ([SuKienId], [MaCode], [MoTa], [LoaiGiamGia], [GiaTri], [GiamToiDa], [DonToiThieu], [SoLuongTong], [SoLuongDaDung], [NgayBatDau], [NgayKetThuc], [TrangThai], [NgayTao])
    VALUES ('5BC842AD-6166-406A-AD93-EB3ECACFBF7E', 'PROMO03', N'Mã giảm giá 15% sự kiện.', 0, 15.0, 50000, 50000, 100, 0, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, GETUTCDATE());

    INSERT INTO [dbo].[MaGiamGia] ([SuKienId], [MaCode], [MoTa], [LoaiGiamGia], [GiaTri], [GiamToiDa], [DonToiThieu], [SoLuongTong], [SoLuongDaDung], [NgayBatDau], [NgayKetThuc], [TrangThai], [NgayTao])
    VALUES ('9B265F0B-613C-4094-9DC8-4B74E1F42E65', 'PROMO04', N'Mã giảm giá 20% sự kiện.', 0, 20.0, 50000, 50000, 100, 0, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, GETUTCDATE());

    INSERT INTO [dbo].[MaGiamGia] ([SuKienId], [MaCode], [MoTa], [LoaiGiamGia], [GiaTri], [GiamToiDa], [DonToiThieu], [SoLuongTong], [SoLuongDaDung], [NgayBatDau], [NgayKetThuc], [TrangThai], [NgayTao])
    VALUES ('A0A26D2F-FF2E-4175-B318-C3FCE0BA23FB', 'PROMO05', N'Mã giảm giá 25% sự kiện.', 0, 25.0, 50000, 50000, 100, 0, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, GETUTCDATE());

    INSERT INTO [dbo].[MaGiamGia] ([SuKienId], [MaCode], [MoTa], [LoaiGiamGia], [GiaTri], [GiamToiDa], [DonToiThieu], [SoLuongTong], [SoLuongDaDung], [NgayBatDau], [NgayKetThuc], [TrangThai], [NgayTao])
    VALUES ('E0000000-0000-0000-0000-000000000007', 'PROMO06', N'Mã giảm giá 30% sự kiện.', 0, 30.0, 50000, 50000, 100, 0, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, GETUTCDATE());

    INSERT INTO [dbo].[MaGiamGia] ([SuKienId], [MaCode], [MoTa], [LoaiGiamGia], [GiaTri], [GiamToiDa], [DonToiThieu], [SoLuongTong], [SoLuongDaDung], [NgayBatDau], [NgayKetThuc], [TrangThai], [NgayTao])
    VALUES ('E0000000-0000-0000-0000-000000000008', 'PROMO07', N'Mã giảm giá 35% sự kiện.', 0, 35.0, 50000, 50000, 100, 0, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, GETUTCDATE());

    INSERT INTO [dbo].[MaGiamGia] ([SuKienId], [MaCode], [MoTa], [LoaiGiamGia], [GiaTri], [GiamToiDa], [DonToiThieu], [SoLuongTong], [SoLuongDaDung], [NgayBatDau], [NgayKetThuc], [TrangThai], [NgayTao])
    VALUES ('E0000000-0000-0000-0000-000000000009', 'PROMO08', N'Mã giảm giá 40% sự kiện.', 0, 40.0, 50000, 50000, 100, 0, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, GETUTCDATE());

    INSERT INTO [dbo].[MaGiamGia] ([SuKienId], [MaCode], [MoTa], [LoaiGiamGia], [GiaTri], [GiamToiDa], [DonToiThieu], [SoLuongTong], [SoLuongDaDung], [NgayBatDau], [NgayKetThuc], [TrangThai], [NgayTao])
    VALUES ('E0000000-0000-0000-0000-000000000010', 'PROMO09', N'Mã giảm giá 45% sự kiện.', 0, 45.0, 50000, 50000, 100, 0, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, GETUTCDATE());

    INSERT INTO [dbo].[MaGiamGia] ([SuKienId], [MaCode], [MoTa], [LoaiGiamGia], [GiaTri], [GiamToiDa], [DonToiThieu], [SoLuongTong], [SoLuongDaDung], [NgayBatDau], [NgayKetThuc], [TrangThai], [NgayTao])
    VALUES ('E0000000-0000-0000-0000-000000000011', 'PROMO10', N'Mã giảm giá 50% sự kiện.', 0, 50.0, 50000, 50000, 100, 0, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, GETUTCDATE());

    INSERT INTO [dbo].[MaGiamGia] ([SuKienId], [MaCode], [MoTa], [LoaiGiamGia], [GiaTri], [GiamToiDa], [DonToiThieu], [SoLuongTong], [SoLuongDaDung], [NgayBatDau], [NgayKetThuc], [TrangThai], [NgayTao])
    VALUES ('E0000000-0000-0000-0000-000000000012', 'PROMO11', N'Mã giảm giá 55% sự kiện.', 0, 55.0, 50000, 50000, 100, 0, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, GETUTCDATE());

    INSERT INTO [dbo].[MaGiamGia] ([SuKienId], [MaCode], [MoTa], [LoaiGiamGia], [GiaTri], [GiamToiDa], [DonToiThieu], [SoLuongTong], [SoLuongDaDung], [NgayBatDau], [NgayKetThuc], [TrangThai], [NgayTao])
    VALUES ('E0000000-0000-0000-0000-000000000013', 'PROMO12', N'Mã giảm giá 60% sự kiện.', 0, 60.0, 50000, 50000, 100, 0, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, GETUTCDATE());

    INSERT INTO [dbo].[MaGiamGia] ([SuKienId], [MaCode], [MoTa], [LoaiGiamGia], [GiaTri], [GiamToiDa], [DonToiThieu], [SoLuongTong], [SoLuongDaDung], [NgayBatDau], [NgayKetThuc], [TrangThai], [NgayTao])
    VALUES ('E0000000-0000-0000-0000-000000000014', 'PROMO13', N'Mã giảm giá 65% sự kiện.', 0, 65.0, 50000, 50000, 100, 0, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, GETUTCDATE());

    INSERT INTO [dbo].[MaGiamGia] ([SuKienId], [MaCode], [MoTa], [LoaiGiamGia], [GiaTri], [GiamToiDa], [DonToiThieu], [SoLuongTong], [SoLuongDaDung], [NgayBatDau], [NgayKetThuc], [TrangThai], [NgayTao])
    VALUES ('E0000000-0000-0000-0000-000000000015', 'PROMO14', N'Mã giảm giá 70% sự kiện.', 0, 70.0, 50000, 50000, 100, 0, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 1, GETUTCDATE());


    -- =============================================
    -- ADJUST EVENT STATES & TIMES FOR DEMO SCENARIOS
    -- =============================================

    -- Event 2 (Jazz): Đang diễn ra, bắt đầu sau 30 phút nữa (check-in Smart Default đang mở)
    UPDATE [dbo].[SuKien] 
    SET NgayBatDau = DATEADD(minute, 30, GETUTCDATE()), 
        NgayKetThuc = DATEADD(hour, 3, GETUTCDATE()),
        BatDauCheckIn = NULL, 
        KetThucCheckIn = NULL
    WHERE Id = 'E20875EC-36DB-45EB-85D1-A706DC9B62D2';

    -- Event 3 (Rock): Chưa đến giờ check-in (check-in mở vào ngày mai)
    UPDATE [dbo].[SuKien] 
    SET NgayBatDau = DATEADD(day, 1, GETUTCDATE()), 
        NgayKetThuc = DATEADD(day, 1, DATEADD(hour, 3, GETUTCDATE())),
        BatDauCheckIn = DATEADD(hour, 20, GETUTCDATE()), 
        KetThucCheckIn = DATEADD(hour, 30, GETUTCDATE())
    WHERE Id = 'D2C252F2-7FD4-4A02-86CB-3D9DE7415795';

    -- Event 4 (Acoustic): Đã kết thúc diễn ra vào hôm qua
    UPDATE [dbo].[SuKien] 
    SET NgayBatDau = DATEADD(day, -2, GETUTCDATE()), 
        NgayKetThuc = DATEADD(day, -1, GETUTCDATE()),
        BatDauCheckIn = DATEADD(day, -2, DATEADD(hour, -1, GETUTCDATE())), 
        KetThucCheckIn = DATEADD(day, -1, GETUTCDATE())
    WHERE Id = '5BC842AD-6166-406A-AD93-EB3ECACFBF7E';

    -- Event 5 (EDM): Tạm dừng bán vé
    UPDATE [dbo].[SuKien] 
    SET TrangThai = 2 
    WHERE Id = '9B265F0B-613C-4094-9DC8-4B74E1F42E65';

    -- Event 6 (Hòa nhạc): Chờ duyệt
    UPDATE [dbo].[SuKien] 
    SET TrangThai = 1 
    WHERE Id = 'A0A26D2F-FF2E-4175-B318-C3FCE0BA23FB';


    -- =============================================
    -- SEED DATA: DonHang & ChiTietDonHang (Large Volume)
    -- =============================================


    -- Order 1 (Event 1): Đã thanh toán, 2 vé VIP A1, A2
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000001', 'DH-WUANG-PAID-01', '77EDA4D0-64A0-4CD8-9BC0-C4B56C3DBA52', 'D3C3FBCE-4FFF-4F33-A4AF-0A2750C9E94E', NULL, N'Khách Hàng Mua Vé 1', 'battlegrounds2004@gmail.com', '0901234501', 1000000, 0, 1000000, 1, DATEADD(hour, -5, GETUTCDATE()), 'TXN-VNP-001', 2, DATEADD(hour, -5, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000001', 1, 1, 500000, N'Khách Hàng Mua Vé 1', 'battlegrounds2004@gmail.com', 'VE-WUANG-VIP-1', 'QR-WUANG-VIP-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000001', 1, 2, 500000, N'Nguyễn Văn Khách 2', 'buyer1-guest@gmail.com', 'VE-WUANG-VIP-2', 'QR-WUANG-VIP-2', 0, NULL, NULL);

    -- Đơn hàng 2 (Event 1): Chưa thanh toán, giữ chỗ VIP A3
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000002', 'DH-WUANG-PEND-02', 'DB847C61-CC0B-41F5-9BEB-F6132B0E5BF2', 'D3C3FBCE-4FFF-4F33-A4AF-0A2750C9E94E', NULL, N'Khách Hàng Mua Vé 2', 'buyer2@gmail.com', '0901234502', 500000, 0, 500000, 0, DATEADD(minute, -5, GETUTCDATE()), NULL, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000002', 1, 3, 500000, N'Khách Hàng Mua Vé 2', 'buyer2@gmail.com', 'VE-WUANG-PEND-3', 'QR-WUANG-PEND-3', 0, NULL, NULL);

    -- Đơn hàng 3 (Event 1): Đã hủy
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000003', 'DH-WUANG-FAIL-03', 'B46BD4B0-EAC9-4C87-A500-785131A97B4A', 'D3C3FBCE-4FFF-4F33-A4AF-0A2750C9E94E', NULL, N'Khách Hàng Mua Vé 3', 'buyer3@gmail.com', '0901234503', 500000, 0, 500000, 2, DATEADD(day, -1, GETUTCDATE()), NULL, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000003', 1, 4, 500000, N'Khách Hàng Mua Vé 3', 'buyer3@gmail.com', 'VE-WUANG-FAIL-4', 'QR-WUANG-FAIL-4', 2, NULL, NULL);

    -- Đơn hàng 4 (Event 2): Đã thanh toán, 1 vé VIP đã check-in, 1 vé Thường chưa check-in
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000004', 'DH-JAZZ-PAID-04', 'FE3E3726-2435-43B9-9688-308CA7D1F34A', 'E20875EC-36DB-45EB-85D1-A706DC9B62D2', NULL, N'Khách Hàng Mua Vé 4', 'buyer4@gmail.com', '0901234504', 800000, 0, 800000, 1, DATEADD(hour, -2, GETUTCDATE()), 'TXN-VNP-004', 2, DATEADD(hour, -2, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000004', 3, NULL, 600000, N'Khách Hàng Mua Vé 4', 'buyer4@gmail.com', 'VE-JAZZ-VIP-4', 'QR-JAZZ-VIP-4', 1, DATEADD(minute, -10, GETUTCDATE()), '55F02A90-5841-4563-A735-C12B9717BB96');

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000004', 4, NULL, 200000, N'Nguyễn Văn Jazz', 'buyer4-guest@gmail.com', 'VE-JAZZ-THUONG-4', 'QR-JAZZ-THUONG-4', 0, NULL, NULL);

    -- Đơn hàng 5 (Event 2): Đã thanh toán, 1 vé Thường chưa check-in
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000005', 'DH-JAZZ-PAID-05', '06BF864B-30A7-4413-B9C4-321686732721', 'E20875EC-36DB-45EB-85D1-A706DC9B62D2', NULL, N'Khách Hàng Mua Vé 5', 'buyer5@gmail.com', '0901234505', 200000, 0, 200000, 1, DATEADD(hour, -1, GETUTCDATE()), 'TXN-VNP-005', 2, DATEADD(hour, -1, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000005', 4, NULL, 200000, N'Khách Hàng Mua Vé 5', 'buyer5@gmail.com', 'VE-JAZZ-THUONG-5', 'QR-JAZZ-THUONG-5', 0, NULL, NULL);

    -- Đơn hàng 6 (Event 3): Đã thanh toán, 1 vé Thường chưa check-in
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000006', 'DH-ROCK-PAID-06', '42F528B2-7107-4672-B7FC-3D49A10F63F6', 'D2C252F2-7FD4-4A02-86CB-3D9DE7415795', NULL, N'Khách Hàng Mua Vé 6', 'buyer6@gmail.com', '0901234506', 250000, 0, 250000, 1, DATEADD(hour, -4, GETUTCDATE()), 'TXN-VNP-006', 2, DATEADD(hour, -4, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000006', 6, NULL, 250000, N'Khách Hàng Mua Vé 6', 'buyer6@gmail.com', 'VE-ROCK-THUONG-6', 'QR-ROCK-THUONG-6', 0, NULL, NULL);

    -- Đơn hàng 7 (Event 4): Đã thanh toán, 1 vé Thường chưa check-in
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000007', 'DH-ACOUSTIC-07', '3C416A14-C60B-48F9-9FA5-7CFE1FFCD5E7', '5BC842AD-6166-406A-AD93-EB3ECACFBF7E', NULL, N'Khách Hàng Mua Vé 7', 'buyer7@gmail.com', '0901234507', 300000, 0, 300000, 1, DATEADD(day, -2, GETUTCDATE()), 'TXN-VNP-007', 2, DATEADD(day, -2, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000007', 8, NULL, 300000, N'Khách Hàng Mua Vé 7', 'buyer7@gmail.com', 'VE-ACOUSTIC-THUONG-7', 'QR-ACOUSTIC-THUONG-7', 0, NULL, NULL);

    -- Order 8
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000008', 'DH-DEMO-008', 'A0000000-0000-0000-0000-000000000013', 'E0000000-0000-0000-0000-000000000051', NULL, N'Khách Hàng Mua Vé 13', 'buyer13@gmail.com', '0901234513', 500000, 0, 500000, 1, DATEADD(day, -18, GETUTCDATE()), 'TXN-VNP-008', 2, DATEADD(day, -18, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000008', 102, NULL, 250000, N'Khách Hàng Mua Vé 13', 'buyer13@gmail.com', 'VE-STD-008-1', 'QR-STD-008-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000008', 102, NULL, 250000, N'Khách Hàng Mua Vé 13', 'buyer13@gmail.com', 'VE-STD-008-2', 'QR-STD-008-2', 0, NULL, NULL);

    -- Order 9
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000009', 'DH-DEMO-009', 'A0000000-0000-0000-0000-000000000034', 'E0000000-0000-0000-0000-000000000018', NULL, N'Khách Hàng Mua Vé 34', 'buyer34@gmail.com', '0901234534', 800000, 0, 800000, 1, DATEADD(day, -19, GETUTCDATE()), 'TXN-VNP-009', 2, DATEADD(day, -19, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000009', 35, NULL, 800000, N'Khách Hàng Mua Vé 34', 'buyer34@gmail.com', 'VE-VIP-009-1', 'QR-VIP-009-1', 0, NULL, NULL);

    -- Order 10
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000010', 'DH-DEMO-010', 'A0000000-0000-0000-0000-000000000014', 'E0000000-0000-0000-0000-000000000051', NULL, N'Khách Hàng Mua Vé 14', 'buyer14@gmail.com', '0901234514', 750000, 0, 750000, 1, DATEADD(day, -19, GETUTCDATE()), 'TXN-VNP-010', 2, DATEADD(day, -19, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000010', 102, NULL, 250000, N'Khách Hàng Mua Vé 14', 'buyer14@gmail.com', 'VE-STD-010-1', 'QR-STD-010-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000010', 102, NULL, 250000, N'Khách Hàng Mua Vé 14', 'buyer14@gmail.com', 'VE-STD-010-2', 'QR-STD-010-2', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000010', 102, NULL, 250000, N'Khách Hàng Mua Vé 14', 'buyer14@gmail.com', 'VE-STD-010-3', 'QR-STD-010-3', 0, NULL, NULL);

    -- Order 11
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000011', 'DH-DEMO-011', 'A0000000-0000-0000-0000-000000000032', 'E0000000-0000-0000-0000-000000000019', NULL, N'Khách Hàng Mua Vé 32', 'buyer32@gmail.com', '0901234532', 1600000, 0, 1600000, 1, DATEADD(day, -11, GETUTCDATE()), 'TXN-VNP-011', 1, DATEADD(day, -11, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000011', 37, NULL, 800000, N'Khách Hàng Mua Vé 32', 'buyer32@gmail.com', 'VE-VIP-011-1', 'QR-VIP-011-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000011', 37, NULL, 800000, N'Khách Hàng Mua Vé 32', 'buyer32@gmail.com', 'VE-VIP-011-2', 'QR-VIP-011-2', 0, NULL, NULL);

    -- Order 12
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000012', 'DH-DEMO-012', 'A0000000-0000-0000-0000-000000000030', 'E0000000-0000-0000-0000-000000000052', NULL, N'Khách Hàng Mua Vé 30', 'buyer30@gmail.com', '0901234530', 1050000, 0, 1050000, 1, DATEADD(day, -16, GETUTCDATE()), 'TXN-VNP-012', 1, DATEADD(day, -16, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000012', 103, NULL, 800000, N'Khách Hàng Mua Vé 30', 'buyer30@gmail.com', 'VE-VIP-012-1', 'QR-VIP-012-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000012', 104, NULL, 250000, N'Khách Hàng Mua Vé 30', 'buyer30@gmail.com', 'VE-STD-012-2', 'QR-STD-012-2', 0, NULL, NULL);

    -- Order 13
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000013', 'DH-DEMO-013', 'A0000000-0000-0000-0000-000000000015', 'E0000000-0000-0000-0000-000000000055', NULL, N'Khách Hàng Mua Vé 15', 'buyer15@gmail.com', '0901234515', 1850000, 0, 1850000, 1, DATEADD(day, -17, GETUTCDATE()), 'TXN-VNP-013', 1, DATEADD(day, -17, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000013', 109, NULL, 800000, N'Khách Hàng Mua Vé 15', 'buyer15@gmail.com', 'VE-VIP-013-1', 'QR-VIP-013-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000013', 109, NULL, 800000, N'Khách Hàng Mua Vé 15', 'buyer15@gmail.com', 'VE-VIP-013-2', 'QR-VIP-013-2', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000013', 110, NULL, 250000, N'Khách Hàng Mua Vé 15', 'buyer15@gmail.com', 'VE-STD-013-3', 'QR-STD-013-3', 0, NULL, NULL);

    -- Order 14
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000014', 'DH-DEMO-014', 'A0000000-0000-0000-0000-000000000019', 'E0000000-0000-0000-0000-000000000018', NULL, N'Khách Hàng Mua Vé 19', 'buyer19@gmail.com', '0901234519', 250000, 0, 250000, 1, DATEADD(day, -17, GETUTCDATE()), 'TXN-VNP-014', 1, DATEADD(day, -17, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000014', 36, NULL, 250000, N'Khách Hàng Mua Vé 19', 'buyer19@gmail.com', 'VE-STD-014-1', 'QR-STD-014-1', 0, NULL, NULL);

    -- Order 15
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000015', 'DH-DEMO-015', 'A0000000-0000-0000-0000-000000000029', 'E0000000-0000-0000-0000-000000000024', NULL, N'Khách Hàng Mua Vé 29', 'buyer29@gmail.com', '0901234529', 1850000, 0, 1850000, 1, DATEADD(day, -12, GETUTCDATE()), 'TXN-VNP-015', 2, DATEADD(day, -12, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000015', 47, NULL, 800000, N'Khách Hàng Mua Vé 29', 'buyer29@gmail.com', 'VE-VIP-015-1', 'QR-VIP-015-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000015', 47, NULL, 800000, N'Khách Hàng Mua Vé 29', 'buyer29@gmail.com', 'VE-VIP-015-2', 'QR-VIP-015-2', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000015', 48, NULL, 250000, N'Khách Hàng Mua Vé 29', 'buyer29@gmail.com', 'VE-STD-015-3', 'QR-STD-015-3', 0, NULL, NULL);

    -- Order 16
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000016', 'DH-DEMO-016', 'A0000000-0000-0000-0000-000000000027', 'E0000000-0000-0000-0000-000000000013', NULL, N'Khách Hàng Mua Vé 27', 'buyer27@gmail.com', '0901234527', 1850000, 0, 1850000, 2, DATEADD(day, -10, GETUTCDATE()), 'NULL', 1, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000016', 25, NULL, 800000, N'Khách Hàng Mua Vé 27', 'buyer27@gmail.com', 'VE-VIP-016-1', 'QR-VIP-016-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000016', 25, NULL, 800000, N'Khách Hàng Mua Vé 27', 'buyer27@gmail.com', 'VE-VIP-016-2', 'QR-VIP-016-2', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000016', 26, NULL, 250000, N'Khách Hàng Mua Vé 27', 'buyer27@gmail.com', 'VE-STD-016-3', 'QR-STD-016-3', 0, NULL, NULL);

    -- Order 17
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000017', 'DH-DEMO-017', '77EDA4D0-64A0-4CD8-9BC0-C4B56C3DBA52', 'E0000000-0000-0000-0000-000000000052', NULL, N'Khách Hàng Mua Vé 1', 'battlegrounds2004@gmail.com', '0901234501', 1050000, 0, 1050000, 0, DATEADD(day, -13, GETUTCDATE()), 'NULL', 1, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000017', 103, NULL, 800000, N'Khách Hàng Mua Vé 1', 'battlegrounds2004@gmail.com', 'VE-VIP-017-1', 'QR-VIP-017-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000017', 104, NULL, 250000, N'Khách Hàng Mua Vé 1', 'battlegrounds2004@gmail.com', 'VE-STD-017-2', 'QR-STD-017-2', 0, NULL, NULL);

    -- Order 18
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000018', 'DH-DEMO-018', 'A0000000-0000-0000-0000-000000000017', 'E0000000-0000-0000-0000-000000000050', NULL, N'Khách Hàng Mua Vé 17', 'buyer17@gmail.com', '0901234517', 1050000, 0, 1050000, 1, DATEADD(day, -14, GETUTCDATE()), 'TXN-VNP-018', 1, DATEADD(day, -14, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000018', 99, NULL, 800000, N'Khách Hàng Mua Vé 17', 'buyer17@gmail.com', 'VE-VIP-018-1', 'QR-VIP-018-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000018', 100, NULL, 250000, N'Khách Hàng Mua Vé 17', 'buyer17@gmail.com', 'VE-STD-018-2', 'QR-STD-018-2', 0, NULL, NULL);

    -- Order 19
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000019', 'DH-DEMO-019', 'A0000000-0000-0000-0000-000000000035', 'E0000000-0000-0000-0000-000000000028', NULL, N'Khách Hàng Mua Vé 35', 'buyer35@gmail.com', '0901234535', 1600000, 0, 1600000, 1, DATEADD(day, -18, GETUTCDATE()), 'TXN-VNP-019', 1, DATEADD(day, -18, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000019', 55, NULL, 800000, N'Khách Hàng Mua Vé 35', 'buyer35@gmail.com', 'VE-VIP-019-1', 'QR-VIP-019-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000019', 55, NULL, 800000, N'Khách Hàng Mua Vé 35', 'buyer35@gmail.com', 'VE-VIP-019-2', 'QR-VIP-019-2', 0, NULL, NULL);

    -- Order 20
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000020', 'DH-DEMO-020', 'A0000000-0000-0000-0000-000000000019', 'E20875EC-36DB-45EB-85D1-A706DC9B62D2', NULL, N'Khách Hàng Mua Vé 19', 'buyer19@gmail.com', '0901234519', 500000, 0, 500000, 0, DATEADD(day, -9, GETUTCDATE()), 'NULL', 1, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000020', 4, NULL, 250000, N'Khách Hàng Mua Vé 19', 'buyer19@gmail.com', 'VE-STD-020-1', 'QR-STD-020-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000020', 4, NULL, 250000, N'Khách Hàng Mua Vé 19', 'buyer19@gmail.com', 'VE-STD-020-2', 'QR-STD-020-2', 0, NULL, NULL);

    -- Order 21
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000021', 'DH-DEMO-021', 'FE3E3726-2435-43B9-9688-308CA7D1F34A', 'E0000000-0000-0000-0000-000000000012', NULL, N'Khách Hàng Mua Vé 4', 'buyer4@gmail.com', '0901234504', 1850000, 0, 1850000, 1, DATEADD(day, -18, GETUTCDATE()), 'TXN-VNP-021', 2, DATEADD(day, -18, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000021', 23, NULL, 800000, N'Khách Hàng Mua Vé 4', 'buyer4@gmail.com', 'VE-VIP-021-1', 'QR-VIP-021-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000021', 23, NULL, 800000, N'Khách Hàng Mua Vé 4', 'buyer4@gmail.com', 'VE-VIP-021-2', 'QR-VIP-021-2', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000021', 24, NULL, 250000, N'Khách Hàng Mua Vé 4', 'buyer4@gmail.com', 'VE-STD-021-3', 'QR-STD-021-3', 0, NULL, NULL);

    -- Order 22
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000022', 'DH-DEMO-022', 'A0000000-0000-0000-0000-000000000037', 'E0000000-0000-0000-0000-000000000058', NULL, N'Khách Hàng Mua Vé 37', 'buyer37@gmail.com', '0901234537', 750000, 0, 750000, 1, DATEADD(day, -4, GETUTCDATE()), 'TXN-VNP-022', 1, DATEADD(day, -4, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000022', 116, NULL, 250000, N'Khách Hàng Mua Vé 37', 'buyer37@gmail.com', 'VE-STD-022-1', 'QR-STD-022-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000022', 116, NULL, 250000, N'Khách Hàng Mua Vé 37', 'buyer37@gmail.com', 'VE-STD-022-2', 'QR-STD-022-2', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000022', 116, NULL, 250000, N'Khách Hàng Mua Vé 37', 'buyer37@gmail.com', 'VE-STD-022-3', 'QR-STD-022-3', 0, NULL, NULL);

    -- Order 23
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000023', 'DH-DEMO-023', 'A0000000-0000-0000-0000-000000000040', 'E0000000-0000-0000-0000-000000000015', NULL, N'Khách Hàng Mua Vé 40', 'buyer40@gmail.com', '0901234540', 1600000, 0, 1600000, 1, DATEADD(day, -8, GETUTCDATE()), 'TXN-VNP-023', 1, DATEADD(day, -8, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000023', 29, NULL, 800000, N'Khách Hàng Mua Vé 40', 'buyer40@gmail.com', 'VE-VIP-023-1', 'QR-VIP-023-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000023', 29, NULL, 800000, N'Khách Hàng Mua Vé 40', 'buyer40@gmail.com', 'VE-VIP-023-2', 'QR-VIP-023-2', 0, NULL, NULL);

    -- Order 24
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000024', 'DH-DEMO-024', 'B46BD4B0-EAC9-4C87-A500-785131A97B4A', 'E0000000-0000-0000-0000-000000000020', NULL, N'Khách Hàng Mua Vé 3', 'buyer3@gmail.com', '0901234503', 1600000, 0, 1600000, 1, DATEADD(day, -10, GETUTCDATE()), 'TXN-VNP-024', 2, DATEADD(day, -10, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000024', 39, NULL, 800000, N'Khách Hàng Mua Vé 3', 'buyer3@gmail.com', 'VE-VIP-024-1', 'QR-VIP-024-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000024', 39, NULL, 800000, N'Khách Hàng Mua Vé 3', 'buyer3@gmail.com', 'VE-VIP-024-2', 'QR-VIP-024-2', 0, NULL, NULL);

    -- Order 25
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000025', 'DH-DEMO-025', '3C416A14-C60B-48F9-9FA5-7CFE1FFCD5E7', '5BC842AD-6166-406A-AD93-EB3ECACFBF7E', NULL, N'Khách Hàng Mua Vé 7', 'buyer7@gmail.com', '0901234507', 800000, 0, 800000, 1, DATEADD(day, -18, GETUTCDATE()), 'TXN-VNP-025', 1, DATEADD(day, -18, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000025', 7, NULL, 800000, N'Khách Hàng Mua Vé 7', 'buyer7@gmail.com', 'VE-VIP-025-1', 'QR-VIP-025-1', 0, NULL, NULL);

    -- Order 26
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000026', 'DH-DEMO-026', 'A0000000-0000-0000-0000-000000000036', 'E0000000-0000-0000-0000-000000000009', NULL, N'Khách Hàng Mua Vé 36', 'buyer36@gmail.com', '0901234536', 500000, 0, 500000, 1, DATEADD(day, -3, GETUTCDATE()), 'TXN-VNP-026', 1, DATEADD(day, -3, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000026', 18, NULL, 250000, N'Khách Hàng Mua Vé 36', 'buyer36@gmail.com', 'VE-STD-026-1', 'QR-STD-026-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000026', 18, NULL, 250000, N'Khách Hàng Mua Vé 36', 'buyer36@gmail.com', 'VE-STD-026-2', 'QR-STD-026-2', 0, NULL, NULL);

    -- Order 27
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000027', 'DH-DEMO-027', 'A0000000-0000-0000-0000-000000000022', 'E0000000-0000-0000-0000-000000000050', NULL, N'Khách Hàng Mua Vé 22', 'buyer22@gmail.com', '0901234522', 1050000, 0, 1050000, 1, DATEADD(day, -3, GETUTCDATE()), 'TXN-VNP-027', 1, DATEADD(day, -3, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000027', 99, NULL, 800000, N'Khách Hàng Mua Vé 22', 'buyer22@gmail.com', 'VE-VIP-027-1', 'QR-VIP-027-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000027', 100, NULL, 250000, N'Khách Hàng Mua Vé 22', 'buyer22@gmail.com', 'VE-STD-027-2', 'QR-STD-027-2', 0, NULL, NULL);

    -- Order 28
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000028', 'DH-DEMO-028', 'A0000000-0000-0000-0000-000000000013', 'E0000000-0000-0000-0000-000000000029', NULL, N'Khách Hàng Mua Vé 13', 'buyer13@gmail.com', '0901234513', 800000, 0, 800000, 1, DATEADD(day, -5, GETUTCDATE()), 'TXN-VNP-028', 2, DATEADD(day, -5, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000028', 57, NULL, 800000, N'Khách Hàng Mua Vé 13', 'buyer13@gmail.com', 'VE-VIP-028-1', 'QR-VIP-028-1', 0, NULL, NULL);

    -- Order 29
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000029', 'DH-DEMO-029', 'A0000000-0000-0000-0000-000000000039', 'E0000000-0000-0000-0000-000000000025', NULL, N'Khách Hàng Mua Vé 39', 'buyer39@gmail.com', '0901234539', 750000, 0, 750000, 1, DATEADD(day, -8, GETUTCDATE()), 'TXN-VNP-029', 1, DATEADD(day, -8, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000029', 50, NULL, 250000, N'Khách Hàng Mua Vé 39', 'buyer39@gmail.com', 'VE-STD-029-1', 'QR-STD-029-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000029', 50, NULL, 250000, N'Khách Hàng Mua Vé 39', 'buyer39@gmail.com', 'VE-STD-029-2', 'QR-STD-029-2', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000029', 50, NULL, 250000, N'Khách Hàng Mua Vé 39', 'buyer39@gmail.com', 'VE-STD-029-3', 'QR-STD-029-3', 0, NULL, NULL);

    -- Order 30
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000030', 'DH-DEMO-030', 'A0000000-0000-0000-0000-000000000035', 'E0000000-0000-0000-0000-000000000017', NULL, N'Khách Hàng Mua Vé 35', 'buyer35@gmail.com', '0901234535', 1600000, 0, 1600000, 1, DATEADD(day, -20, GETUTCDATE()), 'TXN-VNP-030', 1, DATEADD(day, -20, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000030', 33, NULL, 800000, N'Khách Hàng Mua Vé 35', 'buyer35@gmail.com', 'VE-VIP-030-1', 'QR-VIP-030-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000030', 33, NULL, 800000, N'Khách Hàng Mua Vé 35', 'buyer35@gmail.com', 'VE-VIP-030-2', 'QR-VIP-030-2', 0, NULL, NULL);

    -- Order 31
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000031', 'DH-DEMO-031', 'A0000000-0000-0000-0000-000000000012', '5BC842AD-6166-406A-AD93-EB3ECACFBF7E', NULL, N'Khách Hàng Mua Vé 12', 'buyer12@gmail.com', '0901234512', 250000, 0, 250000, 1, DATEADD(day, -6, GETUTCDATE()), 'TXN-VNP-031', 2, DATEADD(day, -6, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000031', 8, NULL, 250000, N'Khách Hàng Mua Vé 12', 'buyer12@gmail.com', 'VE-STD-031-1', 'QR-STD-031-1', 0, NULL, NULL);

    -- Order 32
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000032', 'DH-DEMO-032', 'A0000000-0000-0000-0000-000000000034', 'E0000000-0000-0000-0000-000000000044', NULL, N'Khách Hàng Mua Vé 34', 'buyer34@gmail.com', '0901234534', 1050000, 0, 1050000, 1, DATEADD(day, -6, GETUTCDATE()), 'TXN-VNP-032', 2, DATEADD(day, -6, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000032', 87, NULL, 800000, N'Khách Hàng Mua Vé 34', 'buyer34@gmail.com', 'VE-VIP-032-1', 'QR-VIP-032-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000032', 88, NULL, 250000, N'Khách Hàng Mua Vé 34', 'buyer34@gmail.com', 'VE-STD-032-2', 'QR-STD-032-2', 0, NULL, NULL);

    -- Order 33
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000033', 'DH-DEMO-033', 'A0000000-0000-0000-0000-000000000025', 'E0000000-0000-0000-0000-000000000008', NULL, N'Khách Hàng Mua Vé 25', 'buyer25@gmail.com', '0901234525', 500000, 0, 500000, 1, DATEADD(day, -9, GETUTCDATE()), 'TXN-VNP-033', 2, DATEADD(day, -9, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000033', 16, NULL, 250000, N'Khách Hàng Mua Vé 25', 'buyer25@gmail.com', 'VE-STD-033-1', 'QR-STD-033-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000033', 16, NULL, 250000, N'Khách Hàng Mua Vé 25', 'buyer25@gmail.com', 'VE-STD-033-2', 'QR-STD-033-2', 0, NULL, NULL);

    -- Order 34
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000034', 'DH-DEMO-034', 'A0000000-0000-0000-0000-000000000028', 'E0000000-0000-0000-0000-000000000046', NULL, N'Khách Hàng Mua Vé 28', 'buyer28@gmail.com', '0901234528', 1600000, 0, 1600000, 1, DATEADD(day, -18, GETUTCDATE()), 'TXN-VNP-034', 2, DATEADD(day, -18, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000034', 91, NULL, 800000, N'Khách Hàng Mua Vé 28', 'buyer28@gmail.com', 'VE-VIP-034-1', 'QR-VIP-034-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000034', 91, NULL, 800000, N'Khách Hàng Mua Vé 28', 'buyer28@gmail.com', 'VE-VIP-034-2', 'QR-VIP-034-2', 0, NULL, NULL);

    -- Order 35
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000035', 'DH-DEMO-035', 'A0000000-0000-0000-0000-000000000034', 'E0000000-0000-0000-0000-000000000024', NULL, N'Khách Hàng Mua Vé 34', 'buyer34@gmail.com', '0901234534', 750000, 0, 750000, 1, DATEADD(day, -2, GETUTCDATE()), 'TXN-VNP-035', 2, DATEADD(day, -2, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000035', 48, NULL, 250000, N'Khách Hàng Mua Vé 34', 'buyer34@gmail.com', 'VE-STD-035-1', 'QR-STD-035-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000035', 48, NULL, 250000, N'Khách Hàng Mua Vé 34', 'buyer34@gmail.com', 'VE-STD-035-2', 'QR-STD-035-2', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000035', 48, NULL, 250000, N'Khách Hàng Mua Vé 34', 'buyer34@gmail.com', 'VE-STD-035-3', 'QR-STD-035-3', 0, NULL, NULL);

    -- Order 36
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000036', 'DH-DEMO-036', 'A0000000-0000-0000-0000-000000000026', 'E0000000-0000-0000-0000-000000000024', NULL, N'Khách Hàng Mua Vé 26', 'buyer26@gmail.com', '0901234526', 1850000, 0, 1850000, 1, DATEADD(day, -12, GETUTCDATE()), 'TXN-VNP-036', 1, DATEADD(day, -12, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000036', 47, NULL, 800000, N'Khách Hàng Mua Vé 26', 'buyer26@gmail.com', 'VE-VIP-036-1', 'QR-VIP-036-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000036', 47, NULL, 800000, N'Khách Hàng Mua Vé 26', 'buyer26@gmail.com', 'VE-VIP-036-2', 'QR-VIP-036-2', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000036', 48, NULL, 250000, N'Khách Hàng Mua Vé 26', 'buyer26@gmail.com', 'VE-STD-036-3', 'QR-STD-036-3', 0, NULL, NULL);

    -- Order 37
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000037', 'DH-DEMO-037', 'A0000000-0000-0000-0000-000000000022', 'E0000000-0000-0000-0000-000000000018', NULL, N'Khách Hàng Mua Vé 22', 'buyer22@gmail.com', '0901234522', 1050000, 0, 1050000, 1, DATEADD(day, -16, GETUTCDATE()), 'TXN-VNP-037', 1, DATEADD(day, -16, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000037', 35, NULL, 800000, N'Khách Hàng Mua Vé 22', 'buyer22@gmail.com', 'VE-VIP-037-1', 'QR-VIP-037-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000037', 36, NULL, 250000, N'Khách Hàng Mua Vé 22', 'buyer22@gmail.com', 'VE-STD-037-2', 'QR-STD-037-2', 0, NULL, NULL);

    -- Order 38
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000038', 'DH-DEMO-038', 'A0000000-0000-0000-0000-000000000019', 'D2C252F2-7FD4-4A02-86CB-3D9DE7415795', NULL, N'Khách Hàng Mua Vé 19', 'buyer19@gmail.com', '0901234519', 1050000, 0, 1050000, 0, DATEADD(day, -13, GETUTCDATE()), 'NULL', 1, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000038', 5, NULL, 800000, N'Khách Hàng Mua Vé 19', 'buyer19@gmail.com', 'VE-VIP-038-1', 'QR-VIP-038-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000038', 6, NULL, 250000, N'Khách Hàng Mua Vé 19', 'buyer19@gmail.com', 'VE-STD-038-2', 'QR-STD-038-2', 0, NULL, NULL);

    -- Order 39
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000039', 'DH-DEMO-039', 'A0000000-0000-0000-0000-000000000038', 'E0000000-0000-0000-0000-000000000018', NULL, N'Khách Hàng Mua Vé 38', 'buyer38@gmail.com', '0901234538', 1050000, 0, 1050000, 1, DATEADD(day, -11, GETUTCDATE()), 'TXN-VNP-039', 2, DATEADD(day, -11, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000039', 35, NULL, 800000, N'Khách Hàng Mua Vé 38', 'buyer38@gmail.com', 'VE-VIP-039-1', 'QR-VIP-039-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000039', 36, NULL, 250000, N'Khách Hàng Mua Vé 38', 'buyer38@gmail.com', 'VE-STD-039-2', 'QR-STD-039-2', 0, NULL, NULL);

    -- Order 40
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000040', 'DH-DEMO-040', 'A0000000-0000-0000-0000-000000000038', 'E0000000-0000-0000-0000-000000000040', NULL, N'Khách Hàng Mua Vé 38', 'buyer38@gmail.com', '0901234538', 1050000, 0, 1050000, 1, DATEADD(day, -13, GETUTCDATE()), 'TXN-VNP-040', 1, DATEADD(day, -13, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000040', 79, NULL, 800000, N'Khách Hàng Mua Vé 38', 'buyer38@gmail.com', 'VE-VIP-040-1', 'QR-VIP-040-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000040', 80, NULL, 250000, N'Khách Hàng Mua Vé 38', 'buyer38@gmail.com', 'VE-STD-040-2', 'QR-STD-040-2', 0, NULL, NULL);

    -- Order 41
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000041', 'DH-DEMO-041', 'A0000000-0000-0000-0000-000000000030', 'D3C3FBCE-4FFF-4F33-A4AF-0A2750C9E94E', NULL, N'Khách Hàng Mua Vé 30', 'buyer30@gmail.com', '0901234530', 1850000, 0, 1850000, 1, DATEADD(day, -18, GETUTCDATE()), 'TXN-VNP-041', 2, DATEADD(day, -18, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000041', 1, NULL, 800000, N'Khách Hàng Mua Vé 30', 'buyer30@gmail.com', 'VE-VIP-041-1', 'QR-VIP-041-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000041', 1, NULL, 800000, N'Khách Hàng Mua Vé 30', 'buyer30@gmail.com', 'VE-VIP-041-2', 'QR-VIP-041-2', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000041', 2, NULL, 250000, N'Khách Hàng Mua Vé 30', 'buyer30@gmail.com', 'VE-STD-041-3', 'QR-STD-041-3', 0, NULL, NULL);

    -- Order 42
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000042', 'DH-DEMO-042', 'A0000000-0000-0000-0000-000000000023', 'E0000000-0000-0000-0000-000000000049', NULL, N'Khách Hàng Mua Vé 23', 'buyer23@gmail.com', '0901234523', 250000, 0, 250000, 1, DATEADD(day, -20, GETUTCDATE()), 'TXN-VNP-042', 2, DATEADD(day, -20, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000042', 98, NULL, 250000, N'Khách Hàng Mua Vé 23', 'buyer23@gmail.com', 'VE-STD-042-1', 'QR-STD-042-1', 0, NULL, NULL);

    -- Order 43
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000043', 'DH-DEMO-043', '00858E32-C188-44CC-8A26-21A599A2F73C', 'E0000000-0000-0000-0000-000000000045', NULL, N'Khách Hàng Mua Vé 9', 'buyer9@gmail.com', '0901234509', 250000, 0, 250000, 1, DATEADD(day, -17, GETUTCDATE()), 'TXN-VNP-043', 1, DATEADD(day, -17, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000043', 90, NULL, 250000, N'Khách Hàng Mua Vé 9', 'buyer9@gmail.com', 'VE-STD-043-1', 'QR-STD-043-1', 0, NULL, NULL);

    -- Order 44
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000044', 'DH-DEMO-044', 'A0000000-0000-0000-0000-000000000011', 'E0000000-0000-0000-0000-000000000017', NULL, N'Khách Hàng Mua Vé 11', 'buyer11@gmail.com', '0901234511', 800000, 0, 800000, 1, DATEADD(day, -1, GETUTCDATE()), 'TXN-VNP-044', 1, DATEADD(day, -1, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000044', 33, NULL, 800000, N'Khách Hàng Mua Vé 11', 'buyer11@gmail.com', 'VE-VIP-044-1', 'QR-VIP-044-1', 0, NULL, NULL);

    -- Order 45
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000045', 'DH-DEMO-045', '77EDA4D0-64A0-4CD8-9BC0-C4B56C3DBA52', 'E0000000-0000-0000-0000-000000000026', NULL, N'Khách Hàng Mua Vé 1', 'battlegrounds2004@gmail.com', '0901234501', 1600000, 0, 1600000, 1, DATEADD(day, -20, GETUTCDATE()), 'TXN-VNP-045', 2, DATEADD(day, -20, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000045', 51, NULL, 800000, N'Khách Hàng Mua Vé 1', 'battlegrounds2004@gmail.com', 'VE-VIP-045-1', 'QR-VIP-045-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000045', 51, NULL, 800000, N'Khách Hàng Mua Vé 1', 'battlegrounds2004@gmail.com', 'VE-VIP-045-2', 'QR-VIP-045-2', 0, NULL, NULL);

    -- Order 46
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000046', 'DH-DEMO-046', 'A0000000-0000-0000-0000-000000000018', 'E0000000-0000-0000-0000-000000000053', NULL, N'Khách Hàng Mua Vé 18', 'buyer18@gmail.com', '0901234518', 1050000, 0, 1050000, 1, DATEADD(day, -16, GETUTCDATE()), 'TXN-VNP-046', 2, DATEADD(day, -16, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000046', 105, NULL, 800000, N'Khách Hàng Mua Vé 18', 'buyer18@gmail.com', 'VE-VIP-046-1', 'QR-VIP-046-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000046', 106, NULL, 250000, N'Khách Hàng Mua Vé 18', 'buyer18@gmail.com', 'VE-STD-046-2', 'QR-STD-046-2', 0, NULL, NULL);

    -- Order 47
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000047', 'DH-DEMO-047', 'A0000000-0000-0000-0000-000000000025', 'E0000000-0000-0000-0000-000000000017', NULL, N'Khách Hàng Mua Vé 25', 'buyer25@gmail.com', '0901234525', 1850000, 0, 1850000, 1, DATEADD(day, -17, GETUTCDATE()), 'TXN-VNP-047', 1, DATEADD(day, -17, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000047', 33, NULL, 800000, N'Khách Hàng Mua Vé 25', 'buyer25@gmail.com', 'VE-VIP-047-1', 'QR-VIP-047-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000047', 33, NULL, 800000, N'Khách Hàng Mua Vé 25', 'buyer25@gmail.com', 'VE-VIP-047-2', 'QR-VIP-047-2', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000047', 34, NULL, 250000, N'Khách Hàng Mua Vé 25', 'buyer25@gmail.com', 'VE-STD-047-3', 'QR-STD-047-3', 0, NULL, NULL);

    -- Order 48
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000048', 'DH-DEMO-048', '42F528B2-7107-4672-B7FC-3D49A10F63F6', 'E0000000-0000-0000-0000-000000000012', NULL, N'Khách Hàng Mua Vé 6', 'buyer6@gmail.com', '0901234506', 1600000, 0, 1600000, 1, DATEADD(day, -5, GETUTCDATE()), 'TXN-VNP-048', 2, DATEADD(day, -5, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000048', 23, NULL, 800000, N'Khách Hàng Mua Vé 6', 'buyer6@gmail.com', 'VE-VIP-048-1', 'QR-VIP-048-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000048', 23, NULL, 800000, N'Khách Hàng Mua Vé 6', 'buyer6@gmail.com', 'VE-VIP-048-2', 'QR-VIP-048-2', 0, NULL, NULL);

    -- Order 49
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000049', 'DH-DEMO-049', '00858E32-C188-44CC-8A26-21A599A2F73C', 'E0000000-0000-0000-0000-000000000012', NULL, N'Khách Hàng Mua Vé 9', 'buyer9@gmail.com', '0901234509', 1600000, 0, 1600000, 1, DATEADD(day, -1, GETUTCDATE()), 'TXN-VNP-049', 2, DATEADD(day, -1, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000049', 23, NULL, 800000, N'Khách Hàng Mua Vé 9', 'buyer9@gmail.com', 'VE-VIP-049-1', 'QR-VIP-049-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000049', 23, NULL, 800000, N'Khách Hàng Mua Vé 9', 'buyer9@gmail.com', 'VE-VIP-049-2', 'QR-VIP-049-2', 0, NULL, NULL);

    -- Order 50
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000050', 'DH-DEMO-050', '3C416A14-C60B-48F9-9FA5-7CFE1FFCD5E7', 'E0000000-0000-0000-0000-000000000017', NULL, N'Khách Hàng Mua Vé 7', 'buyer7@gmail.com', '0901234507', 500000, 0, 500000, 1, DATEADD(day, -8, GETUTCDATE()), 'TXN-VNP-050', 2, DATEADD(day, -8, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000050', 34, NULL, 250000, N'Khách Hàng Mua Vé 7', 'buyer7@gmail.com', 'VE-STD-050-1', 'QR-STD-050-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000050', 34, NULL, 250000, N'Khách Hàng Mua Vé 7', 'buyer7@gmail.com', 'VE-STD-050-2', 'QR-STD-050-2', 0, NULL, NULL);

    -- Order 51
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000051', 'DH-DEMO-051', 'A0000000-0000-0000-0000-000000000020', 'E0000000-0000-0000-0000-000000000015', NULL, N'Khách Hàng Mua Vé 20', 'buyer20@gmail.com', '0901234520', 1050000, 0, 1050000, 1, DATEADD(day, -8, GETUTCDATE()), 'TXN-VNP-051', 2, DATEADD(day, -8, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000051', 29, NULL, 800000, N'Khách Hàng Mua Vé 20', 'buyer20@gmail.com', 'VE-VIP-051-1', 'QR-VIP-051-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000051', 30, NULL, 250000, N'Khách Hàng Mua Vé 20', 'buyer20@gmail.com', 'VE-STD-051-2', 'QR-STD-051-2', 0, NULL, NULL);

    -- Order 52
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000052', 'DH-DEMO-052', 'A0000000-0000-0000-0000-000000000024', 'E0000000-0000-0000-0000-000000000051', NULL, N'Khách Hàng Mua Vé 24', 'buyer24@gmail.com', '0901234524', 1850000, 0, 1850000, 1, DATEADD(day, -7, GETUTCDATE()), 'TXN-VNP-052', 2, DATEADD(day, -7, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000052', 101, NULL, 800000, N'Khách Hàng Mua Vé 24', 'buyer24@gmail.com', 'VE-VIP-052-1', 'QR-VIP-052-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000052', 101, NULL, 800000, N'Khách Hàng Mua Vé 24', 'buyer24@gmail.com', 'VE-VIP-052-2', 'QR-VIP-052-2', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000052', 102, NULL, 250000, N'Khách Hàng Mua Vé 24', 'buyer24@gmail.com', 'VE-STD-052-3', 'QR-STD-052-3', 0, NULL, NULL);

    -- Order 53
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000053', 'DH-DEMO-053', 'A0000000-0000-0000-0000-000000000028', 'E0000000-0000-0000-0000-000000000015', NULL, N'Khách Hàng Mua Vé 28', 'buyer28@gmail.com', '0901234528', 1850000, 0, 1850000, 1, DATEADD(day, -6, GETUTCDATE()), 'TXN-VNP-053', 1, DATEADD(day, -6, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000053', 29, NULL, 800000, N'Khách Hàng Mua Vé 28', 'buyer28@gmail.com', 'VE-VIP-053-1', 'QR-VIP-053-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000053', 29, NULL, 800000, N'Khách Hàng Mua Vé 28', 'buyer28@gmail.com', 'VE-VIP-053-2', 'QR-VIP-053-2', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000053', 30, NULL, 250000, N'Khách Hàng Mua Vé 28', 'buyer28@gmail.com', 'VE-STD-053-3', 'QR-STD-053-3', 0, NULL, NULL);

    -- Order 54
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000054', 'DH-DEMO-054', 'A0000000-0000-0000-0000-000000000026', 'E0000000-0000-0000-0000-000000000026', NULL, N'Khách Hàng Mua Vé 26', 'buyer26@gmail.com', '0901234526', 1850000, 0, 1850000, 1, DATEADD(day, -3, GETUTCDATE()), 'TXN-VNP-054', 1, DATEADD(day, -3, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000054', 51, NULL, 800000, N'Khách Hàng Mua Vé 26', 'buyer26@gmail.com', 'VE-VIP-054-1', 'QR-VIP-054-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000054', 51, NULL, 800000, N'Khách Hàng Mua Vé 26', 'buyer26@gmail.com', 'VE-VIP-054-2', 'QR-VIP-054-2', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000054', 52, NULL, 250000, N'Khách Hàng Mua Vé 26', 'buyer26@gmail.com', 'VE-STD-054-3', 'QR-STD-054-3', 0, NULL, NULL);

    -- Order 55
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000055', 'DH-DEMO-055', '3C416A14-C60B-48F9-9FA5-7CFE1FFCD5E7', 'E0000000-0000-0000-0000-000000000036', NULL, N'Khách Hàng Mua Vé 7', 'buyer7@gmail.com', '0901234507', 500000, 0, 500000, 0, DATEADD(day, -6, GETUTCDATE()), 'NULL', 2, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000055', 72, NULL, 250000, N'Khách Hàng Mua Vé 7', 'buyer7@gmail.com', 'VE-STD-055-1', 'QR-STD-055-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000055', 72, NULL, 250000, N'Khách Hàng Mua Vé 7', 'buyer7@gmail.com', 'VE-STD-055-2', 'QR-STD-055-2', 0, NULL, NULL);

    -- Order 56
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000056', 'DH-DEMO-056', 'A0000000-0000-0000-0000-000000000024', 'E0000000-0000-0000-0000-000000000012', NULL, N'Khách Hàng Mua Vé 24', 'buyer24@gmail.com', '0901234524', 800000, 0, 800000, 1, DATEADD(day, -5, GETUTCDATE()), 'TXN-VNP-056', 1, DATEADD(day, -5, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000056', 23, NULL, 800000, N'Khách Hàng Mua Vé 24', 'buyer24@gmail.com', 'VE-VIP-056-1', 'QR-VIP-056-1', 0, NULL, NULL);

    -- Order 57
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000057', 'DH-DEMO-057', 'A0000000-0000-0000-0000-000000000030', 'E0000000-0000-0000-0000-000000000049', NULL, N'Khách Hàng Mua Vé 30', 'buyer30@gmail.com', '0901234530', 500000, 0, 500000, 1, DATEADD(day, -18, GETUTCDATE()), 'TXN-VNP-057', 2, DATEADD(day, -18, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000057', 98, NULL, 250000, N'Khách Hàng Mua Vé 30', 'buyer30@gmail.com', 'VE-STD-057-1', 'QR-STD-057-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000057', 98, NULL, 250000, N'Khách Hàng Mua Vé 30', 'buyer30@gmail.com', 'VE-STD-057-2', 'QR-STD-057-2', 0, NULL, NULL);

    -- Order 58
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000058', 'DH-DEMO-058', 'A0000000-0000-0000-0000-000000000032', 'E0000000-0000-0000-0000-000000000013', NULL, N'Khách Hàng Mua Vé 32', 'buyer32@gmail.com', '0901234532', 1600000, 0, 1600000, 1, DATEADD(day, -1, GETUTCDATE()), 'TXN-VNP-058', 2, DATEADD(day, -1, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000058', 25, NULL, 800000, N'Khách Hàng Mua Vé 32', 'buyer32@gmail.com', 'VE-VIP-058-1', 'QR-VIP-058-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000058', 25, NULL, 800000, N'Khách Hàng Mua Vé 32', 'buyer32@gmail.com', 'VE-VIP-058-2', 'QR-VIP-058-2', 0, NULL, NULL);

    -- Order 59
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000059', 'DH-DEMO-059', 'A0000000-0000-0000-0000-000000000030', 'E0000000-0000-0000-0000-000000000050', NULL, N'Khách Hàng Mua Vé 30', 'buyer30@gmail.com', '0901234530', 250000, 0, 250000, 1, DATEADD(day, -13, GETUTCDATE()), 'TXN-VNP-059', 2, DATEADD(day, -13, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000059', 100, NULL, 250000, N'Khách Hàng Mua Vé 30', 'buyer30@gmail.com', 'VE-STD-059-1', 'QR-STD-059-1', 0, NULL, NULL);

    -- Order 60
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000060', 'DH-DEMO-060', 'A0000000-0000-0000-0000-000000000036', 'E0000000-0000-0000-0000-000000000050', NULL, N'Khách Hàng Mua Vé 36', 'buyer36@gmail.com', '0901234536', 800000, 0, 800000, 1, DATEADD(day, -18, GETUTCDATE()), 'TXN-VNP-060', 1, DATEADD(day, -18, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000060', 99, NULL, 800000, N'Khách Hàng Mua Vé 36', 'buyer36@gmail.com', 'VE-VIP-060-1', 'QR-VIP-060-1', 0, NULL, NULL);

    -- Order 61
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000061', 'DH-DEMO-061', 'A0000000-0000-0000-0000-000000000035', 'E0000000-0000-0000-0000-000000000020', NULL, N'Khách Hàng Mua Vé 35', 'buyer35@gmail.com', '0901234535', 800000, 0, 800000, 1, DATEADD(day, -10, GETUTCDATE()), 'TXN-VNP-061', 1, DATEADD(day, -10, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000061', 39, NULL, 800000, N'Khách Hàng Mua Vé 35', 'buyer35@gmail.com', 'VE-VIP-061-1', 'QR-VIP-061-1', 0, NULL, NULL);

    -- Order 62
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000062', 'DH-DEMO-062', 'DB847C61-CC0B-41F5-9BEB-F6132B0E5BF2', 'E0000000-0000-0000-0000-000000000049', NULL, N'Khách Hàng Mua Vé 2', 'buyer2@gmail.com', '0901234502', 1850000, 0, 1850000, 1, DATEADD(day, -4, GETUTCDATE()), 'TXN-VNP-062', 2, DATEADD(day, -4, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000062', 97, NULL, 800000, N'Khách Hàng Mua Vé 2', 'buyer2@gmail.com', 'VE-VIP-062-1', 'QR-VIP-062-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000062', 97, NULL, 800000, N'Khách Hàng Mua Vé 2', 'buyer2@gmail.com', 'VE-VIP-062-2', 'QR-VIP-062-2', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000062', 98, NULL, 250000, N'Khách Hàng Mua Vé 2', 'buyer2@gmail.com', 'VE-STD-062-3', 'QR-STD-062-3', 0, NULL, NULL);

    -- Order 63
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000063', 'DH-DEMO-063', 'A0000000-0000-0000-0000-000000000028', 'E0000000-0000-0000-0000-000000000058', NULL, N'Khách Hàng Mua Vé 28', 'buyer28@gmail.com', '0901234528', 750000, 0, 750000, 1, DATEADD(day, -19, GETUTCDATE()), 'TXN-VNP-063', 1, DATEADD(day, -19, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000063', 116, NULL, 250000, N'Khách Hàng Mua Vé 28', 'buyer28@gmail.com', 'VE-STD-063-1', 'QR-STD-063-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000063', 116, NULL, 250000, N'Khách Hàng Mua Vé 28', 'buyer28@gmail.com', 'VE-STD-063-2', 'QR-STD-063-2', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000063', 116, NULL, 250000, N'Khách Hàng Mua Vé 28', 'buyer28@gmail.com', 'VE-STD-063-3', 'QR-STD-063-3', 0, NULL, NULL);

    -- Order 64
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000064', 'DH-DEMO-064', '42F528B2-7107-4672-B7FC-3D49A10F63F6', 'E0000000-0000-0000-0000-000000000007', NULL, N'Khách Hàng Mua Vé 6', 'buyer6@gmail.com', '0901234506', 1600000, 0, 1600000, 1, DATEADD(day, -17, GETUTCDATE()), 'TXN-VNP-064', 1, DATEADD(day, -17, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000064', 13, NULL, 800000, N'Khách Hàng Mua Vé 6', 'buyer6@gmail.com', 'VE-VIP-064-1', 'QR-VIP-064-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000064', 13, NULL, 800000, N'Khách Hàng Mua Vé 6', 'buyer6@gmail.com', 'VE-VIP-064-2', 'QR-VIP-064-2', 0, NULL, NULL);

    -- Order 65
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000065', 'DH-DEMO-065', 'A0000000-0000-0000-0000-000000000017', 'E0000000-0000-0000-0000-000000000021', NULL, N'Khách Hàng Mua Vé 17', 'buyer17@gmail.com', '0901234517', 1050000, 0, 1050000, 1, DATEADD(day, -10, GETUTCDATE()), 'TXN-VNP-065', 2, DATEADD(day, -10, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000065', 41, NULL, 800000, N'Khách Hàng Mua Vé 17', 'buyer17@gmail.com', 'VE-VIP-065-1', 'QR-VIP-065-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000065', 42, NULL, 250000, N'Khách Hàng Mua Vé 17', 'buyer17@gmail.com', 'VE-STD-065-2', 'QR-STD-065-2', 0, NULL, NULL);

    -- Order 66
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000066', 'DH-DEMO-066', 'A0000000-0000-0000-0000-000000000032', 'D2C252F2-7FD4-4A02-86CB-3D9DE7415795', NULL, N'Khách Hàng Mua Vé 32', 'buyer32@gmail.com', '0901234532', 500000, 0, 500000, 1, DATEADD(day, -2, GETUTCDATE()), 'TXN-VNP-066', 2, DATEADD(day, -2, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000066', 6, NULL, 250000, N'Khách Hàng Mua Vé 32', 'buyer32@gmail.com', 'VE-STD-066-1', 'QR-STD-066-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000066', 6, NULL, 250000, N'Khách Hàng Mua Vé 32', 'buyer32@gmail.com', 'VE-STD-066-2', 'QR-STD-066-2', 0, NULL, NULL);

    -- Order 67
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000067', 'DH-DEMO-067', 'A0000000-0000-0000-0000-000000000011', 'E0000000-0000-0000-0000-000000000026', NULL, N'Khách Hàng Mua Vé 11', 'buyer11@gmail.com', '0901234511', 250000, 0, 250000, 1, DATEADD(day, -4, GETUTCDATE()), 'TXN-VNP-067', 1, DATEADD(day, -4, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000067', 52, NULL, 250000, N'Khách Hàng Mua Vé 11', 'buyer11@gmail.com', 'VE-STD-067-1', 'QR-STD-067-1', 0, NULL, NULL);

    -- Order 68
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000068', 'DH-DEMO-068', 'A0000000-0000-0000-0000-000000000023', 'E0000000-0000-0000-0000-000000000027', NULL, N'Khách Hàng Mua Vé 23', 'buyer23@gmail.com', '0901234523', 800000, 0, 800000, 1, DATEADD(day, -6, GETUTCDATE()), 'TXN-VNP-068', 1, DATEADD(day, -6, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000068', 53, NULL, 800000, N'Khách Hàng Mua Vé 23', 'buyer23@gmail.com', 'VE-VIP-068-1', 'QR-VIP-068-1', 0, NULL, NULL);

    -- Order 69
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000069', 'DH-DEMO-069', 'A0000000-0000-0000-0000-000000000030', 'E0000000-0000-0000-0000-000000000011', NULL, N'Khách Hàng Mua Vé 30', 'buyer30@gmail.com', '0901234530', 1050000, 0, 1050000, 1, DATEADD(day, -10, GETUTCDATE()), 'TXN-VNP-069', 1, DATEADD(day, -10, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000069', 21, NULL, 800000, N'Khách Hàng Mua Vé 30', 'buyer30@gmail.com', 'VE-VIP-069-1', 'QR-VIP-069-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000069', 22, NULL, 250000, N'Khách Hàng Mua Vé 30', 'buyer30@gmail.com', 'VE-STD-069-2', 'QR-STD-069-2', 0, NULL, NULL);

    -- Order 70
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000070', 'DH-DEMO-070', 'A0000000-0000-0000-0000-000000000033', 'E0000000-0000-0000-0000-000000000052', NULL, N'Khách Hàng Mua Vé 33', 'buyer33@gmail.com', '0901234533', 750000, 0, 750000, 1, DATEADD(day, -9, GETUTCDATE()), 'TXN-VNP-070', 2, DATEADD(day, -9, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000070', 104, NULL, 250000, N'Khách Hàng Mua Vé 33', 'buyer33@gmail.com', 'VE-STD-070-1', 'QR-STD-070-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000070', 104, NULL, 250000, N'Khách Hàng Mua Vé 33', 'buyer33@gmail.com', 'VE-STD-070-2', 'QR-STD-070-2', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000070', 104, NULL, 250000, N'Khách Hàng Mua Vé 33', 'buyer33@gmail.com', 'VE-STD-070-3', 'QR-STD-070-3', 0, NULL, NULL);

    -- Order 71
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000071', 'DH-DEMO-071', 'A0000000-0000-0000-0000-000000000024', 'E0000000-0000-0000-0000-000000000042', NULL, N'Khách Hàng Mua Vé 24', 'buyer24@gmail.com', '0901234524', 800000, 0, 800000, 1, DATEADD(day, -4, GETUTCDATE()), 'TXN-VNP-071', 1, DATEADD(day, -4, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000071', 83, NULL, 800000, N'Khách Hàng Mua Vé 24', 'buyer24@gmail.com', 'VE-VIP-071-1', 'QR-VIP-071-1', 0, NULL, NULL);

    -- Order 72
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000072', 'DH-DEMO-072', 'A0000000-0000-0000-0000-000000000017', 'E0000000-0000-0000-0000-000000000047', NULL, N'Khách Hàng Mua Vé 17', 'buyer17@gmail.com', '0901234517', 800000, 0, 800000, 1, DATEADD(day, -12, GETUTCDATE()), 'TXN-VNP-072', 1, DATEADD(day, -12, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000072', 93, NULL, 800000, N'Khách Hàng Mua Vé 17', 'buyer17@gmail.com', 'VE-VIP-072-1', 'QR-VIP-072-1', 0, NULL, NULL);

    -- Order 73
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000073', 'DH-DEMO-073', 'FE3E3726-2435-43B9-9688-308CA7D1F34A', 'E0000000-0000-0000-0000-000000000052', NULL, N'Khách Hàng Mua Vé 4', 'buyer4@gmail.com', '0901234504', 800000, 0, 800000, 1, DATEADD(day, -9, GETUTCDATE()), 'TXN-VNP-073', 1, DATEADD(day, -9, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000073', 103, NULL, 800000, N'Khách Hàng Mua Vé 4', 'buyer4@gmail.com', 'VE-VIP-073-1', 'QR-VIP-073-1', 0, NULL, NULL);

    -- Order 74
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000074', 'DH-DEMO-074', '42F528B2-7107-4672-B7FC-3D49A10F63F6', 'E0000000-0000-0000-0000-000000000044', NULL, N'Khách Hàng Mua Vé 6', 'buyer6@gmail.com', '0901234506', 500000, 0, 500000, 1, DATEADD(day, -8, GETUTCDATE()), 'TXN-VNP-074', 1, DATEADD(day, -8, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000074', 88, NULL, 250000, N'Khách Hàng Mua Vé 6', 'buyer6@gmail.com', 'VE-STD-074-1', 'QR-STD-074-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000074', 88, NULL, 250000, N'Khách Hàng Mua Vé 6', 'buyer6@gmail.com', 'VE-STD-074-2', 'QR-STD-074-2', 0, NULL, NULL);

    -- Order 75
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000075', 'DH-DEMO-075', 'A0000000-0000-0000-0000-000000000029', 'E0000000-0000-0000-0000-000000000046', NULL, N'Khách Hàng Mua Vé 29', 'buyer29@gmail.com', '0901234529', 250000, 0, 250000, 1, DATEADD(day, -18, GETUTCDATE()), 'TXN-VNP-075', 1, DATEADD(day, -18, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000075', 92, NULL, 250000, N'Khách Hàng Mua Vé 29', 'buyer29@gmail.com', 'VE-STD-075-1', 'QR-STD-075-1', 0, NULL, NULL);

    -- Order 76
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000076', 'DH-DEMO-076', 'A0000000-0000-0000-0000-000000000037', 'E0000000-0000-0000-0000-000000000010', NULL, N'Khách Hàng Mua Vé 37', 'buyer37@gmail.com', '0901234537', 800000, 0, 800000, 1, DATEADD(day, -18, GETUTCDATE()), 'TXN-VNP-076', 1, DATEADD(day, -18, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000076', 19, NULL, 800000, N'Khách Hàng Mua Vé 37', 'buyer37@gmail.com', 'VE-VIP-076-1', 'QR-VIP-076-1', 0, NULL, NULL);

    -- Order 77
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000077', 'DH-DEMO-077', 'A0000000-0000-0000-0000-000000000021', 'E0000000-0000-0000-0000-000000000023', NULL, N'Khách Hàng Mua Vé 21', 'buyer21@gmail.com', '0901234521', 800000, 0, 800000, 1, DATEADD(day, -7, GETUTCDATE()), 'TXN-VNP-077', 1, DATEADD(day, -7, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000077', 45, NULL, 800000, N'Khách Hàng Mua Vé 21', 'buyer21@gmail.com', 'VE-VIP-077-1', 'QR-VIP-077-1', 0, NULL, NULL);

    -- Order 78
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000078', 'DH-DEMO-078', 'A0000000-0000-0000-0000-000000000015', '5BC842AD-6166-406A-AD93-EB3ECACFBF7E', NULL, N'Khách Hàng Mua Vé 15', 'buyer15@gmail.com', '0901234515', 1850000, 0, 1850000, 1, DATEADD(day, -20, GETUTCDATE()), 'TXN-VNP-078', 2, DATEADD(day, -20, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000078', 7, NULL, 800000, N'Khách Hàng Mua Vé 15', 'buyer15@gmail.com', 'VE-VIP-078-1', 'QR-VIP-078-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000078', 7, NULL, 800000, N'Khách Hàng Mua Vé 15', 'buyer15@gmail.com', 'VE-VIP-078-2', 'QR-VIP-078-2', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000078', 8, NULL, 250000, N'Khách Hàng Mua Vé 15', 'buyer15@gmail.com', 'VE-STD-078-3', 'QR-STD-078-3', 0, NULL, NULL);

    -- Order 79
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000079', 'DH-DEMO-079', 'A0000000-0000-0000-0000-000000000031', 'E0000000-0000-0000-0000-000000000015', NULL, N'Khách Hàng Mua Vé 31', 'buyer31@gmail.com', '0901234531', 1850000, 0, 1850000, 1, DATEADD(day, -5, GETUTCDATE()), 'TXN-VNP-079', 1, DATEADD(day, -5, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000079', 29, NULL, 800000, N'Khách Hàng Mua Vé 31', 'buyer31@gmail.com', 'VE-VIP-079-1', 'QR-VIP-079-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000079', 29, NULL, 800000, N'Khách Hàng Mua Vé 31', 'buyer31@gmail.com', 'VE-VIP-079-2', 'QR-VIP-079-2', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000079', 30, NULL, 250000, N'Khách Hàng Mua Vé 31', 'buyer31@gmail.com', 'VE-STD-079-3', 'QR-STD-079-3', 0, NULL, NULL);

    -- Order 80
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000080', 'DH-DEMO-080', 'A0000000-0000-0000-0000-000000000030', 'E0000000-0000-0000-0000-000000000025', NULL, N'Khách Hàng Mua Vé 30', 'buyer30@gmail.com', '0901234530', 1050000, 0, 1050000, 0, DATEADD(day, -1, GETUTCDATE()), 'NULL', 1, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000080', 49, NULL, 800000, N'Khách Hàng Mua Vé 30', 'buyer30@gmail.com', 'VE-VIP-080-1', 'QR-VIP-080-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000080', 50, NULL, 250000, N'Khách Hàng Mua Vé 30', 'buyer30@gmail.com', 'VE-STD-080-2', 'QR-STD-080-2', 0, NULL, NULL);


    -- === DEMO POLISH: sự kiện Việt Nam với ảnh chụp thật được lưu local để demo ổn định. ===
    DECLARE @DemoEvents TABLE (
        Id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        TenSuKien NVARCHAR(300) NOT NULL,
        Slug VARCHAR(350) NOT NULL,
        MoTaNgan NVARCHAR(500) NOT NULL,
        AnhBia NVARCHAR(500) NOT NULL,
        NgayLech INT NOT NULL,
        GioBatDau INT NOT NULL,
        TrangThai TINYINT NOT NULL,
        NoiBat BIT NOT NULL
    );

    INSERT INTO @DemoEvents
        (Id, TenSuKien, Slug, MoTaNgan, AnhBia, NgayLech, GioBatDau, TrangThai, NoiBat)
    VALUES
    -- 1. Âm nhạc & Concert
    ('D3C3FBCE-4FFF-4F33-A4AF-0A2750C9E94E', N'WuangEvents Live 2026: Âm Sắc Thành Phố', 'wuangevents-live-2026-am-sac-thanh-pho', N'Đại nhạc hội ngoài trời quy tụ nghệ sĩ trẻ Việt Nam, khu ẩm thực và hoạt động tương tác dành cho khán giả.', '/uploads/banners/professional/real-vn-concert.jpg', 7, 19, 3, 1),
    ('E20875EC-36DB-45EB-85D1-A706DC9B62D2', N'Đêm Jazz Sài Gòn: Thanh Âm Mùa Hạ', 'dem-jazz-sai-gon-thanh-am-mua-ha', N'Đêm nhạc jazz thân mật với ban nhạc sống và những bản phối mang hơi thở Sài Gòn.', '/uploads/banners/professional/real-jazz-stage.jpg', 0, 19, 3, 1),
    ('D2C252F2-7FD4-4A02-86CB-3D9DE7415795', N'Rock Việt 2026: Bùng Cháy Đam Mê', 'rock-viet-2026-bung-chay-dam-me', N'Đêm nhạc rock Việt ngoài trời với sân khấu lớn, khu cổ vũ và nhiều hạng vé theo vị trí.', '/uploads/banners/professional/real-vn-concert.jpg', 1, 19, 3, 1),
    ('5BC842AD-6166-406A-AD93-EB3ECACFBF7E', N'Hoàng Hôn Acoustic: Những Bản Tình Ca Việt', 'hoang-hon-acoustic-nhung-ban-tinh-ca-viet', N'Không gian acoustic gần gũi với các ca khúc Việt được phối mộc và khu đồ uống nhẹ.', '/uploads/banners/professional/real-jazz-stage.jpg', -2, 18, 3, 0),
    ('9B265F0B-613C-4094-9DC8-4B74E1F42E65', N'Nhịp Trẻ Thăng Long 2026', 'nhip-tre-thang-long-2026', N'Đêm nhạc dành cho khán giả trẻ Hà Nội với sân khấu hiện đại và khu giao lưu cộng đồng.', '/uploads/banners/professional/real-vn-concert.jpg', 15, 19, 2, 0),
    ('A0A26D2F-FF2E-4175-B318-C3FCE0BA23FB', N'Hòa Nhạc Dòng Chảy Quê Hương', 'hoa-nhac-dong-chay-que-huong', N'Chương trình hòa nhạc kết hợp tác phẩm cổ điển và giai điệu Việt, hiện đang chờ quản trị viên duyệt.', '/uploads/banners/professional/real-jazz-stage.jpg', 18, 19, 1, 0),
    ('E0000000-0000-0000-0000-000000000007', N'Hồn Việt: Dân Nhạc Đương Đại', 'hon-viet-dan-nhac-duong-dai', N'Chương trình kết hợp nhạc cụ dân tộc, vũ đạo và ngôn ngữ sân khấu đương đại.', '/uploads/banners/professional/real-vietnamese-performing-arts.jpg', 5, 20, 3, 1),
    ('E0000000-0000-0000-0000-000000000008', N'Mây Trên Phố: Đêm Nhạc Indie Sài Gòn', 'may-tren-pho-dem-nhac-indie-sai-gon', N'Không gian âm nhạc gần gũi với các ban nhạc indie Việt và phần giao lưu sau chương trình.', '/uploads/banners/professional/real-jazz-stage.jpg', 10, 20, 3, 0),
    ('E0000000-0000-0000-0000-000000000009', N'Chạm Vào Mơ: Đêm Nhạc Thị Giác', 'cham-vao-mo-dem-nhac-thi-giac', N'Đêm nhạc kết hợp âm thanh, ánh sáng và khu chụp ảnh dành cho người tham dự.', '/uploads/banners/professional/real-vn-concert.jpg', 16, 19, 3, 0),
    ('E0000000-0000-0000-0000-000000000010', N'Tiếng Gọi Cao Nguyên: Đêm Rock Tây Nguyên', 'tieng-goi-cao-nguyen-dem-rock-tay-nguyen', N'Đêm rock lấy cảm hứng từ đại ngàn, kết hợp tiết tấu hiện đại và nhạc cụ Tây Nguyên.', '/uploads/banners/professional/real-vn-concert.jpg', 22, 20, 3, 0),
    -- 2. Kịch nói & Nghệ thuật
    ('E0000000-0000-0000-0000-000000000011', N'Sân Khấu Chuyện Làng Tôi', 'san-khau-chuyen-lang-toi', N'Vở diễn kể chuyện làng quê Việt Nam bằng tre, múa và âm nhạc dân gian; dữ liệu mẫu thuộc nhóm đã lưu trữ.', '/uploads/banners/professional/real-vietnamese-performing-arts.jpg', -90, 19, 5, 0),
    ('E0000000-0000-0000-0000-000000000012', N'Vũ Kịch Tây Nguyên: Tiếng Gọi Đại Ngàn', 'vu-kich-tay-nguyen-tieng-goi-dai-ngan', N'Vở diễn lấy cảm hứng từ đời sống Tây Nguyên, sử dụng chất liệu tre, cồng chiêng và vũ đạo tập thể.', '/uploads/banners/professional/real-vietnamese-performing-arts.jpg', 6, 19, 3, 1),
    ('E0000000-0000-0000-0000-000000000013', N'Triển Lãm Tương Tác: Chạm Vào Ánh Sáng', 'trien-lam-tuong-tac-cham-vao-anh-sang', N'Không gian nghệ thuật nơi người xem khám phá ánh sáng, chuyển động và các tác phẩm đa phương tiện.', '/uploads/banners/professional/real-art-gallery.jpg', 8, 18, 3, 0),
    ('E0000000-0000-0000-0000-000000000014', N'Đêm Ca Trù: Giai Âm Kinh Kỳ', 'dem-ca-tru-giai-am-kinh-ky', N'Đêm diễn giới thiệu ca trù và câu chuyện về nhạc cụ truyền thống trong không gian sân khấu gần gũi.', '/uploads/banners/professional/real-vietnamese-performing-arts.jpg', 13, 19, 3, 0),
    ('E0000000-0000-0000-0000-000000000015', N'Tuần Phim Việt: Câu Chuyện Đô Thị', 'tuan-phim-viet-cau-chuyen-do-thi', N'Chuỗi chiếu phim Việt độc lập, có phần giao lưu cùng đạo diễn và cộng đồng yêu điện ảnh.', '/uploads/banners/professional/real-art-gallery.jpg', 19, 18, 3, 0),
    ('E0000000-0000-0000-0000-000000000016', N'Xưởng Vẽ Cuối Tuần: Sắc Màu Sài Gòn', 'xuong-ve-cuoi-tuan-sac-mau-sai-gon', N'Lớp vẽ đang tạm dừng nhận đăng ký trong thời gian Ban tổ chức điều chỉnh dụng cụ và sức chứa.', '/uploads/banners/professional/real-vietnam-craft-workshop.jpg', 21, 18, 2, 0),
    ('E0000000-0000-0000-0000-000000000017', N'Sân Khấu Hồn Việt: Dòng Chảy Ba Miền', 'san-khau-hon-viet-dong-chay-ba-mien', N'Chương trình tái hiện nét văn hóa ba miền qua âm nhạc, trang phục và nghệ thuật trình diễn.', '/uploads/banners/professional/real-vietnamese-performing-arts.jpg', 28, 19, 3, 0),
    ('E0000000-0000-0000-0000-000000000018', N'Triển Lãm Tôi Là Người Việt Nam', 'trien-lam-toi-la-nguoi-viet-nam', N'Không gian nghệ thuật đương đại khai thác bản sắc Việt trong đời sống đô thị hôm nay.', '/uploads/banners/professional/real-art-gallery.jpg', 31, 19, 3, 0),
    ('E0000000-0000-0000-0000-000000000019', N'Nhạc Kịch Tuổi Trẻ: Mùa Hè Rực Rỡ', 'nhac-kich-tuoi-tre-mua-he-ruc-ro', N'Chương trình sân khấu mùa hè với hợp xướng, nhạc kịch và các tiết mục của nghệ sĩ trẻ.', '/uploads/banners/professional/real-vietnamese-performing-arts.jpg', 34, 19, 3, 0),
    ('E0000000-0000-0000-0000-000000000020', N'Ngày Hội Thủ Công: Hoa Và Gốm Việt', 'ngay-hoi-thu-cong-hoa-va-gom-viet', N'Ngày hội có lớp cắm hoa, làm gốm và khu trưng bày sản phẩm của nghệ nhân địa phương; hiện đang chờ duyệt.', '/uploads/banners/professional/real-vietnam-craft-workshop.jpg', 37, 10, 1, 0),
    -- 3. Hội thảo & Giáo dục
    ('E0000000-0000-0000-0000-000000000021', N'Diễn Đàn AI Việt Nam: Công Nghệ Cho Doanh Nghiệp', 'dien-dan-ai-viet-nam-cong-nghe-cho-doanh-nghiep', N'Hội thảo về ứng dụng AI trong doanh nghiệp Việt Nam; dữ liệu mẫu thuộc nhóm sự kiện đã lưu trữ.', '/uploads/banners/professional/real-tech-conference.jpg', -60, 8, 5, 0),
    ('E0000000-0000-0000-0000-000000000022', N'Power BI Cho Người Mới: Từ Dữ Liệu Đến Báo Cáo', 'power-bi-cho-nguoi-moi-tu-du-lieu-den-bao-cao', N'Khóa học thực hành giúp người mới tạo báo cáo trực quan từ dữ liệu bán hàng mẫu.', '/uploads/banners/professional/real-tech-conference.jpg', 7, 9, 3, 1),
    ('E0000000-0000-0000-0000-000000000023', N'Quản Trị Rủi Ro Cho Dự Án Khởi Nghiệp', 'quan-tri-rui-ro-cho-du-an-khoi-nghiep', N'Lớp chuyên đề về kiểm tra thông tin, quản lý dòng tiền và nhận diện rủi ro cho dự án mới.', '/uploads/banners/professional/real-tech-conference.jpg', 11, 9, 3, 0),
    ('E0000000-0000-0000-0000-000000000024', N'Đêm Kết Nối Khởi Nghiệp Việt', 'dem-ket-noi-khoi-nghiep-viet', N'Chương trình kết nối nhà sáng lập, cố vấn và nhà đầu tư theo từng nhu cầu hợp tác.', '/uploads/banners/professional/real-tech-conference.jpg', 14, 18, 3, 0),
    ('E0000000-0000-0000-0000-000000000025', N'Thành Phố Đáng Sống: Sáng Kiến Cho Sài Gòn', 'thanh-pho-dang-song-sang-kien-cho-sai-gon', N'Diễn đàn thảo luận các sáng kiến giao thông, không gian xanh và dịch vụ đô thị tại TP.HCM.', '/uploads/banners/professional/real-tech-conference.jpg', 18, 8, 3, 0),
    ('E0000000-0000-0000-0000-000000000026', N'Kết Nối Ngành Game Việt 2026', 'ket-noi-nganh-game-viet-2026', N'Hội nghị trực tuyến kết nối nhà phát triển, nhà phát hành và cộng đồng sáng tạo game Việt Nam.', '/uploads/banners/professional/real-tech-conference.jpg', 24, 9, 3, 0),
    ('E0000000-0000-0000-0000-000000000027', N'Ngày Hội STEM Gia Đình', 'ngay-hoi-stem-gia-dinh', N'Ngày hội khoa học với thí nghiệm an toàn, góc lắp ráp và trò chơi khám phá dành cho gia đình.', '/uploads/banners/professional/real-vietnam-craft-workshop.jpg', 27, 8, 3, 0),
    ('E0000000-0000-0000-0000-000000000028', N'Workshop Cân Bằng Áp Lực Công Việc', 'workshop-can-bang-ap-luc-cong-viec', N'Buổi thực hành kỹ thuật quản lý căng thẳng và xây dựng thói quen làm việc lành mạnh.', '/uploads/banners/professional/real-vietnam-craft-workshop.jpg', 30, 9, 3, 0),
    ('E0000000-0000-0000-0000-000000000029', N'Xưởng Hương Việt: Làm Nến Thảo Mộc', 'xuong-huong-viet-lam-nen-thao-moc', N'Lớp làm nến từ hương sả, quế và cà phê, giới hạn số lượng để mỗi người có đủ dụng cụ.', '/uploads/banners/professional/real-vietnam-craft-workshop.jpg', 33, 14, 3, 0),
    ('E0000000-0000-0000-0000-000000000030', N'Ngày Hội Đổi Sách Và Trò Chuyện Tác Giả', 'ngay-hoi-doi-sach-va-tro-chuyen-tac-gia', N'Sự kiện đổi sách và giao lưu cùng tác giả Việt, hiện đang chờ duyệt thông tin khách mời.', '/uploads/banners/professional/real-vietnam-craft-workshop.jpg', 40, 9, 1, 0),
    -- 4. Thể thao & Giải trí
    ('E0000000-0000-0000-0000-000000000031', N'Giải Chạy Đêm Sài Gòn 2026', 'giai-chay-dem-sai-gon-2026', N'Giải chạy qua các tuyến phố trung tâm với cự ly 5 km, 10 km và khu phát bộ vật phẩm theo khung giờ.', '/uploads/banners/professional/real-vietnam-running.jpg', 5, 20, 3, 1),
    ('E0000000-0000-0000-0000-000000000032', N'Giải Pickleball Phong Trào Toàn Quốc', 'giai-pickleball-phong-trao-toan-quoc', N'Giải đấu dành cho nhiều nhóm trình độ, thi đấu theo nội dung đôi nam, đôi nữ và đôi nam nữ.', '/uploads/banners/professional/real-vietnam-running.jpg', 9, 8, 3, 1),
    ('E0000000-0000-0000-0000-000000000033', N'Cúp Bóng Rổ Thành Phố 2026', 'cup-bong-ro-thanh-pho-2026', N'Giải bóng rổ có khu cổ động viên, hoạt động giữa hiệp và vé theo từng khu vực ghế.', '/uploads/banners/professional/real-saigon-basketball.jpg', 12, 19, 3, 0),
    ('E0000000-0000-0000-0000-000000000034', N'Đêm Futsal Giao Hữu Sài Gòn', 'dem-futsal-giao-huu-sai-gon', N'Đêm thi đấu futsal giao hữu giữa các câu lạc bộ phong trào với vé theo khu vực khán đài.', '/uploads/banners/professional/real-saigon-basketball.jpg', 16, 19, 3, 0),
    ('E0000000-0000-0000-0000-000000000035', N'Giải Leo Núi Trong Nhà Hà Nội', 'giai-leo-nui-trong-nha-ha-noi', N'Giải leo núi trong nhà dành cho nhiều nhóm tuổi và có khu hướng dẫn an toàn cho người mới.', '/uploads/banners/professional/real-vietnam-running.jpg', 20, 8, 3, 0),
    ('E0000000-0000-0000-0000-000000000036', N'Ba Môn Phối Hợp Biển Hồ Tràm', 'ba-mon-phoi-hop-bien-ho-tram', N'Giải bơi, đạp xe và chạy ven biển với các cự ly phù hợp cho cả vận động viên mới.', '/uploads/banners/professional/real-vietnam-running.jpg', 26, 5, 3, 0),
    ('E0000000-0000-0000-0000-000000000037', N'Võ Đài Việt: Đêm Tranh Tài 2026', 'vo-dai-viet-dem-tranh-tai-2026', N'Đêm thi đấu võ thuật với quy trình soát vé, phân khu khán đài và check-in tại cổng.', '/uploads/banners/professional/real-saigon-basketball.jpg', 30, 19, 3, 0),
    ('E0000000-0000-0000-0000-000000000038', N'Chung Kết Thể Thao Điện Tử Sinh Viên', 'chung-ket-the-thao-dien-tu-sinh-vien', N'Vòng chung kết có khu cổ vũ, gian trải nghiệm công nghệ và vé theo khu vực.', '/uploads/banners/professional/real-trade-expo.jpg', 35, 14, 3, 0),
    ('E0000000-0000-0000-0000-000000000039', N'Cúp Bóng Rổ Đà Nẵng Mở Rộng', 'cup-bong-ro-da-nang-mo-rong', N'Giải bóng rổ cộng đồng dành cho các câu lạc bộ trẻ được tổ chức tại Đà Nẵng.', '/uploads/banners/professional/real-saigon-basketball.jpg', 38, 18, 3, 0),
    ('E0000000-0000-0000-0000-000000000040', N'Ngày Hội Yoga Và Sống Khỏe', 'ngay-hoi-yoga-va-song-khoe', N'Ngày hội yoga, vận động và chăm sóc sức khỏe với số lượng đăng ký giới hạn theo từng ca.', '/uploads/banners/professional/real-vietnam-running.jpg', 41, 6, 3, 0),
    -- 5. Ẩm thực & Du lịch
    ('E0000000-0000-0000-0000-000000000041', N'Đêm Ẩm Thực Đường Phố Sài Gòn', 'dem-am-thuc-duong-pho-sai-gon', N'Hành trình khám phá món ăn đường phố buổi tối với điểm tập trung và lộ trình rõ ràng.', '/uploads/banners/professional/real-vietnam-food-festival.jpg', -21, 18, 3, 0),
    ('E0000000-0000-0000-0000-000000000042', N'Hương Vị Cố Đô: Một Trăm Món Huế', 'huong-vi-co-do-mot-tram-mon-hue', N'Ngày hội ẩm thực giới thiệu món Huế, gian hàng đặc sản và khu trình diễn nấu ăn.', '/uploads/banners/professional/real-vietnam-food-festival.jpg', -45, 18, 3, 0),
    ('E0000000-0000-0000-0000-000000000043', N'Lễ Hội Cà Phê Và Trà Việt', 'le-hoi-ca-phe-va-tra-viet', N'Không gian thưởng thức cà phê, trà Việt và giao lưu với các đơn vị rang xay trong nước.', '/uploads/banners/professional/real-vietnam-food-festival.jpg', 9, 17, 3, 0),
    ('E0000000-0000-0000-0000-000000000044', N'Bữa Tối Tinh Hoa Ẩm Thực Việt', 'bua-toi-tinh-hoa-am-thuc-viet', N'Bữa tối theo bàn giới hạn chỗ, giới thiệu thực đơn lấy cảm hứng từ nguyên liệu ba miền.', '/uploads/banners/professional/real-vietnam-food-festival.jpg', 13, 18, 3, 0),
    ('E0000000-0000-0000-0000-000000000045', N'Hoàng Hôn Trên Sông Sài Gòn', 'hoang-hon-tren-song-sai-gon', N'Chuyến trải nghiệm ngắm hoàng hôn với lịch trình, điểm lên xuống và số lượng vé hữu hạn.', '/uploads/banners/professional/real-vietnam-lantern-festival.jpg', 17, 16, 3, 0),
    ('E0000000-0000-0000-0000-000000000046', N'Một Ngày Làm Nông Dân Cà Phê Đà Lạt', 'mot-ngay-lam-nong-dan-ca-phe-da-lat', N'Chuyến tham quan nông trại và tìm hiểu quy trình từ thu hoạch hạt đến pha một ly cà phê.', '/uploads/banners/professional/real-vietnam-craft-workshop.jpg', 22, 7, 3, 0),
    ('E0000000-0000-0000-0000-000000000047', N'Xưởng Đèn Lồng Phố Hội', 'xuong-den-long-pho-hoi', N'Lớp làm đèn lồng tại Hội An với quy mô nhỏ để mỗi người tham dự có đủ dụng cụ thực hành.', '/uploads/banners/professional/real-vietnam-lantern-festival.jpg', 29, 9, 3, 0),
    ('E0000000-0000-0000-0000-000000000048', N'Ngày Hội Văn Hóa Miền Tây', 'ngay-hoi-van-hoa-mien-tay', N'Vé tham quan ngày hội có đờn ca tài tử, trò chơi dân gian và gian hàng đặc sản Nam Bộ.', '/uploads/banners/professional/real-vietnam-lantern-festival.jpg', 32, 8, 3, 0),
    ('E0000000-0000-0000-0000-000000000049', N'Lễ Hội Bánh Dân Gian Nam Bộ', 'le-hoi-banh-dan-gian-nam-bo', N'Ngày hội quy tụ các loại bánh truyền thống, khu trình diễn làm bánh và cổng check-in riêng.', '/uploads/banners/professional/real-vietnam-food-festival.jpg', 36, 17, 3, 0),
    ('E0000000-0000-0000-0000-000000000050', N'Phiên Chợ Xưa Sài Gòn', 'phien-cho-xua-sai-gon', N'Phiên chợ dành cho người yêu đồ thủ công, thời trang thiết kế và các món ăn gợi nhớ Sài Gòn xưa.', '/uploads/banners/professional/real-vietnam-lantern-festival.jpg', 39, 10, 3, 0),
    -- 6. Triển lãm & Hội chợ
    ('E0000000-0000-0000-0000-000000000051', N'Triển Lãm Cưới Việt Nam 2026', 'trien-lam-cuoi-viet-nam-2026', N'Không gian giới thiệu áo dài cưới, trang trí, chụp ảnh và dịch vụ tiệc cưới; dữ liệu mẫu đang ở trạng thái nháp.', '/uploads/banners/professional/real-trade-expo.jpg', 6, 9, 0, 0),
    ('E0000000-0000-0000-0000-000000000052', N'Ngày Hội Công Nghệ Việt 2026', 'ngay-hoi-cong-nghe-viet-2026', N'Hồ sơ ngày hội công nghệ đang chờ quản trị viên xem xét trước khi công khai và mở bán vé.', '/uploads/banners/professional/real-trade-expo.jpg', 10, 9, 1, 0),
    ('E0000000-0000-0000-0000-000000000053', N'Hội Chợ Sống Xanh Việt Nam', 'hoi-cho-song-xanh-viet-nam', N'Hội chợ giới thiệu sản phẩm bền vững, lớp tái chế và các doanh nghiệp xanh trong nước.', '/uploads/banners/professional/real-trade-expo.jpg', 15, 9, 3, 1),
    ('E0000000-0000-0000-0000-000000000054', N'Tuần Lễ Thời Trang Việt Trẻ', 'tuan-le-thoi-trang-viet-tre', N'Sự kiện mua sắm và trình diễn thời trang đang tạm dừng bán vé để Ban tổ chức cấu hình sơ đồ chỗ ngồi trước khi mở bán.', '/uploads/banners/professional/real-art-gallery.jpg', 18, 10, 2, 0),
    ('E0000000-0000-0000-0000-000000000055', N'Triển Lãm Xe Điện Và Di Chuyển Xanh', 'trien-lam-xe-dien-va-di-chuyen-xanh', N'Không gian giới thiệu xe điện, giải pháp sạc và xu hướng giao thông đô thị trong tương lai.', '/uploads/banners/professional/real-trade-expo.jpg', 23, 8, 3, 0),
    ('E0000000-0000-0000-0000-000000000056', N'Diễn Đàn Du Lịch Hàng Không Việt Nam', 'dien-dan-du-lich-hang-khong-viet-nam', N'Diễn đàn về vận hành, dịch vụ hành khách và kết nối các điểm đến trong nước; dữ liệu mẫu thuộc nhóm đã hủy.', '/uploads/banners/professional/real-tech-conference.jpg', 27, 9, 6, 0),
    ('E0000000-0000-0000-0000-000000000057', N'Tuần Lễ Áo Dài Việt Nam', 'tuan-le-ao-dai-viet-nam', N'Chương trình trình diễn áo dài và giao lưu nhà thiết kế; hồ sơ mẫu bị từ chối vì thiếu phương án an toàn.', '/uploads/banners/professional/real-vietnamese-performing-arts.jpg', 31, 18, 7, 0),
    ('E0000000-0000-0000-0000-000000000058', N'Ngày Hội Thú Cưng Thành Phố', 'ngay-hoi-thu-cung-thanh-pho', N'Ngày hội có khu tư vấn chăm sóc, cuộc thi nhỏ và hoạt động trải nghiệm dành cho gia đình.', '/uploads/banners/professional/real-trade-expo.jpg', 34, 8, 3, 0),
    ('E0000000-0000-0000-0000-000000000059', N'Ngày Hội Sản Phẩm Việt Và Làng Nghề', 'ngay-hoi-san-pham-viet-va-lang-nghe', N'Không gian giới thiệu sản phẩm Việt, khu gặp gỡ nghệ nhân và các gian trải nghiệm thủ công.', '/uploads/banners/professional/real-trade-expo.jpg', 37, 18, 3, 0),
    ('E0000000-0000-0000-0000-000000000060', N'Chuỗi Workshop Tết Việt', 'chuoi-workshop-tet-viet', N'Chuỗi lớp gói bánh, làm đồ trang trí và viết thư pháp với nhiều khung giờ giới hạn theo lớp.', '/uploads/banners/professional/real-vietnam-craft-workshop.jpg', 43, 9, 3, 0);

    UPDATE sk
    SET sk.TenSuKien = e.TenSuKien,
        sk.Slug = e.Slug,
        sk.MoTaNgan = e.MoTaNgan,
        sk.MoTaChiTiet = N'<p>' + e.MoTaNgan + N'</p>',
        sk.AnhBia = e.AnhBia,
        sk.AnhThumbnail = e.AnhBia,
        sk.NgayBatDau = DATEADD(hour, e.GioBatDau, CONVERT(DATETIME2(7), DATEADD(day, e.NgayLech, CONVERT(date, DATEADD(hour, 7, GETUTCDATE()))))),
        sk.NgayKetThuc = DATEADD(hour, 3, DATEADD(hour, e.GioBatDau, CONVERT(DATETIME2(7), DATEADD(day, e.NgayLech, CONVERT(date, DATEADD(hour, 7, GETUTCDATE())))))),
        sk.TrangThai = e.TrangThai,
        sk.NoiBat = e.NoiBat,
        sk.HienThiCongKhai = CASE WHEN e.TrangThai IN (2, 3, 5, 6) THEN 1 ELSE 0 END,
        sk.LyDoTuChoi = CASE WHEN e.TrangThai = 7 THEN N'Chưa bổ sung đủ hồ sơ pháp lý và phương án đảm bảo an toàn cho người tham dự.' ELSE NULL END,
        sk.NgayCapNhat = GETUTCDATE(),
        sk.TenDiaDiem = CASE sk.DanhMucId
            WHEN 1 THEN N'Nhà văn hóa Thanh Niên'
            WHEN 2 THEN N'Nhà hát Bến Thành'
            WHEN 3 THEN N'Trung tâm Hội nghị GEM Center'
            WHEN 4 THEN N'Nhà thi đấu Nguyễn Du'
            WHEN 5 THEN N'Phố đi bộ Nguyễn Huệ'
            ELSE N'Trung tâm Triển lãm SECC' END,
        sk.DiaChiDiaDiem = CASE sk.DanhMucId
            WHEN 1 THEN N'4 Phạm Ngọc Thạch'
            WHEN 2 THEN N'6D Mạc Đĩnh Chi'
            WHEN 3 THEN N'8 Nguyễn Bỉnh Khiêm, Phường Đa Kao'
            WHEN 4 THEN N'116 Nguyễn Du, Phường Bến Thành'
            WHEN 5 THEN N'Đường Nguyễn Huệ, Phường Bến Nghé'
            ELSE N'799 Nguyễn Văn Linh, Phường Tân Phú' END,
        sk.ThanhPhoDiaDiem = N'Hồ Chí Minh',
        sk.QuanHuyenDiaDiem = CASE sk.DanhMucId WHEN 6 THEN N'Quận 7' ELSE N'Quận 1' END,
        sk.SucChuaDiaDiem = CASE sk.DanhMucId WHEN 1 THEN 2500 WHEN 2 THEN 800 WHEN 3 THEN 1200 WHEN 4 THEN 3000 WHEN 5 THEN 500 ELSE 5000 END
    FROM dbo.SuKien sk
    INNER JOIN @DemoEvents e ON e.Id = sk.Id;

    -- Gắn ảnh chụp thật đã tải local theo từng nhóm sự kiện.
    UPDATE sk
    SET sk.AnhBia = b.Anh,
        sk.AnhThumbnail = b.Anh
    FROM dbo.SuKien sk
    CROSS APPLY (VALUES (
        CASE
            -- Âm nhạc.
            WHEN sk.Id IN ('E20875EC-36DB-45EB-85D1-A706DC9B62D2', '5BC842AD-6166-406A-AD93-EB3ECACFBF7E', 'A0A26D2F-FF2E-4175-B318-C3FCE0BA23FB', 'E0000000-0000-0000-0000-000000000008')
                THEN N'/uploads/banners/professional/real-jazz-stage.jpg'
            WHEN sk.Id = 'E0000000-0000-0000-0000-000000000007'
                THEN N'/uploads/banners/professional/real-vietnamese-performing-arts.jpg'
            WHEN sk.DanhMucId = 1
                THEN N'/uploads/banners/professional/real-vn-concert.jpg'

            -- Kịch, biểu diễn, triển lãm và workshop nghệ thuật.
            WHEN sk.Id IN ('E0000000-0000-0000-0000-000000000011', 'E0000000-0000-0000-0000-000000000012', 'E0000000-0000-0000-0000-000000000014', 'E0000000-0000-0000-0000-000000000017', 'E0000000-0000-0000-0000-000000000019')
                THEN N'/uploads/banners/professional/real-vietnamese-performing-arts.jpg'
            WHEN sk.Id IN ('E0000000-0000-0000-0000-000000000016', 'E0000000-0000-0000-0000-000000000020')
                THEN N'/uploads/banners/professional/real-vietnam-craft-workshop.jpg'
            WHEN sk.DanhMucId = 2
                THEN N'/uploads/banners/professional/real-art-gallery.jpg'

            -- Hội thảo và workshop thực hành.
            WHEN sk.Id IN ('E0000000-0000-0000-0000-000000000022', 'E0000000-0000-0000-0000-000000000027', 'E0000000-0000-0000-0000-000000000028', 'E0000000-0000-0000-0000-000000000029', 'E0000000-0000-0000-0000-000000000030')
                THEN N'/uploads/banners/professional/real-vietnam-craft-workshop.jpg'
            WHEN sk.DanhMucId = 3
                THEN N'/uploads/banners/professional/real-tech-conference.jpg'

            -- Thể thao.
            WHEN sk.Id IN ('E0000000-0000-0000-0000-000000000033', 'E0000000-0000-0000-0000-000000000034', 'E0000000-0000-0000-0000-000000000037', 'E0000000-0000-0000-0000-000000000039')
                THEN N'/uploads/banners/professional/real-saigon-basketball.jpg'
            WHEN sk.Id = 'E0000000-0000-0000-0000-000000000038'
                THEN N'/uploads/banners/professional/real-trade-expo.jpg'
            WHEN sk.DanhMucId = 4
                THEN N'/uploads/banners/professional/real-vietnam-running.jpg'

            -- Ẩm thực và trải nghiệm văn hóa.
            WHEN sk.Id = 'E0000000-0000-0000-0000-000000000046'
                THEN N'/uploads/banners/professional/real-vietnam-craft-workshop.jpg'
            WHEN sk.Id IN ('E0000000-0000-0000-0000-000000000045', 'E0000000-0000-0000-0000-000000000047', 'E0000000-0000-0000-0000-000000000048', 'E0000000-0000-0000-0000-000000000050')
                THEN N'/uploads/banners/professional/real-vietnam-lantern-festival.jpg'
            WHEN sk.DanhMucId = 5
                THEN N'/uploads/banners/professional/real-vietnam-food-festival.jpg'

            -- Hội chợ, thời trang và workshop.
            WHEN sk.Id = 'E0000000-0000-0000-0000-000000000060'
                THEN N'/uploads/banners/professional/real-vietnam-craft-workshop.jpg'
            WHEN sk.Id = 'E0000000-0000-0000-0000-000000000054'
                THEN N'/uploads/banners/professional/real-art-gallery.jpg'
            WHEN sk.Id = 'E0000000-0000-0000-0000-000000000057'
                THEN N'/uploads/banners/professional/real-vietnamese-performing-arts.jpg'
            ELSE N'/uploads/banners/professional/real-trade-expo.jpg'
        END
    )) b(Anh);

    -- Một số thành phố khác nhau giúp bộ lọc địa điểm có dữ liệu thật để trình diễn.
    UPDATE dbo.SuKien
    SET ThanhPhoDiaDiem = N'Hà Nội', QuanHuyenDiaDiem = N'Quận Hoàn Kiếm', TenDiaDiem = N'Cung Văn hóa Hữu nghị Việt Xô', DiaChiDiaDiem = N'91 Trần Hưng Đạo'
    WHERE Id IN ('9B265F0B-613C-4094-9DC8-4B74E1F42E65', 'E0000000-0000-0000-0000-000000000057');

    UPDATE dbo.SuKien
    SET ThanhPhoDiaDiem = N'Hà Nội', QuanHuyenDiaDiem = N'Quận Cầu Giấy', TenDiaDiem = N'Nhà thi đấu Cầu Giấy', DiaChiDiaDiem = N'35 Trần Quý Kiên'
    WHERE Id = 'E0000000-0000-0000-0000-000000000035';

    UPDATE dbo.SuKien
    SET ThanhPhoDiaDiem = N'Đà Nẵng', QuanHuyenDiaDiem = N'Quận Hải Châu', TenDiaDiem = N'Cung Thể thao Tiên Sơn', DiaChiDiaDiem = N'Đường Phan Đăng Lưu'
    WHERE Id = 'E0000000-0000-0000-0000-000000000039';

    UPDATE dbo.SuKien
    SET ThanhPhoDiaDiem = N'Hội An', QuanHuyenDiaDiem = N'Thành phố Hội An', TenDiaDiem = N'Không gian thủ công Phố Hội', DiaChiDiaDiem = N'Đường Nguyễn Thái Học'
    WHERE Id = 'E0000000-0000-0000-0000-000000000047';

    UPDATE dbo.SuKien
    SET ThanhPhoDiaDiem = N'Huế', QuanHuyenDiaDiem = N'Quận Thuận Hóa', TenDiaDiem = N'Công viên Thương Bạc', DiaChiDiaDiem = N'Đường Trần Hưng Đạo'
    WHERE Id = 'E0000000-0000-0000-0000-000000000042';

    UPDATE dbo.SuKien
    SET ThanhPhoDiaDiem = N'Đà Lạt', QuanHuyenDiaDiem = N'Thành phố Đà Lạt', TenDiaDiem = N'Nông trại cà phê Cầu Đất', DiaChiDiaDiem = N'Xã Xuân Trường'
    WHERE Id = 'E0000000-0000-0000-0000-000000000046';

    UPDATE dbo.SuKien
    SET ThanhPhoDiaDiem = N'Bà Rịa - Vũng Tàu', QuanHuyenDiaDiem = N'Huyện Xuyên Mộc', TenDiaDiem = N'Bãi biển Hồ Tràm', DiaChiDiaDiem = N'Đường ven biển Hồ Tràm'
    WHERE Id = 'E0000000-0000-0000-0000-000000000036';

    UPDATE dbo.SuKien
    SET ThanhPhoDiaDiem = N'Cần Thơ', QuanHuyenDiaDiem = N'Quận Ninh Kiều', TenDiaDiem = N'Công viên Bến Ninh Kiều', DiaChiDiaDiem = N'Đường Hai Bà Trưng'
    WHERE Id IN ('E0000000-0000-0000-0000-000000000048', 'E0000000-0000-0000-0000-000000000049');

    -- Sự kiện online minh họa nhánh nghiệp vụ không có địa điểm vật lý.
    UPDATE dbo.SuKien
    SET LoaiSuKien = 1, LinkOnline = NULL, TenDiaDiem = NULL, DiaChiDiaDiem = NULL, ThanhPhoDiaDiem = NULL, QuanHuyenDiaDiem = NULL, SucChuaDiaDiem = 1000
    WHERE Id = 'E0000000-0000-0000-0000-000000000026';

    -- Ba mốc thời gian đặc biệt để demo logic check-in: mở sớm, chưa mở và đã kết thúc.
    -- StaffController so sánh với giờ Việt Nam (UTC+7), nên mốc custom dưới đây cũng được lưu theo giờ Việt Nam.
    UPDATE dbo.SuKien
    SET NgayBatDau = DATEADD(hour, 5, DATEADD(hour, 7, GETUTCDATE())),
        NgayKetThuc = DATEADD(hour, 8, DATEADD(hour, 7, GETUTCDATE())),
        BatDauCheckIn = DATEADD(hour, -1, DATEADD(hour, 7, GETUTCDATE())),
        KetThucCheckIn = DATEADD(hour, 10, DATEADD(hour, 7, GETUTCDATE()))
    WHERE Id = 'E20875EC-36DB-45EB-85D1-A706DC9B62D2';

    UPDATE dbo.SuKien
    SET NgayBatDau = DATEADD(day, 1, DATEADD(hour, 7, GETUTCDATE())),
        NgayKetThuc = DATEADD(hour, 3, DATEADD(day, 1, DATEADD(hour, 7, GETUTCDATE()))),
        BatDauCheckIn = DATEADD(hour, 20, DATEADD(hour, 7, GETUTCDATE())),
        KetThucCheckIn = DATEADD(hour, 30, DATEADD(hour, 7, GETUTCDATE()))
    WHERE Id = 'D2C252F2-7FD4-4A02-86CB-3D9DE7415795';

    UPDATE dbo.SuKien
    SET NgayBatDau = DATEADD(day, -2, DATEADD(hour, 7, GETUTCDATE())),
        NgayKetThuc = DATEADD(day, -1, DATEADD(hour, 7, GETUTCDATE())),
        BatDauCheckIn = DATEADD(day, -2, DATEADD(hour, 6, GETUTCDATE())),
        KetThucCheckIn = DATEADD(day, -1, DATEADD(hour, 7, GETUTCDATE()))
    WHERE Id = '5BC842AD-6166-406A-AD93-EB3ECACFBF7E';

    -- Chỉ sự kiện đang bán (trạng thái 3) có loại vé đang hoạt động.
    UPDATE lv
    SET -- Dữ liệu demo cần mở bán ngay khi seed, kể cả sự kiện diễn ra sau hơn 30 ngày.
        -- Sự kiện đã qua vẫn giữ khung bán cũ để bảo đảm thời điểm kết thúc > bắt đầu.
        lv.NgayBatDauBan = CASE
            WHEN sk.TrangThai = 3 AND sk.NgayKetThuc > DATEADD(hour, 7, GETUTCDATE())
                THEN DATEADD(day, -30, DATEADD(hour, 7, GETUTCDATE()))
            ELSE DATEADD(day, -30, sk.NgayBatDau)
        END,
        lv.NgayKetThucBan = DATEADD(hour, -1, sk.NgayBatDau),
        -- Loại vé của bản nháp/chờ duyệt vẫn phải hợp lệ để BTC hoàn tất sơ đồ rồi gửi duyệt.
        -- Việc khách có mua được hay không luôn do trạng thái sự kiện quyết định.
        lv.TrangThai = CASE WHEN sk.TrangThai IN (0, 1, 2, 3, 7)
                                  AND sk.NgayKetThuc > DATEADD(hour, 7, GETUTCDATE())
                             THEN 1 ELSE 0 END
    FROM dbo.LoaiVe lv
    INNER JOIN dbo.SuKien sk ON sk.Id = lv.SuKienId;

    -- Đơn chờ thanh toán quá hạn phải trở thành đơn hủy: đây là ràng buộc tránh giữ vé vô thời hạn.
    UPDATE dbo.DonHang
    SET TrangThai = 2, NgayCapNhat = GETUTCDATE(), MaGiaoDich = NULL, NgayThanhToan = NULL
    WHERE TrangThai = 0;

    UPDATE ct
    SET TrangThaiCheckin = 2, NgayCheckin = NULL, NguoiCheckinId = NULL
    FROM dbo.ChiTietDonHang ct
    INNER JOIN dbo.DonHang dh ON dh.Id = ct.DonHangId
    WHERE dh.TrangThai = 2;

    -- Đồng bộ bộ đếm của loại vé với dữ liệu chi tiết đơn hàng, tránh số liệu minh họa mâu thuẫn.
    ;WITH TicketCounts AS (
        SELECT lv.Id,
               SUM(CASE WHEN dh.TrangThai = 1 THEN 1 ELSE 0 END) AS DaBan,
               SUM(CASE WHEN dh.TrangThai = 0 THEN 1 ELSE 0 END) AS DangGiu
        FROM dbo.LoaiVe lv
        LEFT JOIN dbo.ChiTietDonHang ct ON ct.LoaiVeId = lv.Id
        LEFT JOIN dbo.DonHang dh ON dh.Id = ct.DonHangId
        GROUP BY lv.Id
    )
    UPDATE lv
    SET lv.SoLuongDaBan = ISNULL(tc.DaBan, 0),
        lv.SoLuongGiuCho = ISNULL(tc.DangGiu, 0),
        lv.SoLuongTong = CASE WHEN lv.SoLuongTong < ISNULL(tc.DaBan, 0) + ISNULL(tc.DangGiu, 0) + 30
                               THEN ISNULL(tc.DaBan, 0) + ISNULL(tc.DangGiu, 0) + 30
                               ELSE lv.SoLuongTong END
    FROM dbo.LoaiVe lv
    INNER JOIN TicketCounts tc ON tc.Id = lv.Id;

    -- Hai sơ đồ ghế lớn để màn hình chọn ghế có dữ liệu trực quan khi trình bày.
    -- Sự kiện bóng rổ dùng 4 hạng vé để chứng minh sơ đồ không bị giới hạn Thường/VIP.
    INSERT INTO dbo.LoaiVe (SuKienId, TenLoaiVe, MoTa, GiaBan, SoLuongTong,
        SoLuongDaBan, SoLuongGiuCho, GioiHanMoiDon, NgayBatDauBan,
        NgayKetThucBan, ThuTuHienThi, MauSac, TrangThai)
    VALUES
        ('E0000000-0000-0000-0000-000000000033', N'Courtside', N'Hàng sát sân, lối vào riêng và quà lưu niệm.', 1500000, 20, 0, 0, 4, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 0, '#DC2626', 1),
        ('E0000000-0000-0000-0000-000000000033', N'Premium', N'Khán đài trung tâm, góc nhìn trực diện.', 550000, 30, 0, 0, 6, GETUTCDATE(), DATEADD(day, 30, GETUTCDATE()), 2, '#F59E0B', 1);

    DECLARE @SoDoBongRo INT, @SoDoVoThuat INT;
    DECLARE @VeCourtsideBongRo INT, @VeVipBongRo INT, @VePremiumBongRo INT, @VeThuongBongRo INT;
    DECLARE @VeVipVoThuat INT, @VeThuongVoThuat INT;
    DECLARE @KhuVipA INT, @KhuVipB INT, @KhuThuongC INT, @KhuThuongD INT;
    DECLARE @HangVipA INT, @HangVipB INT, @HangThuongC INT, @HangThuongD INT;

    SELECT @VeCourtsideBongRo = Id FROM dbo.LoaiVe WHERE SuKienId = 'E0000000-0000-0000-0000-000000000033' AND TenLoaiVe = N'Courtside';
    SELECT @VePremiumBongRo = Id FROM dbo.LoaiVe WHERE SuKienId = 'E0000000-0000-0000-0000-000000000033' AND TenLoaiVe = N'Premium';
    SELECT TOP (1) @VeVipBongRo = Id FROM dbo.LoaiVe WHERE SuKienId = 'E0000000-0000-0000-0000-000000000033' AND TenLoaiVe = N'Vé VIP' ORDER BY Id;
    SELECT TOP (1) @VeThuongBongRo = Id FROM dbo.LoaiVe WHERE SuKienId = 'E0000000-0000-0000-0000-000000000033' AND TenLoaiVe = N'Vé Thường' ORDER BY Id;
    INSERT INTO dbo.SoDoChoNgoi (SuKienId, TenSoDo, LoaiSoDo, NgayTao)
    VALUES ('E0000000-0000-0000-0000-000000000033', N'Sơ đồ khán đài Cúp Bóng Rổ Thành Phố', N'arena', GETUTCDATE());
    SET @SoDoBongRo = CONVERT(INT, SCOPE_IDENTITY());

    INSERT INTO dbo.KhuVuc (SoDoChoNgoiId, LoaiVeId, TenKhuVuc, MauSac, ViTriX, ViTriY, ThuTu) VALUES (@SoDoBongRo, @VeCourtsideBongRo, N'Courtside A', '#DC2626', 10, 10, 0);
    SET @KhuVipA = CONVERT(INT, SCOPE_IDENTITY());
    INSERT INTO dbo.KhuVuc (SoDoChoNgoiId, LoaiVeId, TenKhuVuc, MauSac, ViTriX, ViTriY, ThuTu) VALUES (@SoDoBongRo, @VeVipBongRo, N'Khán đài VIP B', '#7C3AED', 10, 35, 1);
    SET @KhuVipB = CONVERT(INT, SCOPE_IDENTITY());
    INSERT INTO dbo.KhuVuc (SoDoChoNgoiId, LoaiVeId, TenKhuVuc, MauSac, ViTriX, ViTriY, ThuTu) VALUES (@SoDoBongRo, @VePremiumBongRo, N'Khán đài Premium C', '#F59E0B', 10, 60, 2);
    SET @KhuThuongC = CONVERT(INT, SCOPE_IDENTITY());
    INSERT INTO dbo.KhuVuc (SoDoChoNgoiId, LoaiVeId, TenKhuVuc, MauSac, ViTriX, ViTriY, ThuTu) VALUES (@SoDoBongRo, @VeThuongBongRo, N'Khán đài Thường D', '#2563EB', 10, 90, 3);
    SET @KhuThuongD = CONVERT(INT, SCOPE_IDENTITY());

    INSERT INTO dbo.HangGhe (KhuVucId, TenHang, SoGhe, ThuTu) VALUES (@KhuVipA, N'A', 20, 0); SET @HangVipA = CONVERT(INT, SCOPE_IDENTITY());
    INSERT INTO dbo.HangGhe (KhuVucId, TenHang, SoGhe, ThuTu) VALUES (@KhuVipB, N'B', 20, 0); SET @HangVipB = CONVERT(INT, SCOPE_IDENTITY());
    INSERT INTO dbo.HangGhe (KhuVucId, TenHang, SoGhe, ThuTu) VALUES (@KhuThuongC, N'C', 30, 0); SET @HangThuongC = CONVERT(INT, SCOPE_IDENTITY());
    INSERT INTO dbo.HangGhe (KhuVucId, TenHang, SoGhe, ThuTu) VALUES (@KhuThuongD, N'D', 30, 0); SET @HangThuongD = CONVERT(INT, SCOPE_IDENTITY());

    ;WITH So20 AS (SELECT TOP (20) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS So FROM sys.all_objects),
          So30 AS (SELECT TOP (30) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS So FROM sys.all_objects)
    INSERT INTO dbo.ChoNgoi (HangGheId, SoGhe, ViTriX, ViTriY, TrangThai)
    SELECT @HangVipA, CONCAT(N'A', So), 20 + (So - 1) * 20, 20, 0 FROM So20
    UNION ALL SELECT @HangVipB, CONCAT(N'B', So), 20 + (So - 1) * 20, 45, 0 FROM So20
    UNION ALL SELECT @HangThuongC, CONCAT(N'C', So), 20 + (So - 1) * 15, 75, 0 FROM So30
    UNION ALL SELECT @HangThuongD, CONCAT(N'D', So), 20 + (So - 1) * 15, 105, 0 FROM So30;

    SELECT TOP (1) @VeVipVoThuat = Id FROM dbo.LoaiVe WHERE SuKienId = 'E0000000-0000-0000-0000-000000000037' ORDER BY ThuTuHienThi, Id;
    SELECT TOP (1) @VeThuongVoThuat = Id FROM dbo.LoaiVe WHERE SuKienId = 'E0000000-0000-0000-0000-000000000037' ORDER BY ThuTuHienThi DESC, Id DESC;
    INSERT INTO dbo.SoDoChoNgoi (SuKienId, TenSoDo, LoaiSoDo, NgayTao)
    VALUES ('E0000000-0000-0000-0000-000000000037', N'Sơ đồ khán đài Lion Championship 33', N'arena', GETUTCDATE());
    SET @SoDoVoThuat = CONVERT(INT, SCOPE_IDENTITY());

    INSERT INTO dbo.KhuVuc (SoDoChoNgoiId, LoaiVeId, TenKhuVuc, MauSac, ViTriX, ViTriY, ThuTu) VALUES (@SoDoVoThuat, @VeVipVoThuat, N'Ringside VIP', '#DC2626', 10, 10, 0);
    SET @KhuVipA = CONVERT(INT, SCOPE_IDENTITY());
    INSERT INTO dbo.KhuVuc (SoDoChoNgoiId, LoaiVeId, TenKhuVuc, MauSac, ViTriX, ViTriY, ThuTu) VALUES (@SoDoVoThuat, @VeVipVoThuat, N'Premium VIP', '#F59E0B', 10, 35, 1);
    SET @KhuVipB = CONVERT(INT, SCOPE_IDENTITY());
    INSERT INTO dbo.KhuVuc (SoDoChoNgoiId, LoaiVeId, TenKhuVuc, MauSac, ViTriX, ViTriY, ThuTu) VALUES (@SoDoVoThuat, @VeThuongVoThuat, N'Khán đài C', '#16A34A', 10, 60, 2);
    SET @KhuThuongC = CONVERT(INT, SCOPE_IDENTITY());
    INSERT INTO dbo.KhuVuc (SoDoChoNgoiId, LoaiVeId, TenKhuVuc, MauSac, ViTriX, ViTriY, ThuTu) VALUES (@SoDoVoThuat, @VeThuongVoThuat, N'Khán đài D', '#16A34A', 10, 90, 3);
    SET @KhuThuongD = CONVERT(INT, SCOPE_IDENTITY());

    INSERT INTO dbo.HangGhe (KhuVucId, TenHang, SoGhe, ThuTu) VALUES (@KhuVipA, N'R', 20, 0); SET @HangVipA = CONVERT(INT, SCOPE_IDENTITY());
    INSERT INTO dbo.HangGhe (KhuVucId, TenHang, SoGhe, ThuTu) VALUES (@KhuVipB, N'P', 20, 0); SET @HangVipB = CONVERT(INT, SCOPE_IDENTITY());
    INSERT INTO dbo.HangGhe (KhuVucId, TenHang, SoGhe, ThuTu) VALUES (@KhuThuongC, N'C', 30, 0); SET @HangThuongC = CONVERT(INT, SCOPE_IDENTITY());
    INSERT INTO dbo.HangGhe (KhuVucId, TenHang, SoGhe, ThuTu) VALUES (@KhuThuongD, N'D', 30, 0); SET @HangThuongD = CONVERT(INT, SCOPE_IDENTITY());

    ;WITH So20 AS (SELECT TOP (20) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS So FROM sys.all_objects),
          So30 AS (SELECT TOP (30) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS So FROM sys.all_objects)
    INSERT INTO dbo.ChoNgoi (HangGheId, SoGhe, ViTriX, ViTriY, TrangThai)
    SELECT @HangVipA, CONCAT(N'R', So), 20 + (So - 1) * 20, 20, 0 FROM So20
    UNION ALL SELECT @HangVipB, CONCAT(N'P', So), 20 + (So - 1) * 20, 45, 0 FROM So20
    UNION ALL SELECT @HangThuongC, CONCAT(N'C', So), 20 + (So - 1) * 15, 75, 0 FROM So30
    UNION ALL SELECT @HangThuongD, CONCAT(N'D', So), 20 + (So - 1) * 15, 105, 0 FROM So30;

    UPDATE dbo.SuKien
    SET CoSoDoChoNgoi = 1
    WHERE Id IN ('D3C3FBCE-4FFF-4F33-A4AF-0A2750C9E94E', 'E0000000-0000-0000-0000-000000000033', 'E0000000-0000-0000-0000-000000000037');

    -- Đồng bộ trạng thái ghế với vé đã thanh toán. Ghế trống = 0, ghế đã bán = 2.
    UPDATE dbo.ChoNgoi SET TrangThai = 0;
    UPDATE cn
    SET cn.TrangThai = 2
    FROM dbo.ChoNgoi cn
    INNER JOIN dbo.ChiTietDonHang ct ON ct.ChoNgoiId = cn.Id
    INNER JOIN dbo.DonHang dh ON dh.Id = ct.DonHangId
    WHERE dh.TrangThai = 1;

    -- Một số vé ở sự kiện đã kết thúc được check-in để có số liệu cho màn hình Staff.
    ;WITH VeDaCheckIn AS (
        SELECT TOP (6) ct.Id
        FROM dbo.ChiTietDonHang ct
        INNER JOIN dbo.DonHang dh ON dh.Id = ct.DonHangId
        WHERE dh.SuKienId = '5BC842AD-6166-406A-AD93-EB3ECACFBF7E'
          AND dh.TrangThai = 1
        ORDER BY ct.Id
    )
    UPDATE ct
    SET TrangThaiCheckin = 1,
        NgayCheckin = DATEADD(day, -2, GETUTCDATE()),
        NguoiCheckinId = '706BEA74-E775-460F-8E3B-74BBFA81A5CF'
    FROM dbo.ChiTietDonHang ct
    INNER JOIN VeDaCheckIn v ON v.Id = ct.Id;

    -- Số lượt dùng mã giảm giá chỉ tính các đơn đã thanh toán; riêng OUTOFSTOCK cố ý đầy lượt để demo ràng buộc.
    ;WITH VoucherCounts AS (
        SELECT mg.Id, COUNT(dh.Id) AS DaDung
        FROM dbo.MaGiamGia mg
        LEFT JOIN dbo.DonHang dh ON dh.MaGiamGiaId = mg.Id AND dh.TrangThai = 1
        GROUP BY mg.Id
    )
    UPDATE mg
    SET mg.SoLuongDaDung = ISNULL(vc.DaDung, 0)
    FROM dbo.MaGiamGia mg
    INNER JOIN VoucherCounts vc ON vc.Id = mg.Id;

    UPDATE dbo.MaGiamGia
    SET SoLuongDaDung = SoLuongTong
    WHERE MaCode = 'OUTOFSTOCK';

    -- === MA TRẬN DEMO: bảo đảm các màn lọc đều có dữ liệu để trình bày. ===

    -- Admin: có tài khoản bị khóa, yêu cầu BTC chờ duyệt và yêu cầu đã từ chối.
    UPDATE dbo.NguoiDung
    SET YeuCauBanToChuc = 1,
        SdtBanToChuc = SoDienThoai,
        TenToChuc = N'Thành Đạt Event Studio',
        LoaiChuTheBTC = 0,
        MoTaYeuCauBTC = N'Tổ chức workshop sáng tạo và các đêm nhạc acoustic quy mô nhỏ tại Thành phố Hồ Chí Minh.',
        DaDongYDieuKhoanBTC = 1,
        NgayYeuCauBTC = DATEADD(day, -1, GETUTCDATE()),
        LyDoTuChoiBTC = NULL
    WHERE Id = 'A0000000-0000-0000-0000-000000000039';

    UPDATE dbo.NguoiDung
    SET YeuCauBanToChuc = 3,
        SdtBanToChuc = SoDienThoai,
        TenToChuc = N'Hải Yến Community',
        LoaiChuTheBTC = 0,
        MoTaYeuCauBTC = N'Tổ chức hoạt động kết nối cộng đồng và hội chợ cuối tuần.',
        DaDongYDieuKhoanBTC = 1,
        NgayYeuCauBTC = DATEADD(day, -8, GETUTCDATE()),
        LyDoTuChoiBTC = N'Hồ sơ chưa có thông tin tài khoản nhận thanh toán.'
    WHERE Id = 'A0000000-0000-0000-0000-000000000038';

    UPDATE dbo.NguoiDung
    SET TrangThai = 0,
        NgayCapNhat = GETUTCDATE()
    WHERE Id = 'A0000000-0000-0000-0000-000000000040';

    INSERT INTO dbo.DanhMuc (TenDanhMuc, MoTa, Icon, ThuTu, TrangThai)
    VALUES (N'Sự kiện nội bộ', N'Hoạt động dành riêng cho thành viên và đối tác được mời.', 'fas fa-lock', 99, 0);

    -- Tên người và doanh nghiệp tự nhiên cho các màn tài khoản, đơn hàng và check-in.
    DECLARE @DemoUserNames TABLE (Email varchar(256) PRIMARY KEY, HoTen nvarchar(100));
    INSERT INTO @DemoUserNames (Email, HoTen)
    VALUES
        ('admin@gmail.com', N'Nguyễn Vĩnh Quang'),
        ('organizer1@gmail.com', N'Wuang Events Production'),
        ('organizer2@gmail.com', N'Saigon Live Entertainment'),
        ('organizer3@gmail.com', N'Storm Music Vietnam'),
        ('organizer4@gmail.com', N'Sunset Creative Studio'),
        ('organizer5@gmail.com', N'Nhịp Trẻ Thăng Long'),
        ('organizer6@gmail.com', N'Vietnam Classical Arts'),
        ('organizer7@gmail.com', N'Lotus Stage Company'),
        ('organizer8@gmail.com', N'Heritage Show Vietnam'),
        ('organizer9@gmail.com', N'Urban Culture Hub'),
        ('organizer10@gmail.com', N'Future Connect Events'),
        ('battlegrounds2004@gmail.com', N'Nguyễn Minh Anh'),
        ('buyer2@gmail.com', N'Trần Gia Hân'),
        ('buyer3@gmail.com', N'Lê Quốc Bảo'),
        ('buyer4@gmail.com', N'Phạm Khánh Linh'),
        ('buyer5@gmail.com', N'Hoàng Đức Minh'),
        ('buyer6@gmail.com', N'Võ Ngọc Mai'),
        ('buyer7@gmail.com', N'Đặng Tuấn Kiệt'),
        ('buyer8@gmail.com', N'Bùi Thanh Hà'),
        ('buyer9@gmail.com', N'Đỗ Hải Nam'),
        ('buyer10@gmail.com', N'Nguyễn Yến Nhi'),
        ('buyer11@gmail.com', N'Trần Minh Khang'),
        ('buyer12@gmail.com', N'Lê Bảo Ngọc'),
        ('buyer13@gmail.com', N'Phạm Nhật Long'),
        ('buyer14@gmail.com', N'Hoàng Thu Trang'),
        ('buyer15@gmail.com', N'Võ Anh Tú'),
        ('buyer16@gmail.com', N'Đặng Mỹ Duyên'),
        ('buyer17@gmail.com', N'Bùi Quốc Huy'),
        ('buyer18@gmail.com', N'Đỗ Thảo Vy'),
        ('buyer19@gmail.com', N'Nguyễn Gia Bảo'),
        ('buyer20@gmail.com', N'Trần Phương Anh'),
        ('buyer21@gmail.com', N'Lê Minh Quân'),
        ('buyer22@gmail.com', N'Phạm Ngọc Hân'),
        ('buyer23@gmail.com', N'Hoàng Công Thành'),
        ('buyer24@gmail.com', N'Võ Khánh An'),
        ('buyer25@gmail.com', N'Đặng Quang Vinh'),
        ('buyer26@gmail.com', N'Bùi Hà My'),
        ('buyer27@gmail.com', N'Đỗ Đức Anh'),
        ('buyer28@gmail.com', N'Nguyễn Tú Uyên'),
        ('buyer29@gmail.com', N'Trần Hoàng Phúc'),
        ('buyer30@gmail.com', N'Lê Mai Chi'),
        ('buyer31@gmail.com', N'Phạm Tuấn Anh'),
        ('buyer32@gmail.com', N'Hoàng Bảo Trâm'),
        ('buyer33@gmail.com', N'Võ Minh Trí'),
        ('buyer34@gmail.com', N'Đặng Thanh Tâm'),
        ('buyer35@gmail.com', N'Bùi Gia Khiêm'),
        ('buyer36@gmail.com', N'Đỗ Ngọc Diệp'),
        ('buyer37@gmail.com', N'Nguyễn Khôi Nguyên'),
        ('buyer38@gmail.com', N'Trần Hải Yến'),
        ('buyer39@gmail.com', N'Lê Thành Đạt'),
        ('buyer40@gmail.com', N'Phạm Quỳnh Anh'),
        ('staff1@gmail.com', N'Trần Hoàng Nam'),
        ('staff2@gmail.com', N'Lê Minh Tâm'),
        ('staff3@gmail.com', N'Phạm Quốc Hưng'),
        ('staff4@gmail.com', N'Nguyễn Thu Hà'),
        ('staff5@gmail.com', N'Võ Thanh Sơn'),
        ('staff6@gmail.com', N'Đặng Bảo Châu'),
        ('staff7@gmail.com', N'Bùi Anh Khoa'),
        ('staff8@gmail.com', N'Đỗ Mỹ Linh'),
        ('staff9@gmail.com', N'Hoàng Gia Khánh'),
        ('staff10@gmail.com', N'Nguyễn Ngọc Lan'),
        ('staff11@gmail.com', N'Trần Đức Thịnh'),
        ('staff12@gmail.com', N'Lê Phương Thảo'),
        ('staff13@gmail.com', N'Phạm Minh Nhật'),
        ('staff14@gmail.com', N'Võ Hải Yến'),
        ('staff15@gmail.com', N'Đặng Quốc Trung');

    UPDATE nd
    SET nd.HoTen = names.HoTen
    FROM dbo.NguoiDung nd
    JOIN @DemoUserNames names ON names.Email = nd.Email;

    UPDATE dbo.NguoiDung
    SET ChuTaiKhoan = UPPER(HoTen)
    WHERE VaiTro = 1;

    UPDATE dh
    SET dh.HoTenNguoiMua = nd.HoTen
    FROM dbo.DonHang dh
    JOIN dbo.NguoiDung nd ON nd.Id = dh.NguoiMuaId;

    UPDATE ct
    SET ct.TenNguoiThamDu = nd.HoTen
    FROM dbo.ChiTietDonHang ct
    JOIN dbo.DonHang dh ON dh.Id = ct.DonHangId
    JOIN dbo.NguoiDung nd ON nd.Id = dh.NguoiMuaId
    WHERE ct.TenNguoiThamDu LIKE N'Khách Hàng Mua Vé %';

    -- organizer1 là tài khoản demo chính: có online/offline, sơ đồ ghế, check-in,
    -- doanh thu và đủ nhóm trạng thái nháp/chờ/tạm dừng/lưu trữ/hủy/từ chối.
    UPDATE dbo.SuKien
    SET NguoiToChucId = '5B5CE913-3124-448A-812B-85B5A4AB1A03'
    WHERE Id IN (
        'D3C3FBCE-4FFF-4F33-A4AF-0A2750C9E94E',
        'E20875EC-36DB-45EB-85D1-A706DC9B62D2',
        'D2C252F2-7FD4-4A02-86CB-3D9DE7415795',
        '5BC842AD-6166-406A-AD93-EB3ECACFBF7E',
        'E0000000-0000-0000-0000-000000000021',
        'E0000000-0000-0000-0000-000000000026',
        'E0000000-0000-0000-0000-000000000041',
        'E0000000-0000-0000-0000-000000000042',
        'E0000000-0000-0000-0000-000000000051',
        'E0000000-0000-0000-0000-000000000052',
        'E0000000-0000-0000-0000-000000000054',
        'E0000000-0000-0000-0000-000000000056',
        'E0000000-0000-0000-0000-000000000057'
    );

    UPDATE dbo.SuKien SET HienThiCongKhai = 0 WHERE Id IN (
        'E0000000-0000-0000-0000-000000000051',
        'E0000000-0000-0000-0000-000000000052',
        'E0000000-0000-0000-0000-000000000056',
        'E0000000-0000-0000-0000-000000000057'
    );

    -- Sự kiện nháp dùng để demo thiết kế sơ đồ phải chưa từng có đơn đặt vé.
    DELETE ct
    FROM dbo.ChiTietDonHang ct
    JOIN dbo.DonHang dh ON dh.Id = ct.DonHangId
    WHERE dh.SuKienId = 'E0000000-0000-0000-0000-000000000051';

    DELETE FROM dbo.DonHang
    WHERE SuKienId = 'E0000000-0000-0000-0000-000000000051';

    DELETE FROM dbo.SoDoChoNgoi
    WHERE SuKienId = 'E0000000-0000-0000-0000-000000000051';

    UPDATE dbo.SuKien
    SET CoSoDoChoNgoi = 0
    WHERE Id = 'E0000000-0000-0000-0000-000000000051';

    -- Sự kiện tạm dừng là tình huống sát thực tế hơn để demo chỉnh sơ đồ:
    -- đã có thông tin/loại vé nhưng chưa phát sinh đơn hoặc sơ đồ cũ.
    DELETE ct
    FROM dbo.ChiTietDonHang ct
    JOIN dbo.DonHang dh ON dh.Id = ct.DonHangId
    WHERE dh.SuKienId = 'E0000000-0000-0000-0000-000000000054';

    DELETE FROM dbo.DonHang
    WHERE SuKienId = 'E0000000-0000-0000-0000-000000000054';

    DELETE FROM dbo.SoDoChoNgoi
    WHERE SuKienId = 'E0000000-0000-0000-0000-000000000054';

    UPDATE dbo.SuKien
    SET CoSoDoChoNgoi = 0,
        TrangThai = 2,
        HienThiCongKhai = 1
    WHERE Id = 'E0000000-0000-0000-0000-000000000054';

    -- Staff1 có cả ca sắp tới và ca đã lưu trữ.
    IF NOT EXISTS (
        SELECT 1 FROM dbo.NhanVienSuKien
        WHERE NguoiDungId = '55F02A90-5841-4563-A735-C12B9717BB96'
          AND SuKienId = '5BC842AD-6166-406A-AD93-EB3ECACFBF7E'
    )
    INSERT INTO dbo.NhanVienSuKien (NguoiDungId, SuKienId, VaiTroNV, NgayThem)
    VALUES ('55F02A90-5841-4563-A735-C12B9717BB96', '5BC842AD-6166-406A-AD93-EB3ECACFBF7E', N'Soát vé cổng A', DATEADD(day, -10, GETUTCDATE()));

    -- buyer1 có đủ bốn trạng thái đơn; đơn chờ mô phỏng việc đã chọn cổng VNPay.
    DECLARE @DemoBuyerId UNIQUEIDENTIFIER = '77EDA4D0-64A0-4CD8-9BC0-C4B56C3DBA52';
    DECLARE @DemoEventId UNIQUEIDENTIFIER = 'D3C3FBCE-4FFF-4F33-A4AF-0A2750C9E94E';
    DECLARE @DemoLoaiVeId INT;
    DECLARE @DemoChoNgoiId INT;

    SELECT TOP (1) @DemoLoaiVeId = Id
    FROM dbo.LoaiVe
    WHERE SuKienId = @DemoEventId
    ORDER BY ThuTuHienThi DESC, Id DESC;

    SELECT TOP (1) @DemoChoNgoiId = cn.Id
    FROM dbo.ChoNgoi cn
    JOIN dbo.HangGhe hg ON hg.Id = cn.HangGheId
    JOIN dbo.KhuVuc kv ON kv.Id = hg.KhuVucId
    JOIN dbo.SoDoChoNgoi sd ON sd.Id = kv.SoDoChoNgoiId
    WHERE sd.SuKienId = @DemoEventId
      AND cn.TrangThai = 0
      AND NOT EXISTS (SELECT 1 FROM dbo.ChiTietDonHang ct WHERE ct.ChoNgoiId = cn.Id)
    ORDER BY cn.Id;

    INSERT INTO dbo.DonHang
        (Id, MaDonHang, NguoiMuaId, SuKienId, HoTenNguoiMua, EmailNguoiMua,
         SdtNguoiMua, TongTienVe, TienGiamGia, TongThanhToan, TrangThai,
         NgayTao, MaGiaoDich, PhuongThucThanhToan, NgayThanhToan)
    VALUES
        ('D2000000-0000-0000-0000-000000000081', 'DH-DEMO-CHO-01', @DemoBuyerId, @DemoEventId,
         N'Nguyễn Minh Anh', 'battlegrounds2004@gmail.com', '0901234501', 150000, 0, 150000, 0,
         GETUTCDATE(), NULL, 2, NULL),
        ('D2000000-0000-0000-0000-000000000082', 'DH-DEMO-HUY-01', @DemoBuyerId, @DemoEventId,
         N'Nguyễn Minh Anh', 'battlegrounds2004@gmail.com', '0901234501', 150000, 0, 150000, 2,
         DATEADD(day, -1, GETUTCDATE()), NULL, 3, NULL),
        ('D2000000-0000-0000-0000-000000000084', 'DH-DEMO-HETHAN-01', @DemoBuyerId, @DemoEventId,
         N'Nguyễn Minh Anh', 'battlegrounds2004@gmail.com', '0901234501', 150000, 0, 150000, 4,
         DATEADD(day, -2, GETUTCDATE()), NULL, 2, NULL);

    INSERT INTO dbo.ChiTietDonHang
        (DonHangId, LoaiVeId, ChoNgoiId, GiaVe, TenNguoiThamDu, EmailNguoiThamDu,
         MaVe, MaQRCode, TrangThaiCheckin, NgayCheckin, NguoiCheckinId)
    VALUES
        ('D2000000-0000-0000-0000-000000000081', @DemoLoaiVeId, @DemoChoNgoiId, 150000,
         N'Nguyễn Minh Anh', 'battlegrounds2004@gmail.com', NULL, NULL, 0, NULL, NULL),
        ('D2000000-0000-0000-0000-000000000082', @DemoLoaiVeId, NULL, 150000,
         N'Nguyễn Minh Anh', 'battlegrounds2004@gmail.com', NULL, NULL, 2, NULL, NULL),
        ('D2000000-0000-0000-0000-000000000084', @DemoLoaiVeId, NULL, 150000,
         N'Nguyễn Minh Anh', 'battlegrounds2004@gmail.com', NULL, NULL, 2, NULL, NULL);

    UPDATE dbo.ChoNgoi SET TrangThai = 1 WHERE Id = @DemoChoNgoiId;

    -- Một ghế khóa giúp sơ đồ thể hiện đủ Trống/Đang giữ/Đã bán/Khóa.
    UPDATE dbo.ChoNgoi
    SET TrangThai = 3
    WHERE Id = (
        SELECT TOP (1) cn.Id
        FROM dbo.ChoNgoi cn
        JOIN dbo.HangGhe hg ON hg.Id = cn.HangGheId
        JOIN dbo.KhuVuc kv ON kv.Id = hg.KhuVucId
        JOIN dbo.SoDoChoNgoi sd ON sd.Id = kv.SoDoChoNgoiId
        WHERE sd.SuKienId = @DemoEventId
          AND cn.TrangThai = 0
          AND NOT EXISTS (SELECT 1 FROM dbo.ChiTietDonHang ct WHERE ct.ChoNgoiId = cn.Id)
        ORDER BY cn.Id
    );

    -- Giá demo gần với các sự kiện cộng đồng tại Việt Nam:
    -- chỉ ba chương trình chính giữ giá cao, các sự kiện còn lại miễn phí hoặc 50.000-100.000đ.
    ;WITH SuKienGiaCongDong AS (
        SELECT Id, ROW_NUMBER() OVER (ORDER BY NgayBatDau, Id) AS ThuTu
        FROM dbo.SuKien
        WHERE Id NOT IN (
            'D3C3FBCE-4FFF-4F33-A4AF-0A2750C9E94E', -- WuangEvents Live
            'E20875EC-36DB-45EB-85D1-A706DC9B62D2', -- Đêm Jazz Sài Gòn
            'D2C252F2-7FD4-4A02-86CB-3D9DE7415795'  -- Rock Việt
        )
    )
    UPDATE lv
    SET GiaBan = CASE
        WHEN sg.ThuTu % 5 IN (0, 1) THEN 0
        WHEN lv.TenLoaiVe LIKE N'%VIP%' THEN 100000
        ELSE 50000
    END
    FROM dbo.LoaiVe lv
    JOIN SuKienGiaCongDong sg ON sg.Id = lv.SuKienId;

    UPDATE lv
    SET GiaBan = CASE
        WHEN lv.SuKienId = 'D3C3FBCE-4FFF-4F33-A4AF-0A2750C9E94E'
            THEN CASE WHEN lv.TenLoaiVe LIKE N'%VIP%' THEN 800000 ELSE 250000 END
        WHEN lv.SuKienId = 'E20875EC-36DB-45EB-85D1-A706DC9B62D2'
            THEN CASE WHEN lv.TenLoaiVe LIKE N'%VIP%' THEN 500000 ELSE 200000 END
        WHEN lv.SuKienId = 'D2C252F2-7FD4-4A02-86CB-3D9DE7415795'
            THEN CASE WHEN lv.TenLoaiVe LIKE N'%VIP%' THEN 800000 ELSE 250000 END
        ELSE lv.GiaBan
    END
    FROM dbo.LoaiVe lv;

    -- Online mẫu có một hạng miễn phí và một hạng nâng cao 100.000đ.
    UPDATE dbo.LoaiVe
    SET GiaBan = CASE WHEN TenLoaiVe LIKE N'%VIP%' THEN 100000 ELSE 0 END
    WHERE SuKienId = 'E0000000-0000-0000-0000-000000000026';

    -- Chi tiết đơn và tổng tiền phải đồng bộ với giá vé sau khi chuẩn hóa seed.
    UPDATE ct
    SET GiaVe = lv.GiaBan
    FROM dbo.ChiTietDonHang ct
    JOIN dbo.LoaiVe lv ON lv.Id = ct.LoaiVeId;

    ;WITH TongDon AS (
        SELECT DonHangId, SUM(GiaVe) AS TongTienVe
        FROM dbo.ChiTietDonHang
        GROUP BY DonHangId
    )
    UPDATE dh
    SET TongTienVe = td.TongTienVe,
        TienGiamGia = CASE WHEN dh.TienGiamGia > td.TongTienVe THEN td.TongTienVe ELSE dh.TienGiamGia END,
        TongThanhToan = CASE
            WHEN td.TongTienVe - CASE WHEN dh.TienGiamGia > td.TongTienVe THEN td.TongTienVe ELSE dh.TienGiamGia END < 0 THEN 0
            ELSE td.TongTienVe - CASE WHEN dh.TienGiamGia > td.TongTienVe THEN td.TongTienVe ELSE dh.TienGiamGia END
        END
    FROM dbo.DonHang dh
    JOIN TongDon td ON td.DonHangId = dh.Id;

    -- Online không phát hành QR và không lưu trạng thái check-in tại cổng.
    UPDATE ct
    SET MaQRCode = NULL, TrangThaiCheckin = 0, NgayCheckin = NULL, NguoiCheckinId = NULL
    FROM dbo.ChiTietDonHang ct
    JOIN dbo.DonHang dh ON dh.Id = ct.DonHangId
    JOIN dbo.SuKien sk ON sk.Id = dh.SuKienId
    WHERE sk.LoaiSuKien = 1;

    UPDATE dbo.SuKien
    SET BatDauCheckIn = NULL, KetThucCheckIn = NULL
    WHERE LoaiSuKien = 1;

    -- Một đăng ký miễn phí hoàn tất của buyer1 để demo luồng không qua cổng thanh toán.
    DECLARE @FreeOrderId UNIQUEIDENTIFIER = 'F3000000-0000-0000-0000-000000000001';
    DECLARE @FreeBuyerId UNIQUEIDENTIFIER = '77EDA4D0-64A0-4CD8-9BC0-C4B56C3DBA52';
    DECLARE @FreeEventId UNIQUEIDENTIFIER = 'E0000000-0000-0000-0000-000000000040';
    DECLARE @FreeTicketTypeId INT;

    SELECT TOP (1) @FreeTicketTypeId = Id
    FROM dbo.LoaiVe
    WHERE SuKienId = @FreeEventId AND GiaBan = 0 AND TrangThai = 1
    ORDER BY ThuTuHienThi DESC, Id DESC;

    IF @FreeTicketTypeId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.DonHang WHERE Id = @FreeOrderId)
    BEGIN
        INSERT INTO dbo.DonHang
            (Id, MaDonHang, NguoiMuaId, SuKienId, HoTenNguoiMua, EmailNguoiMua,
             SdtNguoiMua, TongTienVe, TienGiamGia, TongThanhToan, TrangThai,
             NgayTao, MaGiaoDich, PhuongThucThanhToan, NgayThanhToan)
        VALUES
            (@FreeOrderId, 'WE-FREE-DEMO', @FreeBuyerId, @FreeEventId,
             N'Nguyễn Minh Anh', 'battlegrounds2004@gmail.com', '0901234501',
             0, 0, 0, 1, DATEADD(hour, -2, GETUTCDATE()), 'FREE-DEMO', 1, DATEADD(hour, -2, GETUTCDATE()));

        INSERT INTO dbo.ChiTietDonHang
            (DonHangId, LoaiVeId, ChoNgoiId, GiaVe, TenNguoiThamDu, EmailNguoiThamDu,
             MaVe, MaQRCode, TrangThaiCheckin, NgayCheckin, NguoiCheckinId)
        VALUES
            (@FreeOrderId, @FreeTicketTypeId, NULL, 0, N'Nguyễn Minh Anh',
             'battlegrounds2004@gmail.com', 'VE-FREE-DEMO-001', 'QR-FREE-DEMO-001', 0, NULL, NULL);
    END;

    -- Không thể có vé đã check-in trước giờ bắt đầu. Giữ lại lịch sử check-in của sự kiện đã diễn ra.
    UPDATE ct
    SET TrangThaiCheckin = 0,
        NgayCheckin = NULL,
        NguoiCheckinId = NULL
    FROM dbo.ChiTietDonHang ct
    JOIN dbo.DonHang dh ON dh.Id = ct.DonHangId
    JOIN dbo.SuKien sk ON sk.Id = dh.SuKienId
    WHERE sk.LoaiSuKien = 0
      AND sk.NgayBatDau > DATEADD(hour, 7, GETUTCDATE());

    -- Sự kiện miễn phí chỉ dùng một hạng "Vé miễn phí" để khách không thấy VIP/Vé thường cùng giá 0đ.
    -- Các chi tiết đơn và khu vực (nếu có) được chuyển sang hạng vé giữ lại trước khi xóa hạng dư.
    DECLARE @VeMienPhi TABLE (
        SuKienId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        LoaiVeId INT NOT NULL,
        TongSoVe INT NOT NULL
    );

    INSERT INTO @VeMienPhi (SuKienId, LoaiVeId, TongSoVe)
    SELECT lv.SuKienId, MIN(lv.Id), SUM(lv.SoLuongTong)
    FROM dbo.LoaiVe lv
    GROUP BY lv.SuKienId
    HAVING COUNT(CASE WHEN lv.TrangThai = 1 THEN 1 END) > 0
       AND MAX(CASE WHEN lv.TrangThai = 1 THEN lv.GiaBan END) = 0;

    UPDATE ct
    SET LoaiVeId = vm.LoaiVeId
    FROM dbo.ChiTietDonHang ct
    JOIN dbo.LoaiVe lv ON lv.Id = ct.LoaiVeId
    JOIN @VeMienPhi vm ON vm.SuKienId = lv.SuKienId
    WHERE ct.LoaiVeId <> vm.LoaiVeId;

    UPDATE kv
    SET LoaiVeId = vm.LoaiVeId
    FROM dbo.KhuVuc kv
    JOIN dbo.LoaiVe lv ON lv.Id = kv.LoaiVeId
    JOIN @VeMienPhi vm ON vm.SuKienId = lv.SuKienId
    WHERE kv.LoaiVeId <> vm.LoaiVeId;

    UPDATE lv
    SET TenLoaiVe = N'Vé miễn phí',
        MoTa = N'Vé tham dự sự kiện miễn phí.',
        GiaBan = 0,
        SoLuongTong = vm.TongSoVe,
        ThuTuHienThi = 0,
        MauSac = '#16A34A',
        TrangThai = 1
    FROM dbo.LoaiVe lv
    JOIN @VeMienPhi vm ON vm.LoaiVeId = lv.Id;

    DELETE lv
    FROM dbo.LoaiVe lv
    JOIN @VeMienPhi vm ON vm.SuKienId = lv.SuKienId
    WHERE lv.Id <> vm.LoaiVeId;

    -- Đồng bộ lại tồn vé sau khi thêm các đơn trạng thái mẫu.
    ;WITH DemoTicketCounts AS (
        SELECT lv.Id,
               SUM(CASE WHEN dh.TrangThai = 1 THEN 1 ELSE 0 END) AS DaBan,
               SUM(CASE WHEN dh.TrangThai = 0 THEN 1 ELSE 0 END) AS DangGiu
        FROM dbo.LoaiVe lv
        LEFT JOIN dbo.ChiTietDonHang ct ON ct.LoaiVeId = lv.Id
        LEFT JOIN dbo.DonHang dh ON dh.Id = ct.DonHangId
        GROUP BY lv.Id
    )
    UPDATE lv
    SET SoLuongDaBan = ISNULL(tc.DaBan, 0),
        SoLuongGiuCho = ISNULL(tc.DangGiu, 0)
    FROM dbo.LoaiVe lv
    JOIN DemoTicketCounts tc ON tc.Id = lv.Id;

    INSERT INTO dbo.ThongBao (NguoiNhanId, TieuDe, NoiDung, LoaiThongBao, DuongDan, DaDoc, NgayTao)
    VALUES (@DemoBuyerId, N'Vé sắp diễn ra', N'WuangEvents Live 2026 sẽ diễn ra trong tuần này.', 2,
            N'/Booking/DonHangCuaToi', 0, DATEADD(hour, -3, GETUTCDATE()));

    -- Mã đơn thống nhất theo định dạng thương hiệu, không để nhãn kỹ thuật trên giao diện.
    ;WITH OrderedOrders AS (
        SELECT Id, ROW_NUMBER() OVER (ORDER BY NgayTao, Id) AS ThuTu
        FROM dbo.DonHang
    )
    UPDATE dh
    SET MaDonHang = CONCAT('WE', CONVERT(char(8), GETUTCDATE(), 112), '-',
                           RIGHT('000' + CONVERT(varchar(3), oo.ThuTu), 3))
    FROM dbo.DonHang dh
    JOIN OrderedOrders oo ON oo.Id = dh.Id;

    -- Dữ liệu mẫu cho chức năng gửi thông báo của Ban tổ chức.
    INSERT INTO dbo.ThongBao (NguoiNhanId, TieuDe, NoiDung, LoaiThongBao, DuongDan, DaDoc, NgayTao)
    VALUES
    ('77EDA4D0-64A0-4CD8-9BC0-C4B56C3DBA52', N'Xác nhận thanh toán thành công', N'Đơn hàng của bạn đã được thanh toán. Vé điện tử đã sẵn sàng để check-in.', 1, N'/Booking/DonHangCuaToi', 1, DATEADD(day, -2, GETUTCDATE())),
    ('DB847C61-CC0B-41F5-9BEB-F6132B0E5BF2', N'Nhắc lịch sự kiện', N'Đêm Jazz Sài Gòn sẽ bắt đầu trong ít phút. Vui lòng chuẩn bị mã QR để check-in.', 2, N'/Home/ChiTiet?id=dem-jazz-sai-gon-thanh-am-mua-ha', 0, GETUTCDATE()),
    ('B46BD4B0-EAC9-4C87-A500-785131A97B4A', N'Thông báo trạng thái sự kiện', N'Nhịp Trẻ Thăng Long 2026 đang tạm dừng bán vé. Hệ thống không cho phép tạo đơn mới trong trạng thái này.', 2, N'/Home/ChiTiet?id=nhip-tre-thang-long-2026', 0, GETUTCDATE());


    COMMIT TRANSACTION;
    PRINT N'Simplified database schema rebuilt and seeded successfully.';

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    PRINT N'Error occurred during database rebuild: ' + @ErrorMessage;
    RAISERROR(@ErrorMessage, 16, 1);
END CATCH;
GO
