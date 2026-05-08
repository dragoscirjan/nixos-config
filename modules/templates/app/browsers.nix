# Work/Browsers template — additional browsers beyond base
{ pkgs, isHomeManager ? false, ... }:

let
  sharedPackages = with pkgs; [
    brave
  ];
in
{
  imports = [ ./browsers-basic.nix ];
} // (if isHomeManager then {
  home.packages = sharedPackages;
} else {
  environment.systemPackages = sharedPackages;

  modules.flatpak.packages = [
    "com.google.Chrome"
    "app.zen_browser.zen"
  ];
})
