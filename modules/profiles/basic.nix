# Basic Profile
# Can be used on any machine - provides base development environment
# Includes: vscode, neovim, golang, nodejs, bun, ghostty, opencode, chezmoi, oh-my-posh, git
{ config, pkgs, lib, ... }:

{
  imports = [
    ../packages
    ../system
  ];

  # Allow unfree packages (required for vscode, etc.)
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "openssl-1.1.1w"
  ];

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # User: dragosc (on all machines)
  modules.system.users = {
    enable = true;
    dragosc = true;
  };

  # System configuration
  time.timeZone = "Europe/Bucharest";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  console.keyMap = "us";
  services.xserver.xkb.layout = "us";

  # Network configuration with custom DNS
  modules.system.network = {
    enable = true;
    useDHCP = true;
    enableWireless = true;
    firewall = true;
    nameservers = [ "192.168.86.1" "8.8.8.8" ];
  };

  services.openssh.enable = true;
  services.openssh.settings = {
    PermitRootLogin = "prohibit-password";
    PasswordAuthentication = true;
    X11Forwarding = true;
    KbdInteractiveAuthentication = false;
  };

  networking.firewall.allowedTCPPorts = [ 22 ];

  # Desktop: KDE Plasma (on all machines)
  modules.system.desktop = {
    enable = true;
    kde = true;
  };

  # Flatpak: no additional packages in basic profile
  modules.system.flatpak = {
    enable = true;
    packages = [ ];
  };

  # Browsers: chromium
  modules.packages.browsers = {
    enable = true;
    basic = true;
    extended = false;
  };

  # IDEs: vscode, neovim
  modules.packages.ide = {
    enable = true;
    basic = true;
    extended = false;
  };

  # Languages: golang, nodejs, bun
  modules.packages.languages = {
    enable = true;
    basic = true;
    extended = false;
  };

  # Languages: wpsoffice
  modules.packages.office = {
    enable = true;
    basic = true;
    extended = false;
  };

  # Version control: git, jujutsu, gh
  modules.packages.vcs = {
    enable = true;
    basic = true;
    extended = true; # includes jujutsu and gh
  };

  # Terminals: ghostty
  modules.packages.terminals = {
    enable = true;
    basic = true;
    extended = false;
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

  # Utilities: flameshot
  modules.packages.utils = {
    enable = true;
    basic = true;
    extended = false;
  };

  # Creative: gimp, krita
  modules.packages.creative = {
    enable = true;
    basic = true;
    extended = false;
  };

  # Virtualization: podman (basic)
  modules.packages.virtual = {
    enable = true;
    basic = true;
    extended = false;
  };

  # Basic system packages
  environment.systemPackages = with pkgs; [
    curl
    wget
  ];
}
