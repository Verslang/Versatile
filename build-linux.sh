#!/bin/bash
set -e

echo "====================================================="
echo "  Versatile Project - Linux Build Script"
echo "  Verslang + Versscript + Versatile"
echo "====================================================="
echo ""

# Check for verslang compiler
if ! command -v verslang &> /dev/null; then
    echo "ERROR: verslang compiler not found in PATH."
    echo "Please install Verslang first or add it to your PATH."
    echo ""
    echo "You can build the installer manually with an existing compiler,"
    echo "or download a pre-built binary from the releases page."
    exit 1
fi

# Create build output directory
mkdir -p build/output

echo "[1/5] Building Bootstrap Compiler..."
echo ""

echo "  Compiling lexer.vlang..."
verslang verslang-bootstrap/lexer.vlang -o build/output/lexer.o -f obj

echo "  Compiling parser.vlang..."
verslang verslang-bootstrap/parser.vlang -o build/output/parser.o -f obj

echo "  Compiling codegen.vlang..."
verslang verslang-bootstrap/codegen.vlang -o build/output/codegen.o -f obj

echo "  Compiling main.vlang..."
verslang verslang-bootstrap/main.vlang -o build/output/main.o -f obj

echo "  Linking verslang-bootstrap..."
verslang -link build/output/main.o build/output/lexer.o build/output/parser.o build/output/codegen.o -o build/output/verslang-bootstrap -f elf64

chmod +x build/output/verslang-bootstrap
echo "  [OK] Bootstrap compiler built successfully."
echo ""

echo "[2/5] Building Native Modules..."
echo ""

echo "  Compiling string_ops.vlang..."
verslang versscript-native/string_ops.vlang -o build/output/string_ops.o -f obj

echo "  Compiling math_engine.vlang..."
verslang versscript-native/math_engine.vlang -o build/output/math_engine.o -f obj

echo "  Compiling memory_pool.vlang..."
verslang versscript-native/memory_pool.vlang -o build/output/memory_pool.o -f obj

echo "  Compiling json_parser.vlang..."
verslang versscript-native/json_parser.vlang -o build/output/json_parser.o -f obj

echo "  Compiling hash_table.vlang..."
verslang versscript-native/hash_table.vlang -o build/output/hash_table.o -f obj

echo "  Linking libversnative.so..."
verslang -link -shared build/output/string_ops.o build/output/math_engine.o build/output/memory_pool.o build/output/json_parser.o build/output/hash_table.o -o build/output/libversnative.so

echo "  [OK] Native modules built successfully."
echo ""

echo "[3/5] Building Verslang Installer..."
echo ""

echo "  Compiling installer-common.vlang..."
verslang installer/verslang-installer/installer-common.vlang -o build/output/installer-common.o -f obj

echo "  Compiling installer-linux.vlang..."
verslang installer/verslang-installer/installer-linux.vlang -o build/output/installer-linux.o -f obj

echo "  Linking verslang-installer..."
verslang -link build/output/installer-common.o build/output/installer-linux.o -o build/output/verslang-installer -f elf64

chmod +x build/output/verslang-installer
echo "  [OK] Verslang installer built successfully."
echo ""

echo "[4/5] Building Versatile Installer..."
echo ""

echo "  Compiling versatile installer..."
verslang installer/versatile-installer/installer.vlang -o build/output/versatile-installer.o -f obj

echo "  Linking versatile-installer..."
verslang -link build/output/installer-common.o build/output/versatile-installer.o -o build/output/versatile-installer -f elf64

chmod +x build/output/versatile-installer
echo "  [OK] Versatile installer built successfully."
echo ""

echo "[5/5] Building and Running Tests..."
echo ""

echo "  Compiling test_verslang.vlang..."
verslang tests/test_verslang.vlang -o build/output/test_verslang -f elf64
chmod +x build/output/test_verslang

echo "  Running Verslang tests..."
if build/output/test_verslang; then
    echo "  [PASS] Verslang tests passed."
else
    echo "  [FAIL] Verslang tests failed!"
fi
echo ""

echo "  Running Versscript tests..."
if command -v verss &> /dev/null; then
    if verss tests/test_versscript.vs; then
        echo "  [PASS] Versscript tests passed."
    else
        echo "  [FAIL] Versscript tests failed!"
    fi
else
    echo "  [SKIP] verss not found, skipping Versscript tests."
fi
echo ""

echo "====================================================="
echo "  Build Complete!"
echo "====================================================="
echo ""
echo "  Output directory: build/output/"
echo ""
echo "  Built artifacts:"
echo "    - verslang-bootstrap     (Self-hosting compiler)"
echo "    - libversnative.so       (Native module library)"
echo "    - verslang-installer     (Verslang installer)"
echo "    - versatile-installer    (Full suite installer)"
echo "    - test_verslang          (Test runner)"
echo ""
