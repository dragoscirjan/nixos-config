# tw-nixos — Tower workstation (AMD GPU)
{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/templates/app/base.nix
    ../../modules/templates/app/work/dragos.nix
    ../../modules/templates/app/design.nix
    ../../modules/templates/app/ai.nix
    ../../modules/templates/app/virtualization.nix
    ../../modules/templates/app/media.nix
    ../../modules/templates/app/office.nix
    ../../modules/templates/hw/tower.nix
    ../../modules/templates/hw/gpu-amd.nix
  ];

  # ── Boot: UEFI systemd-boot ───────────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ── Networking ────────────────────────────────────────────────────────────
  networking.hostName = "tw-nixos";
  networking.nameservers = [ "192.168.86.1" "8.8.8.8" ];
  networking.firewall.allowedTCPPorts = [ 22 24800 24802 ];

  # ── Printing: HP network printer discovery ────────────────────────────────
  services.printing.browsing = true;
  services.printing.browsed.enable = true;
  environment.systemPackages = with pkgs; [
    system-config-printer # printer management GUI
    hplip # hp-setup tool for HP printer configuration
  ];

  # ── Bluetooth ─────────────────────────────────────────────────────────────
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.General.Enable = "Source,Sink,Media,Socket";
  };
  services.blueman.enable = true;

  # ── Audio: HDA Intel power-save + PipeWire tuning ────────────────────────
  # Disable power-save to prevent audio crashes after suspend/idle
  boot.extraModprobeConfig = ''
    options snd_hda_intel power_save=0 power_save_controller=N
  '';

  services.pipewire.extraConfig.pipewire."92-low-latency" = {
    "context.properties" = {
      "default.clock.rate" = 48000;
      "default.clock.allowed-rates" = [ 44100 48000 ];
      "default.clock.quantum" = 1024;
      "default.clock.min-quantum" = 32;
      "default.clock.max-quantum" = 2048;
    };
  };

  services.pipewire.wireplumber.extraConfig."51-alsa-disable-suspend" = {
    "monitor.alsa.rules" = [
      {
        matches = [
          { "node.name" = "~alsa_output.*"; }
          { "node.name" = "~alsa_input.*"; }
        ];
        actions.update-props = {
          "session.suspend-timeout-seconds" = 0;
          "api.alsa.headroom" = 1024;
        };
      }
    ];
  };

  system.stateVersion = "24.11";
}
