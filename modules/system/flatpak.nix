{ config, lib, pkgs, ... }:

let
  cfg = config.modules.system.flatpak;
in
{
  options.modules.system.flatpak = {
    enable = lib.mkEnableOption "Flatpak support";
    packages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
    };
  };

  config = lib.mkIf cfg.enable {
    services.flatpak.enable = true;
    
    systemd.services."flatpak-install" = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" "flatpak.service" ];
      path = [ pkgs.flatpak ];
      
      serviceConfig = {
        Type = "oneshot";
        ExecStart = ''
          ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
          ${lib.concatMapStringsSep "\n" (pkg: 
            "${pkgs.flatpak}/bin/flatpak install --noninteractive flathub ${pkg} || true"
          ) cfg.packages}
        '';
        RemainAfterExit = true;
      };
    };
  };
}
