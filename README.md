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
│   │   └── configuration.nix
│   └── tw-nixos/               # Workstation (full)
│       └── configuration.nix
└── modules/
    ├── packages/
    │   ├── default.nix         # Package module aggregator
    │   ├── ide.nix             # IDEs and editors
    │   ├── languages.nix       # Programming languages
    │   ├── terminals.nix       # Terminal emulators
    │   ├── code-agents.nix     # AI coding assistants
    │   ├── customize.nix       # Dotfiles & shell customization
    │   └── vcs.nix             # Version control systems
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
}
```

4. Add to `flake.nix` under `nixosConfigurations`
5. Rebuild: `sudo nixos-rebuild switch --flake .#my-hostname`

## License

See [LICENSE](LICENSE) file.
