USE [WuangEvents];
GO

-- =============================================
-- QuanLySuKienWuangEvents - Simplified Database Schema
-- Idempotent script to drop and recreate the simple 12-table schema (2NF)
-- =============================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

BEGIN TRY

    -- Drop constraints first to avoid dependency conflicts
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
        [LyDoTuChoiBTC]   NVARCHAR(1000)   NULL,
        [NgayYeuCauBTC]   DATETIME2(7)     NULL,

        -- Staff relationship column
        [NguoiTaoId]      UNIQUEIDENTIFIER NULL,

        CONSTRAINT [PK_NguoiDung] PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT [UQ_NguoiDung_Email] UNIQUE ([Email]),
        CONSTRAINT [FK_NguoiDung_NguoiTao] FOREIGN KEY ([NguoiTaoId]) REFERENCES [dbo].[NguoiDung]([Id])
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
        CONSTRAINT [FK_SuKien_DanhMuc] FOREIGN KEY ([DanhMucId]) REFERENCES [dbo].[DanhMuc]([Id])
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
        CONSTRAINT [FK_LoaiVe_SuKien] FOREIGN KEY ([SuKienId]) REFERENCES [dbo].[SuKien]([Id]) ON DELETE CASCADE
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
        CONSTRAINT [UQ_MaGiamGia_MaCode] UNIQUE ([MaCode]),
        CONSTRAINT [FK_MaGiamGia_SuKien] FOREIGN KEY ([SuKienId]) REFERENCES [dbo].[SuKien]([Id]) ON DELETE CASCADE
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
        [TrangThai]       TINYINT           NOT NULL DEFAULT 0,  -- 0: ChoThanhToan, 1: DaThanhToan, 2: DaHuy, 3: HoanTien
        [NgayTao]         DATETIME2(7)      NOT NULL DEFAULT GETUTCDATE(),
        [NgayCapNhat]     DATETIME2(7)      NULL,
        
        -- Payment merged columns
        [MaGiaoDich]      VARCHAR(100)      NULL,
        [PhuongThucThanhToan] TINYINT       NULL,                -- 1: ChuyenKhoan, 2: VNPAY
        [NgayThanhToan]   DATETIME2(7)      NULL,

        CONSTRAINT [PK_DonHang] PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT [UQ_DonHang_MaDonHang] UNIQUE ([MaDonHang]),
        CONSTRAINT [FK_DonHang_NguoiMua] FOREIGN KEY ([NguoiMuaId]) REFERENCES [dbo].[NguoiDung]([Id]),
        CONSTRAINT [FK_DonHang_SuKien] FOREIGN KEY ([SuKienId]) REFERENCES [dbo].[SuKien]([Id]),
        CONSTRAINT [FK_DonHang_MaGiamGia] FOREIGN KEY ([MaGiamGiaId]) REFERENCES [dbo].[MaGiamGia]([Id]) ON DELETE SET NULL
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
        CONSTRAINT [UQ_ChiTietDonHang_MaVe] UNIQUE ([MaVe]),
        CONSTRAINT [UQ_ChiTietDonHang_MaQRCode] UNIQUE ([MaQRCode])
    );

    -- 8. SoDoChoNgoi
    CREATE TABLE [dbo].[SoDoChoNgoi] (
        [Id]              INT IDENTITY(1,1) NOT NULL,
        [SuKienId]        UNIQUEIDENTIFIER  NOT NULL,
        [TenSoDo]         NVARCHAR(200)     NOT NULL,
        [NgayTao]         DATETIME2(7)      NOT NULL DEFAULT GETUTCDATE(),

        CONSTRAINT [PK_SoDoChoNgoi] PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT [UQ_SoDoChoNgoi_SuKienId] UNIQUE ([SuKienId]),
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
        [ThuTu]           INT               NOT NULL DEFAULT 0,

        CONSTRAINT [PK_KhuVuc] PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT [FK_KhuVuc_SoDoChoNgoi] FOREIGN KEY ([SoDoChoNgoiId]) REFERENCES [dbo].[SoDoChoNgoi]([Id]) ON DELETE CASCADE,
        CONSTRAINT [FK_KhuVuc_LoaiVe] FOREIGN KEY ([LoaiVeId]) REFERENCES [dbo].[LoaiVe]([Id])
    );

    -- 10. HangGhe
    CREATE TABLE [dbo].[HangGhe] (
        [Id]              INT IDENTITY(1,1) NOT NULL,
        [KhuVucId]        INT               NOT NULL,
        [TenHang]         NVARCHAR(10)      NOT NULL,
        [SoGhe]           INT               NOT NULL,
        [ThuTu]           INT               NOT NULL DEFAULT 0,

        CONSTRAINT [PK_HangGhe] PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT [FK_HangGhe_KhuVuc] FOREIGN KEY ([KhuVucId]) REFERENCES [dbo].[KhuVuc]([Id]) ON DELETE CASCADE
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
        CONSTRAINT [FK_ChoNgoi_HangGhe] FOREIGN KEY ([HangGheId]) REFERENCES [dbo].[HangGhe]([Id]) ON DELETE CASCADE
    );

    -- 12. NhanVienSuKien
    CREATE TABLE [dbo].[NhanVienSuKien] (
        [Id]              INT IDENTITY(1,1) NOT NULL,
        [NguoiDungId]     UNIQUEIDENTIFIER  NOT NULL,
        [SuKienId]        UNIQUEIDENTIFIER  NOT NULL,
        [VaiTroNV]        NVARCHAR(50)      NOT NULL DEFAULT N'CheckIn',
        [NgayThem]        DATETIME2(7)      NOT NULL DEFAULT GETUTCDATE(),

        CONSTRAINT [PK_NhanVienSuKien] PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT [FK_NhanVienSuKien_NguoiDung] FOREIGN KEY ([NguoiDungId]) REFERENCES [dbo].[NguoiDung]([Id]) ON DELETE CASCADE,
        CONSTRAINT [FK_NhanVienSuKien_SuKien] FOREIGN KEY ([SuKienId]) REFERENCES [dbo].[SuKien]([Id]) ON DELETE CASCADE
    );

    -- Add back the constraint for ChiTietDonHang referencing ChoNgoi
    ALTER TABLE [dbo].[ChiTietDonHang] ADD CONSTRAINT [FK_ChiTietDonHang_ChoNgoi] FOREIGN KEY ([ChoNgoiId]) REFERENCES [dbo].[ChoNgoi]([Id]) ON DELETE SET NULL;

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
    VALUES ('F1784A22-D111-4E6D-ABFF-EE1C04F0906D', 'admin@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Quản Trị Viên Hệ Thống', '0912345678', NULL, 3, 1, 1, GETUTCDATE());

    -- Organizer 1
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [TenNganHang], [SoTaiKhoan], [ChuTaiKhoan], [YeuCauBanToChuc], [SdtBanToChuc], [NgayYeuCauBTC], [NgayTao])
    VALUES ('5B5CE913-3124-448A-812B-85B5A4AB1A03', 'organizer1@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhà Tổ Chức 1', '0987654301', NULL, 1, 1, 1, 'Vietcombank', '0071001234001', 'NGUYEN VAN BTC 1', 2, '0987654301', GETUTCDATE(), GETUTCDATE());

    -- Organizer 2
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [TenNganHang], [SoTaiKhoan], [ChuTaiKhoan], [YeuCauBanToChuc], [SdtBanToChuc], [NgayYeuCauBTC], [NgayTao])
    VALUES ('C6D443D8-3015-4677-8BE2-D3C92C777062', 'organizer2@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhà Tổ Chức 2', '0987654302', NULL, 1, 1, 1, 'Vietcombank', '0071001234002', 'NGUYEN VAN BTC 2', 2, '0987654302', GETUTCDATE(), GETUTCDATE());

    -- Organizer 3
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [TenNganHang], [SoTaiKhoan], [ChuTaiKhoan], [YeuCauBanToChuc], [SdtBanToChuc], [NgayYeuCauBTC], [NgayTao])
    VALUES ('3A1B89A7-7E53-4A33-ACAE-FE4A71DC7BE4', 'organizer3@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhà Tổ Chức 3', '0987654303', NULL, 1, 1, 1, 'Vietcombank', '0071001234003', 'NGUYEN VAN BTC 3', 2, '0987654303', GETUTCDATE(), GETUTCDATE());

    -- Organizer 4
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [TenNganHang], [SoTaiKhoan], [ChuTaiKhoan], [YeuCauBanToChuc], [SdtBanToChuc], [NgayYeuCauBTC], [NgayTao])
    VALUES ('DF63CB1F-67FF-4CB5-8BA2-6C30FBF1F240', 'organizer4@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhà Tổ Chức 4', '0987654304', NULL, 1, 1, 1, 'Vietcombank', '0071001234004', 'NGUYEN VAN BTC 4', 2, '0987654304', GETUTCDATE(), GETUTCDATE());

    -- Organizer 5
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [TenNganHang], [SoTaiKhoan], [ChuTaiKhoan], [YeuCauBanToChuc], [SdtBanToChuc], [NgayYeuCauBTC], [NgayTao])
    VALUES ('C7C46C00-D517-46AF-8121-7FADE6992FFA', 'organizer5@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhà Tổ Chức 5', '0987654305', NULL, 1, 1, 1, 'Vietcombank', '0071001234005', 'NGUYEN VAN BTC 5', 2, '0987654305', GETUTCDATE(), GETUTCDATE());

    -- Organizer 6
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [TenNganHang], [SoTaiKhoan], [ChuTaiKhoan], [YeuCauBanToChuc], [SdtBanToChuc], [NgayYeuCauBTC], [NgayTao])
    VALUES ('5146EDFE-FC06-44CD-AAB4-C4B6BC9AD765', 'organizer6@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhà Tổ Chức 6', '0987654306', NULL, 1, 1, 1, 'Vietcombank', '0071001234006', 'NGUYEN VAN BTC 6', 2, '0987654306', GETUTCDATE(), GETUTCDATE());

    -- Organizer 7
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [TenNganHang], [SoTaiKhoan], [ChuTaiKhoan], [YeuCauBanToChuc], [SdtBanToChuc], [NgayYeuCauBTC], [NgayTao])
    VALUES ('95F1339E-2245-4449-A2B9-85C046A2D1DD', 'organizer7@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhà Tổ Chức 7', '0987654307', NULL, 1, 1, 1, 'Vietcombank', '0071001234007', 'NGUYEN VAN BTC 7', 2, '0987654307', GETUTCDATE(), GETUTCDATE());

    -- Organizer 8
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [TenNganHang], [SoTaiKhoan], [ChuTaiKhoan], [YeuCauBanToChuc], [SdtBanToChuc], [NgayYeuCauBTC], [NgayTao])
    VALUES ('1EFB3BD4-1BFD-4F1F-BD98-B17BA7B72074', 'organizer8@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhà Tổ Chức 8', '0987654308', NULL, 1, 1, 1, 'Vietcombank', '0071001234008', 'NGUYEN VAN BTC 8', 2, '0987654308', GETUTCDATE(), GETUTCDATE());

    -- Organizer 9
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [TenNganHang], [SoTaiKhoan], [ChuTaiKhoan], [YeuCauBanToChuc], [SdtBanToChuc], [NgayYeuCauBTC], [NgayTao])
    VALUES ('725DCDFC-12B8-48F7-A427-805527F0112C', 'organizer9@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhà Tổ Chức 9', '0987654309', NULL, 1, 1, 1, 'Vietcombank', '0071001234009', 'NGUYEN VAN BTC 9', 2, '0987654309', GETUTCDATE(), GETUTCDATE());

    -- Organizer 10
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [TenNganHang], [SoTaiKhoan], [ChuTaiKhoan], [YeuCauBanToChuc], [SdtBanToChuc], [NgayYeuCauBTC], [NgayTao])
    VALUES ('50075312-F374-48A9-8B2C-48F109BF34E9', 'organizer10@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhà Tổ Chức 10', '0987654310', NULL, 1, 1, 1, 'Vietcombank', '0071001234010', 'NGUYEN VAN BTC 10', 2, '0987654310', GETUTCDATE(), GETUTCDATE());

    -- Buyer 1
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('77EDA4D0-64A0-4CD8-9BC0-C4B56C3DBA52', 'buyer1@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 1', '0901234501', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 2
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('DB847C61-CC0B-41F5-9BEB-F6132B0E5BF2', 'buyer2@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 2', '0901234502', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 3
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('B46BD4B0-EAC9-4C87-A500-785131A97B4A', 'buyer3@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 3', '0901234503', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 4
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('FE3E3726-2435-43B9-9688-308CA7D1F34A', 'buyer4@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 4', '0901234504', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 5
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('06BF864B-30A7-4413-B9C4-321686732721', 'buyer5@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 5', '0901234505', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 6
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('42F528B2-7107-4672-B7FC-3D49A10F63F6', 'buyer6@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 6', '0901234506', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 7
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('3C416A14-C60B-48F9-9FA5-7CFE1FFCD5E7', 'buyer7@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 7', '0901234507', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 8
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('F5E77535-E905-43E7-907C-108141C0485F', 'buyer8@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 8', '0901234508', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 9
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('00858E32-C188-44CC-8A26-21A599A2F73C', 'buyer9@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 9', '0901234509', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 10
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('CB31862C-E0C2-4590-A9F6-A0AB45513214', 'buyer10@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 10', '0901234510', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 11
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000011', 'buyer11@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 11', '0901234511', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 12
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000012', 'buyer12@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 12', '0901234512', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 13
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000013', 'buyer13@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 13', '0901234513', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 14
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000014', 'buyer14@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 14', '0901234514', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 15
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000015', 'buyer15@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 15', '0901234515', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 16
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000016', 'buyer16@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 16', '0901234516', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 17
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000017', 'buyer17@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 17', '0901234517', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 18
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000018', 'buyer18@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 18', '0901234518', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 19
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000019', 'buyer19@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 19', '0901234519', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 20
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000020', 'buyer20@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 20', '0901234520', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 21
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000021', 'buyer21@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 21', '0901234521', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 22
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000022', 'buyer22@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 22', '0901234522', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 23
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000023', 'buyer23@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 23', '0901234523', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 24
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000024', 'buyer24@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 24', '0901234524', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 25
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000025', 'buyer25@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 25', '0901234525', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 26
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000026', 'buyer26@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 26', '0901234526', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 27
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000027', 'buyer27@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 27', '0901234527', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 28
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000028', 'buyer28@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 28', '0901234528', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 29
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000029', 'buyer29@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 29', '0901234529', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 30
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000030', 'buyer30@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 30', '0901234530', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 31
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000031', 'buyer31@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 31', '0901234531', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 32
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000032', 'buyer32@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 32', '0901234532', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 33
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000033', 'buyer33@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 33', '0901234533', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 34
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000034', 'buyer34@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 34', '0901234534', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 35
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000035', 'buyer35@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 35', '0901234535', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 36
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000036', 'buyer36@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 36', '0901234536', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 37
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000037', 'buyer37@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 37', '0901234537', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 38
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000038', 'buyer38@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 38', '0901234538', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 39
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000039', 'buyer39@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 39', '0901234539', NULL, 0, 1, 1, GETUTCDATE());

    -- Buyer 40
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NgayTao])
    VALUES ('A0000000-0000-0000-0000-000000000040', 'buyer40@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Khách Hàng Mua Vé 40', '0901234540', NULL, 0, 1, 1, GETUTCDATE());

    -- Staff 1 (Quản lý bởi Organizer 1)
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NguoiTaoId], [NgayTao])
    VALUES ('55F02A90-5841-4563-A735-C12B9717BB96', 'staff1@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhân Viên Soát Vé 1', '0971234501', NULL, 2, 1, 1, '5B5CE913-3124-448A-812B-85B5A4AB1A03', GETUTCDATE());

    -- Staff 2 (Quản lý bởi Organizer 2)
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NguoiTaoId], [NgayTao])
    VALUES ('308F7B86-4503-4DB4-87F1-A66A56C7A3BF', 'staff2@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhân Viên Soát Vé 2', '0971234502', NULL, 2, 1, 1, 'C6D443D8-3015-4677-8BE2-D3C92C777062', GETUTCDATE());

    -- Staff 3 (Quản lý bởi Organizer 3)
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NguoiTaoId], [NgayTao])
    VALUES ('73E06548-F2B9-4768-837D-1A942636A27F', 'staff3@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhân Viên Soát Vé 3', '0971234503', NULL, 2, 1, 1, '3A1B89A7-7E53-4A33-ACAE-FE4A71DC7BE4', GETUTCDATE());

    -- Staff 4 (Quản lý bởi Organizer 4)
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NguoiTaoId], [NgayTao])
    VALUES ('706BEA74-E775-460F-8E3B-74BBFA81A5CF', 'staff4@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhân Viên Soát Vé 4', '0971234504', NULL, 2, 1, 1, 'DF63CB1F-67FF-4CB5-8BA2-6C30FBF1F240', GETUTCDATE());

    -- Staff 5 (Quản lý bởi Organizer 5)
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NguoiTaoId], [NgayTao])
    VALUES ('5EA93981-1208-4862-AE9C-7E14FEFB596B', 'staff5@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhân Viên Soát Vé 5', '0971234505', NULL, 2, 1, 1, 'C7C46C00-D517-46AF-8121-7FADE6992FFA', GETUTCDATE());

    -- Staff 6 (Quản lý bởi Organizer 6)
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NguoiTaoId], [NgayTao])
    VALUES ('FC115C36-482E-4648-A580-A4AF9E50D33D', 'staff6@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhân Viên Soát Vé 6', '0971234506', NULL, 2, 1, 1, '5146EDFE-FC06-44CD-AAB4-C4B6BC9AD765', GETUTCDATE());

    -- Staff 7 (Quản lý bởi Organizer 7)
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NguoiTaoId], [NgayTao])
    VALUES ('817AC6A9-9F7E-40F3-A119-D4D31FD01C74', 'staff7@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhân Viên Soát Vé 7', '0971234507', NULL, 2, 1, 1, '95F1339E-2245-4449-A2B9-85C046A2D1DD', GETUTCDATE());

    -- Staff 8 (Quản lý bởi Organizer 8)
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NguoiTaoId], [NgayTao])
    VALUES ('71D84E61-3BC1-4270-8E01-5738E4D673FF', 'staff8@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhân Viên Soát Vé 8', '0971234508', NULL, 2, 1, 1, '1EFB3BD4-1BFD-4F1F-BD98-B17BA7B72074', GETUTCDATE());

    -- Staff 9 (Quản lý bởi Organizer 9)
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NguoiTaoId], [NgayTao])
    VALUES ('16DE5824-396A-49AB-9D33-6850ADA72500', 'staff9@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhân Viên Soát Vé 9', '0971234509', NULL, 2, 1, 1, '725DCDFC-12B8-48F7-A427-805527F0112C', GETUTCDATE());

    -- Staff 10 (Quản lý bởi Organizer 10)
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NguoiTaoId], [NgayTao])
    VALUES ('59443B1B-7793-40DE-B0E2-11ACD1C16FDF', 'staff10@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhân Viên Soát Vé 10', '0971234510', NULL, 2, 1, 1, '50075312-F374-48A9-8B2C-48F109BF34E9', GETUTCDATE());

    -- Staff 11 (Quản lý bởi Organizer 1)
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NguoiTaoId], [NgayTao])
    VALUES ('B0000000-0000-0000-0000-000000000011', 'staff11@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhân Viên Soát Vé 11', '0971234511', NULL, 2, 1, 1, '5B5CE913-3124-448A-812B-85B5A4AB1A03', GETUTCDATE());

    -- Staff 12 (Quản lý bởi Organizer 2)
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NguoiTaoId], [NgayTao])
    VALUES ('B0000000-0000-0000-0000-000000000012', 'staff12@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhân Viên Soát Vé 12', '0971234512', NULL, 2, 1, 1, 'C6D443D8-3015-4677-8BE2-D3C92C777062', GETUTCDATE());

    -- Staff 13 (Quản lý bởi Organizer 3)
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NguoiTaoId], [NgayTao])
    VALUES ('B0000000-0000-0000-0000-000000000013', 'staff13@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhân Viên Soát Vé 13', '0971234513', NULL, 2, 1, 1, '3A1B89A7-7E53-4A33-ACAE-FE4A71DC7BE4', GETUTCDATE());

    -- Staff 14 (Quản lý bởi Organizer 4)
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NguoiTaoId], [NgayTao])
    VALUES ('B0000000-0000-0000-0000-000000000014', 'staff14@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhân Viên Soát Vé 14', '0971234514', NULL, 2, 1, 1, 'DF63CB1F-67FF-4CB5-8BA2-6C30FBF1F240', GETUTCDATE());

    -- Staff 15 (Quản lý bởi Organizer 5)
    INSERT INTO [dbo].[NguoiDung] ([Id], [Email], [MatKhauHash], [HoTen], [SoDienThoai], [AnhDaiDien], [VaiTro], [TrangThai], [EmailXacNhan], [NguoiTaoId], [NgayTao])
    VALUES ('B0000000-0000-0000-0000-000000000015', 'staff15@wuangevents.com', '$2a$11$xxJGoSZ55gn3xGh6Rn1NDuPFCandgtNv4uToYm/QcBn82UnJrYlQ.', N'Nhân Viên Soát Vé 15', '0971234515', NULL, 2, 1, 1, 'C7C46C00-D517-46AF-8121-7FADE6992FFA', GETUTCDATE());


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
    INSERT INTO [dbo].[SoDoChoNgoi] ([SuKienId], [TenSoDo], [NgayTao])
    VALUES ('D3C3FBCE-4FFF-4F33-A4AF-0A2750C9E94E', N'Sơ đồ khán đài Sân vận động Phú Thọ', GETUTCDATE());
 
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
    VALUES ('D1000000-0000-0000-0000-000000000001', 'DH-WUANG-PAID-01', '77EDA4D0-64A0-4CD8-9BC0-C4B56C3DBA52', 'D3C3FBCE-4FFF-4F33-A4AF-0A2750C9E94E', NULL, N'Khách Hàng Mua Vé 1', 'buyer1@wuangevents.com', '0901234501', 1000000, 0, 1000000, 1, DATEADD(hour, -5, GETUTCDATE()), 'TXN-VNP-001', 2, DATEADD(hour, -5, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000001', 1, 1, 500000, N'Khách Hàng Mua Vé 1', 'buyer1@wuangevents.com', 'VE-WUANG-VIP-1', 'QR-WUANG-VIP-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000001', 1, 2, 500000, N'Nguyễn Văn Khách 2', 'buyer1-guest@wuangevents.com', 'VE-WUANG-VIP-2', 'QR-WUANG-VIP-2', 0, NULL, NULL);

    -- Đơn hàng 2 (Event 1): Chưa thanh toán, giữ chỗ VIP A3
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000002', 'DH-WUANG-PEND-02', 'DB847C61-CC0B-41F5-9BEB-F6132B0E5BF2', 'D3C3FBCE-4FFF-4F33-A4AF-0A2750C9E94E', NULL, N'Khách Hàng Mua Vé 2', 'buyer2@wuangevents.com', '0901234502', 500000, 0, 500000, 0, DATEADD(minute, -5, GETUTCDATE()), NULL, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000002', 1, 3, 500000, N'Khách Hàng Mua Vé 2', 'buyer2@wuangevents.com', 'VE-WUANG-PEND-3', 'QR-WUANG-PEND-3', 0, NULL, NULL);

    -- Đơn hàng 3 (Event 1): Đã hủy
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000003', 'DH-WUANG-FAIL-03', 'B46BD4B0-EAC9-4C87-A500-785131A97B4A', 'D3C3FBCE-4FFF-4F33-A4AF-0A2750C9E94E', NULL, N'Khách Hàng Mua Vé 3', 'buyer3@wuangevents.com', '0901234503', 500000, 0, 500000, 2, DATEADD(day, -1, GETUTCDATE()), NULL, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000003', 1, 4, 500000, N'Khách Hàng Mua Vé 3', 'buyer3@wuangevents.com', 'VE-WUANG-FAIL-4', 'QR-WUANG-FAIL-4', 2, NULL, NULL);

    -- Đơn hàng 4 (Event 2): Đã thanh toán, 1 vé VIP đã check-in, 1 vé Thường chưa check-in
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000004', 'DH-JAZZ-PAID-04', 'FE3E3726-2435-43B9-9688-308CA7D1F34A', 'E20875EC-36DB-45EB-85D1-A706DC9B62D2', NULL, N'Khách Hàng Mua Vé 4', 'buyer4@wuangevents.com', '0901234504', 800000, 0, 800000, 1, DATEADD(hour, -2, GETUTCDATE()), 'TXN-VNP-004', 2, DATEADD(hour, -2, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000004', 3, NULL, 600000, N'Khách Hàng Mua Vé 4', 'buyer4@wuangevents.com', 'VE-JAZZ-VIP-4', 'QR-JAZZ-VIP-4', 1, DATEADD(minute, -10, GETUTCDATE()), '55F02A90-5841-4563-A735-C12B9717BB96');

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000004', 4, NULL, 200000, N'Nguyễn Văn Jazz', 'buyer4-guest@wuangevents.com', 'VE-JAZZ-THUONG-4', 'QR-JAZZ-THUONG-4', 0, NULL, NULL);

    -- Đơn hàng 5 (Event 2): Đã thanh toán, 1 vé Thường chưa check-in
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000005', 'DH-JAZZ-PAID-05', '06BF864B-30A7-4413-B9C4-321686732721', 'E20875EC-36DB-45EB-85D1-A706DC9B62D2', NULL, N'Khách Hàng Mua Vé 5', 'buyer5@wuangevents.com', '0901234505', 200000, 0, 200000, 1, DATEADD(hour, -1, GETUTCDATE()), 'TXN-VNP-005', 2, DATEADD(hour, -1, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000005', 4, NULL, 200000, N'Khách Hàng Mua Vé 5', 'buyer5@wuangevents.com', 'VE-JAZZ-THUONG-5', 'QR-JAZZ-THUONG-5', 0, NULL, NULL);

    -- Đơn hàng 6 (Event 3): Đã thanh toán, 1 vé Thường chưa check-in
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000006', 'DH-ROCK-PAID-06', '42F528B2-7107-4672-B7FC-3D49A10F63F6', 'D2C252F2-7FD4-4A02-86CB-3D9DE7415795', NULL, N'Khách Hàng Mua Vé 6', 'buyer6@wuangevents.com', '0901234506', 250000, 0, 250000, 1, DATEADD(hour, -4, GETUTCDATE()), 'TXN-VNP-006', 2, DATEADD(hour, -4, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000006', 6, NULL, 250000, N'Khách Hàng Mua Vé 6', 'buyer6@wuangevents.com', 'VE-ROCK-THUONG-6', 'QR-ROCK-THUONG-6', 0, NULL, NULL);

    -- Đơn hàng 7 (Event 4): Đã thanh toán, 1 vé Thường chưa check-in
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000007', 'DH-ACOUSTIC-07', '3C416A14-C60B-48F9-9FA5-7CFE1FFCD5E7', '5BC842AD-6166-406A-AD93-EB3ECACFBF7E', NULL, N'Khách Hàng Mua Vé 7', 'buyer7@wuangevents.com', '0901234507', 300000, 0, 300000, 1, DATEADD(day, -2, GETUTCDATE()), 'TXN-VNP-007', 2, DATEADD(day, -2, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000007', 8, NULL, 300000, N'Khách Hàng Mua Vé 7', 'buyer7@wuangevents.com', 'VE-ACOUSTIC-THUONG-7', 'QR-ACOUSTIC-THUONG-7', 0, NULL, NULL);

    -- Order 8
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000008', 'DH-DEMO-008', 'A0000000-0000-0000-0000-000000000013', 'E0000000-0000-0000-0000-000000000051', NULL, N'Khách Hàng Mua Vé 13', 'buyer13@wuangevents.com', '0901234513', 500000, 0, 500000, 1, DATEADD(day, -18, GETUTCDATE()), 'TXN-VNP-008', 2, DATEADD(day, -18, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000008', 102, NULL, 250000, N'Khách Hàng Mua Vé 13', 'buyer13@wuangevents.com', 'VE-STD-008-1', 'QR-STD-008-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000008', 102, NULL, 250000, N'Khách Hàng Mua Vé 13', 'buyer13@wuangevents.com', 'VE-STD-008-2', 'QR-STD-008-2', 0, NULL, NULL);

    -- Order 9
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000009', 'DH-DEMO-009', 'A0000000-0000-0000-0000-000000000034', 'E0000000-0000-0000-0000-000000000018', NULL, N'Khách Hàng Mua Vé 34', 'buyer34@wuangevents.com', '0901234534', 800000, 0, 800000, 1, DATEADD(day, -19, GETUTCDATE()), 'TXN-VNP-009', 2, DATEADD(day, -19, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000009', 35, NULL, 800000, N'Khách Hàng Mua Vé 34', 'buyer34@wuangevents.com', 'VE-VIP-009-1', 'QR-VIP-009-1', 0, NULL, NULL);

    -- Order 10
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000010', 'DH-DEMO-010', 'A0000000-0000-0000-0000-000000000014', 'E0000000-0000-0000-0000-000000000051', NULL, N'Khách Hàng Mua Vé 14', 'buyer14@wuangevents.com', '0901234514', 750000, 0, 750000, 1, DATEADD(day, -19, GETUTCDATE()), 'TXN-VNP-010', 2, DATEADD(day, -19, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000010', 102, NULL, 250000, N'Khách Hàng Mua Vé 14', 'buyer14@wuangevents.com', 'VE-STD-010-1', 'QR-STD-010-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000010', 102, NULL, 250000, N'Khách Hàng Mua Vé 14', 'buyer14@wuangevents.com', 'VE-STD-010-2', 'QR-STD-010-2', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000010', 102, NULL, 250000, N'Khách Hàng Mua Vé 14', 'buyer14@wuangevents.com', 'VE-STD-010-3', 'QR-STD-010-3', 0, NULL, NULL);

    -- Order 11
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000011', 'DH-DEMO-011', 'A0000000-0000-0000-0000-000000000032', 'E0000000-0000-0000-0000-000000000019', NULL, N'Khách Hàng Mua Vé 32', 'buyer32@wuangevents.com', '0901234532', 1600000, 0, 1600000, 1, DATEADD(day, -11, GETUTCDATE()), 'TXN-VNP-011', 1, DATEADD(day, -11, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000011', 37, NULL, 800000, N'Khách Hàng Mua Vé 32', 'buyer32@wuangevents.com', 'VE-VIP-011-1', 'QR-VIP-011-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000011', 37, NULL, 800000, N'Khách Hàng Mua Vé 32', 'buyer32@wuangevents.com', 'VE-VIP-011-2', 'QR-VIP-011-2', 0, NULL, NULL);

    -- Order 12
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000012', 'DH-DEMO-012', 'A0000000-0000-0000-0000-000000000030', 'E0000000-0000-0000-0000-000000000052', NULL, N'Khách Hàng Mua Vé 30', 'buyer30@wuangevents.com', '0901234530', 1050000, 0, 1050000, 1, DATEADD(day, -16, GETUTCDATE()), 'TXN-VNP-012', 1, DATEADD(day, -16, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000012', 103, NULL, 800000, N'Khách Hàng Mua Vé 30', 'buyer30@wuangevents.com', 'VE-VIP-012-1', 'QR-VIP-012-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000012', 104, NULL, 250000, N'Khách Hàng Mua Vé 30', 'buyer30@wuangevents.com', 'VE-STD-012-2', 'QR-STD-012-2', 0, NULL, NULL);

    -- Order 13
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000013', 'DH-DEMO-013', 'A0000000-0000-0000-0000-000000000015', 'E0000000-0000-0000-0000-000000000055', NULL, N'Khách Hàng Mua Vé 15', 'buyer15@wuangevents.com', '0901234515', 1850000, 0, 1850000, 1, DATEADD(day, -17, GETUTCDATE()), 'TXN-VNP-013', 1, DATEADD(day, -17, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000013', 109, NULL, 800000, N'Khách Hàng Mua Vé 15', 'buyer15@wuangevents.com', 'VE-VIP-013-1', 'QR-VIP-013-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000013', 109, NULL, 800000, N'Khách Hàng Mua Vé 15', 'buyer15@wuangevents.com', 'VE-VIP-013-2', 'QR-VIP-013-2', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000013', 110, NULL, 250000, N'Khách Hàng Mua Vé 15', 'buyer15@wuangevents.com', 'VE-STD-013-3', 'QR-STD-013-3', 0, NULL, NULL);

    -- Order 14
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000014', 'DH-DEMO-014', 'A0000000-0000-0000-0000-000000000019', 'E0000000-0000-0000-0000-000000000018', NULL, N'Khách Hàng Mua Vé 19', 'buyer19@wuangevents.com', '0901234519', 250000, 0, 250000, 1, DATEADD(day, -17, GETUTCDATE()), 'TXN-VNP-014', 1, DATEADD(day, -17, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000014', 36, NULL, 250000, N'Khách Hàng Mua Vé 19', 'buyer19@wuangevents.com', 'VE-STD-014-1', 'QR-STD-014-1', 0, NULL, NULL);

    -- Order 15
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000015', 'DH-DEMO-015', 'A0000000-0000-0000-0000-000000000029', 'E0000000-0000-0000-0000-000000000024', NULL, N'Khách Hàng Mua Vé 29', 'buyer29@wuangevents.com', '0901234529', 1850000, 0, 1850000, 1, DATEADD(day, -12, GETUTCDATE()), 'TXN-VNP-015', 2, DATEADD(day, -12, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000015', 47, NULL, 800000, N'Khách Hàng Mua Vé 29', 'buyer29@wuangevents.com', 'VE-VIP-015-1', 'QR-VIP-015-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000015', 47, NULL, 800000, N'Khách Hàng Mua Vé 29', 'buyer29@wuangevents.com', 'VE-VIP-015-2', 'QR-VIP-015-2', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000015', 48, NULL, 250000, N'Khách Hàng Mua Vé 29', 'buyer29@wuangevents.com', 'VE-STD-015-3', 'QR-STD-015-3', 0, NULL, NULL);

    -- Order 16
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000016', 'DH-DEMO-016', 'A0000000-0000-0000-0000-000000000027', 'E0000000-0000-0000-0000-000000000013', NULL, N'Khách Hàng Mua Vé 27', 'buyer27@wuangevents.com', '0901234527', 1850000, 0, 1850000, 2, DATEADD(day, -10, GETUTCDATE()), 'NULL', 1, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000016', 25, NULL, 800000, N'Khách Hàng Mua Vé 27', 'buyer27@wuangevents.com', 'VE-VIP-016-1', 'QR-VIP-016-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000016', 25, NULL, 800000, N'Khách Hàng Mua Vé 27', 'buyer27@wuangevents.com', 'VE-VIP-016-2', 'QR-VIP-016-2', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000016', 26, NULL, 250000, N'Khách Hàng Mua Vé 27', 'buyer27@wuangevents.com', 'VE-STD-016-3', 'QR-STD-016-3', 0, NULL, NULL);

    -- Order 17
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000017', 'DH-DEMO-017', '77EDA4D0-64A0-4CD8-9BC0-C4B56C3DBA52', 'E0000000-0000-0000-0000-000000000052', NULL, N'Khách Hàng Mua Vé 1', 'buyer1@wuangevents.com', '0901234501', 1050000, 0, 1050000, 0, DATEADD(day, -13, GETUTCDATE()), 'NULL', 1, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000017', 103, NULL, 800000, N'Khách Hàng Mua Vé 1', 'buyer1@wuangevents.com', 'VE-VIP-017-1', 'QR-VIP-017-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000017', 104, NULL, 250000, N'Khách Hàng Mua Vé 1', 'buyer1@wuangevents.com', 'VE-STD-017-2', 'QR-STD-017-2', 0, NULL, NULL);

    -- Order 18
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000018', 'DH-DEMO-018', 'A0000000-0000-0000-0000-000000000017', 'E0000000-0000-0000-0000-000000000050', NULL, N'Khách Hàng Mua Vé 17', 'buyer17@wuangevents.com', '0901234517', 1050000, 0, 1050000, 1, DATEADD(day, -14, GETUTCDATE()), 'TXN-VNP-018', 1, DATEADD(day, -14, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000018', 99, NULL, 800000, N'Khách Hàng Mua Vé 17', 'buyer17@wuangevents.com', 'VE-VIP-018-1', 'QR-VIP-018-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000018', 100, NULL, 250000, N'Khách Hàng Mua Vé 17', 'buyer17@wuangevents.com', 'VE-STD-018-2', 'QR-STD-018-2', 0, NULL, NULL);

    -- Order 19
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000019', 'DH-DEMO-019', 'A0000000-0000-0000-0000-000000000035', 'E0000000-0000-0000-0000-000000000028', NULL, N'Khách Hàng Mua Vé 35', 'buyer35@wuangevents.com', '0901234535', 1600000, 0, 1600000, 1, DATEADD(day, -18, GETUTCDATE()), 'TXN-VNP-019', 1, DATEADD(day, -18, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000019', 55, NULL, 800000, N'Khách Hàng Mua Vé 35', 'buyer35@wuangevents.com', 'VE-VIP-019-1', 'QR-VIP-019-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000019', 55, NULL, 800000, N'Khách Hàng Mua Vé 35', 'buyer35@wuangevents.com', 'VE-VIP-019-2', 'QR-VIP-019-2', 0, NULL, NULL);

    -- Order 20
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000020', 'DH-DEMO-020', 'A0000000-0000-0000-0000-000000000019', 'E20875EC-36DB-45EB-85D1-A706DC9B62D2', NULL, N'Khách Hàng Mua Vé 19', 'buyer19@wuangevents.com', '0901234519', 500000, 0, 500000, 0, DATEADD(day, -9, GETUTCDATE()), 'NULL', 1, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000020', 4, NULL, 250000, N'Khách Hàng Mua Vé 19', 'buyer19@wuangevents.com', 'VE-STD-020-1', 'QR-STD-020-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000020', 4, NULL, 250000, N'Khách Hàng Mua Vé 19', 'buyer19@wuangevents.com', 'VE-STD-020-2', 'QR-STD-020-2', 0, NULL, NULL);

    -- Order 21
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000021', 'DH-DEMO-021', 'FE3E3726-2435-43B9-9688-308CA7D1F34A', 'E0000000-0000-0000-0000-000000000012', NULL, N'Khách Hàng Mua Vé 4', 'buyer4@wuangevents.com', '0901234504', 1850000, 0, 1850000, 1, DATEADD(day, -18, GETUTCDATE()), 'TXN-VNP-021', 2, DATEADD(day, -18, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000021', 23, NULL, 800000, N'Khách Hàng Mua Vé 4', 'buyer4@wuangevents.com', 'VE-VIP-021-1', 'QR-VIP-021-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000021', 23, NULL, 800000, N'Khách Hàng Mua Vé 4', 'buyer4@wuangevents.com', 'VE-VIP-021-2', 'QR-VIP-021-2', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000021', 24, NULL, 250000, N'Khách Hàng Mua Vé 4', 'buyer4@wuangevents.com', 'VE-STD-021-3', 'QR-STD-021-3', 0, NULL, NULL);

    -- Order 22
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000022', 'DH-DEMO-022', 'A0000000-0000-0000-0000-000000000037', 'E0000000-0000-0000-0000-000000000058', NULL, N'Khách Hàng Mua Vé 37', 'buyer37@wuangevents.com', '0901234537', 750000, 0, 750000, 1, DATEADD(day, -4, GETUTCDATE()), 'TXN-VNP-022', 1, DATEADD(day, -4, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000022', 116, NULL, 250000, N'Khách Hàng Mua Vé 37', 'buyer37@wuangevents.com', 'VE-STD-022-1', 'QR-STD-022-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000022', 116, NULL, 250000, N'Khách Hàng Mua Vé 37', 'buyer37@wuangevents.com', 'VE-STD-022-2', 'QR-STD-022-2', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000022', 116, NULL, 250000, N'Khách Hàng Mua Vé 37', 'buyer37@wuangevents.com', 'VE-STD-022-3', 'QR-STD-022-3', 0, NULL, NULL);

    -- Order 23
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000023', 'DH-DEMO-023', 'A0000000-0000-0000-0000-000000000040', 'E0000000-0000-0000-0000-000000000015', NULL, N'Khách Hàng Mua Vé 40', 'buyer40@wuangevents.com', '0901234540', 1600000, 0, 1600000, 1, DATEADD(day, -8, GETUTCDATE()), 'TXN-VNP-023', 1, DATEADD(day, -8, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000023', 29, NULL, 800000, N'Khách Hàng Mua Vé 40', 'buyer40@wuangevents.com', 'VE-VIP-023-1', 'QR-VIP-023-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000023', 29, NULL, 800000, N'Khách Hàng Mua Vé 40', 'buyer40@wuangevents.com', 'VE-VIP-023-2', 'QR-VIP-023-2', 0, NULL, NULL);

    -- Order 24
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000024', 'DH-DEMO-024', 'B46BD4B0-EAC9-4C87-A500-785131A97B4A', 'E0000000-0000-0000-0000-000000000020', NULL, N'Khách Hàng Mua Vé 3', 'buyer3@wuangevents.com', '0901234503', 1600000, 0, 1600000, 1, DATEADD(day, -10, GETUTCDATE()), 'TXN-VNP-024', 2, DATEADD(day, -10, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000024', 39, NULL, 800000, N'Khách Hàng Mua Vé 3', 'buyer3@wuangevents.com', 'VE-VIP-024-1', 'QR-VIP-024-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000024', 39, NULL, 800000, N'Khách Hàng Mua Vé 3', 'buyer3@wuangevents.com', 'VE-VIP-024-2', 'QR-VIP-024-2', 0, NULL, NULL);

    -- Order 25
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000025', 'DH-DEMO-025', '3C416A14-C60B-48F9-9FA5-7CFE1FFCD5E7', '5BC842AD-6166-406A-AD93-EB3ECACFBF7E', NULL, N'Khách Hàng Mua Vé 7', 'buyer7@wuangevents.com', '0901234507', 800000, 0, 800000, 1, DATEADD(day, -18, GETUTCDATE()), 'TXN-VNP-025', 1, DATEADD(day, -18, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000025', 7, NULL, 800000, N'Khách Hàng Mua Vé 7', 'buyer7@wuangevents.com', 'VE-VIP-025-1', 'QR-VIP-025-1', 0, NULL, NULL);

    -- Order 26
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000026', 'DH-DEMO-026', 'A0000000-0000-0000-0000-000000000036', 'E0000000-0000-0000-0000-000000000009', NULL, N'Khách Hàng Mua Vé 36', 'buyer36@wuangevents.com', '0901234536', 500000, 0, 500000, 1, DATEADD(day, -3, GETUTCDATE()), 'TXN-VNP-026', 1, DATEADD(day, -3, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000026', 18, NULL, 250000, N'Khách Hàng Mua Vé 36', 'buyer36@wuangevents.com', 'VE-STD-026-1', 'QR-STD-026-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000026', 18, NULL, 250000, N'Khách Hàng Mua Vé 36', 'buyer36@wuangevents.com', 'VE-STD-026-2', 'QR-STD-026-2', 0, NULL, NULL);

    -- Order 27
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000027', 'DH-DEMO-027', 'A0000000-0000-0000-0000-000000000022', 'E0000000-0000-0000-0000-000000000050', NULL, N'Khách Hàng Mua Vé 22', 'buyer22@wuangevents.com', '0901234522', 1050000, 0, 1050000, 1, DATEADD(day, -3, GETUTCDATE()), 'TXN-VNP-027', 1, DATEADD(day, -3, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000027', 99, NULL, 800000, N'Khách Hàng Mua Vé 22', 'buyer22@wuangevents.com', 'VE-VIP-027-1', 'QR-VIP-027-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000027', 100, NULL, 250000, N'Khách Hàng Mua Vé 22', 'buyer22@wuangevents.com', 'VE-STD-027-2', 'QR-STD-027-2', 0, NULL, NULL);

    -- Order 28
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000028', 'DH-DEMO-028', 'A0000000-0000-0000-0000-000000000013', 'E0000000-0000-0000-0000-000000000029', NULL, N'Khách Hàng Mua Vé 13', 'buyer13@wuangevents.com', '0901234513', 800000, 0, 800000, 1, DATEADD(day, -5, GETUTCDATE()), 'TXN-VNP-028', 2, DATEADD(day, -5, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000028', 57, NULL, 800000, N'Khách Hàng Mua Vé 13', 'buyer13@wuangevents.com', 'VE-VIP-028-1', 'QR-VIP-028-1', 0, NULL, NULL);

    -- Order 29
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000029', 'DH-DEMO-029', 'A0000000-0000-0000-0000-000000000039', 'E0000000-0000-0000-0000-000000000025', NULL, N'Khách Hàng Mua Vé 39', 'buyer39@wuangevents.com', '0901234539', 750000, 0, 750000, 1, DATEADD(day, -8, GETUTCDATE()), 'TXN-VNP-029', 1, DATEADD(day, -8, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000029', 50, NULL, 250000, N'Khách Hàng Mua Vé 39', 'buyer39@wuangevents.com', 'VE-STD-029-1', 'QR-STD-029-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000029', 50, NULL, 250000, N'Khách Hàng Mua Vé 39', 'buyer39@wuangevents.com', 'VE-STD-029-2', 'QR-STD-029-2', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000029', 50, NULL, 250000, N'Khách Hàng Mua Vé 39', 'buyer39@wuangevents.com', 'VE-STD-029-3', 'QR-STD-029-3', 0, NULL, NULL);

    -- Order 30
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000030', 'DH-DEMO-030', 'A0000000-0000-0000-0000-000000000035', 'E0000000-0000-0000-0000-000000000017', NULL, N'Khách Hàng Mua Vé 35', 'buyer35@wuangevents.com', '0901234535', 1600000, 0, 1600000, 1, DATEADD(day, -20, GETUTCDATE()), 'TXN-VNP-030', 1, DATEADD(day, -20, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000030', 33, NULL, 800000, N'Khách Hàng Mua Vé 35', 'buyer35@wuangevents.com', 'VE-VIP-030-1', 'QR-VIP-030-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000030', 33, NULL, 800000, N'Khách Hàng Mua Vé 35', 'buyer35@wuangevents.com', 'VE-VIP-030-2', 'QR-VIP-030-2', 0, NULL, NULL);

    -- Order 31
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000031', 'DH-DEMO-031', 'A0000000-0000-0000-0000-000000000012', '5BC842AD-6166-406A-AD93-EB3ECACFBF7E', NULL, N'Khách Hàng Mua Vé 12', 'buyer12@wuangevents.com', '0901234512', 250000, 0, 250000, 1, DATEADD(day, -6, GETUTCDATE()), 'TXN-VNP-031', 2, DATEADD(day, -6, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000031', 8, NULL, 250000, N'Khách Hàng Mua Vé 12', 'buyer12@wuangevents.com', 'VE-STD-031-1', 'QR-STD-031-1', 0, NULL, NULL);

    -- Order 32
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000032', 'DH-DEMO-032', 'A0000000-0000-0000-0000-000000000034', 'E0000000-0000-0000-0000-000000000044', NULL, N'Khách Hàng Mua Vé 34', 'buyer34@wuangevents.com', '0901234534', 1050000, 0, 1050000, 1, DATEADD(day, -6, GETUTCDATE()), 'TXN-VNP-032', 2, DATEADD(day, -6, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000032', 87, NULL, 800000, N'Khách Hàng Mua Vé 34', 'buyer34@wuangevents.com', 'VE-VIP-032-1', 'QR-VIP-032-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000032', 88, NULL, 250000, N'Khách Hàng Mua Vé 34', 'buyer34@wuangevents.com', 'VE-STD-032-2', 'QR-STD-032-2', 0, NULL, NULL);

    -- Order 33
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000033', 'DH-DEMO-033', 'A0000000-0000-0000-0000-000000000025', 'E0000000-0000-0000-0000-000000000008', NULL, N'Khách Hàng Mua Vé 25', 'buyer25@wuangevents.com', '0901234525', 500000, 0, 500000, 1, DATEADD(day, -9, GETUTCDATE()), 'TXN-VNP-033', 2, DATEADD(day, -9, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000033', 16, NULL, 250000, N'Khách Hàng Mua Vé 25', 'buyer25@wuangevents.com', 'VE-STD-033-1', 'QR-STD-033-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000033', 16, NULL, 250000, N'Khách Hàng Mua Vé 25', 'buyer25@wuangevents.com', 'VE-STD-033-2', 'QR-STD-033-2', 0, NULL, NULL);

    -- Order 34
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000034', 'DH-DEMO-034', 'A0000000-0000-0000-0000-000000000028', 'E0000000-0000-0000-0000-000000000046', NULL, N'Khách Hàng Mua Vé 28', 'buyer28@wuangevents.com', '0901234528', 1600000, 0, 1600000, 1, DATEADD(day, -18, GETUTCDATE()), 'TXN-VNP-034', 2, DATEADD(day, -18, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000034', 91, NULL, 800000, N'Khách Hàng Mua Vé 28', 'buyer28@wuangevents.com', 'VE-VIP-034-1', 'QR-VIP-034-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000034', 91, NULL, 800000, N'Khách Hàng Mua Vé 28', 'buyer28@wuangevents.com', 'VE-VIP-034-2', 'QR-VIP-034-2', 0, NULL, NULL);

    -- Order 35
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000035', 'DH-DEMO-035', 'A0000000-0000-0000-0000-000000000034', 'E0000000-0000-0000-0000-000000000024', NULL, N'Khách Hàng Mua Vé 34', 'buyer34@wuangevents.com', '0901234534', 750000, 0, 750000, 1, DATEADD(day, -2, GETUTCDATE()), 'TXN-VNP-035', 2, DATEADD(day, -2, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000035', 48, NULL, 250000, N'Khách Hàng Mua Vé 34', 'buyer34@wuangevents.com', 'VE-STD-035-1', 'QR-STD-035-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000035', 48, NULL, 250000, N'Khách Hàng Mua Vé 34', 'buyer34@wuangevents.com', 'VE-STD-035-2', 'QR-STD-035-2', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000035', 48, NULL, 250000, N'Khách Hàng Mua Vé 34', 'buyer34@wuangevents.com', 'VE-STD-035-3', 'QR-STD-035-3', 0, NULL, NULL);

    -- Order 36
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000036', 'DH-DEMO-036', 'A0000000-0000-0000-0000-000000000026', 'E0000000-0000-0000-0000-000000000024', NULL, N'Khách Hàng Mua Vé 26', 'buyer26@wuangevents.com', '0901234526', 1850000, 0, 1850000, 1, DATEADD(day, -12, GETUTCDATE()), 'TXN-VNP-036', 1, DATEADD(day, -12, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000036', 47, NULL, 800000, N'Khách Hàng Mua Vé 26', 'buyer26@wuangevents.com', 'VE-VIP-036-1', 'QR-VIP-036-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000036', 47, NULL, 800000, N'Khách Hàng Mua Vé 26', 'buyer26@wuangevents.com', 'VE-VIP-036-2', 'QR-VIP-036-2', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000036', 48, NULL, 250000, N'Khách Hàng Mua Vé 26', 'buyer26@wuangevents.com', 'VE-STD-036-3', 'QR-STD-036-3', 0, NULL, NULL);

    -- Order 37
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000037', 'DH-DEMO-037', 'A0000000-0000-0000-0000-000000000022', 'E0000000-0000-0000-0000-000000000018', NULL, N'Khách Hàng Mua Vé 22', 'buyer22@wuangevents.com', '0901234522', 1050000, 0, 1050000, 1, DATEADD(day, -16, GETUTCDATE()), 'TXN-VNP-037', 1, DATEADD(day, -16, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000037', 35, NULL, 800000, N'Khách Hàng Mua Vé 22', 'buyer22@wuangevents.com', 'VE-VIP-037-1', 'QR-VIP-037-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000037', 36, NULL, 250000, N'Khách Hàng Mua Vé 22', 'buyer22@wuangevents.com', 'VE-STD-037-2', 'QR-STD-037-2', 0, NULL, NULL);

    -- Order 38
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000038', 'DH-DEMO-038', 'A0000000-0000-0000-0000-000000000019', 'D2C252F2-7FD4-4A02-86CB-3D9DE7415795', NULL, N'Khách Hàng Mua Vé 19', 'buyer19@wuangevents.com', '0901234519', 1050000, 0, 1050000, 0, DATEADD(day, -13, GETUTCDATE()), 'NULL', 1, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000038', 5, NULL, 800000, N'Khách Hàng Mua Vé 19', 'buyer19@wuangevents.com', 'VE-VIP-038-1', 'QR-VIP-038-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000038', 6, NULL, 250000, N'Khách Hàng Mua Vé 19', 'buyer19@wuangevents.com', 'VE-STD-038-2', 'QR-STD-038-2', 0, NULL, NULL);

    -- Order 39
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000039', 'DH-DEMO-039', 'A0000000-0000-0000-0000-000000000038', 'E0000000-0000-0000-0000-000000000018', NULL, N'Khách Hàng Mua Vé 38', 'buyer38@wuangevents.com', '0901234538', 1050000, 0, 1050000, 1, DATEADD(day, -11, GETUTCDATE()), 'TXN-VNP-039', 2, DATEADD(day, -11, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000039', 35, NULL, 800000, N'Khách Hàng Mua Vé 38', 'buyer38@wuangevents.com', 'VE-VIP-039-1', 'QR-VIP-039-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000039', 36, NULL, 250000, N'Khách Hàng Mua Vé 38', 'buyer38@wuangevents.com', 'VE-STD-039-2', 'QR-STD-039-2', 0, NULL, NULL);

    -- Order 40
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000040', 'DH-DEMO-040', 'A0000000-0000-0000-0000-000000000038', 'E0000000-0000-0000-0000-000000000040', NULL, N'Khách Hàng Mua Vé 38', 'buyer38@wuangevents.com', '0901234538', 1050000, 0, 1050000, 1, DATEADD(day, -13, GETUTCDATE()), 'TXN-VNP-040', 1, DATEADD(day, -13, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000040', 79, NULL, 800000, N'Khách Hàng Mua Vé 38', 'buyer38@wuangevents.com', 'VE-VIP-040-1', 'QR-VIP-040-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000040', 80, NULL, 250000, N'Khách Hàng Mua Vé 38', 'buyer38@wuangevents.com', 'VE-STD-040-2', 'QR-STD-040-2', 0, NULL, NULL);

    -- Order 41
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000041', 'DH-DEMO-041', 'A0000000-0000-0000-0000-000000000030', 'D3C3FBCE-4FFF-4F33-A4AF-0A2750C9E94E', NULL, N'Khách Hàng Mua Vé 30', 'buyer30@wuangevents.com', '0901234530', 1850000, 0, 1850000, 1, DATEADD(day, -18, GETUTCDATE()), 'TXN-VNP-041', 2, DATEADD(day, -18, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000041', 1, NULL, 800000, N'Khách Hàng Mua Vé 30', 'buyer30@wuangevents.com', 'VE-VIP-041-1', 'QR-VIP-041-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000041', 1, NULL, 800000, N'Khách Hàng Mua Vé 30', 'buyer30@wuangevents.com', 'VE-VIP-041-2', 'QR-VIP-041-2', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000041', 2, NULL, 250000, N'Khách Hàng Mua Vé 30', 'buyer30@wuangevents.com', 'VE-STD-041-3', 'QR-STD-041-3', 0, NULL, NULL);

    -- Order 42
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000042', 'DH-DEMO-042', 'A0000000-0000-0000-0000-000000000023', 'E0000000-0000-0000-0000-000000000049', NULL, N'Khách Hàng Mua Vé 23', 'buyer23@wuangevents.com', '0901234523', 250000, 0, 250000, 1, DATEADD(day, -20, GETUTCDATE()), 'TXN-VNP-042', 2, DATEADD(day, -20, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000042', 98, NULL, 250000, N'Khách Hàng Mua Vé 23', 'buyer23@wuangevents.com', 'VE-STD-042-1', 'QR-STD-042-1', 0, NULL, NULL);

    -- Order 43
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000043', 'DH-DEMO-043', '00858E32-C188-44CC-8A26-21A599A2F73C', 'E0000000-0000-0000-0000-000000000045', NULL, N'Khách Hàng Mua Vé 9', 'buyer9@wuangevents.com', '0901234509', 250000, 0, 250000, 1, DATEADD(day, -17, GETUTCDATE()), 'TXN-VNP-043', 1, DATEADD(day, -17, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000043', 90, NULL, 250000, N'Khách Hàng Mua Vé 9', 'buyer9@wuangevents.com', 'VE-STD-043-1', 'QR-STD-043-1', 0, NULL, NULL);

    -- Order 44
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000044', 'DH-DEMO-044', 'A0000000-0000-0000-0000-000000000011', 'E0000000-0000-0000-0000-000000000017', NULL, N'Khách Hàng Mua Vé 11', 'buyer11@wuangevents.com', '0901234511', 800000, 0, 800000, 1, DATEADD(day, -1, GETUTCDATE()), 'TXN-VNP-044', 1, DATEADD(day, -1, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000044', 33, NULL, 800000, N'Khách Hàng Mua Vé 11', 'buyer11@wuangevents.com', 'VE-VIP-044-1', 'QR-VIP-044-1', 0, NULL, NULL);

    -- Order 45
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000045', 'DH-DEMO-045', '77EDA4D0-64A0-4CD8-9BC0-C4B56C3DBA52', 'E0000000-0000-0000-0000-000000000026', NULL, N'Khách Hàng Mua Vé 1', 'buyer1@wuangevents.com', '0901234501', 1600000, 0, 1600000, 1, DATEADD(day, -20, GETUTCDATE()), 'TXN-VNP-045', 2, DATEADD(day, -20, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000045', 51, NULL, 800000, N'Khách Hàng Mua Vé 1', 'buyer1@wuangevents.com', 'VE-VIP-045-1', 'QR-VIP-045-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000045', 51, NULL, 800000, N'Khách Hàng Mua Vé 1', 'buyer1@wuangevents.com', 'VE-VIP-045-2', 'QR-VIP-045-2', 0, NULL, NULL);

    -- Order 46
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000046', 'DH-DEMO-046', 'A0000000-0000-0000-0000-000000000018', 'E0000000-0000-0000-0000-000000000053', NULL, N'Khách Hàng Mua Vé 18', 'buyer18@wuangevents.com', '0901234518', 1050000, 0, 1050000, 1, DATEADD(day, -16, GETUTCDATE()), 'TXN-VNP-046', 2, DATEADD(day, -16, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000046', 105, NULL, 800000, N'Khách Hàng Mua Vé 18', 'buyer18@wuangevents.com', 'VE-VIP-046-1', 'QR-VIP-046-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000046', 106, NULL, 250000, N'Khách Hàng Mua Vé 18', 'buyer18@wuangevents.com', 'VE-STD-046-2', 'QR-STD-046-2', 0, NULL, NULL);

    -- Order 47
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000047', 'DH-DEMO-047', 'A0000000-0000-0000-0000-000000000025', 'E0000000-0000-0000-0000-000000000017', NULL, N'Khách Hàng Mua Vé 25', 'buyer25@wuangevents.com', '0901234525', 1850000, 0, 1850000, 1, DATEADD(day, -17, GETUTCDATE()), 'TXN-VNP-047', 1, DATEADD(day, -17, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000047', 33, NULL, 800000, N'Khách Hàng Mua Vé 25', 'buyer25@wuangevents.com', 'VE-VIP-047-1', 'QR-VIP-047-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000047', 33, NULL, 800000, N'Khách Hàng Mua Vé 25', 'buyer25@wuangevents.com', 'VE-VIP-047-2', 'QR-VIP-047-2', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000047', 34, NULL, 250000, N'Khách Hàng Mua Vé 25', 'buyer25@wuangevents.com', 'VE-STD-047-3', 'QR-STD-047-3', 0, NULL, NULL);

    -- Order 48
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000048', 'DH-DEMO-048', '42F528B2-7107-4672-B7FC-3D49A10F63F6', 'E0000000-0000-0000-0000-000000000012', NULL, N'Khách Hàng Mua Vé 6', 'buyer6@wuangevents.com', '0901234506', 1600000, 0, 1600000, 1, DATEADD(day, -5, GETUTCDATE()), 'TXN-VNP-048', 2, DATEADD(day, -5, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000048', 23, NULL, 800000, N'Khách Hàng Mua Vé 6', 'buyer6@wuangevents.com', 'VE-VIP-048-1', 'QR-VIP-048-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000048', 23, NULL, 800000, N'Khách Hàng Mua Vé 6', 'buyer6@wuangevents.com', 'VE-VIP-048-2', 'QR-VIP-048-2', 0, NULL, NULL);

    -- Order 49
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000049', 'DH-DEMO-049', '00858E32-C188-44CC-8A26-21A599A2F73C', 'E0000000-0000-0000-0000-000000000012', NULL, N'Khách Hàng Mua Vé 9', 'buyer9@wuangevents.com', '0901234509', 1600000, 0, 1600000, 1, DATEADD(day, -1, GETUTCDATE()), 'TXN-VNP-049', 2, DATEADD(day, -1, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000049', 23, NULL, 800000, N'Khách Hàng Mua Vé 9', 'buyer9@wuangevents.com', 'VE-VIP-049-1', 'QR-VIP-049-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000049', 23, NULL, 800000, N'Khách Hàng Mua Vé 9', 'buyer9@wuangevents.com', 'VE-VIP-049-2', 'QR-VIP-049-2', 0, NULL, NULL);

    -- Order 50
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000050', 'DH-DEMO-050', '3C416A14-C60B-48F9-9FA5-7CFE1FFCD5E7', 'E0000000-0000-0000-0000-000000000017', NULL, N'Khách Hàng Mua Vé 7', 'buyer7@wuangevents.com', '0901234507', 500000, 0, 500000, 1, DATEADD(day, -8, GETUTCDATE()), 'TXN-VNP-050', 2, DATEADD(day, -8, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000050', 34, NULL, 250000, N'Khách Hàng Mua Vé 7', 'buyer7@wuangevents.com', 'VE-STD-050-1', 'QR-STD-050-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000050', 34, NULL, 250000, N'Khách Hàng Mua Vé 7', 'buyer7@wuangevents.com', 'VE-STD-050-2', 'QR-STD-050-2', 0, NULL, NULL);

    -- Order 51
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000051', 'DH-DEMO-051', 'A0000000-0000-0000-0000-000000000020', 'E0000000-0000-0000-0000-000000000015', NULL, N'Khách Hàng Mua Vé 20', 'buyer20@wuangevents.com', '0901234520', 1050000, 0, 1050000, 1, DATEADD(day, -8, GETUTCDATE()), 'TXN-VNP-051', 2, DATEADD(day, -8, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000051', 29, NULL, 800000, N'Khách Hàng Mua Vé 20', 'buyer20@wuangevents.com', 'VE-VIP-051-1', 'QR-VIP-051-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000051', 30, NULL, 250000, N'Khách Hàng Mua Vé 20', 'buyer20@wuangevents.com', 'VE-STD-051-2', 'QR-STD-051-2', 0, NULL, NULL);

    -- Order 52
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000052', 'DH-DEMO-052', 'A0000000-0000-0000-0000-000000000024', 'E0000000-0000-0000-0000-000000000051', NULL, N'Khách Hàng Mua Vé 24', 'buyer24@wuangevents.com', '0901234524', 1850000, 0, 1850000, 1, DATEADD(day, -7, GETUTCDATE()), 'TXN-VNP-052', 2, DATEADD(day, -7, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000052', 101, NULL, 800000, N'Khách Hàng Mua Vé 24', 'buyer24@wuangevents.com', 'VE-VIP-052-1', 'QR-VIP-052-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000052', 101, NULL, 800000, N'Khách Hàng Mua Vé 24', 'buyer24@wuangevents.com', 'VE-VIP-052-2', 'QR-VIP-052-2', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000052', 102, NULL, 250000, N'Khách Hàng Mua Vé 24', 'buyer24@wuangevents.com', 'VE-STD-052-3', 'QR-STD-052-3', 0, NULL, NULL);

    -- Order 53
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000053', 'DH-DEMO-053', 'A0000000-0000-0000-0000-000000000028', 'E0000000-0000-0000-0000-000000000015', NULL, N'Khách Hàng Mua Vé 28', 'buyer28@wuangevents.com', '0901234528', 1850000, 0, 1850000, 1, DATEADD(day, -6, GETUTCDATE()), 'TXN-VNP-053', 1, DATEADD(day, -6, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000053', 29, NULL, 800000, N'Khách Hàng Mua Vé 28', 'buyer28@wuangevents.com', 'VE-VIP-053-1', 'QR-VIP-053-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000053', 29, NULL, 800000, N'Khách Hàng Mua Vé 28', 'buyer28@wuangevents.com', 'VE-VIP-053-2', 'QR-VIP-053-2', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000053', 30, NULL, 250000, N'Khách Hàng Mua Vé 28', 'buyer28@wuangevents.com', 'VE-STD-053-3', 'QR-STD-053-3', 0, NULL, NULL);

    -- Order 54
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000054', 'DH-DEMO-054', 'A0000000-0000-0000-0000-000000000026', 'E0000000-0000-0000-0000-000000000026', NULL, N'Khách Hàng Mua Vé 26', 'buyer26@wuangevents.com', '0901234526', 1850000, 0, 1850000, 1, DATEADD(day, -3, GETUTCDATE()), 'TXN-VNP-054', 1, DATEADD(day, -3, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000054', 51, NULL, 800000, N'Khách Hàng Mua Vé 26', 'buyer26@wuangevents.com', 'VE-VIP-054-1', 'QR-VIP-054-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000054', 51, NULL, 800000, N'Khách Hàng Mua Vé 26', 'buyer26@wuangevents.com', 'VE-VIP-054-2', 'QR-VIP-054-2', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000054', 52, NULL, 250000, N'Khách Hàng Mua Vé 26', 'buyer26@wuangevents.com', 'VE-STD-054-3', 'QR-STD-054-3', 0, NULL, NULL);

    -- Order 55
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000055', 'DH-DEMO-055', '3C416A14-C60B-48F9-9FA5-7CFE1FFCD5E7', 'E0000000-0000-0000-0000-000000000036', NULL, N'Khách Hàng Mua Vé 7', 'buyer7@wuangevents.com', '0901234507', 500000, 0, 500000, 0, DATEADD(day, -6, GETUTCDATE()), 'NULL', 2, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000055', 72, NULL, 250000, N'Khách Hàng Mua Vé 7', 'buyer7@wuangevents.com', 'VE-STD-055-1', 'QR-STD-055-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000055', 72, NULL, 250000, N'Khách Hàng Mua Vé 7', 'buyer7@wuangevents.com', 'VE-STD-055-2', 'QR-STD-055-2', 0, NULL, NULL);

    -- Order 56
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000056', 'DH-DEMO-056', 'A0000000-0000-0000-0000-000000000024', 'E0000000-0000-0000-0000-000000000012', NULL, N'Khách Hàng Mua Vé 24', 'buyer24@wuangevents.com', '0901234524', 800000, 0, 800000, 1, DATEADD(day, -5, GETUTCDATE()), 'TXN-VNP-056', 1, DATEADD(day, -5, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000056', 23, NULL, 800000, N'Khách Hàng Mua Vé 24', 'buyer24@wuangevents.com', 'VE-VIP-056-1', 'QR-VIP-056-1', 0, NULL, NULL);

    -- Order 57
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000057', 'DH-DEMO-057', 'A0000000-0000-0000-0000-000000000030', 'E0000000-0000-0000-0000-000000000049', NULL, N'Khách Hàng Mua Vé 30', 'buyer30@wuangevents.com', '0901234530', 500000, 0, 500000, 1, DATEADD(day, -18, GETUTCDATE()), 'TXN-VNP-057', 2, DATEADD(day, -18, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000057', 98, NULL, 250000, N'Khách Hàng Mua Vé 30', 'buyer30@wuangevents.com', 'VE-STD-057-1', 'QR-STD-057-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000057', 98, NULL, 250000, N'Khách Hàng Mua Vé 30', 'buyer30@wuangevents.com', 'VE-STD-057-2', 'QR-STD-057-2', 0, NULL, NULL);

    -- Order 58
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000058', 'DH-DEMO-058', 'A0000000-0000-0000-0000-000000000032', 'E0000000-0000-0000-0000-000000000013', NULL, N'Khách Hàng Mua Vé 32', 'buyer32@wuangevents.com', '0901234532', 1600000, 0, 1600000, 1, DATEADD(day, -1, GETUTCDATE()), 'TXN-VNP-058', 2, DATEADD(day, -1, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000058', 25, NULL, 800000, N'Khách Hàng Mua Vé 32', 'buyer32@wuangevents.com', 'VE-VIP-058-1', 'QR-VIP-058-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000058', 25, NULL, 800000, N'Khách Hàng Mua Vé 32', 'buyer32@wuangevents.com', 'VE-VIP-058-2', 'QR-VIP-058-2', 0, NULL, NULL);

    -- Order 59
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000059', 'DH-DEMO-059', 'A0000000-0000-0000-0000-000000000030', 'E0000000-0000-0000-0000-000000000050', NULL, N'Khách Hàng Mua Vé 30', 'buyer30@wuangevents.com', '0901234530', 250000, 0, 250000, 1, DATEADD(day, -13, GETUTCDATE()), 'TXN-VNP-059', 2, DATEADD(day, -13, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000059', 100, NULL, 250000, N'Khách Hàng Mua Vé 30', 'buyer30@wuangevents.com', 'VE-STD-059-1', 'QR-STD-059-1', 0, NULL, NULL);

    -- Order 60
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000060', 'DH-DEMO-060', 'A0000000-0000-0000-0000-000000000036', 'E0000000-0000-0000-0000-000000000050', NULL, N'Khách Hàng Mua Vé 36', 'buyer36@wuangevents.com', '0901234536', 800000, 0, 800000, 1, DATEADD(day, -18, GETUTCDATE()), 'TXN-VNP-060', 1, DATEADD(day, -18, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000060', 99, NULL, 800000, N'Khách Hàng Mua Vé 36', 'buyer36@wuangevents.com', 'VE-VIP-060-1', 'QR-VIP-060-1', 0, NULL, NULL);

    -- Order 61
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000061', 'DH-DEMO-061', 'A0000000-0000-0000-0000-000000000035', 'E0000000-0000-0000-0000-000000000020', NULL, N'Khách Hàng Mua Vé 35', 'buyer35@wuangevents.com', '0901234535', 800000, 0, 800000, 1, DATEADD(day, -10, GETUTCDATE()), 'TXN-VNP-061', 1, DATEADD(day, -10, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000061', 39, NULL, 800000, N'Khách Hàng Mua Vé 35', 'buyer35@wuangevents.com', 'VE-VIP-061-1', 'QR-VIP-061-1', 0, NULL, NULL);

    -- Order 62
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000062', 'DH-DEMO-062', 'DB847C61-CC0B-41F5-9BEB-F6132B0E5BF2', 'E0000000-0000-0000-0000-000000000049', NULL, N'Khách Hàng Mua Vé 2', 'buyer2@wuangevents.com', '0901234502', 1850000, 0, 1850000, 1, DATEADD(day, -4, GETUTCDATE()), 'TXN-VNP-062', 2, DATEADD(day, -4, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000062', 97, NULL, 800000, N'Khách Hàng Mua Vé 2', 'buyer2@wuangevents.com', 'VE-VIP-062-1', 'QR-VIP-062-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000062', 97, NULL, 800000, N'Khách Hàng Mua Vé 2', 'buyer2@wuangevents.com', 'VE-VIP-062-2', 'QR-VIP-062-2', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000062', 98, NULL, 250000, N'Khách Hàng Mua Vé 2', 'buyer2@wuangevents.com', 'VE-STD-062-3', 'QR-STD-062-3', 0, NULL, NULL);

    -- Order 63
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000063', 'DH-DEMO-063', 'A0000000-0000-0000-0000-000000000028', 'E0000000-0000-0000-0000-000000000058', NULL, N'Khách Hàng Mua Vé 28', 'buyer28@wuangevents.com', '0901234528', 750000, 0, 750000, 1, DATEADD(day, -19, GETUTCDATE()), 'TXN-VNP-063', 1, DATEADD(day, -19, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000063', 116, NULL, 250000, N'Khách Hàng Mua Vé 28', 'buyer28@wuangevents.com', 'VE-STD-063-1', 'QR-STD-063-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000063', 116, NULL, 250000, N'Khách Hàng Mua Vé 28', 'buyer28@wuangevents.com', 'VE-STD-063-2', 'QR-STD-063-2', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000063', 116, NULL, 250000, N'Khách Hàng Mua Vé 28', 'buyer28@wuangevents.com', 'VE-STD-063-3', 'QR-STD-063-3', 0, NULL, NULL);

    -- Order 64
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000064', 'DH-DEMO-064', '42F528B2-7107-4672-B7FC-3D49A10F63F6', 'E0000000-0000-0000-0000-000000000007', NULL, N'Khách Hàng Mua Vé 6', 'buyer6@wuangevents.com', '0901234506', 1600000, 0, 1600000, 1, DATEADD(day, -17, GETUTCDATE()), 'TXN-VNP-064', 1, DATEADD(day, -17, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000064', 13, NULL, 800000, N'Khách Hàng Mua Vé 6', 'buyer6@wuangevents.com', 'VE-VIP-064-1', 'QR-VIP-064-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000064', 13, NULL, 800000, N'Khách Hàng Mua Vé 6', 'buyer6@wuangevents.com', 'VE-VIP-064-2', 'QR-VIP-064-2', 0, NULL, NULL);

    -- Order 65
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000065', 'DH-DEMO-065', 'A0000000-0000-0000-0000-000000000017', 'E0000000-0000-0000-0000-000000000021', NULL, N'Khách Hàng Mua Vé 17', 'buyer17@wuangevents.com', '0901234517', 1050000, 0, 1050000, 1, DATEADD(day, -10, GETUTCDATE()), 'TXN-VNP-065', 2, DATEADD(day, -10, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000065', 41, NULL, 800000, N'Khách Hàng Mua Vé 17', 'buyer17@wuangevents.com', 'VE-VIP-065-1', 'QR-VIP-065-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000065', 42, NULL, 250000, N'Khách Hàng Mua Vé 17', 'buyer17@wuangevents.com', 'VE-STD-065-2', 'QR-STD-065-2', 0, NULL, NULL);

    -- Order 66
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000066', 'DH-DEMO-066', 'A0000000-0000-0000-0000-000000000032', 'D2C252F2-7FD4-4A02-86CB-3D9DE7415795', NULL, N'Khách Hàng Mua Vé 32', 'buyer32@wuangevents.com', '0901234532', 500000, 0, 500000, 1, DATEADD(day, -2, GETUTCDATE()), 'TXN-VNP-066', 2, DATEADD(day, -2, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000066', 6, NULL, 250000, N'Khách Hàng Mua Vé 32', 'buyer32@wuangevents.com', 'VE-STD-066-1', 'QR-STD-066-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000066', 6, NULL, 250000, N'Khách Hàng Mua Vé 32', 'buyer32@wuangevents.com', 'VE-STD-066-2', 'QR-STD-066-2', 0, NULL, NULL);

    -- Order 67
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000067', 'DH-DEMO-067', 'A0000000-0000-0000-0000-000000000011', 'E0000000-0000-0000-0000-000000000026', NULL, N'Khách Hàng Mua Vé 11', 'buyer11@wuangevents.com', '0901234511', 250000, 0, 250000, 1, DATEADD(day, -4, GETUTCDATE()), 'TXN-VNP-067', 1, DATEADD(day, -4, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000067', 52, NULL, 250000, N'Khách Hàng Mua Vé 11', 'buyer11@wuangevents.com', 'VE-STD-067-1', 'QR-STD-067-1', 0, NULL, NULL);

    -- Order 68
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000068', 'DH-DEMO-068', 'A0000000-0000-0000-0000-000000000023', 'E0000000-0000-0000-0000-000000000027', NULL, N'Khách Hàng Mua Vé 23', 'buyer23@wuangevents.com', '0901234523', 800000, 0, 800000, 1, DATEADD(day, -6, GETUTCDATE()), 'TXN-VNP-068', 1, DATEADD(day, -6, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000068', 53, NULL, 800000, N'Khách Hàng Mua Vé 23', 'buyer23@wuangevents.com', 'VE-VIP-068-1', 'QR-VIP-068-1', 0, NULL, NULL);

    -- Order 69
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000069', 'DH-DEMO-069', 'A0000000-0000-0000-0000-000000000030', 'E0000000-0000-0000-0000-000000000011', NULL, N'Khách Hàng Mua Vé 30', 'buyer30@wuangevents.com', '0901234530', 1050000, 0, 1050000, 1, DATEADD(day, -10, GETUTCDATE()), 'TXN-VNP-069', 1, DATEADD(day, -10, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000069', 21, NULL, 800000, N'Khách Hàng Mua Vé 30', 'buyer30@wuangevents.com', 'VE-VIP-069-1', 'QR-VIP-069-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000069', 22, NULL, 250000, N'Khách Hàng Mua Vé 30', 'buyer30@wuangevents.com', 'VE-STD-069-2', 'QR-STD-069-2', 0, NULL, NULL);

    -- Order 70
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000070', 'DH-DEMO-070', 'A0000000-0000-0000-0000-000000000033', 'E0000000-0000-0000-0000-000000000052', NULL, N'Khách Hàng Mua Vé 33', 'buyer33@wuangevents.com', '0901234533', 750000, 0, 750000, 1, DATEADD(day, -9, GETUTCDATE()), 'TXN-VNP-070', 2, DATEADD(day, -9, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000070', 104, NULL, 250000, N'Khách Hàng Mua Vé 33', 'buyer33@wuangevents.com', 'VE-STD-070-1', 'QR-STD-070-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000070', 104, NULL, 250000, N'Khách Hàng Mua Vé 33', 'buyer33@wuangevents.com', 'VE-STD-070-2', 'QR-STD-070-2', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000070', 104, NULL, 250000, N'Khách Hàng Mua Vé 33', 'buyer33@wuangevents.com', 'VE-STD-070-3', 'QR-STD-070-3', 0, NULL, NULL);

    -- Order 71
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000071', 'DH-DEMO-071', 'A0000000-0000-0000-0000-000000000024', 'E0000000-0000-0000-0000-000000000042', NULL, N'Khách Hàng Mua Vé 24', 'buyer24@wuangevents.com', '0901234524', 800000, 0, 800000, 1, DATEADD(day, -4, GETUTCDATE()), 'TXN-VNP-071', 1, DATEADD(day, -4, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000071', 83, NULL, 800000, N'Khách Hàng Mua Vé 24', 'buyer24@wuangevents.com', 'VE-VIP-071-1', 'QR-VIP-071-1', 0, NULL, NULL);

    -- Order 72
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000072', 'DH-DEMO-072', 'A0000000-0000-0000-0000-000000000017', 'E0000000-0000-0000-0000-000000000047', NULL, N'Khách Hàng Mua Vé 17', 'buyer17@wuangevents.com', '0901234517', 800000, 0, 800000, 1, DATEADD(day, -12, GETUTCDATE()), 'TXN-VNP-072', 1, DATEADD(day, -12, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000072', 93, NULL, 800000, N'Khách Hàng Mua Vé 17', 'buyer17@wuangevents.com', 'VE-VIP-072-1', 'QR-VIP-072-1', 0, NULL, NULL);

    -- Order 73
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000073', 'DH-DEMO-073', 'FE3E3726-2435-43B9-9688-308CA7D1F34A', 'E0000000-0000-0000-0000-000000000052', NULL, N'Khách Hàng Mua Vé 4', 'buyer4@wuangevents.com', '0901234504', 800000, 0, 800000, 1, DATEADD(day, -9, GETUTCDATE()), 'TXN-VNP-073', 1, DATEADD(day, -9, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000073', 103, NULL, 800000, N'Khách Hàng Mua Vé 4', 'buyer4@wuangevents.com', 'VE-VIP-073-1', 'QR-VIP-073-1', 0, NULL, NULL);

    -- Order 74
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000074', 'DH-DEMO-074', '42F528B2-7107-4672-B7FC-3D49A10F63F6', 'E0000000-0000-0000-0000-000000000044', NULL, N'Khách Hàng Mua Vé 6', 'buyer6@wuangevents.com', '0901234506', 500000, 0, 500000, 1, DATEADD(day, -8, GETUTCDATE()), 'TXN-VNP-074', 1, DATEADD(day, -8, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000074', 88, NULL, 250000, N'Khách Hàng Mua Vé 6', 'buyer6@wuangevents.com', 'VE-STD-074-1', 'QR-STD-074-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000074', 88, NULL, 250000, N'Khách Hàng Mua Vé 6', 'buyer6@wuangevents.com', 'VE-STD-074-2', 'QR-STD-074-2', 0, NULL, NULL);

    -- Order 75
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000075', 'DH-DEMO-075', 'A0000000-0000-0000-0000-000000000029', 'E0000000-0000-0000-0000-000000000046', NULL, N'Khách Hàng Mua Vé 29', 'buyer29@wuangevents.com', '0901234529', 250000, 0, 250000, 1, DATEADD(day, -18, GETUTCDATE()), 'TXN-VNP-075', 1, DATEADD(day, -18, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000075', 92, NULL, 250000, N'Khách Hàng Mua Vé 29', 'buyer29@wuangevents.com', 'VE-STD-075-1', 'QR-STD-075-1', 0, NULL, NULL);

    -- Order 76
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000076', 'DH-DEMO-076', 'A0000000-0000-0000-0000-000000000037', 'E0000000-0000-0000-0000-000000000010', NULL, N'Khách Hàng Mua Vé 37', 'buyer37@wuangevents.com', '0901234537', 800000, 0, 800000, 1, DATEADD(day, -18, GETUTCDATE()), 'TXN-VNP-076', 1, DATEADD(day, -18, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000076', 19, NULL, 800000, N'Khách Hàng Mua Vé 37', 'buyer37@wuangevents.com', 'VE-VIP-076-1', 'QR-VIP-076-1', 0, NULL, NULL);

    -- Order 77
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000077', 'DH-DEMO-077', 'A0000000-0000-0000-0000-000000000021', 'E0000000-0000-0000-0000-000000000023', NULL, N'Khách Hàng Mua Vé 21', 'buyer21@wuangevents.com', '0901234521', 800000, 0, 800000, 1, DATEADD(day, -7, GETUTCDATE()), 'TXN-VNP-077', 1, DATEADD(day, -7, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000077', 45, NULL, 800000, N'Khách Hàng Mua Vé 21', 'buyer21@wuangevents.com', 'VE-VIP-077-1', 'QR-VIP-077-1', 0, NULL, NULL);

    -- Order 78
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000078', 'DH-DEMO-078', 'A0000000-0000-0000-0000-000000000015', '5BC842AD-6166-406A-AD93-EB3ECACFBF7E', NULL, N'Khách Hàng Mua Vé 15', 'buyer15@wuangevents.com', '0901234515', 1850000, 0, 1850000, 1, DATEADD(day, -20, GETUTCDATE()), 'TXN-VNP-078', 2, DATEADD(day, -20, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000078', 7, NULL, 800000, N'Khách Hàng Mua Vé 15', 'buyer15@wuangevents.com', 'VE-VIP-078-1', 'QR-VIP-078-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000078', 7, NULL, 800000, N'Khách Hàng Mua Vé 15', 'buyer15@wuangevents.com', 'VE-VIP-078-2', 'QR-VIP-078-2', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000078', 8, NULL, 250000, N'Khách Hàng Mua Vé 15', 'buyer15@wuangevents.com', 'VE-STD-078-3', 'QR-STD-078-3', 0, NULL, NULL);

    -- Order 79
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000079', 'DH-DEMO-079', 'A0000000-0000-0000-0000-000000000031', 'E0000000-0000-0000-0000-000000000015', NULL, N'Khách Hàng Mua Vé 31', 'buyer31@wuangevents.com', '0901234531', 1850000, 0, 1850000, 1, DATEADD(day, -5, GETUTCDATE()), 'TXN-VNP-079', 1, DATEADD(day, -5, GETUTCDATE()));

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000079', 29, NULL, 800000, N'Khách Hàng Mua Vé 31', 'buyer31@wuangevents.com', 'VE-VIP-079-1', 'QR-VIP-079-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000079', 29, NULL, 800000, N'Khách Hàng Mua Vé 31', 'buyer31@wuangevents.com', 'VE-VIP-079-2', 'QR-VIP-079-2', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000079', 30, NULL, 250000, N'Khách Hàng Mua Vé 31', 'buyer31@wuangevents.com', 'VE-STD-079-3', 'QR-STD-079-3', 0, NULL, NULL);

    -- Order 80
    INSERT INTO [dbo].[DonHang] ([Id], [MaDonHang], [NguoiMuaId], [SuKienId], [MaGiamGiaId], [HoTenNguoiMua], [EmailNguoiMua], [SdtNguoiMua], [TongTienVe], [TienGiamGia], [TongThanhToan], [TrangThai], [NgayTao], [MaGiaoDich], [PhuongThucThanhToan], [NgayThanhToan])
    VALUES ('D1000000-0000-0000-0000-000000000080', 'DH-DEMO-080', 'A0000000-0000-0000-0000-000000000030', 'E0000000-0000-0000-0000-000000000025', NULL, N'Khách Hàng Mua Vé 30', 'buyer30@wuangevents.com', '0901234530', 1050000, 0, 1050000, 0, DATEADD(day, -1, GETUTCDATE()), 'NULL', 1, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000080', 49, NULL, 800000, N'Khách Hàng Mua Vé 30', 'buyer30@wuangevents.com', 'VE-VIP-080-1', 'QR-VIP-080-1', 0, NULL, NULL);

    INSERT INTO [dbo].[ChiTietDonHang] ([DonHangId], [LoaiVeId], [ChoNgoiId], [GiaVe], [TenNguoiThamDu], [EmailNguoiThamDu], [MaVe], [MaQRCode], [TrangThaiCheckin], [NgayCheckin], [NguoiCheckinId])
    VALUES ('D1000000-0000-0000-0000-000000000080', 50, NULL, 250000, N'Khách Hàng Mua Vé 30', 'buyer30@wuangevents.com', 'VE-STD-080-2', 'QR-STD-080-2', 0, NULL, NULL);


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
