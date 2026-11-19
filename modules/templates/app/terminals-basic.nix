{ pkgs, isHomeManager ? false, ... }:

let
  sharedPackages = with pkgs; [
    ghostty
    tmux
    wl-clipboard
  ];
in
if isHomeManager then {
  home.packages = sharedPackages;
} else {
  environment.systemPackages = sharedPackages;
}
