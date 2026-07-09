{ pkgs, isHomeManager ? false, ... }:

let
  sharedPackages = with pkgs; [
    # Language tooling
    tree-sitter

    # C/C++
    (pkgs.lib.hiPrio gcc)
    gnumake
    clang
    clang-tools
    llvmPackages.lld

    # DotNet
    dotnet-sdk

    # Go
    go
    gopls
    hugo

    # Godot
    godot
    gdscript-formatter
    blender

    # JavaScript / TypeScript
    bun
    deno

    # Lua
    lua

    # Python (Basic)
    uv

    # Nix tooling
    nixpkgs-fmt
    statix

    # Rust
    cargo
    rust-analyzer
    rustc

    # Zig
    zig

    # Java
    jdk
    kotlin
    groovy
  ];
in
{
  imports = [ ./languages-basic.nix ];
} // (if isHomeManager then {
  home.packages = sharedPackages;
} else {
  environment.systemPackages = sharedPackages;

  # Extended nix-ld libraries for IDEs and prebuilt language tooling
  programs.nix-ld.libraries = with pkgs; [
    libGL
    libGLU
    stdenv.cc.cc
    libxi
    libxtst
    libxrender
    libxscrnsaver
    gtk3
    gdk-pixbuf
  ];
})
