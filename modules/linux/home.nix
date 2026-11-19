# Shared Home Manager module for generic Linux headless environments
{ config, pkgs, lib, ... }:

let
  # Consume only the package list. Shell initialization is owned by chezmoi;
  # see the ownership warning in modules/templates/app/shells.nix.
  shells = import ../templates/app/shells.nix { inherit pkgs lib; isHomeManager = true; };
in
{
  programs = {
    zsh.enable = true;
    fish.enable = true;
    home-manager.enable = true;
  };

  # Ensure ~/.local/bin is in PATH for all environments
  home.sessionPath = [ "$HOME/.local/bin" ];

  # Base system packages for all headless Linux environments
  home.packages =
    (import ../common/git.nix { inherit pkgs; }) ++
    (import ../common/common.nix { inherit pkgs; }) ++
    (import ../common/ai-mcps.nix { inherit pkgs; }) ++
    (import ../common/fonts.nix { inherit pkgs; }) ++
    shells.home.packages ++
    [ pkgs.simple-scan ];

  # Tell fontconfig to discover fonts installed in user profile
  fonts.fontconfig.enable = true;
}
