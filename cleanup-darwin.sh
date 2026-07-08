#!/bin/bash

set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Error: this script is macOS-only. Use cleanup-nixos.sh or cleanup-linux.sh instead." >&2
  exit 1
fi

KEEP=${1:-5}

# nix-darwin's default system profile lives at the same path as NixOS's:
# /nix/var/nix/profiles/system.
sudo nix-env --delete-generations "+$KEEP" --profile /nix/var/nix/profiles/system

sudo nix-collect-garbage -d

# Homebrew-specific cleanup (removes old cached formula/cask downloads and
# formulae not required by any installed formula).
if command -v brew &> /dev/null; then
  brew cleanup
  brew autoremove
else
  echo "Warning: brew not found on PATH, skipping Homebrew cleanup." >&2
fi
