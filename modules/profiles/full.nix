# Full Profile
# Extends minimal with additional IDEs and terminals
# Adds: intellij-goland, intellij-webstorm, sublime-text, wezterm
{ config, pkgs, lib, ... }:

{
  imports = [
    ./minimal.nix
  ];

  # Browsers: enable full set (adds chrome, zen-browser, brave)
  modules.packages.browsers.full = true;

  # IDEs: enable full set (adds goland, webstorm, sublime)
  modules.packages.ide.full = true;

  # Terminals: enable full set (adds wezterm)
  modules.packages.terminals.full = true;

  # Creative: enable full set (adds lunacy, inkscape)
  modules.packages.creative.full = true;
}
