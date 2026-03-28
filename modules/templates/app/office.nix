# Office template — printing, office suites, email
{ config, pkgs, lib, ... }:

{
  # ── Printing: CUPS + HP drivers + Avahi wireless discovery ───────────────
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.hplip ];
  services.avahi.enable = true;
  services.avahi.nssmdns4 = true; # allow .local resolution
  services.avahi.openFirewall = true;

  # ── Office packages ───────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    libreoffice
    thunderbird
    wpsoffice
  ];
}
