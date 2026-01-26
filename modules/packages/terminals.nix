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
      description = "Install minimal terminal (ghostty)";
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
      ]
      ++
      # Full terminals (additional)
      optionals cfg.full [
        wezterm
      ];
  };
}
