# Browser packages
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.packages.browsers;
in
{
  options.modules.packages.browsers = {
    enable = mkEnableOption "Browser packages";

    minimal = mkOption {
      type = types.bool;
      default = true;
      description = "Install minimal set of browsers (chromium)";
    };

    full = mkOption {
      type = types.bool;
      default = false;
      description = "Install full set of browsers (chrome, zen-browser, brave)";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      # Minimal browsers
      optionals cfg.minimal [
        chromium
        firefox
        thunderbird
      ]
      ++
      # Full browsers (additional)
      optionals cfg.full [
        google-chrome
        zen-browser
        brave
      ];
  };
}
