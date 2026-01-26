# Version control system packages
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.packages.vcs;
in
{
  options.modules.packages.vcs = {
    enable = mkEnableOption "Version control system packages";

    git = mkOption {
      type = types.bool;
      default = true;
      description = "Install Git";
    };

    jujutsu = mkOption {
      type = types.bool;
      default = true;
      description = "Install Jujutsu (jj) version control";
    };

    gh = mkOption {
      type = types.bool;
      default = true;
      description = "Install GitHub CLI";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      optionals cfg.git [ git ]
      ++ optionals cfg.jujutsu [ jujutsu ]
      ++ optionals cfg.gh [ gh ];
  };
}
