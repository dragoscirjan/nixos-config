# Creative suite packages (image editing, vector graphics, design)
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.packages.creative;
in
{
  options.modules.packages.creative = {
    enable = mkEnableOption "Creative suite packages";

    basic = mkOption {
      type = types.bool;
      default = true;
      description = "Install basic set of creative tools (gimp, krita)";
    };

    extended = mkOption {
      type = types.bool;
      default = false;
      description = "Install extended set of creative tools (lunacy, inkscape)";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      # Basic creative tools
      optionals cfg.basic [
        gimp
        krita
      ]
      ++
      # Extended creative tools (additional)
      optionals cfg.extended [
        lunacy
        inkscape
      ];
  };
}
