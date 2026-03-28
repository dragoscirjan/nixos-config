# Work/Shells template — additional shells + autojump integrations
# oh-my-posh hooks are intentionally omitted — managed via chezmoi dotfiles
{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    fish
    nushell
    powershell
    zsh
  ];

  # autojump integrations for shells not covered in base.nix
  programs.zsh.interactiveShellInit = ''
    source ${pkgs.autojump}/share/autojump/autojump.zsh
  '';

  programs.fish.interactiveShellInit = ''
    source ${pkgs.autojump}/share/autojump/autojump.fish
  '';
}
