@echo off
setlocal enabledelayedexpansion
title Versatile Suite - Windows Installer (CLI)

:: ================================================
:: Versatile Suite CLI Installer for Windows
:: Installs Verslang and/or Versscript from built-in
:: source directories or ZIP packages.
:: ================================================

echo.
echo  ____   ____                    _   _ _
echo  \   \ /   /__ _ __ ___  __ _ ^| ^|_^(_) ^| ___
echo   \   V  / _ \ '__/ __|/ _` ^| __^| ^| ^|/ _ \
echo    \   / (__ ) ^|  \__ \ (_^| ^| ^|_^| ^| ^|  __/
echo     \_/ \___^|_^|  ^|___/\__,_^|\__^|_^|_^|\___^|
echo.
echo  Versatile Language Suite - Windows Installer v1.0
echo  ================================================
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

:: ---- Detect source dirs ----
set "SCRIPT_DIR=%~dp0"
set "VL_SRC="
set "VS_SRC="
set "VSIX_PATH="

:: Look for Verslang
for %%p in ("%SCRIPT_DIR%..\Verslang" "%SCRIPT_DIR%..\..\Verslang" "%SCRIPT_DIR%Verslang") do (
    if exist "%%~p\build\verslang.exe" (
        set "VL_SRC=%%~fp"
        goto :found_vl
    )
)
:found_vl

:: Look for Versscript
for %%p in ("%SCRIPT_DIR%..\Versscript" "%SCRIPT_DIR%..\..\Versscript" "%SCRIPT_DIR%Versscript") do (
    if exist "%%~p\build\verss.exe" (
        set "VS_SRC=%%~fp"
        goto :found_vs
    )
)
:found_vs

:: Look for VSIX
for %%p in ("%SCRIPT_DIR%..\versatile-vscode" "%SCRIPT_DIR%..\..\versatile-vscode") do (
    if exist "%%~p" (
        for %%f in ("%%~p\*.vsix") do (
            set "VSIX_PATH=%%~ff"
            goto :found_vsix
        )
    )
)
:found_vsix

if defined VL_SRC echo [FOUND] Verslang source: %VL_SRC%
if not defined VL_SRC echo [    ] Verslang source not found
if defined VS_SRC echo [FOUND] Versscript source: %VS_SRC%
if not defined VS_SRC echo [    ] Versscript source not found
if defined VSIX_PATH echo [FOUND] VS Code extension: %VSIX_PATH%
echo.

:: ---- Product selection ----
echo Select what to install:
echo   [1] Verslang only
echo   [2] Versscript only
echo   [3] Both Verslang and Versscript
echo   [4] Cancel
echo.
set /p "CHOICE=Enter choice (1-4): "

if "%CHOICE%"=="4" exit /b 0
if "%CHOICE%"=="1" set "DO_VL=1" & set "DO_VS=0"
if "%CHOICE%"=="2" set "DO_VL=0" & set "DO_VS=1"
if "%CHOICE%"=="3" set "DO_VL=1" & set "DO_VS=1"
if not defined DO_VL (
    echo Invalid choice.
    pause
    exit /b 1
)

echo.

:: ---- Source selection ----
echo Installation source:
echo   [1] Built-in (from adjacent directories)
echo   [2] From ZIP files
echo.
set /p "SRC_CHOICE=Enter choice (1-2): "

set "VL_ZIP="
set "VS_ZIP="
if "%SRC_CHOICE%"=="2" (
    if "%DO_VL%"=="1" (
        echo.
        set /p "VL_ZIP=Enter path to Verslang ZIP: "
    )
    if "%DO_VS%"=="1" (
        echo.
        set /p "VS_ZIP=Enter path to Versscript ZIP: "
    )
)
echo.

:: ---- Install paths ----
set "VL_DIR=C:\Program Files\Verslang"
set "VS_DIR=C:\Program Files\Versscript"

