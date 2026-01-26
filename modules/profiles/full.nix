# Full Profile
# Extends minimal with additional IDEs and terminals
# Adds: intellij-goland, intellij-webstorm, sublime-text, wezterm
{ config, pkgs, lib, ... }:

{
  imports = [
    ./minimal.nix
  ];

  # IDEs: enable full set (adds goland, webstorm, sublime)
  modules.packages.ide.full = true;

  # Terminals: enable full set (adds wezterm)
  modules.packages.terminals.full = true;
}
