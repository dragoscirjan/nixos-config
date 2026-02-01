# Package modules aggregator
{ config, lib, pkgs, ... }:

{
  imports = [
    ./browsers.nix
    ./code-agents.nix
    ./creative.nix
    ./customize.nix
    ./fonts.nix
    ./ide.nix
    ./languages.nix
    ./office.nix
    ./terminals.nix
    ./virtual.nix
    ./vcs.nix
  ];
}
