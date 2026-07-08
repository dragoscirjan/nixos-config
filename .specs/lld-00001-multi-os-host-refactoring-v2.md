---
id: "00001"
type: lld
title: "Multi-OS Host Refactoring"
version: 2
status: draft
opencode-agent: lead-engineer
---

# Multi-OS Host Refactoring

## 1. Overview
Refactor the current NixOS-centric repository into a modular, multi-OS configuration capable of deploying a headless development environment (CLI tools, configs) across diverse distributions, while preserving GUI and driver configurations strictly for NixOS hosts.

**v2 scope:** v1 scaffolded `darwinConfigurations` but left it non-functional (broken import, no Home Manager wiring, no Homebrew, no bootstrap script). v2 completes the macOS ("Group 3") layer so `mac-m1`/`mac-m5` are real, reinstallable workstation hosts, adds a shared SSH-key bootstrap for all three OS groups, and splits every setup/rebuild/cleanup script into fully OS-specific variants (no shared dispatcher scripts).

## 2. Architecture & File Structure
The flake supports three target systems conceptually:
1. `nixosConfigurations`: Full OS management (NixOS hosts)
2. `homeConfigurations`: User-level dotfiles and CLI tools (Fedora, Arch, Ubuntu, WSL) via Home Manager.
3. `darwinConfigurations`: macOS management via `nix-darwin` + Home Manager (as a nix-darwin module).

**Directory Structure:**
```
├── flake.nix
├── setup-nixos.sh          # NixOS-only bootstrap (trimmed — was multi-OS, now nixos-rebuild path only)
├── setup-linux.sh          # standalone-Linux-only bootstrap (extended: installs Nix + clones flake + home-manager switch)
├── setup-darwin.sh         # NEW — macOS-only bootstrap (hostname + nix + nix-darwin)
├── rebuild-nixos.sh        # NixOS-only rebuild (trimmed — was OS-dispatcher, now nixos-rebuild path only)
├── rebuild-linux.sh        # standalone-Linux-only rebuild (already correctly scoped, unchanged)
├── rebuild-darwin.sh       # NEW — macOS-only rebuild (mirrors rebuild-linux.sh's pattern; switch/build, not switch/test)
├── cleanup-nixos.sh        # renamed from cleanup.sh — NixOS-only generation/GC cleanup
├── cleanup-linux.sh        # NEW — standalone-Linux-only cleanup (home-manager generations + nix-collect-garbage, no sudo)
├── cleanup-darwin.sh       # NEW — macOS-only cleanup (Nix GC via /nix/var/nix/profiles/system + `brew cleanup`/`brew autoremove`)
├── hosts/
│   ├── nixos/              # vm-nixos, tw-nixos, lp-nixos-mariac
│   ├── linux/              # tw-fedora, tw-ubuntu, tw-omarchy, wsl-ubuntu, vm-ubuntu, vm-fedora
│   └── darwin/
│       ├── mac-m1/configuration.nix   # replaces Dragoss-MBP.lan (renamed)
│       └── mac-m5/configuration.nix   # NEW — second Mac
├── modules/
│   ├── nixos/              # NixOS system-level (GUI, display managers, hw drivers)
│   ├── linux/              # Shared headless dev tools (home.nix, home-manager entrypoint)
│   ├── common/             # OS-agnostic package lists (git.nix, common.nix, ai-mcps.nix, fonts.nix, ssh.nix)
│   └── darwin/             # NEW — macOS specific
│       ├── common.nix      # nix-darwin system module: nix settings, zsh, primaryUser, HM wiring
│       ├── homebrew.nix    # nix-homebrew + native `homebrew` (taps/brews/casks) declaration
│       └── home.nix        # Home Manager module for the mac user (packages via isHomeManager templates)
```

**Naming problem identified by user:** both physical Macs currently report the same macOS hostname out of the box, so a single `darwinConfigurations` entry keyed by real hostname doesn't scale. Resolution: two explicit, arbitrarily-named flake hosts — `mac-m1` and `mac-m5` — matching new `hosts/darwin/{mac-m1,mac-m5}/` directories. `setup-darwin.sh` takes `--host` as a *required* argument (validated against the existing `hosts/darwin/*` directories, no auto-detection from the machine's current possibly-wrong/duplicate hostname) and uses `scutil` to *rename* the physical Mac to match the chosen flake host before running `darwin-rebuild`/`nix run nix-darwin`.

## 3. Host Groupings & Constraints

