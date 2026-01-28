# Utility packages
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.packages.utils;
in
{
  options.modules.packages.utils = {
    enable = mkEnableOption "Utility packages";

    basic = mkOption {
      type = types.bool;
      default = true;
      description = "Install basic set of utilities (flameshot)";
    };

    extended = mkOption {
      type = types.bool;
      default = false;
      description = "Install extended set of utilities";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      (optionals cfg.basic [
        flameshot
        btop
        fastfetch  # Using fastfetch instead of neofetch/screenfetch
        fzf
        go-task
        mise
        bat
        autojump
      ]) ++
      (optionals cfg.extended [
        zsh
        fish
        nushell
      ]);

    # Autojump shell integration
    programs.bash.interactiveShellInit = "source ${pkgs.autojump}/share/autojump/autojump.bash";
    programs.zsh.interactiveShellInit = "source ${pkgs.autojump}/share/autojump/autojump.zsh";
  };
}
