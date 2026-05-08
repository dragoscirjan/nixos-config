{ pkgs, isHomeManager ? false, ... }:

let
  sharedPackages = with pkgs; [
    firefox
    chromium
  ];
in
if isHomeManager then {
  home.packages = sharedPackages;
} else {
  environment.systemPackages = sharedPackages;
}
