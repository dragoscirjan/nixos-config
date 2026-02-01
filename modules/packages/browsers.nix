# Browser packages
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.packages.browsers;
in
{
  options.modules.packages.browsers = {
    enable = mkEnableOption "Browser packages";

    extended = mkEnableOption "Extended browsers (brave, chrome, zen via flatpak)";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      # Basic browsers (always installed when enabled)
      [
        chromium
        firefox
        thunderbird
      ]
      ++
      # Extended browsers
      optionals cfg.extended [
        brave
      ];

    # Extended browsers via Flatpak
    modules.system.flatpak.packages = mkIf cfg.extended [
      "app.zen_browser.zen"
      "com.google.Chrome"
    ];
  };
}
