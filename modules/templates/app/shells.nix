{ pkgs, isHomeManager ? false, ... }:

let
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
  ];
in
if isHomeManager then {
  home.packages = sharedPackages;
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
      ExecStart = pkgs.writeShellScript "chezmoi-init" ''
        if [ ! -d "$HOME/.local/share/chezmoi/.git" ]; then
          ${pkgs.chezmoi}/bin/chezmoi init https://github.com/dragoscirjan/dotfiles
        fi
        ${pkgs.chezmoi}/bin/chezmoi apply --no-tty
      '';
    };
  };
}
