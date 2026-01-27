# nixos-config

Modular NixOS configuration for multiple machines with minimal and full development profiles.

## Quick Install

On a fresh NixOS install, just run:

```bash
curl -fsSL https://raw.githubusercontent.com/dragoscirjan/nixos-config/main/setup.sh | bash
```

To re-run setup and overwrite existing host configuration:

```bash
curl -fsSL https://raw.githubusercontent.com/dragoscirjan/nixos-config/main/setup.sh | bash -s -- --overwrite
```

That's it! The script will:
1. Install git temporarily (via nix-shell) if not present
2. Let you select a hostname (vm-nixos, tw-nixos, or custom)
3. Clone this repo to `~/.config/nixos`
4. Generate hardware configuration for your machine
5. Create host configuration (if new hostname, prompts for profile)
6. Symlink `/etc/nixos` to the config
7. Run `nixos-rebuild switch`

## Setup Script

The `setup.sh` script is self-bootstrapping - it works on a completely fresh NixOS install with no dependencies.

### Options

| Option | Description |
|--------|-------------|
| `--overwrite` | Overwrite existing host configuration |
| `--help`, `-h` | Show help message |

### What it does

1. **Installs git** - Uses `nix-shell -p git` if git isn't available
2. **Hostname selection** - Choose from predefined hosts or enter custom
3. **Clones repository** - Downloads config to `~/.config/nixos`
4. **Generates hardware config** - Runs `nixos-generate-config` for your machine
5. **Creates host config** - Uses existing config or prompts for profile
6. **Updates flake.nix** - Adds your hostname automatically
7. **Symlinks /etc/nixos** - Points to `~/.config/nixos`
8. **Applies configuration** - Runs `nixos-rebuild switch`

### Hostname selection

During setup you'll be asked to select a hostname:
- `1) vm-nixos` - Virtual machine (minimal profile)
- `2) tw-nixos` - Workstation (full profile)
- `3) Keep current` - Use current system hostname
- `4) Custom` - Enter a new hostname

### Profile selection

If creating a new host configuration, you'll be asked:
- `1) minimal` - Base development environment (default)
- `2) full` - Extended environment with extra IDEs

### Running locally

```bash
# First run
./setup.sh

# Re-run with overwrite
./setup.sh --overwrite
```

## Manual Setup

```bash
# Clone the repository
git clone https://github.com/dragoscirjan/nixos-config.git ~/.config/nixos

# Generate hardware config
sudo nixos-generate-config --dir ~/.config/nixos/hosts/$(hostname)

# Create your host configuration (copy from existing host)
cp ~/.config/nixos/hosts/vm-nixos/configuration.nix ~/.config/nixos/hosts/$(hostname)/

# Edit and update hostname and profile as needed
# Then rebuild
sudo nixos-rebuild switch --flake ~/.config/nixos#$(hostname)
```

## Structure

```
nixos-config/
├── setup.sh                    # Quick install script
├── flake.nix                   # Flake entry point
├── hosts/
│   ├── vm-nixos/               # VM machine (minimal)
│   │   ├── configuration.nix   # Host-specific settings
│   │   └── hardware-configuration.nix  # Auto-generated hardware config
│   └── tw-nixos/               # Workstation (full)
│       ├── configuration.nix   # Host-specific settings
│       └── hardware-configuration.nix  # Auto-generated hardware config
└── modules/
    ├── packages/               # Software packages
    │   ├── default.nix         # Package module aggregator
    │   ├── ide.nix             # IDEs and editors
    │   ├── languages.nix       # Programming languages
    │   ├── terminals.nix       # Terminal emulators
    │   ├── code-agents.nix     # AI coding assistants
    │   ├── customize.nix       # Dotfiles & shell customization
    │   ├── vcs.nix             # Version control systems
    │   ├── utils.nix           # System utilities
    │   ├── browsers.nix        # Web browsers
    │   └── creative.nix        # Creative tools
    ├── system/                 # System configuration
    │   ├── default.nix         # System module aggregator
    │   ├── desktop.nix         # Desktop environment (KDE/GNOME)
    │   ├── flatpak.nix         # Flatpak application support
    │   ├── localization.nix    # Timezone, locale, keyboard
    │   ├── network.nix         # Networking and firewall
    │   ├── ssh.nix             # SSH server configuration
    │   └── users.nix           # User accounts and sudo
    └── profiles/
        ├── minimal.nix         # Base development profile
        └── full.nix            # Extended profile
```

