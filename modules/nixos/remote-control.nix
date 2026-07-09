{ config, pkgs, lib, ... }:

{
  imports = [
    ./remote-control-basic.nix
  ];

  environment.systemPackages = with pkgs; [
    lan-mouse
    teamviewer
  ];

  # Synergy KVM software via Flatpak direct download URL.
  # Version kept in sync with SYNERGY_VERSION in install-synergy.sh (the
  # standalone installer used for non-NixOS Linux + macOS).
  #
  # KNOWN BUG (see synergy-issue.txt): the Flatpak build's synergy-security
  # binary only recognizes ID=Ubuntu in /etc/os-release, but inside any
  # Flatpak sandbox /etc/os-release reports the Flatpak runtime ID instead
  # -- so TLS cert generation silently fails regardless of host distro.
  # Workaround: generate a cert manually via openssl and launch
  # synergy-core directly with --enable-crypto --tls-cert <path>.
  modules.flatpak.packages = [
    "https://symless.com/synergy/api/download/synergy-3.6.3-linux-noble-x86_64.flatpak?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJwcm9kdWN0UGFja2FnZUlkIjo2NDIsInVzZXJJZCI6Mjc4MzksImlhdCI6MTc3Njc5NjI5Mn0.wajXhDZOuLBPhi9S27LNf1CrIOP5UbaZ2O20X0-Vo8A"
  ];
}
