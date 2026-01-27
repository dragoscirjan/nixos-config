# Full Profile
# Extends minimal with additional IDEs and terminals
# Adds: intellij-goland, intellij-webstorm, sublime-text, wezterm
{ config, pkgs, lib, ... }:

{
  imports = [
    ./minimal.nix
  ];

  # Browsers: enable full set (adds chrome, zen-browser, brave)
  modules.packages.browsers.full = true;

  # IDEs: enable full set (adds goland, webstorm, sublime)
  modules.packages.ide.full = true;

  # Terminals: enable full set (adds wezterm)
  modules.packages.terminals.full = true;



  # Containers: enable docker (in addition to podman)
  modules.packages.containers.docker = true;

  # Containers: add docker (in addition to podman)
  environment.systemPackages = with pkgs; [
    docker
    docker-compose
    docker-buildx
  ];
  
  services.docker = {
    enable = true;
    enableOnBoot = true;
  };
  
  users.users.dragosc.extraGroups = [ "docker" ];
  
  virtualisation.podman.dockerCompat = true;

  # Creative: enable full set (adds lunacy, inkscape)
  modules.packages.creative.full = true;
}
