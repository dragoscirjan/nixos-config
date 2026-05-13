# Gaming template — Steam + Wine
{ pkgs, isHomeManager ? false, ... }:

let
  sharedPackages = with pkgs; [
    steam
    wine

    openttd
  ];
in
if isHomeManager then {
  home.packages = sharedPackages;
} else {
  environment.systemPackages = sharedPackages;

  hardware.steam-hardware.enable = true;
}
