#!/usr/bin/env bash
# ================================================
# Versatile Suite — macOS Installer
# Installs Verslang and/or Versscript
# ================================================
set -euo pipefail

# ========================= Colors & Helpers =========================
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'
PURPLE='\033[0;35m'; CYAN='\033[0;36m'; WHITE='\033[1;37m'; DIM='\033[2m'; NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; }
step()    { echo -e "\n${CYAN}==>${NC} ${WHITE}$1${NC}"; }

# ========================= Banner =========================
echo -e "${PURPLE}"
cat << 'BANNER'
 ____   ____                    _   _ _
 \   \ /   /__ _ __ ___  __ _ | |_(_) | ___
  \   V  / _ \ '__/ __|/ _` | __| | |/ _ \
   \   / (__ ) |  \__ \ (_| | |_| | |  __/
    \_/ \___|_|  |___/\__,_|\__|_|_|\___|

BANNER
echo -e "${NC}"
echo -e "${WHITE}Versatile Language Suite — macOS Installer v1.0${NC}"
echo -e "${DIM}================================================${NC}"
echo

# ========================= macOS Checks =========================
if [[ "$(uname)" != "Darwin" ]]; then
    error "This installer is for macOS only."
    exit 1
fi

ARCH=$(uname -m)
info "macOS $(sw_vers -productVersion) ($ARCH)"

# Check Xcode CLT
if ! xcode-select -p &>/dev/null; then
    warn "Xcode Command Line Tools not found."
    echo "Installing Xcode CLT (this may take a while)..."
    xcode-select --install 2>/dev/null || true
    echo "Please re-run this installer after Xcode CLT is installed."
    exit 1
fi
success "Xcode Command Line Tools found"
echo

# ========================= Privilege Setup =========================
NEED_SUDO=false
PREFIX="/usr/local"

if [[ $EUID -ne 0 ]]; then
    NEED_SUDO=true
fi

run_privileged() {
    if $NEED_SUDO; then sudo "$@"; else "$@"; fi
}

# ========================= Detect Sources =========================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VL_SRC="" VS_SRC="" VSIX_PATH=""

for dir in "$SCRIPT_DIR/../Verslang" "$SCRIPT_DIR/../../Verslang" "$SCRIPT_DIR/Verslang"; do
    if [[ -d "$dir" ]] && { [[ -f "$dir/build/verslang" ]] || [[ -f "$dir/src/main.cpp" ]]; }; then
        VL_SRC="$(cd "$dir" && pwd)"; break
    fi
done

for dir in "$SCRIPT_DIR/../Versscript" "$SCRIPT_DIR/../../Versscript" "$SCRIPT_DIR/Versscript"; do
    if [[ -d "$dir" ]] && { [[ -f "$dir/build/verss" ]] || [[ -f "$dir/CMakeLists.txt" ]]; }; then
        VS_SRC="$(cd "$dir" && pwd)"; break
    fi
done

for dir in "$SCRIPT_DIR/../versatile-vscode" "$SCRIPT_DIR/../../versatile-vscode"; do
    if [[ -d "$dir" ]]; then
        vsix=$(find "$dir" -maxdepth 1 -name "*.vsix" 2>/dev/null | head -1)
        if [[ -n "$vsix" ]]; then VSIX_PATH="$vsix"; break; fi
    fi
done

[[ -n "$VL_SRC" ]]    && success "Verslang source: $VL_SRC" || warn "Verslang source not found"
[[ -n "$VS_SRC" ]]    && success "Versscript source: $VS_SRC" || warn "Versscript source not found"
[[ -n "$VSIX_PATH" ]] && success "VSIX: $VSIX_PATH" || warn "VS Code extension not found"
echo

# ========================= Product Selection =========================
echo -e "${WHITE}Select what to install:${NC}"
echo "  [1] Verslang only"
echo "  [2] Versscript only"
echo "  [3] Both Verslang and Versscript"
echo "  [4] Cancel"
echo
read -rp "Enter choice (1-4): " PRODUCT_CHOICE

DO_VL=false DO_VS=false
case "$PRODUCT_CHOICE" in
    1) DO_VL=true ;; 2) DO_VS=true ;; 3) DO_VL=true; DO_VS=true ;;
    4) echo "Cancelled."; exit 0 ;; *) error "Invalid choice."; exit 1 ;;
esac
echo

# ========================= Source Selection =========================
echo -e "${WHITE}Installation source:${NC}"
echo "  [1] Built-in (from adjacent directories)"
echo "  [2] From ZIP/tarball"
echo
read -rp "Enter choice (1-2): " SRC_CHOICE

VL_ACTUAL_SRC="$VL_SRC" VS_ACTUAL_SRC="$VS_SRC"

