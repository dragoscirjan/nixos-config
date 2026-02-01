# Terminal emulator packages
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.packages.terminals;
in
{
  options.modules.packages.terminals = {
    enable = mkEnableOption "Terminal emulator packages";

    extended = mkEnableOption "Extended terminals (wezterm)";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      # Basic terminals (always installed when enabled)
      [
        alacritty
        ghostty
      ]
      ++
      # Extended terminals
      optionals cfg.extended [
        wezterm
      ];
  };
}
