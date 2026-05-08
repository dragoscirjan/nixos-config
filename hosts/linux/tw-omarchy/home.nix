{ config, pkgs, ... }:

{
  imports = [
    ../../../modules/linux/home.nix
    ../../../modules/templates/app/ide.nix
    ../../../modules/templates/app/browsers.nix
    ../../../modules/templates/app/languages.nix
    ../../../modules/templates/app/terminals.nix
    ../../../modules/templates/app/design.nix
    ../../../modules/templates/app/media.nix
    ../../../modules/templates/app/office.nix
    ../../../modules/templates/app/virtualization.nix
    ../../../modules/templates/app/ai-llm.nix
  ];

  home.username = "dragosc";
  home.homeDirectory = "/home/dragosc";

  home.stateVersion = "24.11"; # Ensure this matches your installation version
}