if [[ "$SRC_CHOICE" == "2" ]]; then
    if $DO_VL; then
        read -rp "Path to Verslang archive: " VL_ARCHIVE
        if [[ -n "$VL_ARCHIVE" && -f "$VL_ARCHIVE" ]]; then
            VL_TEMP=$(mktemp -d)
            case "$VL_ARCHIVE" in
                *.tar.gz|*.tgz) tar xzf "$VL_ARCHIVE" -C "$VL_TEMP" ;;
                *.zip)          unzip -q "$VL_ARCHIVE" -d "$VL_TEMP" ;;
            esac
            dirs=$(find "$VL_TEMP" -mindepth 1 -maxdepth 1 -type d | wc -l)
            [[ $dirs -eq 1 ]] && VL_ACTUAL_SRC=$(find "$VL_TEMP" -mindepth 1 -maxdepth 1 -type d) || VL_ACTUAL_SRC="$VL_TEMP"
            success "Extracted Verslang archive"
        fi
    fi
    if $DO_VS; then
        read -rp "Path to Versscript archive: " VS_ARCHIVE
        if [[ -n "$VS_ARCHIVE" && -f "$VS_ARCHIVE" ]]; then
            VS_TEMP=$(mktemp -d)
            case "$VS_ARCHIVE" in
                *.tar.gz|*.tgz) tar xzf "$VS_ARCHIVE" -C "$VS_TEMP" ;;
                *.zip)          unzip -q "$VS_ARCHIVE" -d "$VS_TEMP" ;;
            esac
            dirs=$(find "$VS_TEMP" -mindepth 1 -maxdepth 1 -type d | wc -l)
            [[ $dirs -eq 1 ]] && VS_ACTUAL_SRC=$(find "$VS_TEMP" -mindepth 1 -maxdepth 1 -type d) || VS_ACTUAL_SRC="$VS_TEMP"
            success "Extracted Versscript archive"
        fi
    fi
fi
echo

# ========================= Build from Source =========================
ensure_cmake() {
    if ! command -v cmake &>/dev/null; then
        if command -v brew &>/dev/null; then
            info "Installing cmake via Homebrew..."
            brew install cmake
        else
            error "cmake not found. Install via: brew install cmake"
            exit 1
        fi
    fi
}

build_from_source() {
    local lang="$1" src_dir="$2"
    step "Building $lang from source..."
    ensure_cmake
    pushd "$src_dir" > /dev/null
    mkdir -p build && cd build
    cmake .. -DCMAKE_BUILD_TYPE=Release
    make -j"$(sysctl -n hw.ncpu)"
    popd > /dev/null
    success "$lang built from source"
}

# ========================= Install Verslang =========================
if $DO_VL; then
    step "Installing Verslang"

    VL_BIN="$PREFIX/bin"
    VL_LIB="$PREFIX/lib/verslang"
    VL_SHARE="$PREFIX/share/verslang"
    run_privileged mkdir -p "$VL_BIN" "$VL_LIB" "$VL_SHARE"

    VL_EXE=""
    [[ -f "$VL_ACTUAL_SRC/build/verslang" ]] && VL_EXE="$VL_ACTUAL_SRC/build/verslang"
    [[ -z "$VL_EXE" && -f "$VL_ACTUAL_SRC/verslang" ]] && VL_EXE="$VL_ACTUAL_SRC/verslang"
    if [[ -z "$VL_EXE" ]]; then
        build_from_source "Verslang" "$VL_ACTUAL_SRC"
        VL_EXE="$VL_ACTUAL_SRC/build/verslang"
    fi

    if [[ -f "$VL_EXE" ]]; then
        run_privileged cp "$VL_EXE" "$VL_BIN/verslang"
        run_privileged chmod +x "$VL_BIN/verslang"
        # Code sign on Apple Silicon
        if [[ "$ARCH" == "arm64" ]]; then
            codesign --force --sign - "$VL_BIN/verslang" 2>/dev/null || true
        fi
        success "Installed verslang"
    else
        error "verslang binary not found!"
    fi

    [[ -d "$VL_ACTUAL_SRC/examples" ]] && run_privileged cp -R "$VL_ACTUAL_SRC/examples" "$VL_SHARE/" && success "Installed examples"
    [[ -d "$VL_ACTUAL_SRC/stdlib" ]]   && run_privileged cp -R "$VL_ACTUAL_SRC/stdlib" "$VL_LIB/"     && success "Installed stdlib"

    # Man page
    run_privileged mkdir -p "$PREFIX/share/man/man1"
    run_privileged tee "$PREFIX/share/man/man1/verslang.1" > /dev/null << 'MANPAGE'
