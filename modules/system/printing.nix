# Printing service configuration
{ config, lib, pkgs, ... }:

{
  options.modules.system.printing = {
    enable = lib.mkEnableOption "Printing service (CUPS)";

    drivers = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Additional printer drivers to install";
    };

    hplip = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable HPLIP for HP printers";
    };

    wireless = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable network/wireless printer discovery (Avahi)";
    };
  };

  config = lib.mkIf config.modules.system.printing.enable {
    # Enable CUPS printing service
    services.printing = {
      enable = true;
      drivers = config.modules.system.printing.drivers
        ++ lib.optionals config.modules.system.printing.hplip [ pkgs.hplip ];
    };

    # Enable Avahi for network printer discovery (mDNS/DNS-SD)
    services.avahi = lib.mkIf config.modules.system.printing.wireless {
      enable = true;
      nssmdns4 = true; # Enable .local hostname resolution
      openFirewall = true; # Open firewall for mDNS
    };

    # HP printer tools (hp-setup, hp-toolbox)
    environment.systemPackages = lib.optionals config.modules.system.printing.hplip [
      pkgs.hplip
    ];
  };
}
