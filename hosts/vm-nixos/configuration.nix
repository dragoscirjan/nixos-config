# vm-nixos — VM / basic install
{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/templates/app/base.nix
    ../../modules/templates/app/work/dragos.nix
  ];

  # ── Boot: BIOS/Legacy GRUB ────────────────────────────────────────────────
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  # ── Networking ────────────────────────────────────────────────────────────
  networking.hostName = "vm-nixos";
  networking.firewall.allowedTCPPorts = [ 22 ];

  system.stateVersion = "24.11";
}
