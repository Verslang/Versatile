#!/usr/bin/env bash
# ================================================
# Versatile Suite — Linux/macOS Uninstaller
# ================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'
CYAN='\033[0;36m'; WHITE='\033[1;37m'; NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; }

echo -e "${WHITE}Versatile Suite — Uninstaller${NC}"
echo "=============================="
echo

# Privilege helper
NEED_SUDO=false
[[ $EUID -ne 0 ]] && NEED_SUDO=true
run_privileged() { if $NEED_SUDO; then sudo "$@"; else "$@"; fi; }

PREFIX="/usr/local"

# Detect what's installed
VL_INSTALLED=false
VS_INSTALLED=false

[[ -f "$PREFIX/bin/verslang" ]] && VL_INSTALLED=true
[[ -f "$PREFIX/bin/verss" ]]    && VS_INSTALLED=true

if ! $VL_INSTALLED && ! $VS_INSTALLED; then
    echo "No Versatile Suite products found at $PREFIX."
    exit 0
fi

echo "Detected installations:"
$VL_INSTALLED && echo "  [*] Verslang ($PREFIX/bin/verslang)"
$VS_INSTALLED && echo "  [*] Versscript ($PREFIX/bin/verss)"
echo

echo "What would you like to uninstall?"
echo "  [1] Verslang only"
echo "  [2] Versscript only"
echo "  [3] Everything"
echo "  [4] Cancel"
echo
read -rp "Enter choice (1-4): " CHOICE

RM_VL=false RM_VS=false
case "$CHOICE" in
    1) RM_VL=true ;; 2) RM_VS=true ;; 3) RM_VL=true; RM_VS=true ;;
    4) echo "Cancelled."; exit 0 ;; *) error "Invalid choice."; exit 1 ;;
esac

echo
read -rp "Are you sure? This will remove all selected components. [y/N]: " CONFIRM
[[ "${CONFIRM,,}" != "y" ]] && echo "Cancelled." && exit 0
echo

if $RM_VL && $VL_INSTALLED; then
    echo -e "${CYAN}--- Uninstalling Verslang ---${NC}"
    run_privileged rm -f "$PREFIX/bin/verslang" && success "Removed verslang binary"
    run_privileged rm -rf "$PREFIX/lib/verslang" && success "Removed stdlib"
    run_privileged rm -rf "$PREFIX/share/verslang" && success "Removed examples/docs"
    run_privileged rm -f "$PREFIX/share/man/man1/verslang.1" && success "Removed man page"
    [[ -f /etc/profile.d/verslang.sh ]] && run_privileged rm -f /etc/profile.d/verslang.sh && success "Removed PATH entry"
    success "Verslang uninstalled"
    echo
fi

if $RM_VS && $VS_INSTALLED; then
    echo -e "${CYAN}--- Uninstalling Versscript ---${NC}"
    run_privileged rm -f "$PREFIX/bin/verss" && success "Removed verss binary"
    run_privileged rm -rf "$PREFIX/lib/versscript" && success "Removed native modules"
    run_privileged rm -rf "$PREFIX/share/versscript" && success "Removed examples/docs"
    run_privileged rm -f "$PREFIX/share/man/man1/verss.1" && success "Removed man page"
    [[ -f /etc/profile.d/versscript.sh ]] && run_privileged rm -f /etc/profile.d/versscript.sh && success "Removed PATH entry"
    success "Versscript uninstalled"
    echo
fi

echo -e "${GREEN}Uninstallation complete!${NC}"
echo "Restart your shell for changes to take effect."
