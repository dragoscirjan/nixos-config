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
      # Use these exact names which exist in pkgs.nerd-fonts
      default = [ 
        "fira-code" 
        "inconsolata" 
        "jetbrains-mono" 
        "monofur" 
        "roboto-mono"    # Changed from 'roboto'
        "sauce-code-pro" 
        "ubuntu" 
        "hasklug" 
      ];
      description = "List of Nerd Fonts to install";
    };
  };

  config = mkIf cfg.enable {
    fonts.packages = (map (font: pkgs.nerd-fonts.${font}) cfg.nerdFonts)
      ++ (with pkgs; [
        noto-fonts
        noto-fonts-color-emoji
      ]);
  };
}
