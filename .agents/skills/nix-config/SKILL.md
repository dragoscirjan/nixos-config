---
name: nix-config
description: "Design, change, review, or test this project's Nix flakes, NixOS modules, nix-darwin configuration, and Home Manager environments with host-impact and operational-safety checks."
requires: [coding]
---

# Maintain Nix configuration

Use `coding` for the shared implementation workflow. Read the project's `AGENTS.md` and `CONTRIBUTING.md`; their feature-branch and owner-approval rules govern all work. This skill is project-owned, not an upstream language reference.

## 1. Map the change

Read the affected flake output, host configuration, imported modules, and relevant options before designing a change. Trace direct and shared consumers rather than assuming a module affects only the host that prompted the request.

Record the affected output keys and platforms. Identify whether each changed file is a module, a function returning packages, an option declaration, or generated hardware configuration. For a shared change, list the hosts whose import chains must remain compatible.

Continue when the intended behavior, module interface, and affected consumers are explicit. Ask about policy or behavior choices that the files cannot settle.

## 2. Preserve platform boundaries

Follow existing interfaces and feature groups. Use NixOS, nix-darwin, and Home Manager options only in their proper module context. Preserve `specialArgs`, `extraSpecialArgs`, and the existing `isHomeManager` convention where used.

Reuse the current package set and input relationships. Check option types, merge behavior, conditional imports, and package availability on the affected systems. Use the existing priority conventions rather than adding force overrides to hide an unexplained conflict.

Keep host identity and hardware choices in host files. Put reusable behavior in the narrowest existing feature or platform module. Avoid a module-framework rewrite for a single package or host change.

For embedded Bash or Python work, also select the corresponding references through `coding-with-rules`. That skill currently has no Nix reference; do not substitute another language's rules for Nix semantics.

## 3. Protect operational state

Preserve state versions, generated hardware configuration, boot settings, device identities, authentication, and remote-access behavior unless their change is explicitly in scope. Explain the affected host and recovery implications before changing them.

Read `libvirt/README.md` before changing physical-disk VM behavior. Keep disk identity, mounted-device, and in-use checks intact. Tests and XML inspection do not authorize launching a guest or writing to a device.

Keep secrets outside prompts, logs, committed configuration, and generated artifacts. Refer to an existing secret mechanism without reading secret values merely to inspect configuration.

## 4. Validate the affected outputs

Read `VALIDATION.md` and run the applicable approved checks. Stage only task-owned newly referenced files when Git-backed flake evaluation requires it. Do not stage unrelated work.

Check the flake and the affected output derivation paths, including shared consumers supported on the current platform. Keep evaluation, building, and activation separate; report unavailable platform coverage instead of treating it as a pass.

Input updates, dependency installation, garbage collection, rebuild activation, setup scripts, VM launches, and disk operations require their own explicit scope and approval. Do not use them as inspection shortcuts or speculative fixes.

## 5. Report the result

Report changed files, affected output keys, intended behavior, package or service impact, observed checks, unrun coverage, and remaining owner actions. Update the relevant operational documentation in the same scoped change. Leave commits, publication, and applying configurations to separately authorized actions.
