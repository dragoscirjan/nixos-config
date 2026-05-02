# Work/Tools template — developer CLI tools, KVM sharing, VCS extras
{ config, pkgs, lib, ... }:

{
  environment.systemPackages = (import ../../linux/packages.nix { inherit pkgs; }) ++ (with pkgs; [
    # KVM sharing
    lan-mouse

    # Snapshots
    grim

    # Window Managers / Headless dev testing (GUI dependent)
    sway
    xorg.xorgserver # Provides Xvfb
    xvfb-run
    kdePackages.kwin # Provides kwin_wayland and kwin_x11
  ]);

  # Synergy KVM software via Flatpak direct download URL
  modules.flatpak.packages = [
    "https://symless.com/synergy/api/download/synergy-3.6.0-linux-noble-x86_64.flatpak?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJwcm9kdWN0UGFja2FnZUlkIjo2NDIsInVzZXJJZCI6Mjc4MzksImlhdCI6MTc3Njc5NjI5Mn0.wajXhDZOuLBPhi9S27LNf1CrIOP5UbaZ2O20X0-Vo8A"
  ];
}
