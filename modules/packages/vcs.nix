# Version control system packages
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.packages.vcs;
in
{
  options.modules.packages.vcs = {
    enable = mkEnableOption "Version control system packages";

    extended = mkEnableOption "Extended VCS tools (gh, jujutsu)";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      # Basic VCS (always installed when enabled)
      [ git ]
      ++
      # Extended VCS
      optionals cfg.extended [
        gh
        jujutsu
      ];
  };
}
