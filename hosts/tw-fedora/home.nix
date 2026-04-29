{ config, pkgs, ... }:

{
  home.username = "dragosc";
  home.homeDirectory = "/home/dragosc";

  # ── Packages mapped from tw-nixos ──────────────────────────────────────────
  home.packages = with pkgs; [
    # ---- Base ----
    curl wget bat eza fd fzf ripgrep tree yazi jq yq
    autojump chezmoi mise oh-my-posh
    btop fastfetch flameshot pavucontrol
    firefox chromium alacritty ghostty kitty tmux git

    # ---- Design ----
    blender gimp inkscape krita lunacy

    # ---- AI (Local LLM) ----
    koboldcpp llama-cpp lmstudio ollama (pkgs.lib.lowPrio whisper-cpp)

    # ---- Virtualization ----
    docker docker-buildx docker-compose 
    podman podman-compose podman-tui 
    qemu skopeo virt-manager

    # ---- Media ----
    celluloid mpv vlc

    # ---- Office ----
    libreoffice thunderbird wpsoffice

    # ---- Work / Browsers ----
    brave

    # ---- Work / IDE ----
    codeium helix neovim vscode zed-editor
    antigravity code-cursor kiro
    android-studio jetbrains.clion jetbrains.goland jetbrains.idea
    jetbrains.phpstorm jetbrains.pycharm jetbrains.rust-rover

    # ---- Work / Languages ----
    (pkgs.lib.hiPrio gcc) gnumake clang clang-tools llvmPackages.lld
    go gopls bun deno nodejs_24 lua php

    # ---- Work / Shells ----
    fish nushell powershell zsh

    # ---- Work / Tools ----
    gh glab forgejo-cli jujutsu lazygit
    go-task nixpkgs-fmt statix tree-sitter lan-mouse
  ];

  # Note: Flatpaks (Spotify, Chrome, Zen Browser) must be installed natively on Fedora
  # Note: AMD ROCm / Nvidia CUDA support is not included here as it is better managed by the host OS.

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  home.stateVersion = "24.11"; # Match the state version of the NixOS config
}