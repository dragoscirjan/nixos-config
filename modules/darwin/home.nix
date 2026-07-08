# Home Manager module for the macOS user (dragosc). Mirrors
# modules/linux/home.nix, but deliberately excludes packages that are
# hard-incompatible with Darwin (see comments below) — GUI browsers/
# terminals are expected to come from Homebrew casks instead
# (modules/darwin/homebrew.nix).
{ config, pkgs, lib, ... }:

{
  # home.username / home.homeDirectory are intentionally NOT set here.
  # home-manager's nix-darwin integration derives them directly from
  # users.users.dragosc.{name,home} (see modules/darwin/common.nix) at
  # normal priority; setting them again here would conflict.
  home.stateVersion = "24.11"; # Ensure this matches your installation version

  programs.zsh.enable = true;
  programs.fish.enable = true;

  home.sessionPath = [ "$HOME/.local/bin" ];

  # NOTE: modules/common/ai-mcps.nix is intentionally NOT imported here —
  # it relies on pkgs.buildFHSEnv (bubblewrap/Linux namespaces), which has
  # no Darwin equivalent and fails to evaluate on aarch64-darwin.
  #
  # browsers-basic.nix / terminals-basic.nix are NOT imported here either:
  # both bundle at least one Linux-only package (chromium, ghostty) that
  # fails to evaluate on aarch64-darwin. GUI browsers/terminals come from
  # Homebrew casks instead (modules/darwin/homebrew.nix).
  #
  # shells.nix IS included: it is isHomeManager-aware and evaluates cleanly
  # on Darwin (its NixOS-only activation/systemd logic is skipped).
  #
  # modules/common/common.nix is a flat Linux+NixOS-oriented package list
  # (e.g. pavucontrol, a PulseAudio-only GUI, is not buildable on Darwin at
  # all). Rather than hand-pick exclusions here (fragile as the shared list
  # grows), filter it down to whatever nixpkgs actually supports on the
  # current hostPlatform — this stays correct automatically as common.nix
  # evolves.
  home.packages =
    (import ../common/git.nix { inherit pkgs; })
    ++ (lib.filter (lib.meta.availableOn pkgs.stdenv.hostPlatform) (import ../common/common.nix { inherit pkgs; }))
    ++ (import ../common/fonts.nix { inherit pkgs; })
    ++ (import ../templates/app/shells.nix { inherit pkgs lib; isHomeManager = true; }).home.packages;

  fonts.fontconfig.enable = true;

  # Shared SSH bootstrap: generate ~/.ssh/id_ed25519 if missing, on every
  # `darwin-rebuild switch` / `home-manager switch`. Never overwrites.
  home.activation.ensureSshKey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${import ../common/ssh.nix { inherit pkgs; }}
  '';

  programs.home-manager.enable = true;
}
