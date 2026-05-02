#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

REPO_URL="https://github.com/dragoscirjan/nixos-config.git"
CONFIG_DIR="$HOME/.config/nixos"
HOST=""
OVERWRITE=false

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        --host)
            HOST="$2"
            shift 2
            ;;
        --overwrite)
            OVERWRITE=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

if [ -z "$HOST" ]; then
    HOST=$(hostname | sed 's/\.lan$//')
    info "No --host provided. Detected hostname: $HOST"
fi

OS="$(uname -s)"
info "Detected OS: $OS"

if [ ! -d "$CONFIG_DIR" ]; then
    info "Cloning repository..."
    mkdir -p "$(dirname "$CONFIG_DIR")"
    git clone "$REPO_URL" "$CONFIG_DIR" || error "Failed to clone repository"
fi

cd "$CONFIG_DIR"

if [[ "$OS" == "Linux" ]]; then
    if [ -f /etc/NIXOS ]; then
        info "Setting up NixOS host..."
        sudo ln -sf "$CONFIG_DIR" /etc/nixos
        sudo nixos-rebuild switch --flake .#$HOST
    else
        info "Setting up standalone Linux host via Home Manager..."
        if ! command -v home-manager &> /dev/null; then
            info "Installing Home Manager..."
            nix run home-manager/master -- init --switch .#$USER@$HOST
        else
            home-manager switch --flake .#$USER@$HOST
        fi
    fi
elif [[ "$OS" == "Darwin" ]]; then
    info "Setting up macOS host via nix-darwin..."
    if ! command -v darwin-rebuild &> /dev/null; then
        nix run nix-darwin -- switch --flake .#$HOST
    else
        darwin-rebuild switch --flake .#$HOST
    fi
else
    error "Unsupported OS: $OS"
fi

success "Setup complete for host: $HOST"
