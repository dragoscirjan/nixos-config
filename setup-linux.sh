#!/usr/bin/env bash
#
# Linux (Non-NixOS) Nix setup script
# Usage: curl -fsSL https://raw.githubusercontent.com/dragoscirjan/nixos-config/main/setup-linux.sh | bash
#
# This script bootstraps Nix on a standard Linux distribution (like Fedora, Ubuntu, etc.):
# 1. Installs the Nix package manager (Determinate Systems installer with Flakes enabled)
# 2. Sets up the environment variables

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

echo ""
echo "========================================"
echo "  Nix Setup for Linux (Non-NixOS)"
echo "========================================"
echo ""

# 1. Check for curl
if ! command -v curl &> /dev/null; then
    error "curl is required but not installed. Please install it using your system package manager (e.g., sudo dnf install curl)."
fi

# 2. Check if Nix is already installed
if command -v nix &> /dev/null; then
    success "Nix is already installed!"
else
    info "Installing Nix via the Determinate Systems installer..."
    info "This will enable Nix Flakes by default."
    
    # Run the Determinate Systems Nix installer
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
    
    success "Nix has been installed successfully."
fi

echo ""
echo "========================================"
echo "  Setup Complete!"
echo "========================================"
echo ""
echo -e "${YELLOW}IMPORTANT: You need to restart your terminal or run the following command to make Nix available in your current session:${NC}"
echo ""
echo "  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
echo ""
echo "After that, you can test it by running:"
echo "  nix --version"
echo ""
