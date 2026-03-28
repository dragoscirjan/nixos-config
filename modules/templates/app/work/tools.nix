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

    # Snapshots
    grim
  ];

  # Synergy KVM software via Flatpak direct download URL
  modules.flatpak.packages = [
    "https://symless.com/synergy/api/download/synergy-3.6.0-linux-noble-x86_64.flatpak?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJwcm9kdWN0UGFja2FnZUlkIjo2NDIsInVzZXJJZCI6Mjc4MzksImlhdCI6MTc3Njc5NjI5Mn0.wajXhDZOuLBPhi9S27LNf1CrIOP5UbaZ2O20X0-Vo8A"
  ];
}
