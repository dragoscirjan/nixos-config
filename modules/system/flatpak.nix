# Flatpak configuration
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.system.flatpak;
in
{
  options.modules.system.flatpak = {
    enable = mkEnableOption "Flatpak support";

    packages = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of Flatpak packages to install";
    };
  };

  config = mkIf cfg.enable {
    # Enable Flatpak
    services.flatpak.enable = true;

    # Install flatpak package
    environment.systemPackages = with pkgs; [
      flatpak
    ];

    # Add Flatpak packages
    systemd.services."flatpak-install" = {
      wantedBy = [ "multi-user.target" ];
      after = [ "flatpak.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = let
          installCmds = map (pkg: "flatpak install --noninteractive --assumeyes ${pkg}") cfg.packages;
        in "${pkgs.bash}/bin/bash -c '${lib.concatStringsSep "; " installCmds}'";
      };
    };
  };
}
