# Shared Home Manager module for generic Linux headless environments
{ config, pkgs, lib, ... }:

{
  programs.zsh.enable = true;
  programs.fish.enable = true;

  # Ensure ~/.local/bin is in PATH for all environments
  home.sessionPath = [ "$HOME/.local/bin" ];

  # Base system packages for all headless Linux environments
  home.packages = 
    (import ../common/git.nix { inherit pkgs; }) ++ 
    (import ../common/common.nix { inherit pkgs; }) ++ 
    (import ../common/ai-mcps.nix { inherit pkgs; }) ++ 
    (import ../common/fonts.nix { inherit pkgs; });
  
  # Tell fontconfig to discover fonts installed in user profile
  fonts.fontconfig.enable = true;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
