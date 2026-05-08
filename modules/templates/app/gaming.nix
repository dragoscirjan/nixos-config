# Gaming template — Steam + Wine
{ pkgs, isHomeManager ? false, ... }:

let
  sharedPackages = with pkgs; [
    steam
    wine
  ];
in
if isHomeManager then {
  home.packages = sharedPackages;
} else {
  environment.systemPackages = sharedPackages;

  hardware.steam-hardware.enable = true;
}
