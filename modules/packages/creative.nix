# Creative suite packages (image editing, vector graphics, design)
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.packages.creative;
in
{
  options.modules.packages.creative = {
    enable = mkEnableOption "Creative suite packages";

    extended = mkEnableOption "Extended creative tools (lunacy, inkscape)";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      # Basic creative tools (always installed when enabled)
      [
        gimp
        krita
      ]
      ++
      # Extended creative tools
      optionals cfg.extended [
        lunacy
        inkscape
      ];
  };
}
