#!/usr/bin/env bash

set -euo pipefail

echo "=== Cleaning developer utilities and package caches ==="

# Node.js / npm
if command -v npm &>/dev/null; then
  echo "Cleaning npm cache..."
  npm cache clean --force 2>/dev/null || true
fi

# pnpm
if command -v pnpm &>/dev/null; then
  echo "Pruning pnpm store..."
  pnpm store prune 2>/dev/null || true
fi

# yarn
if command -v yarn &>/dev/null; then
  echo "Cleaning yarn cache..."
  yarn cache clean 2>/dev/null || true
fi

# bun
if command -v bun &>/dev/null; then
  echo "Cleaning bun cache..."
  bun pm cache rm 2>/dev/null || true
fi

# Python / uv
if command -v uv &>/dev/null; then
  echo "Cleaning uv cache..."
  uv cache clean 2>/dev/null || true
fi

# Python / pip
if command -v pip &>/dev/null; then
  echo "Purging pip cache..."
  pip cache purge 2>/dev/null || true
fi

# Rust / Cargo
if command -v cargo-cache &>/dev/null; then
  echo "Cleaning cargo cache..."
  cargo-cache --remove-dir all 2>/dev/null || true
elif [ -d "$HOME/.cargo/registry/cache" ]; then
  echo "Cleaning cargo registry cache..."
  rm -rf "$HOME/.cargo/registry/cache"/* 2>/dev/null || true
fi

# Go
if command -v go &>/dev/null; then
  echo "Cleaning Go build and module cache..."
  go clean -cache -modcache 2>/dev/null || true
fi

# Systemd Journal (Linux)
if command -v journalctl &>/dev/null && command -v sudo &>/dev/null; then
  echo "Vacuuming systemd journal..."
  sudo journalctl --vacuum-size=500M 2>/dev/null || true
fi

echo "=== Utilities cleanup completed ==="
