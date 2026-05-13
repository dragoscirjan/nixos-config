# Shared git tools list
{ pkgs }: with pkgs; [
  git
  gh
  glab
  forgejo-cli
  jujutsu
  lazygit

  # Script to install gh extensions imperatively
  (writeShellScriptBin "install-gh-extensions" ''
    #!/usr/bin/env bash
    echo "Installing gh extensions..."
    ${gh}/bin/gh extension install dlvhdr/gh-dash || true
    ${gh}/bin/gh extension install gennaro-tedesco/gh-i || true
    echo "Extensions installed successfully!"
  '')
]
