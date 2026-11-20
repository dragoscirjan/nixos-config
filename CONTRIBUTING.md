# Contributing & Architecture Guide

This repository defines NixOS systems, nix-darwin systems, and standalone Home Manager environments. Keep host-specific choices separate from reusable modules.

Read this document before planning or performing an architecture, implementation, documentation, configuration, policy, or publication change.

## Contribution workflow

1. Clarify ambiguous requirements and confirm shared understanding.
2. Keep each change focused on one task.
3. Follow the feature-branch workflow in `AGENTS.md` before changing repository state.
4. Identify the affected flake outputs and the hosts that import each changed module.
5. Preserve the platform and module boundaries described below.
6. Update documentation when behavior, policy, host support, or usage changes.
7. Read and follow [`VALIDATION.md`](VALIDATION.md) before validating, committing, pushing, or publishing.
8. Do not commit, push, open a pull request, merge, release, or apply a system configuration without explicit owner instruction.

## Configuration boundaries

`flake.nix` defines the supported outputs, inputs, package sets, and arguments passed into each configuration. Use it and the host imports as the current source of truth for host support.

| Location | Responsibility |
|---|---|
| `hosts/nixos/<host>/` | NixOS host configuration, hardware imports, and feature selection. |
| `hosts/linux/<host>/home.nix` | Standalone Home Manager configuration and feature selection. |
| `hosts/darwin/<host>/configuration.nix` | Darwin host identity and selection of shared Darwin configuration. |
| `modules/nixos/` | Shared NixOS services, system options, and platform integration. |
| `modules/linux/home.nix` | Shared standalone Home Manager setup. |
| `modules/darwin/` | Shared nix-darwin configuration, Home Manager integration, and Homebrew settings. |
| `modules/common/` | Shared package lists and configuration helpers; inspect each file's interface before reuse. |
| `modules/templates/app/` | Application feature groups, including basic and fuller variants where available. |
| `modules/templates/hw/` | Hardware feature groups selected by the relevant hosts. |
| `modules/templates/dev/` | Reusable development-environment features. |
| `modules/options.nix`, `modules/nixos/project-options.nix` | Project option declarations; preserve their types and consumers. |
| `libvirt/` | Physical-disk VM module, launcher, documentation, and Python tests. |

### Host composition

Hosts select reusable features through imports. Follow the existing import chain before moving a package, option, or service:

- NixOS hosts combine shared NixOS configuration with application and hardware templates.
- Standalone Linux hosts use `modules/linux/home.nix` and select application templates directly. Some import GUI and creative tools; do not assume every non-NixOS Linux host is headless.
- Darwin hosts use `modules/darwin/common.nix`, which integrates Home Manager. Do not duplicate modules already imported by `flake.nix` or the shared Darwin layer.

Host names, output keys, and feature selections can change. Inspect the current files rather than maintaining a second host inventory here.

## Placing a change

### Applications and tools

Extend an existing feature group when its purpose matches the tool:

- GUI IDEs: inspect `modules/templates/app/ide.nix` and `ide-basic.nix`.
- Languages and compilers: inspect `modules/templates/app/languages.nix` and `languages-basic.nix`.
- Browsers, terminals, office, design, media, gaming, AI, and virtualization: use the corresponding application template.
- Shared CLI packages: inspect `modules/common/common.nix` and the platform consumers before adding a dependency for every host.
- Platform-only services or settings: keep them in the corresponding platform module or host.

Check whether a template returns a package list, a module, or branches on `isHomeManager`. Preserve its interface and install packages through the correct system or Home Manager option.

### Hosts and hardware

Edit the relevant file under `hosts/<platform>/<host>/`. Import only the features that host needs. Keep machine-specific device identities and generated hardware settings out of reusable templates.

Changes to boot, disks, hardware configuration, state versions, authentication, or remote access need an explicit explanation of the affected host and operational risk. Do not change them merely to silence an unrelated evaluation error.

Before changing physical-disk VM behavior, read [`libvirt/README.md`](libvirt/README.md). Keep its device-use and mount-safety checks intact.

### New Nix files

Git-backed flakes omit untracked files. Before evaluating a new Nix module or another newly referenced flake input file, stage only the task-owned file with `git add -- path/to/file`. Do not stage unrelated changes.

## Documentation

Keep task instructions and examples consistent with the implementation. Read the affected pages before editing them. Verify commands against the current scripts and flake outputs; historical specifications and older README examples are not evidence that a command still exists.

Keep a documentation-site introduction or a broad documentation rewrite separate from a small configuration change unless the owner approves the larger scope.

## Agent assets

Pi and OpenCode share complete, flat skill packages under `.agents/skills/<name>/`. Do not create Claude-specific files or projections in this project.

- Use project-scoped Skills CLI installations and its `skills-lock.json`; do not edit the CLI's lock by hand.
- Pin reviewed source revisions in installation URLs. Review an update's content and policy changes before installing it; do not run an unreviewed bulk update.
- Preserve complete supporting files and required upstream license notices. A license notice added from the reviewed source repository is packaging, not permission to modify the skill's behavior.
- If a skill links to a source-repository file outside its package, propose a pinned upstream URL for that reference before changing it. A documentation link does not require installing an unrelated manager.
- `nix-config` is project-owned and is not an upstream Skills CLI package. Maintain it through the normal feature-branch and instruction-review workflow.
- Adding or removing skills, changing root instructions, replacing locally modified content, or adopting a new manager requires an exact proposal and owner approval. Retain unknown custom assets until their ownership is clear.

This project uses Skills CLI records rather than a project-local synchronization manager or a separate managed-assets lock.

## Validation and application

Read [`VALIDATION.md`](VALIDATION.md) and run the applicable checks. Evaluation and builds do not authorize applying a configuration.

`rebuild-nixos.sh`, `rebuild-darwin.sh`, and `rebuild-linux.sh` apply configurations by default. Run them, setup scripts, or direct activation commands only when the owner explicitly requests the exact target and action.
