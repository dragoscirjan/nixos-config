# Terminal emulator packages
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.packages.terminals;
in
{
  options.modules.packages.terminals = {
    enable = mkEnableOption "Terminal emulator packages";

    basic = mkOption {
      type = types.bool;
      default = true;
      description = "Install basic terminals (ghostty, alacritty)";
    };

    extended = mkOption {
      type = types.bool;
      default = false;
      description = "Install additional terminals (wezterm)";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      # Basic terminals
      optionals cfg.basic [
        ghostty
        alacritty
      ]
      ++
      # Extended terminals (additional)
      optionals cfg.extended [
        wezterm
      ];
  };
}
