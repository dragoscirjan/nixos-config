# SSH and security configuration
{ config, lib, pkgs, ... }:

{
  options.modules.system.ssh = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable SSH server";
    };

    permitRootLogin = lib.mkOption {
      type = lib.types.enum [ "yes" "without-password" "prohibit-password" "no" ];
      default = "prohibit-password";
      description = "Whether to allow root login via SSH";
    };

    passwordAuthentication = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable password authentication";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open SSH port in firewall";
    };

    ports = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [ 22 ];
      description = "SSH ports to listen on";
    };
  };

  config = lib.mkIf config.modules.system.ssh.enable {
    # Enable SSH server
    services.openssh.enable = true;
    
    # SSH configuration
    services.openssh.settings = {
      PermitRootLogin = config.modules.system.ssh.permitRootLogin;
      PasswordAuthentication = config.modules.system.ssh.passwordAuthentication;
      X11Forwarding = true;
      KbdInteractiveAuthentication = false;
    };

    # SSH ports
    services.openssh.ports = config.modules.system.ssh.ports;

    # Open firewall ports
    networking.firewall.allowedTCPPorts = lib.mkIf config.modules.system.ssh.openFirewall config.modules.system.ssh.ports;

    # Hardening
    programs.ssh.askPassword = "";
  };
}