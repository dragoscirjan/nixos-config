# Office template — printing, office suites, email
{ pkgs, isHomeManager ? false, ... }:

let
  sharedPackages = with pkgs; [
    libreoffice
    thunderbird
    wpsoffice
  ];
in
if isHomeManager then {
  home.packages = sharedPackages;
} else {
  environment.systemPackages = sharedPackages;

  # ── Printing: CUPS + HP drivers + Avahi wireless discovery ───────────────
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.hplip ];
  services.avahi.enable = true;
  services.avahi.nssmdns4 = true; # allow .local resolution
  services.avahi.openFirewall = true;
}
