{ pkgs, isHomeManager ? false, ... }:

let
  sharedPackages = with pkgs; [
    ghostty
    tmux
  ];
in
if isHomeManager then {
  home.packages = sharedPackages;
} else {
  environment.systemPackages = sharedPackages;
}
