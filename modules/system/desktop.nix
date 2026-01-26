# Desktop environment configuration
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.system.desktop;
in
{
  options.modules.system.desktop = {
    enable = mkEnableOption "Desktop environment";

    kde = mkOption {
      type = types.bool;
      default = false;
      description = "Enable KDE Plasma desktop";
    };

    gnome = mkOption {
      type = types.bool;
      default = false;
      description = "Enable GNOME desktop";
    };
  };

  config = mkIf cfg.enable {
    # X11/Wayland base
    services.xserver.enable = true;

    # KDE Plasma
    services.displayManager.sddm.enable = cfg.kde;
    services.desktopManager.plasma6.enable = cfg.kde;

    # GNOME
    services.xserver.displayManager.gdm.enable = cfg.gnome;
    services.xserver.desktopManager.gnome.enable = cfg.gnome;

    # Networking (needed for most desktops)
    networking.networkmanager.enable = true;

    # Audio
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };
  };
}
