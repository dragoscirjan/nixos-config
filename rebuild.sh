#!/usr/bin/env bash

set -euo pipefail

ACTION=${1:-switch}
HOST=$(hostname)
# Truncate .lan domain from hostname if present (common on macOS)
HOST=${HOST%.lan}

# Detect OS
OS="$(uname -s)"

nix flake update

if [[ "$ACTION" != "switch" && "$ACTION" != "test" ]]; then
  echo "Error: Invalid action '$ACTION'. Only 'switch' or 'test' are allowed." >&2
  exit 1
fi

echo "Detected OS: $OS"
echo "Target Host: $HOST"

if [[ "$OS" == "Linux" ]]; then
  if [ -f /etc/NIXOS ]; then
    echo "Running nixos-rebuild for NixOS..."
    sudo nixos-rebuild $ACTION --flake .#$HOST
  else
    echo "Running home-manager for standalone Linux..."
    # home-manager doesn't use sudo to switch user profiles
    # Default to current user @ hostname
    home-manager $ACTION --flake .#$USER@$HOST
  fi
elif [[ "$OS" == "Darwin" ]]; then
  echo "Running darwin-rebuild for macOS..."
  darwin-rebuild $ACTION --flake .#$HOST
else
  echo "Error: Unsupported OS '$OS'" >&2
  exit 1
fi
