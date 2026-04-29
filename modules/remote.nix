{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    rustdesk
    teamviewer
  ];

  services.teamviewer.enable = true;
}
