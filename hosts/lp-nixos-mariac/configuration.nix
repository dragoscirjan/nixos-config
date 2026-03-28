# lp-nixos-mariac — Laptop (Nvidia GPU)
# Boot loader TBD — fill in hardware-configuration.nix and boot section after nixos-generate-config
{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/templates/app/base.nix
    ../../modules/templates/app/office.nix
    ../../modules/templates/app/media.nix
    ../../modules/templates/hw/laptop.nix
    ../../modules/templates/hw/gpu-nvidia.nix
  ];

  # ── Boot: TBD (fill after nixos-generate-config on target hardware) ───────
  # boot.loader.systemd-boot.enable      = true;
  # boot.loader.efi.canTouchEfiVariables = true;

  # ── Networking ────────────────────────────────────────────────────────────
  networking.hostName = "lp-nixos-mariac";
  networking.firewall.allowedTCPPorts = [ 22 ];

  system.stateVersion = "24.11";
}
