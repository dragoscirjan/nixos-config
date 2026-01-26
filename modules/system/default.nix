# System modules aggregator
{ config, lib, pkgs, ... }:

{
  imports = [
    ./desktop.nix
    ./flatpak.nix
    ./users.nix
  ];
}
