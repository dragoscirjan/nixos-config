#!/usr/bin/env bash
#
# Symless Synergy 3.x installer — generic cross-platform tool, not tied to
# any single host (see modules/nixos/remote-control.nix for the NixOS/
# Flatpak equivalent, kept separate since NixOS doesn't do native package
# installs like this).
#
# No nixpkgs package or Homebrew cask exists for Synergy 3 (proprietary,
# license-gated), so this script downloads the correct native installer
# for the detected OS/distro directly from Symless and installs it via
# the OS's own package manager.
#
# Usage: ./install-synergy.sh
#
# Supported: Ubuntu 22.04/24.04/26.04, Debian 12/13, Fedora 42/43/44,
# Arch Linux, macOS (Apple Silicon / arm64 only).

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Single source of truth for the version we download — bump this (and the
# matching Flatpak URL in modules/nixos/remote-control.nix) together.
SYNERGY_VERSION="3.6.3"
BASE_URL="https://symless.com/synergy/download/package/synergy-personal-v3"
DOWNLOAD_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJwcm9kdWN0UGFja2FnZUlkIjo2NDIsInVzZXJJZCI6Mjc4MzksImlhdCI6MTc3Njc5NjI5Mn0.wajXhDZOuLBPhi9S27LNf1CrIOP5UbaZ2O20X0-Vo8A"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

download() {
    local url="$1"
    local dest="$2"
    info "Downloading $url ..."
    curl --proto '=https' --tlsv1.2 -fsSL -o "$dest" "$url"
}

install_deb() {
    local url="$1"
    local dest="$TMP_DIR/synergy.deb"
    download "$url" "$dest"
    info "Installing via apt..."
    sudo apt install -y "$dest"
}

install_rpm() {
    local url="$1"
    local dest="$TMP_DIR/synergy.rpm"
    download "$url" "$dest"
    info "Installing via dnf..."
    sudo dnf install -y "$dest"
}

install_arch() {
    local url="$1"
    local dest="$TMP_DIR/synergy.pkg.tar.zst"
    download "$url" "$dest"
    info "Installing via pacman..."
    sudo pacman -U --noconfirm "$dest"
}

install_macos() {
    local url="$1"
    local dest="$TMP_DIR/synergy.dmg"
    local mount_point="$TMP_DIR/mnt"
    download "$url" "$dest"
    mkdir -p "$mount_point"
    info "Mounting disk image..."
    hdiutil attach "$dest" -mountpoint "$mount_point" -nobrowse -quiet
    local app
    app="$(find "$mount_point" -maxdepth 1 -name '*.app' | head -n1)"
    if [ -z "$app" ]; then
        hdiutil detach "$mount_point" -quiet || true
        error "No .app bundle found inside the Synergy disk image."
    fi
    info "Copying $(basename "$app") to /Applications..."
    rm -rf "/Applications/$(basename "$app")"
    cp -R "$app" /Applications/
    hdiutil detach "$mount_point" -quiet
}

if [[ "$(uname -s)" == "Darwin" ]]; then
    ARCH="$(uname -m)"
    if [[ "$ARCH" != "arm64" ]]; then
        error "Synergy 3 for macOS is only published for Apple Silicon (arm64). Detected: $ARCH."
    fi
    install_macos "https://symless.com/synergy/api/download/synergy-${SYNERGY_VERSION}-macos-arm64.dmg?token=${DOWNLOAD_TOKEN}"
    success "Synergy $SYNERGY_VERSION installed to /Applications."
    exit 0
fi

if [[ "$(uname -s)" != "Linux" ]]; then
    error "Unsupported OS: $(uname -s). This script supports Linux distros and macOS only."
fi

if [ ! -f /etc/os-release ]; then
    error "/etc/os-release not found — cannot detect distro."
fi

# shellcheck disable=SC1091
. /etc/os-release
DISTRO_ID="${ID:-}"
DISTRO_VERSION="${VERSION_ID:-}"

case "$DISTRO_ID" in
    ubuntu)
        case "$DISTRO_VERSION" in
            26.04) install_deb "$BASE_URL/ubuntu-26.04/synergy-${SYNERGY_VERSION}-linux-noble-x86_64.deb" ;;
            24.04) install_deb "$BASE_URL/ubuntu-24.04/synergy-${SYNERGY_VERSION}-linux-noble-x86_64.deb" ;;
            22.04) install_deb "$BASE_URL/ubuntu-22.04/synergy-${SYNERGY_VERSION}-linux-jammy-x86_64.deb" ;;
            *) error "Unsupported Ubuntu version: $DISTRO_VERSION. Supported: 22.04, 24.04, 26.04." ;;
        esac
        ;;
    debian)
        case "$DISTRO_VERSION" in
            13) install_deb "$BASE_URL/debian-13/synergy-${SYNERGY_VERSION}-linux-noble-x86_64.deb" ;;
            12) install_deb "$BASE_URL/debian-12/synergy-${SYNERGY_VERSION}-linux-jammy-x86_64.deb" ;;
            *) error "Unsupported Debian version: $DISTRO_VERSION. Supported: 12, 13." ;;
        esac
        ;;
    fedora)
        case "$DISTRO_VERSION" in
            44) install_rpm "$BASE_URL/fedora-44/synergy-${SYNERGY_VERSION}-linux-noble-x86_64.rpm" ;;
            43) install_rpm "$BASE_URL/fedora-43/synergy-${SYNERGY_VERSION}-linux-noble-x86_64.rpm" ;;
            42) install_rpm "$BASE_URL/fedora-42/synergy-${SYNERGY_VERSION}-linux-noble-x86_64.rpm" ;;
            *) error "Unsupported Fedora version: $DISTRO_VERSION. Supported: 42, 43, 44." ;;
        esac
        ;;
    arch)
        install_arch "$BASE_URL/arch-linux/synergy-${SYNERGY_VERSION}-linux-noble-x86_64.pkg.tar.zst"
        ;;
    nixos)
        error "On NixOS, Synergy is installed declaratively via modules/nixos/remote-control.nix (Flatpak). This script does not apply here."
        ;;
    *)
        error "Unsupported distro: '$DISTRO_ID'. Supported: Ubuntu, Debian, Fedora, Arch Linux."
        ;;
esac

success "Synergy $SYNERGY_VERSION installed."
