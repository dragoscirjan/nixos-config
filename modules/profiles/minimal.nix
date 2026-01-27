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

  networking.useDHCP = lib.mkDefault true;
  networking.wireless.enable = lib.mkDefault true;
  networking.firewall.enable = lib.mkDefault true;

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

  # Containers: podman (minimal)
  virtualisation.podman = {
    enable = true;
    dockerCompat = false;
    dockerSocket.enable = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  # Basic system packages
  environment.systemPackages = with pkgs; [
    curl
    wget
    podman
    podman-compose
    podman-tui
    skopeo
  ];
}
