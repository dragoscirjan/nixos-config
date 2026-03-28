# Virtualization template — Docker, Podman, libvirt/QEMU
{ config, pkgs, lib, ... }:

{
  # ── Docker ────────────────────────────────────────────────────────────────
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  # ── Podman (no dockerCompat — Docker is present) ───────────────────────────
  virtualisation.podman = {
    enable = true;
    dockerCompat = false;
    dockerSocket.enable = false;
    defaultNetwork.settings.dns_enabled = true;
  };

  # ── libvirt / QEMU ────────────────────────────────────────────────────────
  virtualisation.libvirtd.enable = true;

  # ── User groups ───────────────────────────────────────────────────────────
  users.users.dragosc.extraGroups = [ "docker" "libvirtd" ];

  # ── Packages ──────────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    docker
    docker-buildx
    docker-compose
    podman
    podman-compose
    podman-tui
    qemu
    skopeo
    virt-manager
  ];
}
