# Work/Tools template — developer CLI tools, KVM sharing, VCS extras
{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    # VCS / forge CLIs
    gh # GitHub CLI
    glab # GitLab CLI
    forgejo-cli # Forgejo CLI (https://forgejo.org/docs/next/admin/command-line/)
    jujutsu # jj — modern VCS
    lazygit # terminal UI for git

    # Task runner / project tooling
    go-task

    # Nix tooling
    nixpkgs-fmt
    statix

    # Language tooling
    tree-sitter

    # KVM sharing
    lan-mouse

    # SSL / crypto libs
    openssl

    # Terminal
    wezterm
  ];

  # Synergy KVM software via Flatpak (direct URL — not available on Flathub)
  modules.flatpak.packages = [
    "https://symless.com/synergy/download/package/synergy-personal-v3/flatpak/synergy-3.5.1-linux-noble-x86_64.flatpak"
  ];
}
