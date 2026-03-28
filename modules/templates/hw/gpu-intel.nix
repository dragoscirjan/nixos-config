# HW: Intel GPU template
{ config, pkgs, lib, ... }:

{
  host.hw.gpuIntel = true;

  services.xserver.videoDrivers = [ "intel" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver # VA-API (Broadwell+)
      vaapiIntel # VA-API (older)
      vaapiVdpau
      libvdpau-va-gl
    ];
  };
}
