# Media template — video players + Spotify via Flatpak
{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    celluloid
    mpv
    vlc
  ];

  modules.flatpak.packages = [
    "com.spotify.Client"
  ];
}
