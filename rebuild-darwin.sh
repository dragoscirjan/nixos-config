#! /bin/bash

set -euo pipefail

# Valid darwin-rebuild actions we support here (deliberately NOT "test",
# which darwin-rebuild does not implement -- only switch/build/check/
# activate/rollback are valid subcommands).
ACTION=${1:-switch}

if [[ "$ACTION" != "switch" && "$ACTION" != "build" ]]; then
  echo "Error: Invalid action '$ACTION'. Only 'switch' or 'build' are allowed." >&2
  exit 1
fi

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Error: this script is macOS-only. Use rebuild-nixos.sh or rebuild-linux.sh instead." >&2
  exit 1
fi

HOST=$(scutil --get HostName 2>/dev/null || hostname)

echo "Updating Nix flake inputs..."
nix flake update

echo "Running darwin-rebuild $ACTION for $HOST..."
# "switch" performs system activation, which recent nix-darwin versions
# require to be run as root (no more internal self-elevating sudo).
# "build" only builds the derivation and doesn't need root.
#
# sudo's secure_path often excludes /run/current-system/sw/bin (where
# nix-darwin symlinks darwin-rebuild) and PATH-forwarding via `env` can
# still fail if `env` itself isn't on sudo's secure_path either. Resolve
# the absolute path *before* elevating so sudo needs no PATH lookup at all.
DARWIN_REBUILD="$(command -v darwin-rebuild)"
if [[ "$ACTION" == "switch" ]]; then
  sudo "$DARWIN_REBUILD" "$ACTION" --flake ".#$HOST"
else
  "$DARWIN_REBUILD" "$ACTION" --flake ".#$HOST"
fi
