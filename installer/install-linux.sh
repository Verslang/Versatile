#!/usr/bin/env bash
# ================================================
# Versatile Suite — Linux Installer
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
echo -e "${WHITE}Versatile Language Suite — Linux Installer v1.0${NC}"
echo -e "${DIM}================================================${NC}"
echo

# ========================= Privilege Check =========================
NEED_SUDO=false
if [[ $EUID -ne 0 ]]; then
    NEED_SUDO=true
    if ! command -v sudo &>/dev/null; then
        error "This installer needs root privileges. Please run with sudo."
        exit 1
    fi
fi

run_privileged() {
    if $NEED_SUDO; then sudo "$@"; else "$@"; fi
}

# ========================= Detect Environment =========================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARCH=$(uname -m)

detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        DISTRO_ID="${ID:-unknown}"
        DISTRO_NAME="${PRETTY_NAME:-$ID}"
    elif command -v lsb_release &>/dev/null; then
        DISTRO_ID=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
        DISTRO_NAME=$(lsb_release -sd)
    else
        DISTRO_ID="unknown"
        DISTRO_NAME="Unknown Linux"
    fi
}

detect_distro
info "Distro: $DISTRO_NAME"
info "Arch: $ARCH"
echo

# ========================= Detect Sources =========================
VL_SRC=""
VS_SRC=""
VSIX_PATH=""

for dir in "$SCRIPT_DIR/../Verslang" "$SCRIPT_DIR/../../Verslang" "$SCRIPT_DIR/Verslang"; do
    if [[ -f "$dir/build/verslang" || -f "$dir/src/main.cpp" ]]; then
        VL_SRC="$(cd "$dir" && pwd)"
        break
    fi
done

for dir in "$SCRIPT_DIR/../Versscript" "$SCRIPT_DIR/../../Versscript" "$SCRIPT_DIR/Versscript"; do
    if [[ -f "$dir/build/verss" || -f "$dir/CMakeLists.txt" ]]; then
        VS_SRC="$(cd "$dir" && pwd)"
        break
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

DO_VL=false
DO_VS=false

case "$PRODUCT_CHOICE" in
    1) DO_VL=true ;;
    2) DO_VS=true ;;
    3) DO_VL=true; DO_VS=true ;;
    4) echo "Cancelled."; exit 0 ;;
    *) error "Invalid choice."; exit 1 ;;
esac
echo

# ========================= Source Selection =========================
echo -e "${WHITE}Installation source:${NC}"
echo "  [1] Built-in (from adjacent directories)"
echo "  [2] From ZIP/tarball files"
echo
read -rp "Enter choice (1-2): " SRC_CHOICE

VL_ACTUAL_SRC="$VL_SRC"
VS_ACTUAL_SRC="$VS_SRC"

if [[ "$SRC_CHOICE" == "2" ]]; then
    if $DO_VL; then
        read -rp "Path to Verslang archive (.tar.gz or .zip): " VL_ARCHIVE
        if [[ -n "$VL_ARCHIVE" && -f "$VL_ARCHIVE" ]]; then
            VL_TEMP=$(mktemp -d)
            info "Extracting Verslang archive..."
            case "$VL_ARCHIVE" in
                *.tar.gz|*.tgz) tar xzf "$VL_ARCHIVE" -C "$VL_TEMP" ;;
                *.zip)          unzip -q "$VL_ARCHIVE" -d "$VL_TEMP" ;;
                *) error "Unsupported format"; exit 1 ;;
            esac
            # Check for single root dir
            dirs=$(find "$VL_TEMP" -mindepth 1 -maxdepth 1 -type d | wc -l)
            if [[ $dirs -eq 1 ]]; then
                VL_ACTUAL_SRC=$(find "$VL_TEMP" -mindepth 1 -maxdepth 1 -type d)
            else
                VL_ACTUAL_SRC="$VL_TEMP"
            fi
            success "Extracted Verslang archive"
        fi
    fi
    if $DO_VS; then
        read -rp "Path to Versscript archive (.tar.gz or .zip): " VS_ARCHIVE
        if [[ -n "$VS_ARCHIVE" && -f "$VS_ARCHIVE" ]]; then
            VS_TEMP=$(mktemp -d)
            info "Extracting Versscript archive..."
            case "$VS_ARCHIVE" in
                *.tar.gz|*.tgz) tar xzf "$VS_ARCHIVE" -C "$VS_TEMP" ;;
                *.zip)          unzip -q "$VS_ARCHIVE" -d "$VS_TEMP" ;;
                *) error "Unsupported format"; exit 1 ;;
            esac
            dirs=$(find "$VS_TEMP" -mindepth 1 -maxdepth 1 -type d | wc -l)
            if [[ $dirs -eq 1 ]]; then
                VS_ACTUAL_SRC=$(find "$VS_TEMP" -mindepth 1 -maxdepth 1 -type d)
            else
                VS_ACTUAL_SRC="$VS_TEMP"
            fi
            success "Extracted Versscript archive"
        fi
    fi
