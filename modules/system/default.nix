# System modules aggregator
{ config, lib, pkgs, ... }:

{
  imports = [
    ./desktop.nix
    ./flatpak.nix
    ./network.nix
    ./printing.nix
    ./users.nix
  ];
}
