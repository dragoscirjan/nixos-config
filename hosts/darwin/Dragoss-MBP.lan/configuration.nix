{ pkgs, ... }:

{
  # Import pure developer tools from linux modules (these are cross-platform)
  environment.systemPackages = import ../../../modules/linux/packages.nix { inherit pkgs; };

  # MacOS specific settings
  services.nix-daemon.enable = true;
  nix.settings.experimental-features = "nix-command flakes";

  # Set zsh as default
  programs.zsh.enable = true;

  system.stateVersion = 4;
}
