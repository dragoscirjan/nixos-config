# Work/Browsers template — additional browsers beyond base
{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    brave
  ];

  modules.flatpak.packages = [
    "com.google.Chrome"
    "app.zen_browser.zen"
  ];
}
