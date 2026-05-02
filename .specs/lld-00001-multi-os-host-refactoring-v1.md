---
id: "00001"
type: lld
title: "Multi-OS Host Refactoring"
version: 1
status: draft
opencode-agent: lead-engineer
---

# Multi-OS Host Refactoring

## 1. Overview
Refactor the current NixOS-centric repository into a modular, multi-OS configuration capable of deploying a headless development environment (CLI tools, configs) across diverse distributions, while preserving GUI and driver configurations strictly for NixOS hosts.

## 2. Architecture & File Structure
The flake will be reorganized to support three target systems conceptually:
1. `nixosConfigurations`: Full OS management (NixOS hosts)
2. `linuxConfigurations` (via `homeConfigurations` in flake outputs): User-level dotfiles and CLI tools (Fedora, Arch, Ubuntu, WSL) via Home Manager.
3. `darwinConfigurations`: macOS management via `nix-darwin` + Home Manager.

**Proposed Directory Structure:**
```
├── flake.nix               # Extended with inputs for home-manager & nix-darwin
├── rebuild.sh              # Refactored to detect OS/host and trigger correct rebuild command
├── setup.sh                # Refactored to accept a host argument and bootstrap the correct env
├── hosts/
│   ├── nixos/              # vm-nixos, tw-nixos, lp-nixos-mariac
│   ├── linux/              # tw-fedora, tw-ubuntu, tw-omarchy, wsl-ubuntu, vm-ubuntu, vm-fedora
│   └── darwin/             # Dragoss-MBP.lan
├── modules/
│   ├── nixos/              # NixOS system-level (GUI, display managers, hw drivers)
│   ├── linux/              # Shared headless dev tools (the new core)
│   └── darwin/             # macOS specific system settings (brew, defaults)
```

## 3. Host Groupings & Constraints

### Group 1: NixOS Development Machines (`tw-nixos`, `vm-nixos`, `lp-nixos-mariac`)
- **Management:** Full system management via NixOS.
- **GUI:** Enabled (Sway, Kwin, Xvfb).
- **Drivers:** Hardware-specific. Only `tw-nixos` & `lp-nixos-mariac` define actual hardware drivers.
- **Tools:** Base tools from `modules/linux/` + NixOS GUI/Drivers.

### Group 2: Non-NixOS Linux Machines (`tw-*`, `vm-*`, `wsl-*`)
- **Hosts:** `tw-fedora`, `tw-ubuntu`, `tw-omarchy`, `vm-ubuntu`, `vm-fedora`, `wsl-ubuntu`.
- **Management:** Home Manager only (Standalone).
- **GUI:** NONE managed by Nix.
- **Drivers:** NONE managed by Nix.
- **Payload:** Strictly CLI apps from `modules/linux/` (e.g. `gh`, `go-task`, `lazygit`), shells.

### Group 3: macOS (`Dragoss-MBP.lan`)
- **Management:** `nix-darwin` + Home Manager.
- **GUI/Drivers:** NONE managed by Nix. Homebrew handled if necessary.
- **Payload:** CLI tools from `modules/linux/` + macOS defaults.

## 4. Tasks

1. **Flake Inputs Update:** Add `home-manager` and `nix-darwin` to `flake.nix`.
2. **Module Refactoring:** Rename `modules/templates/app/work/` to `modules/linux/` and extract GUI/hardware logic into `modules/nixos/`.
3. **Host Declarations:**
   - Migrate current hosts to `hosts/nixos/`.
   - Scaffold Home Manager hosts in `hosts/linux/`.
   - Scaffold Darwin host in `hosts/darwin/Dragoss-MBP.lan/`.
4. **Script Updates:**
   - `rebuild.sh`: Detect OS and hostname to dispatch `nixos-rebuild`, `darwin-rebuild`, or `home-manager switch`.
   - `setup.sh`: Accept an explicit `--host <name>` argument to bypass interactive prompts and run the proper bootstrapping commands based on whether the host is nixos, darwin, or linux.
