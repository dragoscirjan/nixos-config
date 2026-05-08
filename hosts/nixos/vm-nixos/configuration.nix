# vm-nixos — VM / basic install
{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/nixos/common.nix
    ../../../modules/templates/app/ide-basic.nix
    ../../../modules/templates/app/languages-basic.nix
    ../../../modules/templates/app/terminals.nix
    ../../../modules/templates/dev/tuikit.nix
    ../../../modules/nixos/remote-control.nix
  ];

  # ── Boot: BIOS/Legacy GRUB ────────────────────────────────────────────────
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  # ── Networking ────────────────────────────────────────────────────────────
  networking.hostName = "vm-nixos";
  networking.firewall.allowedTCPPorts = [ 22 ];

  system.stateVersion = "24.11";
}
