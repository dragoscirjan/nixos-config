# Browser packages
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.packages.browsers;
in
{
  options.modules.packages.browsers = {
    enable = mkEnableOption "Browser packages";

    basic = mkOption {
      type = types.bool;
      default = true;
      description = "Install basic set of browsers (chromium)";
    };

    extended = mkOption {
      type = types.bool;
      default = false;
      description = "Install extended set of browsers (chrome, zen-browser, brave)";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      # Basic browsers
      optionals cfg.basic [
        chromium
        firefox
        thunderbird
      ]
      ++
      # Extended browsers (additional)
      optionals cfg.extended [
        # google-chrome - installed via Flatpak
        # zen-browser - installed via Flatpak
        brave
      ];
  };
}
