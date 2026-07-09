#! /bin/bash

set -euo pipefail

# Valid darwin-rebuild actions we support here (deliberately NOT "test",
# which darwin-rebuild does not implement -- only switch/build/check/
# activate/rollback are valid subcommands).
ACTION=${1:-switch}
UPDATE_LOCK=${2:-}

if [[ "$ACTION" != "switch" && "$ACTION" != "build" ]]; then
  echo "Error: Invalid action '$ACTION'. Only 'switch' or 'build' are allowed." >&2
  exit 1
fi

if [[ -n "$UPDATE_LOCK" && "$UPDATE_LOCK" != "--update" ]]; then
  echo "Error: Invalid option '$UPDATE_LOCK'. Supported: --update" >&2
  exit 1
fi

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Error: this script is macOS-only. Use rebuild-nixos.sh or rebuild-linux.sh instead." >&2
  exit 1
fi

# Running this script (e.g. via ./rebuild-darwin.sh) is a non-login,
# non-interactive shell, so it does NOT source /etc/zshrc/etc/bashrc --
# which is where nix-darwin actually appends its bin dirs to PATH for
# your interactive shell. Make sure they're present here too, or
# darwin-rebuild/nix won't be found even though they work fine when you
# type them directly in your terminal.
export PATH="/run/current-system/sw/bin:/nix/var/nix/profiles/system/sw/bin:$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"

HOST=$(scutil --get HostName 2>/dev/null || hostname)

# flake.lock is now committed to the repo (shared, tested pins across
# machines) -- do NOT rewrite it on every rebuild. Only update it when
# explicitly asked via --update, and never let darwin-rebuild itself
# silently rewrite it either (--no-write-lock-file).
if [[ "$UPDATE_LOCK" == "--update" ]]; then
  echo "Updating flake.lock before rebuild..."
  nix flake update
fi

echo "Running darwin-rebuild $ACTION for $HOST..."
# "switch" performs system activation, which recent nix-darwin versions
# require to be run as root (no more internal self-elevating sudo).
# "build" only builds the derivation and doesn't need root.
#
# sudo's secure_path often excludes /run/current-system/sw/bin (where
# nix-darwin symlinks darwin-rebuild) and PATH-forwarding via `env` can
# still fail if `env` itself isn't on sudo's secure_path either. Resolve
# the absolute path *before* elevating so sudo needs no PATH lookup at all.
if ! DARWIN_REBUILD="$(command -v darwin-rebuild)"; then
  echo "Error: darwin-rebuild not found on PATH ($PATH). Has nix-darwin been bootstrapped yet? Run setup-darwin.sh first." >&2
  exit 1
fi
if [[ "$ACTION" == "switch" ]]; then
  sudo "$DARWIN_REBUILD" "$ACTION" --flake ".#$HOST" --no-write-lock-file
else
  "$DARWIN_REBUILD" "$ACTION" --flake ".#$HOST" --no-write-lock-file
fi
