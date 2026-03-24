@echo off
setlocal enabledelayedexpansion
title Versatile Suite - Uninstaller

echo.
echo  Versatile Suite - Windows Uninstaller
echo  ======================================
echo.

:: ---- Admin check ----
net session >nul 2>&1
if errorlevel 1 (
    echo [!] Administrator privileges required.
    echo     Please right-click and "Run as administrator".
    pause
    exit /b 1
)
echo [OK] Running as administrator.
echo.

:: ---- Detect installations ----
set "VL_DIR="
set "VS_DIR="
set "VL_VER="
set "VS_VER="

for /f "tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Verslang" /v InstallLocation 2^>nul') do set "VL_DIR=%%b"
for /f "tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Verslang" /v DisplayVersion 2^>nul') do set "VL_VER=%%b"
for /f "tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Versscript" /v InstallLocation 2^>nul') do set "VS_DIR=%%b"
for /f "tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Versscript" /v DisplayVersion 2^>nul') do set "VS_VER=%%b"

if not defined VL_DIR if not defined VS_DIR (
    echo No Versatile Suite products found on this system.
    pause
    exit /b 0
)

echo Detected installations:
if defined VL_DIR echo   [*] Verslang %VL_VER% at %VL_DIR%
if defined VS_DIR echo   [*] Versscript %VS_VER% at %VS_DIR%
echo.

:: ---- Selection ----
echo What would you like to uninstall?
echo   [1] Verslang only
echo   [2] Versscript only
echo   [3] Everything
echo   [4] Cancel
echo.
set /p "CHOICE=Enter choice (1-4): "

if "%CHOICE%"=="4" exit /b 0

set "RM_VL=0"
set "RM_VS=0"
if "%CHOICE%"=="1" set "RM_VL=1"
if "%CHOICE%"=="2" set "RM_VS=1"
if "%CHOICE%"=="3" set "RM_VL=1" & set "RM_VS=1"

echo.
echo Are you sure? This will remove all selected components.
set /p "CONFIRM=Continue? [y/N]: "
if /i not "%CONFIRM%"=="y" (
    echo Cancelled.
    pause
    exit /b 0
)
echo.

:: ========================= Uninstall Verslang =========================
if "%RM_VL%"=="1" if defined VL_DIR (
    echo ---- Uninstalling Verslang ----
    echo.

    :: Remove from PATH
    echo Removing Verslang from PATH...
    for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYSPATH=%%b"
    set "NEW_PATH=!SYSPATH!"
    set "NEW_PATH=!NEW_PATH:;%VL_DIR%\bin=!"
    set "NEW_PATH=!NEW_PATH:%VL_DIR%\bin;=!"
    set "NEW_PATH=!NEW_PATH:%VL_DIR%\bin=!"
    if not "!NEW_PATH!"=="!SYSPATH!" (
        setx /M Path "!NEW_PATH!" >nul
        echo [OK] Removed from PATH
    )

    :: Remove file association
    echo Removing .vlang file association...
    assoc .vlang= >nul 2>nul
    ftype VerslangFile= >nul 2>nul
    reg delete "HKCR\.vlang" /f >nul 2>nul
    reg delete "HKCR\VerslangFile" /f >nul 2>nul
    echo [OK] Removed file association

    :: Remove registry uninstall entry
    reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Verslang" /f >nul 2>nul
    echo [OK] Removed registry entries

    :: Remove files
    echo Removing installation directory...
    if exist "%VL_DIR%" (
        rd /s /q "%VL_DIR%"
        echo [OK] Removed %VL_DIR%
    )

    :: Remove shortcuts
    if exist "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Verslang" (
        rd /s /q "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Verslang"
        echo [OK] Removed Start Menu entry
    )
    if exist "%Public%\Desktop\Verslang.lnk" (
        del /q "%Public%\Desktop\Verslang.lnk"
        echo [OK] Removed desktop shortcut
    )

    echo [OK] Verslang uninstalled
    echo.
)

:: ========================= Uninstall Versscript =========================
if "%RM_VS%"=="1" if defined VS_DIR (
    echo ---- Uninstalling Versscript ----
    echo.

    :: Remove from PATH
    echo Removing Versscript from PATH...
    for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYSPATH=%%b"
    set "NEW_PATH=!SYSPATH!"
    set "NEW_PATH=!NEW_PATH:;%VS_DIR%\bin=!"
    set "NEW_PATH=!NEW_PATH:%VS_DIR%\bin;=!"
    set "NEW_PATH=!NEW_PATH:%VS_DIR%\bin=!"
    if not "!NEW_PATH!"=="!SYSPATH!" (
        setx /M Path "!NEW_PATH!" >nul
        echo [OK] Removed from PATH
    )

    :: Remove file associations
    echo Removing .vs/.verss file associations...
    assoc .vs= >nul 2>nul
    assoc .verss= >nul 2>nul
    ftype VersscriptFile= >nul 2>nul
    reg delete "HKCR\.vs" /f >nul 2>nul
    reg delete "HKCR\.verss" /f >nul 2>nul
    reg delete "HKCR\VersscriptFile" /f >nul 2>nul
    echo [OK] Removed file associations

    :: Remove registry
    reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Versscript" /f >nul 2>nul
    echo [OK] Removed registry entries

    :: Remove files
    echo Removing installation directory...
    if exist "%VS_DIR%" (
        rd /s /q "%VS_DIR%"
        echo [OK] Removed %VS_DIR%
    )

    :: Remove shortcuts
    if exist "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Versscript" (
        rd /s /q "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Versscript"
        echo [OK] Removed Start Menu entry
    )
    if exist "%Public%\Desktop\Versscript REPL.lnk" (
        del /q "%Public%\Desktop\Versscript REPL.lnk"
        echo [OK] Removed desktop shortcut
    )

    echo [OK] Versscript uninstalled
    echo.
)

:: ========================= Done =========================
echo ================================================
echo   Uninstallation Complete!
echo ================================================
echo.
echo   Please restart your terminal for PATH changes.
echo.
pause
