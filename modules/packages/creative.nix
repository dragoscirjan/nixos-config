# Creative suite packages (image editing, vector graphics, design)
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.packages.creative;
in
{
  options.modules.packages.creative = {
    enable = mkEnableOption "Creative suite packages";

    minimal = mkOption {
      type = types.bool;
      default = true;
      description = "Install minimal set of creative tools (gimp, krita)";
    };

    full = mkOption {
      type = types.bool;
      default = false;
      description = "Install full set of creative tools (lunacy, inkscape)";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      # Minimal creative tools
      optionals cfg.minimal [
        gimp
        krita
      ]
      ++
      # Full creative tools (additional)
      optionals cfg.full [
        lunacy
        inkscape
      ];
  };
}
