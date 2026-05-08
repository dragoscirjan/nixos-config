# Contributing & Architecture Guide

Welcome to the NixOS/Nix configuration repository. This document explains how the repository is structured, how our machines (hosts) are grouped by their feature sets, and the rationale behind the modular template system.

## Hosts Grouped by Features

Our hosts are categorized by the feature sets they provide. Rather than duplicating configurations, each host acts as a router that imports specific feature groups based on its real-world purpose:

### 1. Full Developer Workstations (e.g., `tw-nixos`, `Dragoss-MBP`)
**Purpose:** Primary daily drivers for software engineering, design, AI research, and general productivity.
**Features Included:**
- **Development (`modules/nixos/work/`):** Full UI-based IDEs (JetBrains, VSCode, Cursor), web browsers, and system-wide dev tools.
- **Office (`modules/templates/app/office.nix`):** Slack, LibreOffice, and daily communication tools.
- **Creative (`modules/templates/app/design.nix`, `media.nix`):** UI/UX software, image editing, audio routing, and OBS.
- **Advanced (`modules/templates/app/ai.nix`, `virtualization.nix`):** Local LLMs (Ollama, Open-WebUI), Docker, Podman, and VMs.
- **Hardware:** Specific desktop/GPU tuning (e.g., `modules/templates/hw/gpu-amd.nix`).

### 2. Headless Development Environments (e.g., `tw-ubuntu`, `wsl-ubuntu`, `tw-fedora`)
**Purpose:** Remote servers, WSL instances, or secondary Linux partitions used strictly for terminal-based workflows and compilation.
**Features Included:**
- **Headless Dev (`modules/linux/packages.nix`):** CLI editors (Neovim, Helix), task runners, Git tools, compilers (Rust, Go, Python, Node), and custom shells (Zsh, Fish).
- **Excludes:** Deliberately excludes GUI applications, Office suites, and Media tools to keep the environment lightweight and server-friendly.

### 3. Lightweight / Office Endpoints (e.g., `lp-nixos-mariac`, `vm-nixos`)
**Purpose:** Laptops for standard usage, VMs for testing, or non-heavy-developer machines.
**Features Included:**
- **Base System (`modules/templates/app/base.nix`):** Core networking and CLI utilities.
- **Office & Web:** Often paired with Office templates and basic browsers, skipping the heavy IDEs and virtualization stacks.

---

## The Feature Modules (Templates)

To support the host groupings above, features are organized into modular building blocks:

### 1. Application Templates (`modules/templates/app/`)
These are the core semantic groupings you mix and match to define a host's capabilities:
*   **`base.nix`**: The foundation (core system utilities, basic networking).
*   **`office.nix`**: Productivity (document viewers, communication apps).
*   **`design.nix`**: Creative tools (vector graphics, image editing).
*   **`media.nix`**: Audio, video, and streaming.
*   **`ai.nix`**: Local LLM and AI utilities.
*   **`virtualization.nix`**: Containers (Docker) and VMs (libvirt).

### 2. Developer Profiles
Development environments adapt to the OS:
*   **NixOS (`modules/nixos/work/`)**: Contains full GUI apps (IDEs, browsers) installed via `environment.systemPackages`, plus OS-level patches like `programs.nix-ld.libraries` for binary compatibility.
*   **Standalone Linux (`modules/linux/home.nix`)**: A headless Home Manager setup focusing purely on shell environments and compilers.

### 3. Hardware Templates (`modules/templates/hw/`)
Groups hardware-specific drivers:
*   **`tower.nix`**: Desktop-specific power and network settings.
*   **`gpu-amd.nix`**: AMD graphics drivers, ROCm, and display server settings.

---

## Making Changes

### 1. Adding a New Tool
Ask yourself: *Which feature group does this belong to?*
*   Is it an Office app? Add it to `modules/templates/app/office.nix`.
*   Is it a headless compiler or CLI tool? Add it to `modules/linux/packages.nix` so all headless dev environments get it.
*   Is it a GUI IDE? Currently goes in `modules/nixos/work/ide.nix`.

### 2. Modifying an Existing Host
Edit `hosts/<os>/<hostname>/configuration.nix` (or `home.nix`). Add or remove the `imports = [ ... ]` lines corresponding to the feature templates you want that host to have.

### 3. Applying Changes
Because Nix Flakes track files via Git, **if you create a new file, you must `git add` it before building.**

Apply via the local script:
```bash
./rebuild.sh
```
*(Or use standard `nixos-rebuild switch --flake .#<host>` / `home-manager switch --flake .#<host>` commands).*
