#! /bin/bash

set -euo pipefail

# For Linux (non-NixOS), the equivalent to 'switch' is 'switch' 
# and the equivalent to 'test' is 'build' (which builds without activating).
ACTION=${1:-switch}

if [[ "$ACTION" != "switch" && "$ACTION" != "build" ]]; then
  echo "Error: Invalid action '$ACTION'. Only 'switch' or 'build' are allowed." >&2
  exit 1
fi

echo "Updating Nix flake inputs..."
nix flake update

echo "Running home-manager $ACTION for $(hostname)..."
# Unlike NixOS, Home Manager runs entirely in user-space, so NO sudo is used here!
# We use 'nix run' to fetch home-manager directly so you don't even need to install it first.
nix run github:nix-community/home-manager -- $ACTION --flake .#$(hostname)
