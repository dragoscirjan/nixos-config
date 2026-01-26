#!/usr/bin/env bash
#
# NixOS Configuration Bootstrap Script
# Usage: curl -fsSL https://raw.githubusercontent.com/dragoscirjan/nixos-config/main/setup.sh | bash
#        curl -fsSL ... | bash -s -- --overwrite
#
# Options:
#   --overwrite    Overwrite existing host configuration
#   --help         Show this help message
#
# This script bootstraps a fresh NixOS installation:
# 1. Installs git (if not present) using nix-shell
# 2. Clones the nixos-config repository
# 3. Generates hardware configuration
# 4. Creates host configuration
# 5. Symlinks /etc/nixos
# 6. Runs nixos-rebuild switch
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/dragoscirjan/nixos-config.git"
CONFIG_DIR="$HOME/.config/nixos"
HOSTNAME=$(hostname)
NEW_HOSTNAME=""
OVERWRITE=false
PROFILE=""  # Will be set based on hostname or user choice

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --overwrite)
                OVERWRITE=true
                shift
                ;;
            --help|-h)
                echo "NixOS Configuration Bootstrap Script"
                echo ""
                echo "Usage:"
                echo "  curl -fsSL https://raw.githubusercontent.com/dragoscirjan/nixos-config/main/setup.sh | bash"
                echo "  curl -fsSL ... | bash -s -- --overwrite"
                echo "  ./setup.sh [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --overwrite    Overwrite existing host configuration"
                echo "  --help, -h     Show this help message"
                exit 0
                ;;
            *)
                warn "Unknown option: $1"
                shift
                ;;
        esac
    done
}

# Helper functions
info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
  echo -e "${GREEN}[OK]${NC} $1"
}

warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
  echo -e "${RED}[ERROR]${NC} $1"
  exit 1
}

# Read user input - works even when script is piped
# Reads from /dev/tty to handle curl | bash scenario
prompt_read() {
  local prompt="$1"
  local default="${2:-}"
  local reply

  # Print prompt to stderr so it shows up
  echo -n "$prompt" >&2

  # Read from /dev/tty for interactive input
  read -r reply </dev/tty

  # Return default if empty
  if [ -z "$reply" ] && [ -n "$default" ]; then
    echo "$default"
  else
    echo "$reply"
  fi
}

# Check if running on NixOS
check_nixos() {
  if [ ! -f /etc/NIXOS ]; then
    error "This script is intended for NixOS systems only."
  fi
  success "NixOS detected"
}

# Ask user to select hostname
configure_hostname() {
  local current_hostname="$HOSTNAME"
  local hostname_choice

  echo ""
  echo "Current system hostname: $current_hostname"
  echo ""
  echo "Select hostname for this machine:"
  echo "  1) vm-nixos  - Virtual machine (minimal profile)"
  echo "  2) tw-nixos  - Workstation (full profile)"
  echo "  3) Keep current: $current_hostname"
  echo "  4) Enter custom hostname"
  echo ""
  hostname_choice=$(prompt_read "Enter choice [1-4] (default: 3): " "3")

  case "$hostname_choice" in
  1)
    HOSTNAME="vm-nixos"
    PROFILE="minimal"
    ;;
  2)
    HOSTNAME="tw-nixos"
    PROFILE="full"
    ;;
  3)
    info "Keeping hostname: $current_hostname"
    # Set profile based on known hostnames
    case "$current_hostname" in
      vm-nixos) PROFILE="minimal" ;;
      tw-nixos) PROFILE="full" ;;
    esac
    ;;
  4)
    local custom_hostname
    custom_hostname=$(prompt_read "Enter custom hostname: " "")
    if [ -n "$custom_hostname" ]; then
      if [[ "$custom_hostname" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?$ ]]; then
        HOSTNAME="$custom_hostname"
        # Set profile based on known hostnames
        case "$custom_hostname" in
          vm-nixos) PROFILE="minimal" ;;
          tw-nixos) PROFILE="full" ;;
        esac
      else
        warn "Invalid hostname. Using current: $current_hostname"
        warn "Hostnames must be alphanumeric with optional hyphens."
      fi
    else
      info "No hostname entered. Keeping: $current_hostname"
    fi
    ;;
  *)
    info "Invalid choice. Keeping: $current_hostname"
    ;;
  esac

  # If profile not set yet (unknown hostname), ask user
  if [ -z "$PROFILE" ]; then
    echo ""
    echo "Which profile would you like to use?"
    echo "  1) minimal - Base dev environment (recommended)"
    echo "  2) full    - Extended with extra IDEs"
    echo ""
    local profile_choice
    profile_choice=$(prompt_read "Enter choice [1/2] (default: 1): " "1")
    
    if [ "$profile_choice" = "2" ]; then
      PROFILE="full"
    else
      PROFILE="minimal"
    fi
  fi

  success "Hostname: $HOSTNAME (profile: $PROFILE)"
  echo ""
}

# Install git if not available (using nix-shell for fresh installs)
ensure_git() {
  if command -v git &>/dev/null; then
    success "Git is available"
    return
  fi

  info "Git not found. Installing temporarily via nix-shell..."

  # Use nix-shell to get git temporarily
  # This works on fresh NixOS installs
  export PATH="$(nix-shell -p git --run 'echo $PATH')"

  if command -v git &>/dev/null; then
    success "Git installed temporarily"
  else
    error "Failed to install git. Please install it manually: nix-env -iA nixos.git"
  fi
}

