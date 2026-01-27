# Container runtime packages module
# Container runtime packages module
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
      default = true;
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
      (optionals cfg.podman [
        podman
        podman-compose
        podman-tui
        skopeo
      ]) ++
      (optionals cfg.docker [
        docker
        (mkIf cfg.docker-compose docker-compose)
        (mkIf cfg.buildkit docker-buildx)
      ]);

    # Enable Docker service
    virtualisation.docker = mkIf cfg.docker {
      enable = true;
      enableOnBoot = true;
      # Use BuildKit if specified
      daemon.settings = mkIf cfg.buildkit {
        features = { buildkit = true; };
      };
    };

    # Enable Podman service
    virtualisation.podman = mkIf cfg.podman {
      enable = true;
      # ONLY enable dockerCompat if Docker itself is NOT enabled
      # to avoid systemd socket conflicts.
      dockerCompat = !cfg.docker;
      dockerSocket.enable = !cfg.docker;
      defaultNetwork.dnsname.enable = true;
    };

    # Add user to docker group only if Docker is actually enabled
    users.users.dragosc.extraGroups = mkIf cfg.docker [ "docker" ];
  };
}
