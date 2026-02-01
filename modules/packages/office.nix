# Office suite packages
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.packages.office;
in
{
  options.modules.packages.office = {
    enable = mkEnableOption "Office suite packages";

    extended = mkEnableOption "Extended office suite (LibreOffice)";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      # Basic office (always installed when enabled)
      [
        wpsoffice
      ]
      ++
      # Extended office
      optionals cfg.extended [
        libreoffice
      ];
  };
}
