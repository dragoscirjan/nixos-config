# Programming language packages
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.packages.languages;
in
{
  options.modules.packages.languages = {
    enable = mkEnableOption "Programming language packages";

    golang = mkOption {
      type = types.bool;
      default = true;
      description = "Install Go programming language";
    };

    nodejs = mkOption {
      type = types.bool;
      default = true;
      description = "Install Node.js";
    };

    bun = mkOption {
      type = types.bool;
      default = true;
      description = "Install Bun JavaScript runtime";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      optionals cfg.golang [ go gopls ]
      ++ optionals cfg.nodejs [ nodejs ]
      ++ optionals cfg.bun [ bun ];
  };
}
