# Basic Profile
# Can be used on any machine - provides base development environment
{ config, pkgs, lib, ... }:

{
  imports = [
    ../packages
    ../system
  ];

  # Enable nix-ld for running dynamically linked binaries (e.g., npx, mise tools)
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    # Common libraries needed by precompiled binaries
    stdenv.cc.cc.lib
    zlib
    openssl
    curl
    libgcc
    icu
    # For Node.js and other tools
    glib
    nss
    nspr
    atk
    cups
    dbus
    expat
    libdrm
    libxkbcommon
    pango
    cairo
    xorg.libX11
    xorg.libXcomposite
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXrandr
    xorg.libxcb
    mesa
    alsa-lib
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

  # SSH Configuration
  services.openssh.enable = true;
  services.openssh.settings = {
    PermitRootLogin = "prohibit-password";
    PasswordAuthentication = true;
    X11Forwarding = true;
    KbdInteractiveAuthentication = false;
  };

  networking.firewall.allowedTCPPorts = [ 22 ];

  # Desktop: KDE Plasma
  modules.system.desktop = {
    enable = true;
    kde = true;
  };

  # Flatpak
  modules.system.flatpak.enable = true;

  # Packages (basic set - extended options are off by default)
  modules.packages = {
    browsers.enable = true;
    code-agents.enable = true;
    creative.enable = true;
    customize.enable = true;
    ide.enable = true;
    languages.enable = true;
    office.enable = true;
    terminals.enable = true;
    vcs.enable = true;
    virtual.enable = true;
  };

  # VCS: include extended (jujutsu, gh) even in basic profile
  modules.packages.vcs.extended = true;

  # Basic system packages
  environment.systemPackages = with pkgs; [
    curl
    wget
  ];
}
