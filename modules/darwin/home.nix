# Home Manager module for the macOS user (dragosc). Ports the tw-nixos
# reference "full workstation" template set to Darwin wherever the
# packages are actually buildable/functional (verified via `nix eval`,
# not assumed) — GUI apps with no Darwin support, or that fail their own
# outPath eval (e.g. steam), are excluded; the real gap is filled by
# Homebrew casks/brews (modules/darwin/homebrew.nix) instead.
{ config, pkgs, lib, ... }:

let
  availableHere = lib.filter (lib.meta.availableOn pkgs.stdenv.hostPlatform);

  ideBasic = import ../templates/app/ide-basic.nix { inherit pkgs config; isHomeManager = true; };
  aiLlmBasic = import ../templates/app/ai-llm-basic.nix { inherit pkgs lib config; isHomeManager = true; };
in
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
  # gaming.nix (steam/wine/openttd) and hw/tower.nix + hw/gpu-amd.nix
  # (AMD-tower-hardware-specific) are excluded entirely: steam passes
  # meta.availableOn but fails a deeper outPath-forcing eval on Darwin,
  # wine/openttd are Linux-only, and the hw/* templates don't apply to
  # Apple Silicon at all.
  #
  # Everything else below reuses `availableHere` (lib.filter over
  # lib.meta.availableOn) rather than hand-picked exclusions — this stays
  # correct automatically as the shared template lists evolve, and was
  # verified via direct `nix eval --impure` (system=aarch64-darwin) to
  # safely drop only genuinely-unsupported packages (chromium, ghostty,
  # android-studio, gimp, krita, lunacy, celluloid, vlc, libreoffice,
  # wpsoffice, notion) without crashing on the packages bundled alongside
  # them (firefox, tmux, etc).
  home.packages =
    (import ../common/git.nix { inherit pkgs; })
    ++ (availableHere (import ../common/common.nix { inherit pkgs; }))
    ++ (import ../common/fonts.nix { inherit pkgs; })
    ++ (import ../templates/app/shells.nix { inherit pkgs lib; isHomeManager = true; }).home.packages
    ++ (import ../templates/app/languages-basic.nix { inherit pkgs; isHomeManager = true; }).home.packages
    ++ (import ../templates/app/languages.nix { inherit pkgs; isHomeManager = true; }).home.packages
    ++ (availableHere (import ../templates/app/browsers-basic.nix { inherit pkgs; isHomeManager = true; }).home.packages)
    ++ (import ../templates/app/browsers.nix { inherit pkgs; isHomeManager = true; }).home.packages
    ++ (availableHere (import ../templates/app/terminals-basic.nix { inherit pkgs; isHomeManager = true; }).home.packages)
    ++ (import ../templates/app/terminals.nix { inherit pkgs; isHomeManager = true; }).home.packages
    ++ ideBasic.home.packages
    ++ (availableHere (import ../templates/app/ide.nix { inherit pkgs; isHomeManager = true; }).home.packages)
    ++ (availableHere (import ../templates/app/design.nix { inherit pkgs; isHomeManager = true; }).home.packages)
    ++ (availableHere (import ../templates/app/media.nix { inherit pkgs; isHomeManager = true; }).home.packages)
    ++ (availableHere (import ../templates/app/office.nix { inherit pkgs; isHomeManager = true; }).home.packages)
    ++ aiLlmBasic.home.packages
    ++ (import ../templates/app/ai-llm.nix { inherit pkgs; isHomeManager = true; }).home.packages
    ++ (import ../templates/app/virtualization.nix { inherit pkgs; isHomeManager = true; }).home.packages;

  # ollama etc. model storage: use the user-writable per-machine path
  # (see modules/templates/app/ai-llm-basic.nix), not the NixOS-service
  # -owned /var/lib path.
  home.sessionVariables = aiLlmBasic.home.sessionVariables;

  fonts.fontconfig.enable = true;

  # Shared SSH bootstrap: generate ~/.ssh/id_ed25519 if missing, on every
  # `darwin-rebuild switch` / `home-manager switch`. Never overwrites.
  home.activation.ensureSshKey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${import ../common/ssh.nix { inherit pkgs; }}
  '';

  # Auto-fetch latest Neovim release (darwin-aware tarball name, see
  # modules/templates/app/ide-basic.nix).
  home.activation.installNeovimLatest = ideBasic.home.activation.installNeovimLatest;

  programs.home-manager.enable = true;
}
