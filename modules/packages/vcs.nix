# Version control system packages
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.packages.vcs;
in
{
  options.modules.packages.vcs = {
    enable = mkEnableOption "Version control system packages";

    basic = mkOption {
      type = types.bool;
      default = true;
      description = "Install basic set of languages (git)";
    };

    extended = mkOption {
      type = types.bool;
      default = false;
      description = "Install additional languages (gh, jujutsu)";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      optionals cfg.basic [ git ]
      ++ optionals cfg.extended [ jujutsu gh ];
  };
}
