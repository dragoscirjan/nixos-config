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

      # Disable HDA Intel power save to prevent audio crashes after suspend/idle
      # Your system has 4 audio devices and power management causes conflicts
      boot.extraModprobeConfig = ''
        options snd_hda_intel power_save=0 power_save_controller=N
      '';

      # PipeWire session suspend timeout and sample rate fixes
      services.pipewire.extraConfig.pipewire."92-low-latency" = {
        "context.properties" = {
          # Disable node suspension to prevent audio device sleep issues
          "default.clock.rate" = 48000;
          "default.clock.allowed-rates" = [ 44100 48000 ];
          "default.clock.quantum" = 1024;
          "default.clock.min-quantum" = 32;
          "default.clock.max-quantum" = 2048;
        };
      };

      # Wireplumber ALSA device rules to prevent suspend issues
      services.pipewire.wireplumber.extraConfig."51-alsa-disable-suspend" = {
        "monitor.alsa.rules" = [
          {
            matches = [
              { "node.name" = "~alsa_output.*"; }
              { "node.name" = "~alsa_input.*"; }
            ];
            actions = {
              update-props = {
                # Disable session suspend for ALSA devices
                "session.suspend-timeout-seconds" = 0;
                # Increase headroom for stability
                "api.alsa.headroom" = 1024;
              };
            };
          }
        ];
      };
    }

    # XDG Portal for KDE
    (mkIf cfg.kde {
      xdg.portal.enable = true;
      xdg.portal.extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];

      # KDE Platform runtime for Flatpak apps
      modules.system.flatpak.packages = [
        "org.kde.Platform/x86_64/6.9"
      ];
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
  ]);
}
