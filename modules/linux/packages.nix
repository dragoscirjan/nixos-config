# Pure list of headless dev tools, compilers, and shells.
# Imported by both NixOS and standalone Linux/Darwin via Home Manager.
{ pkgs }: with pkgs; [
  # VCS / forge CLIs
  gh
  glab
  forgejo-cli
  jujutsu
  lazygit

  # Task runner / project tooling
  go-task

  # Nix tooling
  nixpkgs-fmt
  statix

  # Language tooling
  tree-sitter

  # SSL / crypto libs
  openssl

  # Terminal
  wezterm

  # Shells
  fish
  nushell
  powershell
  zsh

  # Build tools
  gcc
  gnumake

  # C/C++
  clang
  clang-tools # includes clangd
  llvmPackages.lld

  # Go
  go
  gopls

  # JavaScript / TypeScript
  bun
  deno
  nodejs_24

  # Lua
  lua

  # Python
  python3
  uv

  # Rust
  cargo
  rust-analyzer
  rustc

  # Zig
  zig

  # Java
  jdk
]
