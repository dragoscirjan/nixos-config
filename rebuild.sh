#! /bin/bash

set -euo pipefail

ACTION=${1:-switch}

if [[ "$ACTION" != "switch" && "$ACTION" != "test" ]]; then
    echo "Error: Invalid action '$ACTION'. Only 'switch' or 'test' are allowed." >&2
    exit 1
fi

sudo nixos-rebuild $ACTION --flake .#$(hostname)
