# MCP Tuikit Development Template (GUI Tools & Headless testing)
{ config, pkgs, lib, isHomeManager ? false, ... }:

let
  tuikitPackages = with pkgs; [
    # Snapshots / Image Processing
    grim
    imagemagick # Provides `import`, `convert`, etc.

    # Window Managers / Headless dev testing (GUI dependent)
    sway
    xorg.xorgserver # Provides Xvfb
    xvfb-run
    kdePackages.kwin # Provides kwin_wayland and kwin_x11
  ];
in
if isHomeManager then {
  # These are heavy X11/Wayland dependencies.
  # We gracefully do nothing when imported into a headless Linux/Home Manager setup.
} else {
  config = lib.mkIf config.devProjects.mcpTuikit {
    environment.systemPackages = tuikitPackages;
  };
}
