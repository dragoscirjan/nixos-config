# Gaming template — Steam + Wine
{ config, pkgs, lib, ... }:

{
  hardware.steam-hardware.enable = true;

  environment.systemPackages = with pkgs; [
    steam
    wine
  ];
}
