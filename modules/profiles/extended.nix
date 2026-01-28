# Full Profile
# Extends minimal with additional IDEs and terminals
# Adds: intellij-goland, intellij-webstorm, sublime-text, wezterm
{ config, pkgs, lib, ... }:

{
  imports = [
    ./basic.nix
  ];

  # Browsers: enable full set (adds chrome, brave) - Zen via Flatpak
  modules.packages.browsers.full = lib.mkForce true;

  # IDEs: enable full set (adds goland, webstorm, sublime)
  modules.packages.ide.full = lib.mkForce true;

  # Terminals: enable full set (adds wezterm)
  modules.packages.terminals.full = lib.mkForce true;



  # Containers: enable docker (in addition to podman)
#   modules.packages.containers.docker = true;

  # Containers: add docker (in addition to podman)
  environment.systemPackages = with pkgs; [
    docker
    docker-compose
    docker-buildx
  ];
  
#   services.docker = {
#     enable = true;
#     enableOnBoot = true;
#   };

#   users.users.dragosc.extraGroups = [ "docker" ];
  
  virtualisation.podman.dockerCompat = true;

  # Flatpak: add Zen Browser and Synergy to full profile
  modules.system.flatpak = {
    enable = true;
    packages = [
      "app.zen_browser.zen"
      "org.kde.Platform/x86_64/6.9"
      "https://symless.com/synergy/download/package/synergy-personal-v3/flatpak/synergy-3.5.1-linux-noble-x86_64.flatpak"
    ];
  };

  # Creative: enable full set (adds lunacy, inkscape)
  modules.packages.creative.full = lib.mkForce true;

  # Code Agents: enable all code agents
  modules.packages.code-agents.enable = true;
}
