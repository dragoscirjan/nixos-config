# Package modules aggregator
{ config, lib, pkgs, ... }:

{
  imports = [
    ./ide.nix
    ./languages.nix
    ./terminals.nix
    ./code-agents.nix
    ./customize.nix
    ./vcs.nix
  ];
}
