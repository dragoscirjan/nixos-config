# User configuration
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.system.users;
in
{
  options.modules.system.users = {
    enable = mkEnableOption "User configuration";

    dragosc = mkOption {
      type = types.bool;
      default = true;
      description = "Create dragosc user account";
    };
  };

  config = mkIf cfg.enable {
    users.users = mkIf cfg.dragosc {
      dragosc = {
        isNormalUser = true;
        description = "Dragos Cirjan";
        extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
        # Password will be set on first login or via `passwd`
        initialPassword = "changeme";
      };
    };

    # Allow wheel group to use sudo
    security.sudo.wheelNeedsPassword = true;
  };
}
