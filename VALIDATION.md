# Validation

Read this document before validating, committing, pushing, or publishing a repository change. Run only the checks that match the changed files and behavior, and report checks that could not run.

## Every change

- Run `git diff --check`.
- Review `git status` and the complete diff, including new and deleted files.
- Confirm that only files required by the approved task changed; preserve owner changes already present at the start.
- Check that documentation and command examples describe behavior that exists.
- Do not claim that an unexecuted check passed.

## Nix changes

For changes to Nix flakes, modules, hosts, or templates:

```bash
nix flake check --no-build --no-write-lock-file
```

Map changed shared modules to their consuming hosts. Also evaluate the relevant derivation path for each affected output that the current platform can evaluate. `flake check` alone does not prove that every custom Home Manager or Darwin output evaluates.

Replace the angle-bracket placeholders with existing output keys from `flake.nix`:

```bash
# NixOS
nix eval --no-write-lock-file --raw '.#nixosConfigurations.<host>.config.system.build.toplevel.drvPath'

# Standalone Home Manager
nix eval --no-write-lock-file --raw '.#homeConfigurations."<user>@<host>".activationPackage.drvPath'

# nix-darwin
nix eval --no-write-lock-file --raw '.#darwinConfigurations.<host>.config.system.build.toplevel.drvPath'
```

Report evaluation failures, unsupported platforms, unavailable inputs, and affected hosts left unchecked. Do not update the flake lock or install tools to make a check pass without separate approval. Build a derivation only when that build is part of the approved validation scope.

## Shell changes

Run Bash syntax validation for each changed Bash script:

```bash
bash -n path/to/script.sh
```

Use the script's declared interpreter when it is not Bash. If an applicable linter is already available, report whether it ran; installing or configuring one requires approval.

## Python changes

For changes under `libvirt/` or its Python tests, run:

```bash
python -m unittest discover -s libvirt/tests
```

These tests do not authorize launching a VM or accessing a physical disk.

## Agent instruction and skill changes

When agent assets change:

- Check instruction routes and relative reference links; every required target must exist after the change.
- Verify every selected skill directory contains its complete supporting files and required license notices.
- Verify each directory name matches the `name` in its `SKILL.md` frontmatter and that selected prerequisites exist.
- Compare installed upstream package content with the reviewed source revision. Account separately for required license notices, unchanged retained supporting files, and explicitly approved pinned-link rewrites.
- Verify Pi and OpenCode project layout under `.agents/skills/`. Use the CLI's per-agent inventory as an observed check:

  ```bash
  npx --yes skills@1.7.4 list --agent pi opencode --json
  ```

- Distinguish static layout and CLI inventory checks from discovery observed in a fresh Pi or OpenCode session. Report a required reload or an unrun harness check rather than claiming it passed.
- Verify `skills-lock.json` reflects Skills CLI installation, contains pinned upstream references, and contains no credentials or local absolute paths. The project-owned `nix-config` skill is intentionally not an upstream lock entry.
- Confirm that no Claude-specific project files or projections were introduced.
- Do not recreate the retired project-local synchronization manager or `.agents/ai-assets.lock.json` as part of validation.

## Applying configurations

The following scripts apply host configurations and are not validation commands:

- `./rebuild-nixos.sh`
- `./rebuild-darwin.sh`
- `./rebuild-linux.sh`

Setup scripts, direct activation commands, cleanup scripts, disk operations, and VM launches are not substitutes for validation. Run an applying or destructive command only when the owner explicitly requests its exact target and action.

## Publication report

Before any authorized commit, push, pull request, merge, or release, summarize:

- changed files
- checks that passed
- checks that failed
- checks that did not run and why
- remaining risks or follow-up work

Validation does not authorize publication, merge, release, or system application.
