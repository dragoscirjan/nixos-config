# Office suite packages
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.packages.office;
in
{
  options.modules.packages.office = {
    enable = mkEnableOption "Office suite packages";

    basic = mkOption {
      type = types.bool;
      default = true;
      description = "Install basic office suite (WPS)";
    };

    extended = mkOption {
      type = types.bool;
      default = false;
      description = "Install extended office suite (LibreOffice)";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      # Basic office
      optionals cfg.basic [
        wpsoffice
      ]
      ++
      # Extended office (additional)
      optionals cfg.extended [
        libreoffice
      ];
  };
}
