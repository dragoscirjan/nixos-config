#! /bin/bash

set -euo pipefail

sudo nixos-rebuild switch --flake .#$(hostname)
