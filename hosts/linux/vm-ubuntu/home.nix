{ config, pkgs, ... }:

{
  imports = [
    ../../../modules/linux/home.nix
    ../../../modules/templates/app/ide-basic.nix
    ../../../modules/templates/app/languages-basic.nix
  ];

  home.username = "dragosc";
  home.homeDirectory = "/home/dragosc";

  home.stateVersion = "24.11"; # Ensure this matches your installation version
}
