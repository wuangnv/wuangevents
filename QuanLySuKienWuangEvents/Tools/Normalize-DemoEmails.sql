/*
    Đồng bộ email dữ liệu demo hiện có với Database_WuangEvents.sql.
    - Tất cả tài khoản demo dùng đuôi @gmail.com.
    - buyer1 là tài khoản nhận email demo thật.
    Chạy bằng Windows Authentication: sqlcmd -S localhost -d WuangEvents -E -i Tools\Normalize-DemoEmails.sql
*/
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET QUOTED_IDENTIFIER ON;
SET NUMERIC_ROUNDABORT OFF;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

DECLARE @Buyer1Id UNIQUEIDENTIFIER = '77EDA4D0-64A0-4CD8-9BC0-C4B56C3DBA52';
DECLARE @Buyer1Email NVARCHAR(255) = N'battlegrounds2004@gmail.com';

-- Dừng an toàn nếu email thật đã thuộc một tài khoản khác.
IF EXISTS (
    SELECT 1
    FROM dbo.NguoiDung
    WHERE Email = @Buyer1Email
      AND Id <> @Buyer1Id
)
BEGIN
    ROLLBACK TRANSACTION;
    THROW 51020, N'Email battlegrounds2004@gmail.com đang thuộc một tài khoản khác.', 1;
END;

-- Email trên đơn và vé là bản ghi lịch sử, cần đổi cùng tài khoản để màn hình demo thống nhất.
UPDATE dbo.DonHang
SET EmailNguoiMua = CASE
    WHEN EmailNguoiMua = N'buyer1@wuangevents.com' THEN @Buyer1Email
    ELSE REPLACE(EmailNguoiMua, N'@wuangevents.com', N'@gmail.com')
END
WHERE EmailNguoiMua LIKE N'%@wuangevents.com';

UPDATE dbo.ChiTietDonHang
SET EmailNguoiThamDu = CASE
    WHEN EmailNguoiThamDu = N'buyer1@wuangevents.com' THEN @Buyer1Email
    ELSE REPLACE(EmailNguoiThamDu, N'@wuangevents.com', N'@gmail.com')
END
WHERE EmailNguoiThamDu LIKE N'%@wuangevents.com';

UPDATE dbo.NguoiDung
SET Email = CASE
    WHEN Id = @Buyer1Id THEN @Buyer1Email
    ELSE REPLACE(Email, N'@wuangevents.com', N'@gmail.com')
END
WHERE Email LIKE N'%@wuangevents.com';

COMMIT TRANSACTION;

SELECT Email, HoTen, VaiTro
FROM dbo.NguoiDung
WHERE Id = @Buyer1Id;
