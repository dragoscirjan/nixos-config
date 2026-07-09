{ pkgs, lib ? null, isHomeManager ? false, ... }@args:

let
  # NOTE: githubUsername is deliberately NOT a named lambda arg. NixOS's
  # module system satisfies every *named* function arg via
  # `config._module.args.<name>` (falling back to the lambda's own default
  # ONLY if that arg is provided some other way, e.g. `isHomeManager` is
  # explicitly set via flake.nix's `specialArgs`) -- an undeclared name
  # with no matching _module.args entry throws "attribute ... missing"
  # even though it has a `?` default. Reading it off the `...` catch-all
  # via `args.githubUsername or ...` sidesteps that entirely.
  githubUsername = args.githubUsername or "dragoscirjan";

  sharedPackages = with pkgs; [
    # Shell environments & Prompts
    autojump
    chezmoi
    oh-my-posh

    # Alternate Shells
    fish
    nushell
    powershell
    zsh
    shellcheck
  ];

  dotfilesUrl = "https://github.com/${githubUsername}/dotfiles";

  # Idempotent: only clones if the chezmoi source dir doesn't already exist,
  # then always re-applies (safe/no-op if nothing changed).
  #
  # chezmoi shells out to `git` for its .git-managed source dir (init,
  # and any per-file git-managed template hooks). Home Manager activation
  # scripts (and the NixOS systemd service below) run with a minimal,
  # sanitized PATH that does NOT include git even if it's installed
  # elsewhere on the system -- confirmed via a live failure: "chezmoi:
  # .config/nvim: exec: git: executable file not found in $PATH" despite
  # git being on the interactive shell's PATH. Prepend pkgs.git explicitly
  # rather than relying on the ambient PATH.
  chezmoiInitScript = pkgs.writeShellScript "chezmoi-init" ''
    export PATH="${pkgs.git}/bin:$PATH"
    if [ ! -d "$HOME/.local/share/chezmoi/.git" ]; then
      ${pkgs.chezmoi}/bin/chezmoi init ${dotfilesUrl}
    fi
    ${pkgs.chezmoi}/bin/chezmoi apply --no-tty
  '';
in
if isHomeManager then {
  home.packages = sharedPackages;

  # chezmoi: init dotfiles on first Home Manager activation (standalone
  # Linux + Darwin/macOS -- NixOS hosts use the systemd user service below
  # instead, since they don't run Home Manager).
  home.activation.chezmoiInit = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${chezmoiInitScript}
  '';
} else {
  environment.systemPackages = sharedPackages;

  # autojump shell integration
  programs.bash.interactiveShellInit = ''
    source ${pkgs.autojump}/share/autojump/autojump.bash
  '';
  programs.zsh.interactiveShellInit = ''
    source ${pkgs.autojump}/share/autojump/autojump.zsh
  '';
  programs.fish.interactiveShellInit = ''
    source ${pkgs.autojump}/share/autojump/autojump.fish
  '';

  # Clear oh-my-posh cache on rebuild to avoid broken Nix store paths
  system.activationScripts.clearOhMyPoshCache = ''
    rm -rf /home/dragosc/.cache/oh-my-posh
  '';

  # ── chezmoi: init dotfiles on first activation ────────────────────────────
  systemd.user.services."chezmoi-init" = {
    description = "Initialise chezmoi dotfiles";
    wantedBy = [ "default.target" ];
    after = [ "network-online.target" ];

    # Ensure this service ONLY runs for the dragosc user session
    unitConfig = {
      ConditionUser = "dragosc";
    };

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = chezmoiInitScript;
    };
  };
}
