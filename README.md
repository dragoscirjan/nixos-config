# nixos-config

Modular NixOS configuration for multiple machines with basic and extended development profiles.

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
- `1) vm-nixos` - Virtual machine (basic profile)
- `2) tw-nixos` - Workstation (extended profile)
- `3) Keep current` - Use current system hostname
- `4) Custom` - Enter a new hostname

### Profile selection

If creating a new host configuration, you'll be asked:
- `1) basic` - Base development environment (default)
- `2) extended` - Extended environment with extra IDEs

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
│   ├── vm-nixos/               # VM machine (basic)
│   │   ├── configuration.nix   # Host-specific settings
│   │   └── hardware-configuration.nix  # Auto-generated hardware config
│   └── tw-nixos/               # Workstation (extended)
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
        ├── basic.nix         # Base development profile
        └── extended.nix            # Extended profile
```

## Profiles

This repository defines two primary profiles for NixOS configurations: `basic` and `extended`. These profiles allow for flexible system setups, from a basic development environment to a extendedy-featured workstation.

### Basic Profile

The `basic` profile establishes a core development environment suitable for most tasks. It includes essential tools, utilities, and development dependencies.

### Extended Profile

The `extended` profile builds upon the `basic` profile, adding a comprehensive suite of advanced tools, additional IDEs, and specialized software for a extendedy-equipped development or creative workstation.

## Installed Packages

This section provides a detailed list of packages installed with each profile, categorized for clarity.

### Browsers

| Package           | Basic Profile | Extended Profile |
|-------------------|:-------------:|:----------------:|
| `chromium`        |      ✅       |        ✅        |
| `firefox`         |      ✅       |        ✅        |
| `thunderbird`     |      ✅       |        ✅        |
| `google-chrome`   |      ❌       |        ✅        |
| `brave`           |      ❌       |        ✅        |

### Code Agents

| Package           | Basic Profile | Extended Profile |
|-------------------|:-------------:|:----------------:|
| `opencode`        |      ✅       |        ✅        |
| `claude-code`     |      ❌       |        ✅        |
| `gemini-cli`      |      ❌       |        ✅        |
| `codex`           |      ❌       |        ✅        |
| `copilot-cli`     |      ❌       |        ✅        |

### Containers

| Package           | Basic Profile | Extended Profile |
|-------------------|:-------------:|:----------------:|
| `podman`          |      ✅       |        ✅        |
| `podman-compose`  |      ✅       |        ✅        |
| `podman-tui`      |      ✅       |        ✅        |
| `skopeo`          |      ✅       |        ✅        |
| `docker-compose`  |      ✅       |        ✅        |
| `docker`          |      ❌       |        ✅        |
| `docker-buildx`   |      ❌       |        ✅        |

### Creative

| Package           | Basic Profile | Extended Profile |
|-------------------|:-------------:|:----------------:|
| `gimp`            |      ✅       |        ✅        |
| `krita`           |      ✅       |        ✅        |
| `lunacy`          |      ❌       |        ✅        |
| `inkscape`        |      ❌       |        ✅        |

### Customization

| Package           | Basic Profile | Extended Profile |
|-------------------|:-------------:|:----------------:|
| `chezmoi`         |      ✅       |        ✅        |
| `oh-my-posh`      |      ✅       |        ✅        |

### Fonts

| Package                     | Basic Profile | Extended Profile |
|-----------------------------|:-------------:|:----------------:|
| `fira-code` (Nerd Font)     |      ✅       |        ✅        |
| `inconsolata` (Nerd Font)   |      ✅       |        ✅        |
| `jetbrains-mono` (Nerd Font)|      ✅       |        ✅        |
| `monofur` (Nerd Font)       |      ✅       |        ✅        |
| `roboto-mono` (Nerd Font)   |      ✅       |        ✅        |
| `sauce-code-pro` (Nerd Font)|      ✅       |        ✅        |
| `ubuntu` (Nerd Font)        |      ✅       |        ✅        |
| `hasklug` (Nerd Font)       |      ✅       |        ✅        |
| `noto-fonts`                |      ✅       |        ✅        |
| `noto-fonts-color-emoji`    |      ✅       |        ✅        |

### IDEs

| Package                      | Basic Profile | Extended Profile |
|------------------------------|:-------------:|:----------------:|
| `vscode`                     |      ✅       |        ✅        |
| `neovim`                     |      ✅       |        ✅        |
| `codeium`                    |      ✅       |        ✅        |
| `zed-editor`                 |      ✅       |        ✅        |
| `jetbrains.pycharm`          |      ❌       |        ✅        |
| `jetbrains.idea`             |      ❌       |        ✅        |
| `jetbrains.goland`           |      ❌       |        ✅        |
| `jetbrains.clion`            |      ❌       |        ✅        |
| `jetbrains.rust-rover`       |      ❌       |        ✅        |
| `jetbrains.phpstorm`         |      ❌       |        ✅        |
| `jetbrains.webstorm`         |      ❌       |        ✅        |
| `sublime4`                   |      ❌       |        ✅        |
| `helix`                      |      ❌       |        ✅        |
| `code-cursor`                |      ❌       |        ✅        |
| `kiro`                       |      ❌       |        ✅        |
| `antigravity`                |      ❌       |        ✅        |

### Languages

| Package                      | Basic Profile | Extended Profile |
|------------------------------|:-------------:|:----------------:|
| `go`                         |      ✅       |        ✅        |
| `gopls`                      |      ✅       |        ✅        |
| `nodejs_24`                  |      ✅       |        ✅        |
| `bun`                        |      ✅       |        ✅        |
| `rustc`                      |      ✅       |        ✅        |
| `cargo`                      |      ✅       |        ✅        |
| `rust-analyzer`              |      ✅       |        ✅        |
| `python311`                  |      ✅       |        ✅        |
| `uv`                         |      ✅       |        ✅        |
| `lua`                        |      ✅       |        ✅        |
| `gcc`                        |      ✅       |        ✅        |
| `gnumake`                    |      ✅       |        ✅        |
| `deno`                       |      ❌       |        ✅        |
| `clang`                      |      ❌       |        ✅        |
| `clang-tools`                |      ❌       |        ✅        |
| `llvmPackages.lld`           |      ❌       |        ✅        |

### Office

| Package           | Basic Profile | Extended Profile |
|-------------------|:-------------:|:----------------:|
| `wps-office`      |      ✅       |        ✅        |
| `libreoffice`     |      ❌       |        ✅        |

### Terminals

| Package           | Basic Profile | Extended Profile |
|-------------------|:-------------:|:----------------:|
| `ghostty`         |      ✅       |        ✅        |
| `alacritty`       |      ✅       |        ✅        |
| `wezterm`         |      ❌       |        ✅        |

### Utilities

| Package           | Basic Profile | Extended Profile |
|-------------------|:-------------:|:----------------:|
| `flameshot`       |      ✅       |        ✅        |
| `btop`            |      ✅       |        ✅        |
| `fastfetch`       |      ✅       |        ✅        |
| `fzf`             |      ✅       |        ✅        |
| `go-task`         |      ✅       |        ✅        |
| `mise`            |      ✅       |        ✅        |
| `bat`             |      ✅       |        ✅        |
| `autojump`        |      ✅       |        ✅        |
| `zsh`             |      ❌       |        ✅        |
| `fish`            |      ❌       |        ✅        |
| `nushell`         |      ❌       |        ✅        |

### VCS

| Package           | Basic Profile | Extended Profile |
|-------------------|:-------------:|:----------------:|
| `git`             |      ✅       |        ✅        |
| `jujutsu`         |      ✅       |        ✅        |
| `gh`              |      ✅       |        ✅        |

## Hosts

| Host | Profile | Description |
|------|---------|-------------|
| `vm-nixos` | basic | Virtual machine |
| `tw-nixos` | extended | Workstation |

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

**Default settings (basic profile):**
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

**Default desktop (basic profile):** KDE Plasma
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
    ../../modules/profiles/basic.nix  # or extended.nix
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
