@echo off
setlocal enabledelayedexpansion
title Versatile Suite - Build Installer

echo ============================================
echo   Versatile Suite Installer - Build Script
echo ============================================
echo.

:: ---- Find Visual Studio ----
set "VCVARS="
for %%e in (Community Professional Enterprise) do (
    set "candidate=C:\Program Files\Microsoft Visual Studio\2022\%%e\VC\Auxiliary\Build\vcvarsall.bat"
    if exist "!candidate!" (
        set "VCVARS=!candidate!"
        echo Found VS2022 %%e
        goto :found_vs
    )
)
for %%e in (Community Professional Enterprise) do (
    set "candidate=C:\Program Files (x86)\Microsoft Visual Studio\2019\%%e\VC\Auxiliary\Build\vcvarsall.bat"
    if exist "!candidate!" (
        set "VCVARS=!candidate!"
        echo Found VS2019 %%e
        goto :found_vs
    )
)
echo [ERROR] Visual Studio 2019/2022 not found.
echo Please install Visual Studio with C++ workload.
pause
exit /b 1

:found_vs
echo Using: %VCVARS%
echo.

:: ---- Set up environment ----
call "%VCVARS%" x64
if errorlevel 1 (
    echo [ERROR] Failed to set up build environment.
    pause
    exit /b 1
)

:: ---- Build ----
echo Compiling resources (embedding verslang.exe + verss.exe) ...
echo.

rc /nologo installer.rc
if errorlevel 1 (
    echo.
    echo [ERROR] Resource compilation failed!
    echo Make sure verslang.exe and verss.exe exist at:
    echo   ..\..\Verslang\build\verslang.exe
    echo   ..\..\Versscript\build\verss.exe
    pause
    exit /b 1
)

echo Compiling versatile-installer.cpp ...
echo.

cl /std:c++20 /EHsc /O2 /DUNICODE /D_UNICODE /DNOMINMAX ^
   /W3 /WX- ^
   versatile-installer.cpp installer.res ^
   /Fe:VersatileSetup.exe ^
   /link /SUBSYSTEM:WINDOWS ^
   user32.lib gdi32.lib shell32.lib ole32.lib advapi32.lib ^
   comctl32.lib dwmapi.lib shlwapi.lib comdlg32.lib uuid.lib

if errorlevel 1 (
    echo.
    echo [ERROR] Build failed!
    pause
    exit /b 1
)

:: ---- Clean intermediate files ----
del /q versatile-installer.obj 2>nul
del /q installer.res 2>nul

echo.
echo ============================================
echo   BUILD SUCCESSFUL
echo   Output: VersatileSetup.exe
echo ============================================
echo.
echo File size:
for %%f in (VersatileSetup.exe) do echo   %%~zf bytes (%%f)
echo.
pause