set /p "CUSTOM_PATH=Use default install paths? [Y/n]: "
if /i "%CUSTOM_PATH%"=="n" (
    if "%DO_VL%"=="1" set /p "VL_DIR=Verslang install path: "
    if "%DO_VS%"=="1" set /p "VS_DIR=Versscript install path: "
)
echo.

:: ---- VS Code extension ----
set "DO_VSCODE=0"
where code >nul 2>&1
if not errorlevel 1 (
    echo [FOUND] VS Code detected.
    set /p "VSCODE_CHOICE=Install VS Code extension? [Y/n]: "
    if /i not "!VSCODE_CHOICE!"=="n" set "DO_VSCODE=1"
) else (
    echo [    ] VS Code not found, skipping extension.
)
echo.

:: ========================= Handle ZIP extraction =========================
set "VL_ACTUAL_SRC=%VL_SRC%"
set "VS_ACTUAL_SRC=%VS_SRC%"

if "%SRC_CHOICE%"=="2" (
    if "%DO_VL%"=="1" if defined VL_ZIP (
        echo Extracting Verslang ZIP...
        set "VL_TEMP=%TEMP%\VerslangZipExtract"
        if exist "!VL_TEMP!" rd /s /q "!VL_TEMP!"
        powershell -NoProfile -Command "Expand-Archive -Path '%VL_ZIP%' -DestinationPath '!VL_TEMP!' -Force"
        if errorlevel 1 (
            echo [ERROR] Failed to extract Verslang ZIP.
            pause
            exit /b 1
        )
        set "VL_ACTUAL_SRC=!VL_TEMP!"
        echo [OK] Extracted Verslang ZIP.
    )
    if "%DO_VS%"=="1" if defined VS_ZIP (
        echo Extracting Versscript ZIP...
        set "VS_TEMP=%TEMP%\VersscriptZipExtract"
        if exist "!VS_TEMP!" rd /s /q "!VS_TEMP!"
        powershell -NoProfile -Command "Expand-Archive -Path '%VS_ZIP%' -DestinationPath '!VS_TEMP!' -Force"
        if errorlevel 1 (
            echo [ERROR] Failed to extract Versscript ZIP.
            pause
            exit /b 1
        )
        set "VS_ACTUAL_SRC=!VS_TEMP!"
        echo [OK] Extracted Versscript ZIP.
    )
    echo.
)

:: ========================= Install Verslang =========================
if "%DO_VL%"=="1" (
    echo ---- Installing Verslang ----
    echo.

    echo Creating directories...
    mkdir "%VL_DIR%\bin" 2>nul

    echo Copying verslang.exe...
    if exist "%VL_ACTUAL_SRC%\build\verslang.exe" (
        copy /y "%VL_ACTUAL_SRC%\build\verslang.exe" "%VL_DIR%\bin\verslang.exe" >nul
        echo [OK] Installed verslang.exe
    ) else (
        echo [ERROR] verslang.exe not found!
    )

    :: Examples
    if exist "%VL_ACTUAL_SRC%\examples" (
        echo Copying examples...
        xcopy /e /i /y "%VL_ACTUAL_SRC%\examples" "%VL_DIR%\examples" >nul 2>nul
        echo [OK] Installed examples
    )

    :: Stdlib
    if exist "%VL_ACTUAL_SRC%\stdlib" (
        echo Copying stdlib...
        xcopy /e /i /y "%VL_ACTUAL_SRC%\stdlib" "%VL_DIR%\stdlib" >nul 2>nul
        echo [OK] Installed stdlib
    )

    :: PATH
    echo Adding Verslang to PATH...
    for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYSPATH=%%b"
    echo !SYSPATH! | findstr /i /c:"%VL_DIR%\bin" >nul
    if errorlevel 1 (
        setx /M Path "!SYSPATH!;%VL_DIR%\bin" >nul
        echo [OK] Added to PATH
    ) else (
        echo [OK] Already in PATH
    )

    :: File association
    echo Registering .vlang file association...
    assoc .vlang=VerslangFile >nul 2>nul
    ftype VerslangFile="%VL_DIR%\bin\verslang.exe" compile "%%1" >nul 2>nul
    echo [OK] Registered .vlang files

    :: Registry uninstall info
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Verslang" /v DisplayName /t REG_SZ /d "Verslang" /f >nul
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Verslang" /v DisplayVersion /t REG_SZ /d "1.0.0" /f >nul
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Verslang" /v Publisher /t REG_SZ /d "Lonidev" /f >nul
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Verslang" /v InstallLocation /t REG_SZ /d "%VL_DIR%" /f >nul

    echo [OK] Verslang installation complete
    echo.
)

