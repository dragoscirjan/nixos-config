# Virtualization packages (containers, VMs)
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.packages.virtual;
in
{
  options.modules.packages.virtual = {
    enable = mkEnableOption "Virtualization packages";

    extended = mkEnableOption "Extended virtualization (docker)";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      # Basic virtualization (always installed when enabled)
      [
        podman
        podman-compose
        podman-tui
        skopeo
      ]
      ++
      # Extended virtualization
      optionals cfg.extended [
        docker
        docker-buildx
        docker-compose
      ];

    # Enable Podman service
    virtualisation.podman = {
      enable = true;
      # ONLY enable dockerCompat if Docker itself is NOT enabled
      # to avoid systemd socket conflicts.
      dockerCompat = !cfg.extended;
      dockerSocket.enable = !cfg.extended;
      defaultNetwork.settings.dns_enabled = true;
    };

    # Enable Docker service
    virtualisation.docker = mkIf cfg.extended {
      enable = true;
      enableOnBoot = true;
    };

    # Add user to docker group only if Docker is actually enabled
    users.users.dragosc.extraGroups = mkIf cfg.extended [ "docker" ];
  };
}
