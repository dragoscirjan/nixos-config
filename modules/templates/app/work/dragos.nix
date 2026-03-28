# Work/Dragos aggregate template
# Imports all work sub-templates and adds extended nix-ld libraries + PATH
{ config, pkgs, lib, ... }:

{
  imports = [
    ./ide.nix
    ./languages.nix
    ./shells.nix
    ./browsers.nix
    ./tools.nix
  ];

  # Extended nix-ld libraries (on top of what base.nix provides)
  programs.nix-ld.libraries = with pkgs; [
    # Additional libs commonly needed by dev toolchains
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

  # Ensure ~/.local/bin is in PATH (mise shims, pip scripts, etc.)
  environment.sessionVariables = {
    PATH = [ "$HOME/.local/bin" ];
  };
}
