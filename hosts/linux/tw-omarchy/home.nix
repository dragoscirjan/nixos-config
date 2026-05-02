{ config, pkgs, ... }:

{
  imports = [
    ../../../modules/linux/home.nix
  ];

  home.username = "dragosc";
  home.homeDirectory = "/home/dragosc";

  home.stateVersion = "24.11"; # Ensure this matches your installation version
}
