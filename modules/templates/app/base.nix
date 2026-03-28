# Base template — imported by every host
# Provides: core nix config, locale, user, KDE Plasma, PipeWire, SSH, flatpak, base packages, fonts, chezmoi init
{ config, pkgs, lib, ... }:

{
  imports = [
    ../../options.nix
    ../../flatpak.nix
  ];

  # ── Nix ──────────────────────────────────────────────────────────────────
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "openssl-1.1.1w"
  ];

  # ── nix-ld (run pre-built binaries: mise tools, npx, etc.) ───────────────
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    zlib
    openssl
    curl
    libgcc
    icu
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

  # ── Locale & keyboard ────────────────────────────────────────────────────
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

  # ── User ─────────────────────────────────────────────────────────────────
  users.groups.dragosc = { };
  users.users.dragosc = {
    isNormalUser = true;
    description = "Dragos Cirjan";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "dragosc" ];
    initialPassword = "changeme";
  };
  security.sudo.wheelNeedsPassword = true;

  # ── Desktop: KDE Plasma 6 + SDDM ─────────────────────────────────────────
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  networking.networkmanager.enable = true;

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];

  # ── Audio: PipeWire ───────────────────────────────────────────────────────
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;

  # ── SSH ───────────────────────────────────────────────────────────────────
  services.openssh.enable = true;
  services.openssh.settings = {
    PermitRootLogin = "prohibit-password";
    PasswordAuthentication = true;
    X11Forwarding = true;
    KbdInteractiveAuthentication = false;
  };

  # ── Flatpak: enable + KDE runtime ─────────────────────────────────────────
  modules.flatpak.enable = true;
  modules.flatpak.packages = [
    "org.kde.Platform/x86_64/6.9"
  ];

  # ── Base packages ─────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # Network
    curl
    wget

    # File/directory utilities
    bat
    eza
    fd
    fzf
    ripgrep
    tree
    yazi
    jq
    yq

    # Shell environment
    autojump
    chezmoi
    mise
    oh-my-posh

    # System monitoring
    btop
    fastfetch

    # Screenshot / audio control
    flameshot
    pavucontrol

    # Browsers
    firefox
    chromium

    # Terminals
    alacritty
    ghostty
    kitty
    tmux

    # VCS
    git
  ];

  # autojump shell integration (bash — other shells handled in work/shells.nix)
  programs.bash.interactiveShellInit = ''
    source ${pkgs.autojump}/share/autojump/autojump.bash
  '';

  # ── Fonts ─────────────────────────────────────────────────────────────────
  fonts.packages = (map (f: pkgs.nerd-fonts.${f}) [
    "fira-code"
    "jetbrains-mono"
    "monofur"
    "roboto-mono"
    "sauce-code-pro"
    "ubuntu"
    "hasklug"
    "inconsolata"
  ]) ++ (with pkgs; [
    noto-fonts
    noto-fonts-color-emoji
  ]);

  # ── chezmoi: init dotfiles on first activation ────────────────────────────
  # Runs once as user dragosc; idempotent (chezmoi init is a no-op if already initialised).
  # Switch to SSH remote later by running: chezmoi cd && git remote set-url origin git@github.com:dragoscirjan/dotfiles
  systemd.user.services."chezmoi-init" = {
    description = "Initialise chezmoi dotfiles";
    wantedBy = [ "default.target" ];
    after = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "chezmoi-init" ''
        if [ ! -d "$HOME/.local/share/chezmoi/.git" ]; then
          ${pkgs.chezmoi}/bin/chezmoi init https://github.com/dragoscirjan/dotfiles
        fi
        ${pkgs.chezmoi}/bin/chezmoi apply --no-tty
      '';
    };
  };
}