:: ========================= Install Versscript =========================
if "%DO_VS%"=="1" (
    echo ---- Installing Versscript ----
    echo.

    echo Creating directories...
    mkdir "%VS_DIR%\bin" 2>nul

    echo Copying verss.exe...
    if exist "%VS_ACTUAL_SRC%\build\verss.exe" (
        copy /y "%VS_ACTUAL_SRC%\build\verss.exe" "%VS_DIR%\bin\verss.exe" >nul
        echo [OK] Installed verss.exe
    ) else (
        echo [ERROR] verss.exe not found!
    )

    :: Examples
    if exist "%VS_ACTUAL_SRC%\examples" (
        echo Copying examples...
        xcopy /e /i /y "%VS_ACTUAL_SRC%\examples" "%VS_DIR%\examples" >nul 2>nul
        echo [OK] Installed examples
    )

    :: Docs
    if exist "%VS_ACTUAL_SRC%\docs" (
        echo Copying documentation...
        xcopy /e /i /y "%VS_ACTUAL_SRC%\docs" "%VS_DIR%\docs" >nul 2>nul
        echo [OK] Installed docs
    )

    :: PATH
    echo Adding Versscript to PATH...
    for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYSPATH=%%b"
    echo !SYSPATH! | findstr /i /c:"%VS_DIR%\bin" >nul
    if errorlevel 1 (
        setx /M Path "!SYSPATH!;%VS_DIR%\bin" >nul
        echo [OK] Added to PATH
    ) else (
        echo [OK] Already in PATH
    )

    :: File associations
    echo Registering .vs/.verss file associations...
    assoc .vs=VersscriptFile >nul 2>nul
    assoc .verss=VersscriptFile >nul 2>nul
    ftype VersscriptFile="%VS_DIR%\bin\verss.exe" run "%%1" >nul 2>nul
    echo [OK] Registered .vs and .verss files

    :: Registry uninstall info
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Versscript" /v DisplayName /t REG_SZ /d "Versscript" /f >nul
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Versscript" /v DisplayVersion /t REG_SZ /d "1.2.0" /f >nul
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Versscript" /v Publisher /t REG_SZ /d "Lonidev" /f >nul
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Versscript" /v InstallLocation /t REG_SZ /d "%VS_DIR%" /f >nul

    echo [OK] Versscript installation complete
    echo.
)

:: ========================= VS Code Extension =========================
if "%DO_VSCODE%"=="1" if defined VSIX_PATH (
    echo ---- Installing VS Code Extension ----
    echo.
    code --install-extension "%VSIX_PATH%" --force
    if not errorlevel 1 (
        echo [OK] VS Code extension installed
    ) else (
        echo [WARN] VS Code extension install failed
    )
    echo.
)

:: ========================= Done =========================
echo ================================================
echo   Installation Complete!
echo ================================================
echo.
if "%DO_VL%"=="1" echo   Verslang: %VL_DIR%
if "%DO_VS%"=="1" echo   Versscript: %VS_DIR%
echo.
echo   Restart your terminal for PATH changes.
echo.

:: Clean up temp dirs
if defined VL_TEMP if exist "!VL_TEMP!" rd /s /q "!VL_TEMP!"
if defined VS_TEMP if exist "!VS_TEMP!" rd /s /q "!VS_TEMP!"

pause
