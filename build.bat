@echo off
setlocal enabledelayedexpansion

set PLATFORM=%1
if "%PLATFORM%"=="" (
    echo Usage: build.bat [apk^|windows^|all]
    echo Example: build.bat apk
    exit /b 1
)

echo.
echo ==========================================
echo [1/4] Cleaning Project...
echo ==========================================
call flutter clean

echo.
echo ==========================================
echo [2/4] Getting Dependencies...
echo ==========================================
call flutter pub get

echo.
echo ==========================================
echo [3/4] Generating Launcher Icons...
echo ==========================================
call dart run flutter_launcher_icons

echo.
echo ==========================================
echo [4/4] Building Application...
echo ==========================================

if /i "%PLATFORM%"=="apk" (
    echo Building Android APK...
    call flutter build apk --release
) else if /i "%PLATFORM%"=="windows" (
    echo Building Windows Desktop...
    call flutter build windows --release
) else if /i "%PLATFORM%"=="all" (
    echo Building Android APK...
    call flutter build apk --release
    echo.
    echo Building Windows Desktop...
    call flutter build windows --release
) else (
    echo Unknown platform: %PLATFORM%
    echo Supported: apk, windows, all
    exit /b 1
)

echo.
echo ==========================================
echo Build Process Completed Successfully!
echo ==========================================
pause
