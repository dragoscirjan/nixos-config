# Flatpak utility module
# Provides services.flatpak + an aggregated package list that templates contribute to
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.flatpak;
in
{
  options.modules.flatpak = {
    enable = lib.mkEnableOption "Flatpak support";
    packages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Flatpak application IDs (or direct URLs) to install from Flathub.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.flatpak.enable = true;

    systemd.services."flatpak-install" = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" "flatpak.service" ];
      requires = [ "network-online.target" ];
      path = [ pkgs.flatpak ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "flatpak-install" ''
          ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists flathub \
            https://dl.flathub.org/repo/flathub.flatpakrepo
          ${lib.concatMapStringsSep "\n" (pkg:
            "${pkgs.flatpak}/bin/flatpak install --noninteractive flathub ${pkg} || true"
          ) cfg.packages}
        '';
      };
    };
  };
}
