#!/usr/bin/env bash

set -euo pipefail

ACTION=${1:-switch}
HOST=$(hostname)
# Truncate .lan domain from hostname if present (common on macOS)
HOST=${HOST%.lan}
UPDATE_LOCK=${2:-}

# Detect OS
OS="$(uname -s)"

if [[ "$ACTION" != "switch" && "$ACTION" != "test" ]]; then
  echo "Error: Invalid action '$ACTION'. Only 'switch' or 'test' are allowed." >&2
  exit 1
fi

if [[ -n "$UPDATE_LOCK" && "$UPDATE_LOCK" != "--update" ]]; then
  echo "Error: Invalid option '$UPDATE_LOCK'. Supported: --update" >&2
  exit 1
fi

if [[ "$UPDATE_LOCK" == "--update" ]]; then
  echo "Updating flake.lock before rebuild..."
  nix flake update
fi

echo "Detected OS: $OS"
echo "Target Host: $HOST"

COMMON_FLAGS=(--flake ".#$HOST" --option max-jobs 1 --no-write-lock-file)

if [[ "$OS" == "Linux" ]]; then
  if [ -f /etc/NIXOS ]; then
    echo "Running nixos-rebuild for NixOS..."
    sudo nixos-rebuild "$ACTION" "${COMMON_FLAGS[@]}"
  else
    echo "Running home-manager for standalone Linux..."
    # home-manager doesn't use sudo to switch user profiles
    # Default to current user @ hostname
    home-manager "$ACTION" --flake ".#$USER@$HOST" --option max-jobs 1 --no-write-lock-file
  fi
elif [[ "$OS" == "Darwin" ]]; then
  echo "Running darwin-rebuild for macOS..."
  darwin-rebuild "$ACTION" "${COMMON_FLAGS[@]}"
else
  echo "Error: Unsupported OS '$OS'" >&2
  exit 1
fi
