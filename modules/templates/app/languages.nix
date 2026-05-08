{ pkgs, isHomeManager ? false, ... }:

let
  sharedPackages = with pkgs; [
    # Language tooling
    tree-sitter

    # C/C++
    gcc
    gnumake
    clang
    clang-tools
    llvmPackages.lld

    # Go
    go
    gopls

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
    xorg.libXi
    xorg.libXtst
    xorg.libXrender
    xorg.libXScrnSaver
    gtk3
    gdk-pixbuf
  ];
})
