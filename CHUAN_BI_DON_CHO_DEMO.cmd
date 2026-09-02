@echo off
setlocal
chcp 65001 >nul

rem Run this file before each demo to rebuild time-aware demo data.
rem It only resets the WuangEvents demo database.
set "SQL_SERVER=localhost"
set "DATABASE=WuangEvents"
set "ROOT=%~dp0"
set "PROJECT=%ROOT%QuanLySuKienWuangEvents"

where sqlcmd >nul 2>&1
if errorlevel 1 (
    echo Khong tim thay sqlcmd. Hay cai SQL Server Command Line Utilities hoac chay file Database_WuangEvents.sql bang SSMS.
    pause
    exit /b 1
)

if not exist "%PROJECT%\Database_WuangEvents.sql" (
    echo Khong tim thay file seed Database_WuangEvents.sql.
    pause
    exit /b 1
)

echo.
echo Dang dung lai database %DATABASE% tren %SQL_SERVER%...
sqlcmd -S "%SQL_SERVER%" -d master -E -C -b -f i:65001,o:65001 -i "%PROJECT%\Database_WuangEvents.sql"
if errorlevel 1 (
    echo.
    echo Seed that bai. Kiem tra SQL Server dang chay va chuoi ket noi trong appsettings.json.
    pause
    exit /b 1
)

echo.
echo Dang kiem tra ma tran du lieu demo...
sqlcmd -S "%SQL_SERVER%" -d "%DATABASE%" -E -C -b -f i:65001,o:65001 -i "%PROJECT%\Tools\Verify-DemoData.sql"
if errorlevel 1 (
    echo.
    echo Seed da chay nhung du lieu demo chua dat kiem tra. Khong nen demo cho den khi sua xong loi tren.
    pause
    exit /b 1
)

echo.
echo HOAN TAT: du lieu demo da duoc can theo thoi diem hien tai va da qua kiem tra.
echo Tai khoan demo dung mat khau 123456. Don cho thanh toan moi co hieu luc 10 phut.
pause
