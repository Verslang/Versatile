@echo off
setlocal enabledelayedexpansion

echo =====================================================
echo   Versatile Project - Windows Build Script
echo   Verslang + Versscript + Versatile
echo =====================================================
echo.

:: Check for verslang compiler
where verslang >nul 2>&1
if errorlevel 1 (
    echo ERROR: verslang compiler not found in PATH.
    echo Please install Verslang first or add it to your PATH.
    echo.
    echo You can install it by running:
    echo   installer\verslang-installer\installer-windows.vlang
    exit /b 1
)

:: Create build output directory
if not exist "build\output" mkdir "build\output"

echo [1/5] Building Bootstrap Compiler...
echo.

echo   Compiling lexer.vlang...
verslang verslang-bootstrap\lexer.vlang -o build\output\lexer.o -f obj
if errorlevel 1 goto :error

echo   Compiling parser.vlang...
verslang verslang-bootstrap\parser.vlang -o build\output\parser.o -f obj
if errorlevel 1 goto :error

echo   Compiling codegen.vlang...
verslang verslang-bootstrap\codegen.vlang -o build\output\codegen.o -f obj
if errorlevel 1 goto :error

echo   Compiling main.vlang...
verslang verslang-bootstrap\main.vlang -o build\output\main.o -f obj
if errorlevel 1 goto :error

echo   Linking verslang-bootstrap.exe...
verslang -link build\output\main.o build\output\lexer.o build\output\parser.o build\output\codegen.o -o build\output\verslang-bootstrap.exe -f pe64
if errorlevel 1 goto :error

echo   [OK] Bootstrap compiler built successfully.
echo.

echo [2/5] Building Native Modules...
echo.

echo   Compiling string_ops.vlang...
verslang versscript-native\string_ops.vlang -o build\output\string_ops.o -f obj
if errorlevel 1 goto :error

echo   Compiling math_engine.vlang...
verslang versscript-native\math_engine.vlang -o build\output\math_engine.o -f obj
if errorlevel 1 goto :error

echo   Compiling memory_pool.vlang...
verslang versscript-native\memory_pool.vlang -o build\output\memory_pool.o -f obj
if errorlevel 1 goto :error

echo   Compiling json_parser.vlang...
verslang versscript-native\json_parser.vlang -o build\output\json_parser.o -f obj
if errorlevel 1 goto :error

echo   Compiling hash_table.vlang...
verslang versscript-native\hash_table.vlang -o build\output\hash_table.o -f obj
if errorlevel 1 goto :error

echo   Linking versnative.dll...
verslang -link -shared build\output\string_ops.o build\output\math_engine.o build\output\memory_pool.o build\output\json_parser.o build\output\hash_table.o -o build\output\versnative.dll
if errorlevel 1 goto :error

echo   [OK] Native modules built successfully.
echo.

echo [3/5] Building Verslang Installer...
echo.

echo   Compiling installer-common.vlang...
verslang installer\verslang-installer\installer-common.vlang -o build\output\installer-common.o -f obj
if errorlevel 1 goto :error

echo   Compiling installer-windows.vlang...
verslang installer\verslang-installer\installer-windows.vlang -o build\output\installer-win.o -f obj
if errorlevel 1 goto :error

echo   Linking verslang-installer.exe...
verslang -link build\output\installer-common.o build\output\installer-win.o -o build\output\verslang-installer.exe -f pe64
if errorlevel 1 goto :error

echo   [OK] Verslang installer built successfully.
echo.

echo [4/5] Building Versatile Installer...
echo.

echo   Compiling versatile installer...
verslang installer\versatile-installer\installer.vlang -o build\output\versatile-installer.o -f obj
if errorlevel 1 goto :error

echo   Linking versatile-installer.exe...
verslang -link build\output\installer-common.o build\output\versatile-installer.o -o build\output\versatile-installer.exe -f pe64
if errorlevel 1 goto :error

echo   [OK] Versatile installer built successfully.
echo.

echo [5/5] Building and Running Tests...
echo.

echo   Compiling test_verslang.vlang...
verslang tests\test_verslang.vlang -o build\output\test_verslang.exe -f pe64
if errorlevel 1 goto :error

echo   Running Verslang tests...
build\output\test_verslang.exe
if errorlevel 1 (
    echo   [FAIL] Verslang tests failed!
) else (
    echo   [PASS] Verslang tests passed.
)
echo.

echo   Running Versscript tests...
where verss >nul 2>&1
if errorlevel 1 (
    echo   [SKIP] verss not found, skipping Versscript tests.
) else (
    verss tests\test_versscript.vs
    if errorlevel 1 (
        echo   [FAIL] Versscript tests failed!
    ) else (
        echo   [PASS] Versscript tests passed.
    )
)
echo.

echo =====================================================
echo   Build Complete!
echo =====================================================
echo.
echo   Output directory: build\output\
echo.
echo   Built artifacts:
echo     - verslang-bootstrap.exe    (Self-hosting compiler)
echo     - versnative.dll            (Native module library)
echo     - verslang-installer.exe    (Verslang installer)
echo     - versatile-installer.exe   (Full suite installer)
echo     - test_verslang.exe         (Test runner)
echo.
goto :eof

:error
echo.
echo =====================================================
echo   BUILD FAILED
echo =====================================================
echo   Check the error messages above for details.
exit /b 1
