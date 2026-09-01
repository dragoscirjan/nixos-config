# nix-darwin system module — shared by mac-m1 and mac-m5. Both hosts import
# this file as-is (identical config); only hostName/computerName/primaryUser
# differ, set in each host's own hosts/darwin/<name>/configuration.nix.
{ pkgs, lib, home-manager, mac-app-util, ... }:

{
  # mac-app-util.darwinModules.default is already wired in flake.nix's
  # darwinSystem modules list (alongside nix-homebrew.darwinModules), not
  # re-imported here -- importing it in both places caused a duplicate
  # option declaration error ("services.mac-app-util.enable ... already
  # declared").
  imports = [
    ./homebrew.nix
    home-manager.darwinModules.home-manager
  ];

  # Nix itself is installed/managed by the Determinate Systems installer
  # (setup-darwin.sh uses it), which runs its own daemon and manages
  # /etc/nix/nix.custom.conf. nix-darwin detects this and refuses to also
  # manage the Nix installation ("Determinate detected, aborting
  # activation") unless we explicitly hand that responsibility off.
  # Determinate already ships flakes + nix-command enabled by default, so
  # nix.settings.experimental-features is neither needed nor honored here.
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;

  # home-manager's nix-darwin integration derives home.username/homeDirectory
  # directly from users.users.<name>.{name,home} (normal priority, not
  # mkDefault — see home-manager's nixos/common.nix). nix-darwin's
  # users.users.<name>.home defaults to null, so it MUST be declared here or
  # home-manager's eval fails with "not of type absolute path". Do not also
  # set home.username/home.homeDirectory in modules/darwin/home.nix — that
  # would conflict with this at the same priority.
  users.users.dragosc = {
    name = "dragosc";
    home = "/Users/dragosc";
  };

  programs.zsh.enable = true;

  # nix-darwin's own release-compatibility version, NOT a macOS version.
  system.stateVersion = 4;

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = { isHomeManager = true; };
  # mac-app-util's home-manager module symlinks Nix-installed .app bundles
  # into ~/Applications/Home Manager Apps, so Spotlight/Launchpad/Finder
  # can find them (Nix packages otherwise only land in the store).
  home-manager.sharedModules = [ mac-app-util.homeManagerModules.default ];
  home-manager.users.dragosc = import ./home.nix;
}
