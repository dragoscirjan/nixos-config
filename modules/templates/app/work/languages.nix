# Work/Languages template — compilers, runtimes, LSPs
{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
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

    # Game engine
    godot_4
  ];
}