.TH VERSLANG 1 "2026" "1.0.0" "Verslang Compiler"
.SH NAME
verslang \- low-level systems programming language compiler
.SH SYNOPSIS
.B verslang
[\fIcommand\fR] [\fIoptions\fR] \fIfile\fR
.SH DESCRIPTION
Verslang compiles .vlang source files to native x86-64 machine code.
.SH AUTHOR
Lonidev
MANPAGE
    success "Installed man page"

    # PATH for non-standard prefix
    if [[ "$PREFIX" != "/usr/local" && "$PREFIX" != "/usr" ]]; then
        SHELL_RC="$HOME/.zshrc"
        [[ "$SHELL" == *bash* ]] && SHELL_RC="$HOME/.bash_profile"
        if ! grep -q "$VL_BIN" "$SHELL_RC" 2>/dev/null; then
            echo "export PATH=\"$VL_BIN:\$PATH\"" >> "$SHELL_RC"
            success "Added to PATH in $SHELL_RC"
        fi
    fi

    success "Verslang installation complete"
    echo
fi

# ========================= Install Versscript =========================
if $DO_VS; then
    step "Installing Versscript"

    VS_BIN="$PREFIX/bin"
    VS_LIB="$PREFIX/lib/versscript"
    VS_SHARE="$PREFIX/share/versscript"
    run_privileged mkdir -p "$VS_BIN" "$VS_LIB" "$VS_SHARE"

    VS_EXE=""
    [[ -f "$VS_ACTUAL_SRC/build/verss" ]] && VS_EXE="$VS_ACTUAL_SRC/build/verss"
    [[ -z "$VS_EXE" && -f "$VS_ACTUAL_SRC/verss" ]] && VS_EXE="$VS_ACTUAL_SRC/verss"
    if [[ -z "$VS_EXE" ]]; then
        build_from_source "Versscript" "$VS_ACTUAL_SRC"
        VS_EXE="$VS_ACTUAL_SRC/build/verss"
    fi

    if [[ -f "$VS_EXE" ]]; then
        run_privileged cp "$VS_EXE" "$VS_BIN/verss"
        run_privileged chmod +x "$VS_BIN/verss"
        if [[ "$ARCH" == "arm64" ]]; then
            codesign --force --sign - "$VS_BIN/verss" 2>/dev/null || true
        fi
        success "Installed verss"
    else
        error "verss binary not found!"
    fi

    [[ -d "$VS_ACTUAL_SRC/native_modules" ]] && run_privileged cp -R "$VS_ACTUAL_SRC/native_modules" "$VS_LIB/" && success "Installed native modules"
    [[ -d "$VS_ACTUAL_SRC/examples" ]]        && run_privileged cp -R "$VS_ACTUAL_SRC/examples" "$VS_SHARE/"     && success "Installed examples"
    [[ -d "$VS_ACTUAL_SRC/docs" ]]            && run_privileged cp -R "$VS_ACTUAL_SRC/docs" "$VS_SHARE/"         && success "Installed docs"

    run_privileged mkdir -p "$PREFIX/share/man/man1"
    run_privileged tee "$PREFIX/share/man/man1/verss.1" > /dev/null << 'MANPAGE'
.TH VERSS 1 "2026" "1.2.0" "Versscript Runtime"
.SH NAME
verss \- modern scripting language runtime
.SH SYNOPSIS
.B verss
[\fIcommand\fR] [\fIoptions\fR] [\fIfile\fR]
.SH DESCRIPTION
Versscript is a modern scripting language with 500+ functions and 95+ modules.
.SH AUTHOR
Lonidev
MANPAGE
    success "Installed man page"

    if [[ "$PREFIX" != "/usr/local" && "$PREFIX" != "/usr" ]]; then
        SHELL_RC="$HOME/.zshrc"
        [[ "$SHELL" == *bash* ]] && SHELL_RC="$HOME/.bash_profile"
        if ! grep -q "$VS_BIN" "$SHELL_RC" 2>/dev/null; then
            echo "export PATH=\"$VS_BIN:\$PATH\"" >> "$SHELL_RC"
            success "Added to PATH in $SHELL_RC"
        fi
    fi

    success "Versscript installation complete"
    echo
fi

# ========================= VS Code Extension =========================
if command -v code &>/dev/null && [[ -n "$VSIX_PATH" ]]; then
    read -rp "Install VS Code extension? [Y/n]: " INSTALL_VSCODE
    if [[ "${INSTALL_VSCODE,,}" != "n" ]]; then
        step "Installing VS Code extension"
        code --install-extension "$VSIX_PATH" --force && success "VS Code extension installed" || warn "Install failed"
    fi
    echo
fi

# ========================= Cleanup =========================
[[ -n "${VL_TEMP:-}" ]] && rm -rf "$VL_TEMP"
[[ -n "${VS_TEMP:-}" ]] && rm -rf "$VS_TEMP"

# ========================= Done =========================
echo
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  Installation Complete!${NC}"
echo -e "${GREEN}================================================${NC}"
echo
$DO_VL && echo -e "  ${CYAN}Verslang:${NC}   verslang compile hello.vlang"
$DO_VS && echo -e "  ${CYAN}Versscript:${NC} verss run script.vs"
echo
echo -e "  ${YELLOW}Restart your terminal for PATH changes.${NC}"
echo