fi
echo

# ========================= Install Paths =========================
VL_PREFIX="/usr/local"
VS_PREFIX="/usr/local"

read -rp "Use default install prefix (/usr/local)? [Y/n]: " USE_DEFAULT
if [[ "${USE_DEFAULT,,}" == "n" ]]; then
    read -rp "Install prefix: " CUSTOM_PREFIX
    VL_PREFIX="$CUSTOM_PREFIX"
    VS_PREFIX="$CUSTOM_PREFIX"
fi
echo

# ========================= Build Dependencies =========================
build_from_source() {
    local lang="$1" src_dir="$2"
    step "Building $lang from source..."

    if ! command -v cmake &>/dev/null; then
        info "Installing build dependencies..."
        case "$DISTRO_ID" in
            ubuntu|debian|linuxmint|pop)
                run_privileged apt-get update -qq
                run_privileged apt-get install -y -qq cmake g++ make ;;
            fedora|rhel|centos|rocky|alma)
                run_privileged dnf install -y cmake gcc-c++ make ;;
            arch|manjaro|endeavouros)
                run_privileged pacman -S --noconfirm cmake gcc make ;;
            opensuse*)
                run_privileged zypper install -y cmake gcc-c++ make ;;
            *)
                warn "Unknown distro. Please install cmake, g++, make manually." ;;
        esac
    fi

    pushd "$src_dir" > /dev/null
    mkdir -p build && cd build
    cmake .. -DCMAKE_BUILD_TYPE=Release
    make -j"$(nproc)"
    popd > /dev/null
    success "$lang built from source"
}

# ========================= Install Verslang =========================
if $DO_VL; then
    step "Installing Verslang"
    echo

    VL_BIN="$VL_PREFIX/bin"
    VL_LIB="$VL_PREFIX/lib/verslang"
    VL_SHARE="$VL_PREFIX/share/verslang"

    run_privileged mkdir -p "$VL_BIN" "$VL_LIB" "$VL_SHARE"

    # Find binary
    VL_EXE=""
    if [[ -f "$VL_ACTUAL_SRC/build/verslang" ]]; then
        VL_EXE="$VL_ACTUAL_SRC/build/verslang"
    elif [[ -f "$VL_ACTUAL_SRC/verslang" ]]; then
        VL_EXE="$VL_ACTUAL_SRC/verslang"
    else
        warn "Verslang binary not found, attempting build from source..."
        build_from_source "Verslang" "$VL_ACTUAL_SRC"
        VL_EXE="$VL_ACTUAL_SRC/build/verslang"
    fi

    if [[ -f "$VL_EXE" ]]; then
        run_privileged cp "$VL_EXE" "$VL_BIN/verslang"
        run_privileged chmod +x "$VL_BIN/verslang"
        success "Installed verslang to $VL_BIN/verslang"
    else
        error "verslang binary not found!"
    fi

    # Examples
    if [[ -d "$VL_ACTUAL_SRC/examples" ]]; then
        run_privileged cp -r "$VL_ACTUAL_SRC/examples" "$VL_SHARE/"
        success "Installed examples"
    fi

    # Stdlib
    if [[ -d "$VL_ACTUAL_SRC/stdlib" ]]; then
        run_privileged cp -r "$VL_ACTUAL_SRC/stdlib" "$VL_LIB/"
        success "Installed stdlib"
    fi

    # Man page
    run_privileged mkdir -p "$VL_PREFIX/share/man/man1"
    cat << 'MANPAGE' | run_privileged tee "$VL_PREFIX/share/man/man1/verslang.1" > /dev/null
