# HW: Laptop template — power management, backlight
{ config, pkgs, lib, ... }:

{
  host.hw.laptop = true;

  services.tlp.enable = true;
  services.acpid.enable = true;

  # power-profiles-daemon conflicts with TLP — disable it
  services.power-profiles-daemon.enable = false;

  environment.systemPackages = with pkgs; [
    brightnessctl
    powertop
  ];
}
