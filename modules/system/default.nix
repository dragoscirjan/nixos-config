# System modules aggregator
{ config, lib, pkgs, ... }:

{
  imports = [
    ./users.nix
    ./desktop.nix
  ];
}