.TH VERSLANG 1 "2026" "1.0.0" "Verslang Compiler"
.SH NAME
verslang \- low-level systems programming language compiler
.SH SYNOPSIS
.B verslang
[\fIcommand\fR] [\fIoptions\fR] \fIfile\fR
.SH DESCRIPTION
Verslang compiles .vlang source files to native x86-64 machine code.
Supports ELF, PE, and flat binary output formats.
.SH COMMANDS
.TP
.B compile
Compile a .vlang file to native code
.TP
.B run
Compile and execute
.SH AUTHOR
Lonidev
MANPAGE
    success "Installed man page"

    # PATH (profile.d)
    if [[ "$VL_PREFIX" != "/usr/local" && "$VL_PREFIX" != "/usr" ]]; then
        echo "export PATH=\"$VL_BIN:\$PATH\"" | run_privileged tee /etc/profile.d/verslang.sh > /dev/null
        run_privileged chmod +x /etc/profile.d/verslang.sh
        success "Added Verslang to PATH via /etc/profile.d/"
    fi

    success "Verslang installation complete"
    echo
fi

# ========================= Install Versscript =========================
if $DO_VS; then
    step "Installing Versscript"
    echo

    VS_BIN="$VS_PREFIX/bin"
    VS_LIB="$VS_PREFIX/lib/versscript"
    VS_SHARE="$VS_PREFIX/share/versscript"

    run_privileged mkdir -p "$VS_BIN" "$VS_LIB" "$VS_SHARE"

    # Find binary
    VS_EXE=""
    if [[ -f "$VS_ACTUAL_SRC/build/verss" ]]; then
        VS_EXE="$VS_ACTUAL_SRC/build/verss"
    elif [[ -f "$VS_ACTUAL_SRC/verss" ]]; then
        VS_EXE="$VS_ACTUAL_SRC/verss"
    else
        warn "Versscript binary not found, attempting build from source..."
        build_from_source "Versscript" "$VS_ACTUAL_SRC"
        VS_EXE="$VS_ACTUAL_SRC/build/verss"
    fi

    if [[ -f "$VS_EXE" ]]; then
        run_privileged cp "$VS_EXE" "$VS_BIN/verss"
        run_privileged chmod +x "$VS_BIN/verss"
        success "Installed verss to $VS_BIN/verss"
    else
        error "verss binary not found!"
    fi

    # Native modules
    if [[ -d "$VS_ACTUAL_SRC/native_modules" ]]; then
        run_privileged cp -r "$VS_ACTUAL_SRC/native_modules" "$VS_LIB/"
        success "Installed native modules"
    fi

    # Examples
    if [[ -d "$VS_ACTUAL_SRC/examples" ]]; then
        run_privileged cp -r "$VS_ACTUAL_SRC/examples" "$VS_SHARE/"
        success "Installed examples"
    fi

    # Docs
    if [[ -d "$VS_ACTUAL_SRC/docs" ]]; then
        run_privileged cp -r "$VS_ACTUAL_SRC/docs" "$VS_SHARE/"
        success "Installed documentation"
    fi

    # Man page
    run_privileged mkdir -p "$VS_PREFIX/share/man/man1"
    cat << 'MANPAGE' | run_privileged tee "$VS_PREFIX/share/man/man1/verss.1" > /dev/null
.TH VERSS 1 "2026" "1.2.0" "Versscript Runtime"
.SH NAME
verss \- modern scripting language runtime
.SH SYNOPSIS
.B verss
[\fIcommand\fR] [\fIoptions\fR] [\fIfile\fR]
.SH DESCRIPTION
Versscript is a modern scripting language with 500+ built-in functions
and 95+ modules. Supports REPL, GUI development, and more.
.SH COMMANDS
.TP
.B run
Run a .vs or .verss script
.TP
.B repl
Start interactive REPL
.TP
.B test
Run test assertions
.SH AUTHOR
Lonidev
MANPAGE
    success "Installed man page"

    # PATH (profile.d)
    if [[ "$VS_PREFIX" != "/usr/local" && "$VS_PREFIX" != "/usr" ]]; then
        echo "export PATH=\"$VS_BIN:\$PATH\"" | run_privileged tee /etc/profile.d/versscript.sh > /dev/null
        run_privileged chmod +x /etc/profile.d/versscript.sh
        success "Added Versscript to PATH via /etc/profile.d/"
    fi

    success "Versscript installation complete"
    echo
fi

# ========================= VS Code Extension =========================
if command -v code &>/dev/null && [[ -n "$VSIX_PATH" ]]; then
    read -rp "Install VS Code extension? [Y/n]: " INSTALL_VSCODE
    if [[ "${INSTALL_VSCODE,,}" != "n" ]]; then
        step "Installing VS Code extension"
        code --install-extension "$VSIX_PATH" --force && success "VS Code extension installed" || warn "VS Code extension install failed"
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
echo -e "  ${YELLOW}Restart your shell for PATH changes.${NC}"
echo