# Clone or update the repository
clone_repository() {
  if [ -d "$CONFIG_DIR" ]; then
    if [ -d "$CONFIG_DIR/.git" ]; then
      info "Repository exists. Pulling latest..."
      nix-shell -p git --run "git -C '$CONFIG_DIR' pull" || warn "Pull failed, using existing version"
    else
      error "$CONFIG_DIR exists but is not a git repository. Remove it first."
    fi
  else
    info "Cloning repository to $CONFIG_DIR..."
    mkdir -p "$(dirname "$CONFIG_DIR")"
    nix-shell -p git --run "git clone '$REPO_URL' '$CONFIG_DIR'"
  fi
  success "Repository ready at $CONFIG_DIR"
}

# Generate hardware configuration
generate_hardware_config() {
  local host_dir="$CONFIG_DIR/hosts/$HOSTNAME"
  local hardware_file="$host_dir/hardware-configuration.nix"

  mkdir -p "$host_dir"

  if [ -f "$hardware_file" ]; then
    info "Hardware config exists, regenerating..."
  fi

  info "Generating hardware configuration..."

  local temp_dir=$(mktemp -d)
  sudo nixos-generate-config --dir "$temp_dir"

  if [ -f "$temp_dir/hardware-configuration.nix" ]; then
    cp "$temp_dir/hardware-configuration.nix" "$hardware_file"
    success "Hardware configuration saved"
  else
    error "Failed to generate hardware configuration"
  fi

  rm -rf "$temp_dir"
}

# Create host configuration
create_host_config() {
  local host_dir="$CONFIG_DIR/hosts/$HOSTNAME"
  local config_file="$host_dir/configuration.nix"

  if [ -f "$config_file" ]; then
    if [ "$OVERWRITE" = true ]; then
      warn "Overwriting existing host configuration"
    else
      success "Host configuration already exists (use --overwrite to replace)"
      return
    fi
  fi

  info "Creating host configuration with $PROFILE profile..."

  cat >"$config_file" <<EOF
# $HOSTNAME NixOS Configuration
{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/$PROFILE.nix
  ];

  # Boot loader - adjust based on your system (UEFI vs BIOS)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  system.stateVersion = "24.11";
  networking.hostName = "$HOSTNAME";
}
EOF

  success "Host configuration created with $PROFILE profile"
}

# Update flake.nix to include new host
update_flake() {
  local flake_file="$CONFIG_DIR/flake.nix"

  if grep -q "\"$HOSTNAME\"" "$flake_file" 2>/dev/null || grep -q "$HOSTNAME = " "$flake_file" 2>/dev/null; then
    success "Host already in flake.nix"
    return
  fi

  info "Adding $HOSTNAME to flake.nix..."

  cp "$flake_file" "$flake_file.bak"

  local new_host_block="
        # $HOSTNAME
        $HOSTNAME = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/$HOSTNAME/configuration.nix
          ];
        };"

  awk -v new_host="$new_host_block" '
    /nixosConfigurations = {/ { in_block=1 }
    in_block && /^[[:space:]]*};[[:space:]]*$/ && !added {
        print new_host
        added=1
    }
    { print }
    ' "$flake_file.bak" >"$flake_file"

  success "Added $HOSTNAME to flake.nix"
}

# Setup symlink
setup_symlink() {
  info "Setting up /etc/nixos symlink..."

  if [ -L /etc/nixos ]; then
    local current=$(readlink -f /etc/nixos)
    if [ "$current" = "$CONFIG_DIR" ]; then
      success "Symlink already configured"
      return
    fi
    sudo rm /etc/nixos
  elif [ -d /etc/nixos ]; then
    local backup="/etc/nixos.backup.$(date +%Y%m%d%H%M%S)"
    warn "Backing up /etc/nixos to $backup"
    sudo mv /etc/nixos "$backup"
  fi

  sudo ln -sf "$CONFIG_DIR" /etc/nixos
  success "Created /etc/nixos -> $CONFIG_DIR"
}

# Stage changes for flake to see them
stage_changes() {
  info "Staging configuration changes for nix flake..."
  
  # Git needs to see the files for flake to work
  # We stage but don't commit - user can decide to commit later
  nix-shell -p git --run "cd '$CONFIG_DIR' && git add -A"
  
  success "Changes staged"
}

# Apply configuration
apply_configuration() {
  info "Applying NixOS configuration..."
  echo ""

  sudo nixos-rebuild switch --flake "$CONFIG_DIR#$HOSTNAME"

  success "Configuration applied!"
}

# Main
main() {
  echo ""
  echo "========================================"
  echo "  NixOS Bootstrap Setup"
  echo "========================================"
  echo "  Config: $CONFIG_DIR"
  echo "========================================"
  echo ""

  check_nixos
  configure_hostname
  ensure_git
  clone_repository
  generate_hardware_config
  create_host_config
  update_flake
  setup_symlink
  stage_changes

  echo ""
  echo "========================================"
  echo "  Ready to apply configuration"
  echo "========================================"
  echo "  Hostname: $HOSTNAME"
  echo "========================================"
  echo ""

  local apply_choice
  apply_choice=$(prompt_read "Apply configuration now? [Y/n] " "y")

  if [[ "$apply_choice" =~ ^[Yy]$ ]]; then
    apply_configuration
  else
    info "Skipped. Run manually:"
    echo "  sudo nixos-rebuild switch --flake $CONFIG_DIR#$HOSTNAME"
  fi

  echo ""
  success "Setup complete!"
  echo ""
  echo "Useful commands:"
  echo "  sudo nixos-rebuild switch --flake $CONFIG_DIR#$HOSTNAME"
  echo "  sudo nixos-rebuild test --flake $CONFIG_DIR#$HOSTNAME"
  echo ""
}

parse_args "$@"
main
