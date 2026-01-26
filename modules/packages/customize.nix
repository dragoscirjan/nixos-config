# Customization packages (dotfiles, shell prompts, etc.)
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.packages.customize;
in
{
  options.modules.packages.customize = {
    enable = mkEnableOption "Customization packages";

    chezmoi = mkOption {
      type = types.bool;
      default = true;
      description = "Install chezmoi dotfiles manager";
    };

    oh-my-posh = mkOption {
      type = types.bool;
      default = true;
      description = "Install oh-my-posh prompt theme engine";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      optionals cfg.chezmoi [ chezmoi ]
      ++ optionals cfg.oh-my-posh [ oh-my-posh ];
  };
}
