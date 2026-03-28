# HW: AMD GPU template
{ config, lib, ... }:

{
  host.hw.gpuAmd = true;

  services.xserver.videoDrivers = [ "amdgpu" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true; # required for Wine, Steam
  };
}
