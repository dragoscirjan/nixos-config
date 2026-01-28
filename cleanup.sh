#!/bin/bash

KEEP=${1:-5}

sudo nix-env --delete-generations +$KEEP --profile /nix/var/nix/profiles/system
