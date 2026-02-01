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

    bluetooth = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Bluetooth support";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      # X11/Wayland base
      services.xserver.enable = true;

      # KDE Plasma
      services.displayManager.sddm.enable = cfg.kde;
      services.desktopManager.plasma6.enable = cfg.kde;

      # GNOME
      services.displayManager.gdm.enable = cfg.gnome;
      services.desktopManager.gnome.enable = cfg.gnome;

      # Networking (needed for most desktops)
      networking.networkmanager.enable = true;

      # Audio
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        wireplumber = {
          enable = true;
          extraConfig = {
            # Prevent apps from having mute state restored (fixes Chrome muting issue)
            "10-disable-mute-restore" = {
              "wireplumber.settings" = {
                "default-audio-sink.restore-mute" = false;
                "default-audio-source.restore-mute" = false;
              };
              "stream.rules" = [
                {
                  matches = [
                    { "application.name" = "Google Chrome"; }
                    { "application.name" = "Chromium"; }
                  ];
                  actions = {
                    update-props = {
                      "stream.restore-mute" = false;
                      "stream.restore-props" = false;
                    };
                  };
                }
              ];
            };
          };
        };
      };
      security.rtkit.enable = true;
    }

    # XDG Portal for KDE
    (mkIf cfg.kde {
      xdg.portal.enable = true;
      xdg.portal.extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
    })

    # XDG Portal for GNOME
    (mkIf cfg.gnome {
      xdg.portal.enable = true;
      xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
    })

    # Bluetooth
    (mkIf cfg.bluetooth {
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
        settings = {
          General = {
            Enable = "Source,Sink,Media,Socket";
          };
        };
      };
      services.blueman.enable = true;
    })

    # services.pipewire.extraConfig.pipewire."92-disable-suspend" = {
    #   "context.properties" = {
    #     "session.suspend-timeout-seconds" = 0;
    #   };
    # };
    # services.pipewire.extraConfig.pipewire."91-samplerate" = {
    #   "context.properties" = {
    #     "default.clock.rate" = 48000;
    #     "default.clock.allowed-rates" = [ 48000 ];
    #   };
    # };
  ]);
}
