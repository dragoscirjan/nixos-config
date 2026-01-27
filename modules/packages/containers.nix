# Container runtime packages
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.packages.containers;
in
{
  options.modules.packages.containers = {
    enable = mkEnableOption "Container runtime packages";

    podman = mkOption {
      type = types.bool;
      default = true;
      description = "Install Podman (container runtime)";
    };

    docker = mkOption {
      type = types.bool;
      default = false;
      description = "Install Docker (container runtime)";
    };

    docker-compose = mkOption {
      type = types.bool;
      default = false;
      description = "Install Docker Compose";
    };

    buildkit = mkOption {
      type = types.bool;
      default = false;
      description = "Install Docker BuildKit";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      # Podman (default for minimal)
      optionals cfg.podman [
        podman
        podman-compose
        podman-tui
        skopeo  # Container image operations
      ]
      ++
      # Docker (for full profile)
      optionals cfg.docker [
        docker
        docker-compose
        docker-buildx  # BuildKit
      ];

    # Enable Docker service
    services.docker = mkIf cfg.docker {
      enable = true;
      enableOnBoot = true;
    };

    # Enable Podman service (user sockets)
    virtualisation.podman = mkIf cfg.podman {
      enable = true;
      dockerCompat = cfg.docker;  # Enable docker CLI compatibility
      dockerSocket.enable = true;
      defaultNetwork.dnsname.enable = true;
    };

    # Add user to docker group if Docker is enabled
    users.users.dragosc.extraGroups = mkIf cfg.docker [ "docker" ];
  };
}