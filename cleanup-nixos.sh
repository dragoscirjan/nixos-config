#!/usr/bin/env bash

set -euo pipefail

KEEP=${1:-5}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Cleaning NixOS system generations (keeping last $KEEP) ==="
sudo nix-env --delete-generations +$KEEP --profile /nix/var/nix/profiles/system

echo "=== Running Nix garbage collection ==="
sudo nix-collect-garbage

echo "=== Running utilities cleanup ==="
bash "$SCRIPT_DIR/cleanup-utilities.sh"

echo "=== NixOS cleanup finished ==="
