# Terminal emulator packages
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.packages.terminals;
in
{
  options.modules.packages.terminals = {
    enable = mkEnableOption "Terminal emulator packages";

    minimal = mkOption {
      type = types.bool;
      default = true;
      description = "Install minimal terminals (ghostty, alacritty)";
    };

    full = mkOption {
      type = types.bool;
      default = false;
      description = "Install additional terminals (wezterm)";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      # Minimal terminals
      optionals cfg.minimal [
        ghostty
        alacritty
      ]
      ++
      # Full terminals (additional)
      optionals cfg.full [
        wezterm
      ];
  };
}