## Profiles

### Minimal Profile
Base development environment that works on any machine:
- **IDEs:** vscode, neovim
- **Languages:** golang, nodejs, bun
- **Terminals:** ghostty
- **Code Agents:** opencode
- **Customization:** chezmoi, oh-my-posh
- **VCS:** git, jujutsu, gh

### Full Profile
Extends minimal with additional tools:
- **IDEs:** + intellij-goland, intellij-webstorm, sublime-text
- **Terminals:** + wezterm

## Hosts

| Host | Profile | Description |
|------|---------|-------------|
| `vm-nixos` | minimal | Virtual machine |
| `tw-nixos` | full | Workstation |

## Usage

```bash
# Rebuild current system
sudo nixos-rebuild switch --flake ~/.config/nixos#$(hostname)

# Test configuration without switching
sudo nixos-rebuild test --flake ~/.config/nixos#$(hostname)

# Update flake inputs
nix flake update ~/.config/nixos

# Build specific host
sudo nixos-rebuild switch --flake ~/.config/nixos#vm-nixos
```

## System Configuration

### Network & Hostname

Hostname is configured per host in `configuration.nix`:

```nix
networking.hostName = "my-hostname";
```

Network configuration is managed through the `network` module:

```nix
modules.system.network = {
  enable = true;              # Enable networking
  useDHCP = true;             # Use DHCP for auto IP assignment
  enableWireless = true;      # Enable WiFi support
  firewall = true;            # Enable firewall
  allowedTCPPorts = [ ];      # Open additional TCP ports
  allowedUDPPorts = [ ];      # Open additional UDP ports
};
```

**Default settings (minimal profile):**
- NetworkManager enabled for easy network management
- DHCP enabled for automatic IP configuration
- WiFi support enabled
- Firewall enabled with no open ports

### Localization (Timezone, Locale, Keyboard)

System localization is configured through the `localization` module:

```nix
modules.system.localization = {
  enable = true;
  timezone = "Europe/Bucharest";    # System timezone
  locale = "en_US.UTF-8";           # System locale
  keyboardLayout = "us";            # Keyboard layout
  keyboardVariant = "";             # Keyboard variant (optional)
};
```

**Default settings:**
- **Timezone:** Europe/Bucharest
- **Locale:** en_US.UTF-8
- **Keyboard Layout:** US (QWERTY)
- **Console:** Matches keyboard layout
- **X11:** Configured for desktop environments

To change timezone, use any valid IANA timezone (e.g., "America/New_York", "Asia/Tokyo").

### Users & Security

#### User Accounts

Users are configured through the `users` module:

```nix
modules.system.users = {
  enable = true;
  dragosc = true;              # Create dragosc user
};
```

**Default user (dragosc):**
- **Username:** dragosc
- **Full name:** Dragos Cirjan
- **Groups:** wheel, networkmanager, video, audio
- **Password:** "changeme" (change on first login with `passwd`)
- **Sudo:** Requires password (wheel group)

#### SSH Server

SSH server configuration through the `ssh` module:

```nix
modules.system.ssh = {
  enable = true;                           # Enabled by default
  permitRootLogin = "prohibit-password";    # Root login policy
  passwordAuthentication = true;             # Allow password auth
  openFirewall = true;                      # Open SSH port in firewall
  ports = [ 22 ];                           # SSH ports
};
```

