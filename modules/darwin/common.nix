# nix-darwin system module — shared by mac-m1 and mac-m5. Both hosts import
# this file as-is (identical config); only hostName/computerName/primaryUser
# differ, set in each host's own hosts/darwin/<name>/configuration.nix.
{ pkgs, lib, home-manager, ... }:

{
  imports = [
    ./homebrew.nix
    home-manager.darwinModules.home-manager
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  programs.zsh.enable = true;

  # nix-darwin's own release-compatibility version, NOT a macOS version.
  system.stateVersion = 4;

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = { isHomeManager = true; };
  home-manager.users.dragosc = import ./home.nix;
}
