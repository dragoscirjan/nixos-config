# HW: Nvidia GPU template
{ config, lib, ... }:

{
  host.hw.gpuNvidia = true;

  hardware.nvidia = {
    modesetting.enable = true;
    open = false; # use proprietary kernel module
  };

  hardware.graphics.enable = true;

  services.xserver.videoDrivers = [ "nvidia" ];
}
