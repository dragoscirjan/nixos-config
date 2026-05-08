{ pkgs, isHomeManager ? false, ... }:

let
  sharedPackages = with pkgs; [
    alacritty
    kitty
    wezterm
  ];
in
{
  imports = [ ./terminals-basic.nix ];
} // (if isHomeManager then {
  home.packages = sharedPackages;
} else {
  environment.systemPackages = sharedPackages;
})
