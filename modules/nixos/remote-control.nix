{ config, pkgs, lib, ... }:

{
  imports = [
    ./remote-control-basic.nix
  ];

  environment.systemPackages = with pkgs; [
    lan-mouse
    teamviewer
  ];

  # Synergy KVM software via Flatpak direct download URL
  modules.flatpak.packages = [
    "https://symless.com/synergy/api/download/synergy-3.6.0-linux-noble-x86_64.flatpak?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJwcm9kdWN0UGFja2FnZUlkIjo2NDIsInVzZXJJZCI6Mjc4MzksImlhdCI6MTc3Njc5NjI5Mn0.wajXhDZOuLBPhi9S27LNf1CrIOP5UbaZ2O20X0-Vo8A"
  ];
}
