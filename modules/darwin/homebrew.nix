# nix-homebrew: declaratively installs & owns the Homebrew installation
# itself (not the packages it manages) so a wiped Mac gets Homebrew back
# via `darwin-rebuild switch` — no manual curl-install-script step needed.
{ ... }:

{
  nix-homebrew = {
    enable = true;
    user = "dragosc";
    autoMigrate = true; # adopt a pre-existing manual Homebrew install without conflict
    enableRosetta = true; # some casks/formulae are still Intel-only on aarch64-darwin
  };

  # Native nix-darwin Homebrew management: declares the *fallback* package
  # list for anything unavailable/unwieldy in nixpkgs (GUI browsers,
  # terminal apps, proprietary casks, etc). Starts empty/minimal — fill in
  # taps/brews/casks here over time as needed.
  homebrew = {
    enable = true;
    taps = [ ];
    # colima: macOS has no Linux kernel, so the Nix-provided docker/podman
    # CLIs (modules/templates/app/virtualization.nix) need a real container
    # runtime backend. colima provides that (lightweight Lima VM + Docker
    # context), same role Docker Desktop/OrbStack would play.
    brews = [ "colima" ];
    casks = import ./casks.nix;
    onActivation.cleanup = "zap";
  };
}
