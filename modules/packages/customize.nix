# Customization and utility packages (dotfiles, shell prompts, utils, etc.)
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.packages.customize;
in
{
  options.modules.packages.customize = {
    enable = mkEnableOption "Customization and utility packages";

    extended = mkEnableOption "Extended tools (zsh, fish, nushell)";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      # Basic tools (always installed when enabled)
      [
        # Development Tools
        go-task
        lazygit
        nixpkgs-fmt
        statix
        tree-sitter

        # File/Directory Utilities
        bat
        fd
        fzf
        jq
        ripgrep
        yazi
        yq

        # Shell/Prompt/Environment Management
        autojump
        chezmoi
        mise
        oh-my-posh

        # System/Info/Monitoring
        btop
        fastfetch
        pulseaudio

        # Screenshot/Media
        flameshot
      ]
      ++
      # Extended tools
      optionals cfg.extended [
        # Other Shells
        fish
        nushell
        zsh

        # SSL
        openssl
      ];

    # Autojump shell integration
    programs.bash.interactiveShellInit = "source ${pkgs.autojump}/share/autojump/autojump.bash";
    programs.zsh.interactiveShellInit = "source ${pkgs.autojump}/share/autojump/autojump.zsh";

    # Extended utilities via Flatpak
    modules.system.flatpak.packages = mkIf cfg.extended [
      # Synergy - KVM software for sharing keyboard/mouse
      "https://symless.com/synergy/download/package/synergy-personal-v3/flatpak/synergy-3.5.1-linux-noble-x86_64.flatpak"
    ];
  };
}
