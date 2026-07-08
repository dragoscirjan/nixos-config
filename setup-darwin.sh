#!/usr/bin/env bash
#
# macOS (nix-darwin) setup script
# Usage: ./setup-darwin.sh --host <mac-m1|mac-m5>
#
# This script bootstraps a Mac from scratch:
# 1. Requires --host, validated against the hosts/darwin/* flake hosts
# 2. Renames the physical machine (scutil) to match the chosen host,
#    since out-of-box Macs can share the same default hostname
# 3. Installs the Nix package manager if missing (Determinate installer)
# 4. Clones this flake repo if missing
# 5. Bootstraps via nix-darwin (first run) or darwin-rebuild (subsequent runs)
#    Homebrew itself is installed declaratively by nix-homebrew during this
#    switch -- no separate imperative brew-install step is needed.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

REPO_URL="https://github.com/dragoscirjan/nixos-config.git"
CONFIG_DIR="$HOME/.config/nixos"
HOST=""

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        --host)
            HOST="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

if [ -z "$HOST" ]; then
    error "Usage: $0 --host <mac-m1|mac-m5>. --host is required (Macs share the same out-of-box hostname, so it cannot be auto-detected)."
fi

if [[ "$(uname -s)" != "Darwin" ]]; then
    error "This script is macOS-only. Use setup-nixos.sh or setup-linux.sh instead."
fi

# 1. Clone the repo first (needed to validate --host against hosts/darwin/*),
#    unless it's already checked out.
if [ ! -d "$CONFIG_DIR" ]; then
    if ! command -v git &> /dev/null; then
        error "git is required to clone the config repo but is not installed. Install Xcode Command Line Tools first: xcode-select --install"
    fi
    info "Cloning repository..."
    mkdir -p "$(dirname "$CONFIG_DIR")"
    git clone "$REPO_URL" "$CONFIG_DIR" || error "Failed to clone repository"
fi

cd "$CONFIG_DIR"

if [ ! -d "hosts/darwin/$HOST" ]; then
    error "Unknown host '$HOST'. Expected a directory at hosts/darwin/$HOST (available: $(ls hosts/darwin))."
fi

# 2. Rename the physical Mac to match the chosen flake host.
info "Setting hostname to '$HOST'..."
sudo scutil --set ComputerName "$HOST"
sudo scutil --set HostName "$HOST"
sudo scutil --set LocalHostName "$HOST"

# 3. Install Nix if missing.
if command -v nix &> /dev/null; then
    success "Nix is already installed!"
else
    info "Installing Nix via the Determinate Systems installer..."
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
    success "Nix has been installed successfully."
    warn "Restart your terminal (or source the Nix daemon script) before continuing if this is a fresh shell."
fi

# 4. Bootstrap via nix-darwin.
info "Setting up macOS host '$HOST' via nix-darwin..."
if ! command -v darwin-rebuild &> /dev/null; then
    nix run nix-darwin -- switch --flake ".#$HOST"
else
    darwin-rebuild switch --flake ".#$HOST"
fi

# 5. Homebrew is installed declaratively by nix-homebrew as part of the
#    switch above. Verify it landed rather than assuming.
if command -v brew &> /dev/null; then
    success "Homebrew is available."
else
    warn "Homebrew was not found on PATH after the switch. Check 'nix-homebrew' activation logs -- it should have installed Homebrew declaratively."
fi

success "Setup complete for host: $HOST"
