#!/usr/bin/env bash

set -euo pipefail

KEEP=${1:-5}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Cleaning Darwin system generations (keeping last $KEEP) ==="
sudo nix-env --delete-generations +$KEEP --profile /nix/var/nix/profiles/system 2>/dev/null || true

echo "=== Running Nix garbage collection ==="
nix-collect-garbage

echo "=== Running utilities cleanup ==="
bash "$SCRIPT_DIR/cleanup-utilities.sh"

echo "=== Darwin cleanup finished ==="
