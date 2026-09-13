{ config, pkgs, synergyVersion, ... }:

let
  synergyFlatpakUrl = "https://symless.com/synergy/download/package/synergy-personal-v3/flatpak/synergy-${synergyVersion}-linux-noble-x86_64.flatpak";
in
{
  imports = [
    ./remote-control-basic.nix
  ];

  environment.systemPackages = with pkgs; [
    lan-mouse
    teamviewer
  ];

  # Synergy KVM software via Flatpak direct download URL.
  # The version comes from the flake-level synergyVersion binding, so the
  # Flatpak URL and the native installer package always stay in sync.
  #
  # KNOWN BUG (see synergy-issue.txt): the Flatpak build's synergy-security
  # binary only recognizes ID=Ubuntu in /etc/os-release, but inside any
  # Flatpak sandbox /etc/os-release reports the Flatpak runtime ID instead
  # -- so TLS cert generation silently fails regardless of host distro.
  # Workaround: generate a cert manually via openssl and launch
  # synergy-core directly with --enable-crypto --tls-cert <path>.
  modules.flatpak.packages = [ synergyFlatpakUrl ];
}
