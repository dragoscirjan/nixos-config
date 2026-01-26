# Utility packages
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.packages.utils;
in
{
  options.modules.packages.utils = {
    enable = mkEnableOption "Utility packages";

    minimal = mkOption {
      type = types.bool;
      default = true;
      description = "Install minimal set of utilities (flameshot)";
    };

    full = mkOption {
      type = types.bool;
      default = false;
      description = "Install full set of utilities";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      # Minimal utilities
      optionals cfg.minimal [
        flameshot
      ]
      ++
      # Full utilities (additional)
      optionals cfg.full [
        # Add more utilities here for full profile
      ];
  };
}
