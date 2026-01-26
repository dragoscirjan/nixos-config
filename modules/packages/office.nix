# Office suite packages
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.packages.office;
in
{
  options.modules.packages.office = {
    enable = mkEnableOption "Office suite packages";

    minimal = mkOption {
      type = types.bool;
      default = true;
      description = "Install minimal office suite (WPS)";
    };

    full = mkOption {
      type = types.bool;
      default = false;
      description = "Install full office suite (LibreOffice)";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      # Minimal office
      optionals cfg.minimal [
        wps-office
      ]
      ++
      # Full office (additional)
      optionals cfg.full [
        libreoffice
      ];
  };
}
