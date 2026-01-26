# Minimal Profile
# Can be used on any machine - provides base development environment
# Includes: vscode, neovim, golang, nodejs, bun, ghostty, opencode, chezmoi, oh-my-posh, git, jujutsu, gh
{ config, pkgs, lib, ... }:

{
  imports = [
    ../packages
    ../system
  ];

  # Allow unfree packages (required for vscode, etc.)
  nixpkgs.config.allowUnfree = true;

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # User: dragosc (on all machines)
  modules.system.users = {
    enable = true;
    dragosc = true;
  };

  # Desktop: KDE Plasma (on all machines)
  modules.system.desktop = {
    enable = true;
    kde = true;
  };

  # Flatpak: Synergy 3.5
  modules.system.flatpak = {
    enable = true;
    packages = [
      "https://symless.com/synergy/download/package/synergy-personal-v3/flatpak/synergy-3.5.1-linux-noble-x86_64.flatpak"
    ];
  };

  # Browsers: chromium
  modules.packages.browsers = {
    enable = true;
    minimal = true;
    full = false;
  };

  # IDEs: vscode, neovim
  modules.packages.ide = {
    enable = true;
    minimal = true;
    full = false;
  };

  # Languages: golang, nodejs, bun
  modules.packages.languages = {
    enable = true;
    golang = true;
    nodejs = true;
    bun = true;
  };

  # Terminals: ghostty
  modules.packages.terminals = {
    enable = true;
    minimal = true;
    full = false;
  };

  # Code agents: opencode
  modules.packages.code-agents = {
    enable = true;
    opencode = true;
  };

  # Customization: chezmoi, oh-my-posh
  modules.packages.customize = {
    enable = true;
    chezmoi = true;
    oh-my-posh = true;
  };

  # Version control: git, jujutsu, gh
  modules.packages.vcs = {
    enable = true;
    git = true;
    jujutsu = true;
    gh = true;
  };

  # Utilities: flameshot
  modules.packages.utils = {
    enable = true;
    minimal = true;
    full = false;
  };

  # Creative: gimp, krita
  modules.packages.creative = {
    enable = true;
    minimal = true;
    full = false;
  };

  # Basic system packages
  environment.systemPackages = with pkgs; [
    curl
    wget
  ];
}
