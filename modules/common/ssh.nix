# Shared SSH bootstrap — ensures every Nix-managed dev host has a default
# ed25519 keypair, without ever overwriting an existing one.
# Consumed by:
#   - modules/linux/home.nix   (Home Manager activation hook)
#   - modules/darwin/home.nix  (Home Manager activation hook)
#   - modules/nixos/common.nix (systemd --user oneshot service)
{ pkgs }:

pkgs.writeShellScript "ensure-ssh-key" ''
  set -euo pipefail

  SSH_DIR="$HOME/.ssh"
  KEY_FILE="$SSH_DIR/id_ed25519"

  mkdir -p "$SSH_DIR"
  chmod 700 "$SSH_DIR"

  if [ ! -f "$KEY_FILE" ]; then
    echo "No SSH key found at $KEY_FILE — generating a new ed25519 keypair."
    ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -N "" -f "$KEY_FILE" -C "$(whoami)@$(hostname)"
  fi
''
