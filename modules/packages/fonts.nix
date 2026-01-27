# Font packages
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.packages.fonts;
in
{
  options.modules.packages.fonts = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Font packages";
    };

    nerdFonts = mkOption {
      type = types.listOf types.str;
      default = [ "FiraCode" "Inconsolata" "JetBrainsMono" "Monofur" "Roboto" "SauceCodePro" "Ubuntu" "Hasklug" ];
      description = "List of Nerd Fonts to install (e.g. FiraCode, JetBrainsMono, Hack)";
    };
  };

  config = mkIf cfg.enable {
    fonts.packages = with pkgs;
      optionals (cfg.nerdFonts != []) [
        (nerdfonts.override { fonts = cfg.nerdFonts; })
      ];
  };
}