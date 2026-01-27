# Network configuration
{ config, lib, pkgs, ... }:

{
  options.modules.system.network = {
    enable = lib.mkEnableOption "Network configuration";

    useDHCP = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable DHCP for network interfaces";
    };

    enableWireless = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable wireless networking support";
    };

    firewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable firewall";
    };

    allowedTCPPorts = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [];
      description = "List of TCP ports to open in firewall";
    };

    allowedUDPPorts = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [];
      description = "List of UDP ports to open in firewall";
    };
  };

  config = lib.mkIf config.modules.system.network.enable {
    # Enable networking
    networking.networkmanager.enable = true;
    
    # DHCP configuration
    networking.useDHCP = config.modules.system.network.useDHCP;
    
    # Wireless support
    networking.wireless.enable = config.modules.system.network.enableWireless;

    # Firewall
    networking.firewall.enable = config.modules.system.network.firewall;
    networking.firewall.allowedTCPPorts = config.modules.system.network.allowedTCPPorts;
    networking.firewall.allowedUDPPorts = config.modules.system.network.allowedUDPPorts;

    # NetworkManager requires user in networkmanager group (handled in users.nix)
  };
}