### Group 1: NixOS Development Machines (`tw-nixos`, `vm-nixos`, `lp-nixos-mariac`)
Full system management via NixOS. GUI enabled. Hardware drivers where applicable. Base tools from `modules/linux/`/`modules/common/` + NixOS GUI/Drivers. Bootstrap/rebuild/cleanup exclusively via `setup-nixos.sh`/`rebuild-nixos.sh`/`cleanup-nixos.sh` (NixOS-only, no cross-OS branching).

### Group 2: Non-NixOS Linux Machines (`tw-*`, `vm-*`, `wsl-*`)
Home Manager only (Standalone). No GUI/drivers managed by Nix. CLI apps from `modules/linux/`/`modules/common/`. Bootstrap/rebuild/cleanup exclusively via `setup-linux.sh`/`rebuild-linux.sh`/`cleanup-linux.sh` (standalone-Linux-only).

### Group 3: macOS (`mac-m1`, `mac-m5`) — v2 detail
- **Management:** `nix-darwin` (system) + Home Manager (user), composed via `home-manager.darwinModules.home-manager` imported *inside* the nix-darwin config (not a separate flake output).
- **Hosts:** two physical machines, `mac-m1` and `mac-m5`, both sharing `modules/darwin/{common,homebrew,home}.nix` and differing only by `networking.hostName`/`networking.computerName` (set per-host in each `hosts/darwin/<name>/configuration.nix`). Old single-host `Dragoss-MBP.lan` scaffold is renamed/retired in favor of these two.
- **Chip:** always `aarch64-darwin`.
- **Packages:** everything installable via nix goes through Home Manager, reusing the same `isHomeManager`-branching templates already used by Linux/NixOS hosts (`modules/common/*.nix`, `modules/templates/app/*.nix`). Git itself stays a Homebrew/system-provided binary bootstrap dependency (needed to `git clone` the flake before Nix can take over) — everything else prefers Nix.
- **Scope for v2 (start small, confirmed with user):** only OS-agnostic CLI payload — `modules/common/git.nix`, `common.nix`, `ai-mcps.nix`, `fonts.nix` — plus `browsers-basic.nix`, `terminals-basic.nix`, `shells.nix` (already isHomeManager-aware, same set `modules/nixos/common.nix` pulls in). Heavier templates (`ide.nix`, `office.nix`, `design.nix`, `ai-llm.nix`, `virtualization.nix`, `media.nix`, `gaming.nix`) are explicitly deferred to a future increment — they are NOT wired in v2, just noted as the upgrade path.
- **Homebrew:** kept as primary/parallel tool, not replaced. `nix-homebrew` (new flake input) declaratively manages the Homebrew *installation* itself (so a wiped Mac gets Homebrew back via `darwin-rebuild switch` with no manual `/bin/bash -c "$(curl brew install script)"` step). Native nix-darwin `homebrew` options (`taps`/`brews`/`casks`) declare the fallback package list for anything unavailable/unwieldy in nixpkgs (starts with an empty/minimal list — user fills in casks over time).
- **System defaults:** explicitly OUT of scope per user — no `system.defaults.*` (Dock/Finder/trackpad) management in v2.
- **Bootstrap/rebuild/cleanup:** three fully self-contained macOS-only scripts, no cross-OS branching — `setup-darwin.sh` requires `--host <mac-m1|mac-m5>`, validates it against the `hosts/darwin/*` directories, sets the hostname via `scutil` (`ComputerName`, `HostName`, `LocalHostName`) to match, installs Nix if missing (Determinate installer), clones the flake repo if missing, then runs `nix run nix-darwin -- switch --flake .#<host>` (first run) or `darwin-rebuild switch --flake .#<host>` (if already installed). `rebuild-darwin.sh` handles subsequent flake-update + switch/build cycles. `cleanup-darwin.sh` handles Nix GC + Homebrew cleanup.
- **Homebrew install-if-missing (verified, not assumed):** per `nix-homebrew` upstream docs, `nix-homebrew.enable = true` (already wired in `modules/darwin/homebrew.nix`) declaratively installs Homebrew itself as part of the `darwin-rebuild switch` activation — no separate imperative install step is needed or correct (running the official Homebrew curl-install script first would conflict with `nix-homebrew`'s ownership model unless `autoMigrate = true`, which we already set). `setup-darwin.sh` adds a post-switch defensive check only: `command -v brew` after the switch completes, printing a clear warning (not a failure) if `brew` still isn't on `PATH` — surfaces a broken/partial activation rather than silently continuing.

### Cross-cutting: Default SSH key bootstrap (all Nix-managed dev hosts — NixOS, standalone Linux, macOS)
User request: auto-generate `~/.ssh/id_ed25519` if missing, on **every** developer-tooling host (Group 1 NixOS, Group 2 standalone Linux, Group 3 macOS) — one shared implementation, two wiring mechanisms since Group 1 hosts do not run Home Manager today:

- **Shared script:** `modules/common/ssh.nix` — exposes a `pkgs.writeShellScript "ensure-ssh-key"` that, idempotently: creates `~/.ssh` (0700) if missing, and if `~/.ssh/id_ed25519` does not exist, runs `ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519 -C "<user>@<host>"`. Never overwrites an existing key.
- **Group 2 (standalone Linux, Home Manager) + Group 3 (macOS, Home Manager):** wired via `home.activation.ensureSshKey = lib.hm.dag.entryAfter [ "writeBoundary" ] "run ${ensureSshKeyScript}"` in `modules/linux/home.nix` and `modules/darwin/home.nix` respectively — runs on every `home-manager switch`/`darwin-rebuild switch`.
- **Group 1 (NixOS, no Home Manager currently):** wired via a `systemd.user.services.ensure-ssh-key` (oneshot, `wantedBy = [ "default.target" ]`, `ConditionPathExists = "!%h/.ssh/id_ed25519"`) added to `modules/nixos/common.nix` — runs once per user session on login, self-skips once the key exists.

## 4. Tasks (v1 — done)
1. Flake Inputs Update: `home-manager` + `nix-darwin` added.
2. Module Refactoring: `modules/linux/` (headless tools) + `modules/nixos/` (GUI/hw) split done.
3. Host Declarations: `hosts/nixos/`, `hosts/linux/`, `hosts/darwin/` scaffolded.
4. Script Updates: `rebuild-nixos.sh` OS-detection dispatch done; `setup-nixos.sh` has a darwin branch.

**v2 design correction:** the v1 single-dispatcher-per-action model (one `setup-nixos.sh`/`rebuild-nixos.sh` branching on `uname -s` to cover all three OS families, plus a generic `cleanup.sh`) is explicitly REJECTED by the user in v2. Every deployment type gets its own fully self-contained script per action — no cross-OS branching logic inside any single script. This means `setup-nixos.sh` and `rebuild-nixos.sh` must be TRIMMED (Linux-non-NixOS and Darwin branches removed), `setup-linux.sh` must be EXTENDED to full parity (repo clone + home-manager switch, not just Nix install), `cleanup.sh` is RENAMED to `cleanup-nixos.sh`, and net-new `cleanup-linux.sh`, `setup-darwin.sh`, `rebuild-darwin.sh`, `cleanup-darwin.sh` are created.

## 5. Tasks (v2 — macOS completion + SSH bootstrap + 3-way script split, this version)

1. **Flake input:** add `nix-homebrew` (`zhaofengli/nix-homebrew`) to `flake.nix`.
2. **Retire single-host scaffold:** delete `hosts/darwin/Dragoss-MBP.lan/`, create `hosts/darwin/mac-m1/configuration.nix` and `hosts/darwin/mac-m5/configuration.nix` — both thin (import `../../../modules/darwin/common.nix`, set only `networking.hostName`/`networking.computerName` + `system.primaryUser = "dragosc"` per host).
3. **Flake outputs:** replace the single `darwinConfigurations."Dragoss-MBP"` entry with `mac-m1` and `mac-m5`, each `nix-darwin.lib.darwinSystem { system = "aarch64-darwin"; modules = [ ./hosts/darwin/<name>/configuration.nix ]; }`.
4. **`modules/darwin/common.nix`:** nix-darwin system module —
   - `nix.settings.experimental-features = [ "nix-command" "flakes" ];`
   - `nixpkgs.config.allowUnfree = true;`
   - `programs.zsh.enable = true;`
   - `system.stateVersion` (nix-darwin numbering, currently 4 — verified against installed nix-darwin release).
   - imports `./homebrew.nix`
   - wires `home-manager.darwinModules.home-manager` with `useGlobalPkgs = true; useUserPackages = true; extraSpecialArgs = { isHomeManager = true; }; users.dragosc = import ./home.nix;`
5. **`modules/darwin/homebrew.nix`:**
   - `nix-homebrew.enable = true` config (owner user `dragosc`, `autoMigrate = true`).
   - native `homebrew = { enable = true; taps = [...]; brews = [...]; casks = [...]; onActivation.cleanup = "zap"; };` — start with an empty/minimal placeholder list (documented as the fallback slot).
6. **`modules/darwin/home.nix`:** Home Manager module for `dragosc`, mirrors `modules/linux/home.nix` structure —
   - `home.stateVersion` set appropriately.
   - `home.packages` = `modules/common/git.nix` + `common.nix` + `ai-mcps.nix` + `fonts.nix` (same as Linux payload — start small, per Group 3 scope above).
   - imports `modules/templates/app/browsers-basic.nix`, `terminals-basic.nix`, `shells.nix` (already `isHomeManager` aware).
   - `home.activation.ensureSshKey` hook (see Cross-cutting section above).
   - `programs.home-manager.enable = true;`
7. **`modules/common/ssh.nix`** (new, shared): the `ensure-ssh-key` script described in the Cross-cutting section.
8. **`modules/linux/home.nix`:** add the same `home.activation.ensureSshKey` hook, reusing `modules/common/ssh.nix`.
9. **`modules/nixos/common.nix`:** add `systemd.user.services.ensure-ssh-key` (oneshot, login-triggered, self-skipping), reusing `modules/common/ssh.nix`.
10. **Trim `setup-nixos.sh`:** remove the Linux-non-NixOS and Darwin `elif` branches entirely; keep only `--host`/`--overwrite` flags, repo-clone, `/etc/nixos` symlink, `sudo nixos-rebuild switch --flake .#$HOST`.
11. **Trim `rebuild-nixos.sh`:** remove `uname -s` OS-detection dispatch and the home-manager/darwin-rebuild branches; keep only the `nixos-rebuild` path (also fixes the latent `test`-action-on-darwin-rebuild bug by simply deleting that branch).
12. **Extend `setup-linux.sh`:** after installing Nix (existing logic, unchanged), add repo clone into `$HOME/.config/nixos` (same convention as `setup-nixos.sh`) + `home-manager` init/switch against `.#$USER@$HOST` — bringing it to full end-to-end bootstrap parity.
13. **Rename `cleanup.sh` → `cleanup-nixos.sh`:** no logic change (already NixOS-appropriate: `nix-env --delete-generations` + `nix-collect-garbage -d` against `/nix/var/nix/profiles/system`).
14. **Create `cleanup-linux.sh`** (new): Home Manager generation cleanup (`home-manager expire-generations` or `nix-env --delete-generations` against the user profile, no `sudo`) + `nix-collect-garbage -d`.
15. **Create `setup-darwin.sh`** (new, executable): requires `--host <name>`, validates against `hosts/darwin/*` directory names (`mac-m1`/`mac-m5`), sets hostname via `scutil --set ComputerName/HostName/LocalHostName`, installs Nix via Determinate installer if missing, clones the flake repo if missing (same convention as `setup-nixos.sh`), then bootstraps via `nix run nix-darwin -- switch --flake .#$HOST` (first run) or `darwin-rebuild switch --flake .#$HOST` if nix-darwin is already on PATH. Homebrew itself is installed declaratively by `nix-homebrew` during this switch (no separate imperative brew-install step) — script does a post-switch `command -v brew` check and prints a warning if it's still missing.
16. **Create `rebuild-darwin.sh`** (new): mirrors `rebuild-linux.sh`'s pattern (flake update + rebuild), but calls `darwin-rebuild switch/build --flake .#$HOST` (valid darwin-rebuild actions only — switch/build, deliberately not the buggy "test" action `rebuild-nixos.sh` had for its darwin branch).
17. **Create `cleanup-darwin.sh`** (new): same Nix GC logic as `cleanup-nixos.sh` (`/nix/var/nix/profiles/system` is nix-darwin's default system profile path too, verified via nix-darwin manual) PLUS `brew cleanup` + `brew autoremove`.
18. **Validation:** `nix flake check` (eval-only on this Linux dev machine, since darwin systems can't be built cross-platform without emulation); syntax-check the NixOS systemd unit addition and the trimmed `setup-nixos.sh`/`rebuild-nixos.sh` don't break existing NixOS host rebuilds; shellcheck all new/modified `.sh` files.

## 6. Explicit Non-Goals (v2)
- No `system.defaults.*` (Dock/Finder/keyboard/trackpad) — user declined.
- No GUI/office/design/ai-llm/virtualization/media/gaming templates wired into the mac home yet — deferred, upgrade path only.
- No changes to `list.sh` (NixOS-only `nixos-rebuild list-generations`, already correctly scoped) or `CONTRIBUTING.md`'s stale `./rebuild.sh` reference — out of scope, tracked separately if needed.
- SSH key bootstrap only ever creates `id_ed25519` — does not manage `known_hosts`, agent config, or upload the pubkey anywhere (e.g. GitHub) automatically.
- No single shared/generic script for any action — deliberately rejected by user; each of the 9 scripts (`{setup,rebuild,cleanup}-{nixos,linux,darwin}.sh`) is fully self-contained.

## 7. Task Breakdown (execution order, tracked as issues)
1. Add `nix-homebrew` flake input to `flake.nix`.
2. Create `modules/common/ssh.nix`.
3. Create `modules/darwin/common.nix`, `modules/darwin/homebrew.nix`, `modules/darwin/home.nix` (wired with the ssh activation hook).
4. Delete `hosts/darwin/Dragoss-MBP.lan/`; create `hosts/darwin/mac-m1/configuration.nix` and `hosts/darwin/mac-m5/configuration.nix`.
5. Update `flake.nix` `darwinConfigurations` to `mac-m1` + `mac-m5`.
6. Add SSH activation hook to `modules/linux/home.nix` (Group 2) and `systemd.user.services.ensure-ssh-key` to `modules/nixos/common.nix` (Group 1).
7. Trim `setup-nixos.sh` and `rebuild-nixos.sh` to NixOS-only (remove Linux/Darwin branches).
8. Extend `setup-linux.sh` to full bootstrap parity (repo clone + home-manager switch).
9. Rename `cleanup.sh` → `cleanup-nixos.sh`; create `cleanup-linux.sh`.
10. Create `setup-darwin.sh`, `rebuild-darwin.sh`, `cleanup-darwin.sh` (mode 755 each).
11. Validate: `nix flake check` / eval-only smoke test across all three groups; shellcheck all 9 OS-specific scripts.

## 8. Implementation Notes (v2, as-built — macOS-only pass)

Per explicit user direction ('Focus for now on the two mac configurations... start implementing and consider the task finished ONLY when the entire mac flow is fully analyz[ed] and works (in theory)'), this implementation pass covers **only** Task Breakdown items 1–5 and 10–11 above (the macOS/nix-homebrew/darwin-scripts work), plus the `modules/common/ssh.nix` shared script itself and its wiring into `modules/darwin/home.nix`. Item 6's other half — wiring the SSH activation hook into `modules/linux/home.nix` (Group 2) and the `systemd.user.services.ensure-ssh-key` unit into `modules/nixos/common.nix` (Group 1) — is **explicitly deferred**, same as items 7–9 (trimming `setup-nixos.sh`/`rebuild-nixos.sh`, extending `setup-linux.sh`, renaming `cleanup.sh`→`cleanup-nixos.sh`, creating `cleanup-linux.sh`). None of these are silently dropped — all tracked as an explicit follow-up pass, scoped strictly to "the two mac configurations" per the user's instruction.

### 8.1 Host roles (mac-m1 / mac-m5)
Per user clarification, `mac-m1` (portable "do-it-all" laptop) and `mac-m5` (leans toward LLM-server usage) are **identical** in `modules/darwin/*.nix` payload for v2 — role is documented only as a comment in each `hosts/darwin/<name>/configuration.nix`, not divergent configuration. Divergence can be introduced later once actual usage patterns differ.

### 8.2 Darwin package payload — deviation from original LLD text (hard platform incompatibilities)
Direct `nix eval --impure` testing against `system = "aarch64-darwin"` revealed that several templates originally assumed reusable-as-is are **not buildable on Darwin at all** (not a packaging gap — fundamental sandboxing/GUI-stack incompatibilities):
- `modules/common/ai-mcps.nix` uses `pkgs.buildFHSEnv` (relies on `bubblewrap`/Linux namespaces) — **no macOS equivalent exists**. Excluded entirely from `modules/darwin/home.nix`.
- `modules/templates/app/browsers-basic.nix` bundles `chromium` (Linux-only `meta.platforms`, no darwin support) alongside `firefox` (darwin-buildable) — since the whole file fails to evaluate as a unit, it is excluded entirely rather than partially imported. GUI browsers are expected to come from Homebrew casks instead.
- `modules/templates/app/terminals-basic.nix` bundles `ghostty` (Linux-only) alongside `tmux` (darwin-buildable) — same reasoning, excluded entirely. GUI terminal apps expected from Homebrew casks.
- `modules/templates/app/shells.nix` **is** included — fully `isHomeManager`-aware, evaluates cleanly on Darwin (its NixOS-only activation/systemd logic is skipped under `isHomeManager = true`).
- `modules/common/common.nix` contains one Darwin-incompatible package (`pavucontrol`, PulseAudio-only GUI). Rather than hand-excluding it (fragile as the shared list grows), `modules/darwin/home.nix` wraps the import in `lib.filter (lib.meta.availableOn pkgs.stdenv.hostPlatform) (...)` — this stays correct automatically as `common.nix` evolves, with no further Darwin-side maintenance needed.

**Final Darwin v2 Home Manager payload:** `modules/common/{git,common(filtered),fonts}.nix` + `modules/templates/app/shells.nix` (isHomeManager=true) + the SSH activation hook.

### 8.3 Shared LLM model storage ("one single place for LLM models")
Interpreted as: consolidate model cache location *per machine* across LLM tooling (not literal cross-machine/cross-disk sharing). Implemented in `modules/templates/app/ai-llm-basic.nix`:
- NixOS branch: `services.ollama.modelsDir = "/var/lib/ollama/models"` (matches upstream default, now pinned explicitly and documented — not a behavior change). Note: this option was recently renamed from `services.ollama.models`; the correct current name (`modelsDir`) is used, verified via `nix flake check` (which initially surfaced an evaluation warning for the old name, now fixed).
- Home Manager branch: `home.sessionVariables.OLLAMA_MODELS = "/var/lib/ollama/models"` so a user-invoked `ollama` CLI on Linux/HM hosts shares the same path convention as the NixOS service, instead of the tool's own default (`~/.ollama/models`).
- **Not yet wired into the Mac payload** — `ai-llm-basic.nix` is not imported by `modules/darwin/home.nix` in v2 (heavy AI/GUI templates are deferred per the "start small" scope). The `/var/lib/...` path is also a Linux-FHS convention that may need a Darwin-specific override (e.g. `~/Library/...` or a user-writable path) if/when LLM tooling is added to the Mac hosts — documented as a known caveat for that future work, not an active bug.

### 8.4 Validation performed
- `nix flake check --impure` — **all checks passed**, zero warnings, across `nixosConfigurations` (vm-nixos, tw-nixos, lp-nixos-mariac), `homeConfigurations`, and `darwinConfigurations` (mac-m1, mac-m5).
- Targeted `nix eval --impure` spot checks confirmed: `mac-m1`/`mac-m5` `system.stateVersion`, full `home.packages` list (pavucontrol correctly excluded, all darwin-buildable packages present), `home.activation.ensureSshKey` wiring, `homebrew.enable`, `nix-homebrew.enable`.
- `shellcheck` (v0.11.0, via `nix run nixpkgs#shellcheck`) run against `setup-darwin.sh`, `rebuild-darwin.sh`, `cleanup-darwin.sh` — **zero warnings**.
- **Not performed:** a full `darwin-rebuild`/`config.system.build.toplevel` *build* (as opposed to eval) — cross-platform building of an `aarch64-darwin` system from this `x86_64-linux` dev machine is not possible without emulation/a real Mac. Per the user's own framing, this pass is "theory-verified" (eval-level, cross-platform) rather than build-verified; final confirmation requires running `setup-darwin.sh --host mac-m1` (or `mac-m5`) on a real Mac.

### 8.5 Files created/modified (this pass)
- **New:** `modules/common/ssh.nix`, `modules/darwin/common.nix`, `modules/darwin/homebrew.nix`, `modules/darwin/home.nix`, `hosts/darwin/mac-m1/configuration.nix`, `hosts/darwin/mac-m5/configuration.nix`, `setup-darwin.sh`, `rebuild-darwin.sh`, `cleanup-darwin.sh`.
- **Modified:** `flake.nix` (added `nix-homebrew` input, replaced single `darwinConfigurations."Dragoss-MBP"` with `mac-m1`/`mac-m5`), `modules/templates/app/ai-llm-basic.nix` (shared LLM model path).
- **Deleted:** `hosts/darwin/Dragoss-MBP.lan/configuration.nix` (old broken scaffold, non-existent import path).
- **Deferred (not this pass):** SSH activation hook into `modules/linux/home.nix` + `systemd.user.services.ensure-ssh-key` into `modules/nixos/common.nix` (other half of item 6); `setup-nixos.sh`/`rebuild-nixos.sh` trimming, `setup-linux.sh` extension, `cleanup.sh`→`cleanup-nixos.sh` rename + `cleanup-linux.sh` creation (Task Breakdown items 7–9).
