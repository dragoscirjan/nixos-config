# Design template — image editing, vector graphics, 3D
{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    blender
    gimp
    inkscape
    krita
    lunacy
  ];
}
