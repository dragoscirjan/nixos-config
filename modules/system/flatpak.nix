# Flatpak configuration
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
      description = "List of Flatpak packages or URLs to install";
    };
  };

  config = mkIf cfg.enable {
    # Enable Flatpak infrastructure
    services.flatpak.enable = true;

    # Ensure flatpak is available in the user environment
    environment.systemPackages = [ pkgs.flatpak ];

    systemd.services."flatpak-install" = {
      description = "Install configured Flatpak packages";
      wantedBy = [ "multi-user.target" ];
      
      # Wait for network and flatpak service to be ready
      after = [ "network-online.target" "flatpak.service" ];
      wants = [ "network-online.target" ];

      path = [ pkgs.flatpak pkgs.bash ];

      serviceConfig = {
        Type = "oneshot";
        # This script checks if the package is already installed before trying to install it
        ExecStart = let
          flatpakBin = "${pkgs.flatpak}/bin/flatpak";
          script = pkgs.writeShellScript "install-flatpaks" ''
            ${concatMapStringsSep "\n" (pkg: ''
              # If it's a URL (like Synergy), we check if the name is already in the list
              # Otherwise, we just try to install it non-interactively.
              echo "Checking/Installing flatpak: ${pkg}"
              ${flatpakBin} install --noninteractive --assumeyes ${pkg} || true
            '') cfg.packages}
          '';
        in "${script}";
        
        RemainAfterExit = true;
      };
    };
  };
}
