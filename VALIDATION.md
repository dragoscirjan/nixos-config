# Validation

Read this document before validating, committing, pushing, or publishing a repository change. Run only the checks that match the changed files and behavior, and report checks that could not run.

## Every change

- Run `git diff --check`.
- Review `git status` and the complete diff.
- Confirm that only files required by the task changed.
- Check that documentation and command examples describe behavior that exists.
- Do not claim that an unexecuted check passed.

## Nix changes

For changes to Nix flakes, modules, hosts, or templates:

```bash
nix flake check --no-build
```

Report evaluation failures and any checks skipped because the current platform cannot evaluate a host.

## Shell changes

Run Bash syntax validation for each changed shell script:

```bash
bash -n path/to/script.sh
```

Use the script's declared interpreter when it is not Bash.

## Python changes

For changes under `libvirt/` or its Python tests, run:

```bash
python -m unittest discover -s libvirt/tests
```

## Agent instruction and skill changes

When agent assets change:

- Verify every selected skill directory contains its complete supporting files.
- Verify each skill directory name matches the `name` in its `SKILL.md` frontmatter.
- Verify all selected skill dependencies are installed.
- Verify Pi and OpenCode discover each selected project skill under `.agents/skills/`.
- Verify Claude Code sees each selected skill through the exact relative symlink `.claude/skills/<name> -> ../../.agents/skills/<name>`.
- Verify `CLAUDE.md` imports `AGENTS.md` before any Claude-specific instructions.
- Verify `skills-lock.json` reflects Skills CLI installation.
- Verify `.agents/ai-assets.lock.json` contains no credentials, secrets, temporary paths, personal paths, or absolute paths.
- Run the synchronization helper's status command and require a clean managed state.

## Applying configurations

The following scripts apply host configurations and are not validation commands:

- `./rebuild-nixos.sh`
- `./rebuild-darwin.sh`
- `./rebuild-linux.sh`

Run an applying command only when the owner explicitly requests it.

## Publication report

Before any authorized commit, push, pull request, merge, or release, summarize:

- changed files
- checks that passed
- checks that failed
- checks that did not run and why
- remaining risks or follow-up work

Validation does not authorize publication, merge, release, or system application.
