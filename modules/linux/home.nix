# Shared Home Manager module for generic Linux headless environments
{ config, pkgs, lib, ... }:

{
  home.packages = import ./packages.nix { inherit pkgs; };

  # Shell initializations that don't depend on system-level configuration
  programs.zsh = {
    enable = true;
    initExtra = ''
      # Optional: Add any cross-platform Zsh configs here
      if [ -f ${pkgs.autojump}/share/autojump/autojump.zsh ]; then
        source ${pkgs.autojump}/share/autojump/autojump.zsh
      fi
    '';
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      # Optional: Add any cross-platform Fish configs here
      if test -f ${pkgs.autojump}/share/autojump/autojump.fish
        source ${pkgs.autojump}/share/autojump/autojump.fish
      end
    '';
  };

  # Ensure ~/.local/bin is in PATH for all environments
  home.sessionPath = [ "$HOME/.local/bin" ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