**Security settings:**
- SSH server enabled by default for convenience
- Root login prohibited with password
- X11 forwarding enabled
- Keyboard-interactive authentication disabled
- Firewall automatically configured

To disable SSH for security, set `enable = false` in your host configuration.

### Hardware & Boot

#### Boot Configuration

Boot configuration varies by host type:

**UEFI Systems (recommended):**
```nix
boot.loader.systemd-boot.enable = true;
boot.loader.efi.canTouchEfiVariables = true;
```

**Legacy BIOS Systems:**
```nix
boot.loader.grub.enable = true;
boot.loader.grub.device = "/dev/sda";  # Adjust for your disk
```

#### Hardware Configuration

Hardware configuration is auto-generated by `nixos-generate-config`:

```bash
sudo nixos-generate-config --dir hosts/my-hostname
```

This creates `hardware-configuration.nix` with:
- Filesystem configuration
- Kernel modules
- Boot loader requirements
- Graphics drivers
- Other hardware-specific settings

**Never edit `hardware-configuration.nix` manually** - regenerate when hardware changes.

### Desktop Environment

Desktop environments are configured through the `desktop` module:

```nix
modules.system.desktop = {
  enable = true;
  kde = true;          # Enable KDE Plasma
  gnome = false;       # Disable GNOME
};
```

**Supported desktops:**
- **KDE Plasma 6:** Full-featured desktop environment
- **GNOME:** Modern desktop environment

**Default desktop (minimal profile):** KDE Plasma
- Display Manager: SDDM
- Audio: PipeWire with ALSA and Pulse support
- Networking: NetworkManager integration

## Adding a New Host

1. Create directory: `mkdir -p hosts/my-hostname`
2. Generate hardware config: `sudo nixos-generate-config --dir hosts/my-hostname`
3. Create `configuration.nix`:

```nix
{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/minimal.nix  # or full.nix
  ];

  system.stateVersion = "24.11";
  networking.hostName = "my-hostname";
  
  # Optional: Override default system settings
  modules.system.localization.timezone = "America/New_York";
  modules.system.ssh.enable = true;
}
```

4. Add to `flake.nix` under `nixosConfigurations`
5. Rebuild: `sudo nixos-rebuild switch --flake .#my-hostname`

## Quick Reference

### Common System Tasks

**Change timezone:**
```nix
modules.system.localization.timezone = "America/New_York";
```

**Enable SSH server:**
```nix
modules.system.ssh.enable = true;
```

**Open firewall port:**
```nix
modules.system.network.allowedTCPPorts = [ 8080 ];
```

**Change keyboard layout:**
```nix
modules.system.localization.keyboardLayout = "de";
```

**Add user to additional groups:**
Edit `modules/system/users.nix` and modify the `extraGroups` list.

**Switch to GNOME desktop:**
```nix
modules.system.desktop.kde = false;
modules.system.desktop.gnome = true;
```

### System State Commands

```bash
# Check current system configuration
sudo nixos-rebuild dry-build --flake ~/.config/nixos#$(hostname)

# Rebuild system (apply changes)
sudo nixos-rebuild switch --flake ~/.config/nixos#$(hostname)

# Test configuration (temporary)
sudo nixos-rebuild test --flake ~/.config/nixos#$(hostname)

# Rollback to previous generation
sudo nixos-rebuild switch --rollback

# List system generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
```

### First-Time Setup

After installing with `setup.sh`:

1. **Change user password:**
   ```bash
   passwd
   ```

2. **Optional: Disable SSH for security:**
   Edit your host's `configuration.nix` and set:
   ```nix
   modules.system.ssh.enable = false;
   ```
   Then rebuild:
   ```bash
   sudo nixos-rebuild switch --flake ~/.config/nixos#$(hostname)
   ```

3. **Optional: Set up SSH keys (recommended):**
   ```bash
   ssh-keygen -t ed25519 -C "your-email@example.com"
   ```

## License

See [LICENSE](LICENSE) file.
