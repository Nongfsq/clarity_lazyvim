# Current Reality

Last updated: 2026-07-10

## Product

`clarity_lazyvim` is an accessibility-first, high-contrast Neovim distribution built on LazyVim.

The product direction is:

- readable daily editor experience
- minimal public plugin surface
- explicit Windows / WSL / Linux workflow discipline
- Clarity-owned help, audit, validation, and recovery paths
- bilingual Clarity-owned runtime UI with English source governance

This is not a shell framework, maximal plugin showcase, or generic starter template.

## Repository Location

Current local repository:

```text
/Users/frank/Github/clarity_lazyvim
```

Local Neovim config symlink observed during this session:

```text
/Users/frank/.config/nvim -> /Users/frank/Github/clarity_lazyvim
```

The repository root has `init.lua`, and the nested Neovim runtime lives under `nvim/`.

## Stack

Primary runtime:

- Neovim 0.12+
- Lua
- LazyVim
- lazy.nvim
- Snacks picker (search/picker only)
- nvim-treesitter
- neo-tree.nvim (the sole file explorer, selected explicitly before LazyVim startup)
- toggleterm.nvim
- gitsigns.nvim
- conform.nvim
- copilot.lua

Support scripts:

- Python validation scripts in `scripts/`
- GitHub Actions workflow in `.github/workflows/clarity-validate.yml`

Clarity runtime diagnostics now has a dependency-free first slice:

- `config.diagnostics`: schema-versioned bounded in-memory and JSONL events
- `config.actions.fold`: typed fold outcomes instead of raw `normal! za`
- persistence defaults to WARN/ERROR under isolated/user state roots
- Noice and `vim.notify` remain presentation layers, not diagnostic authority
- `:ClarityLog` exposes recent events, tail, path, and sanitized export
- `scripts/run_clarity_tests.py` routes fast/contracts/behavior/faults/release

## Directory Map

Important paths:

```text
README.md
init.lua
lazy-lock.json
nvim/init.lua
nvim/lua/config/
nvim/lua/plugins/
nvim/colors/custom_colorblind_theme.lua
doc/clarity_lazyvim_complete_guide_zh.md
doc/clarity_architecture_governance.md
scripts/run_clarity_audit.py
scripts/clarity_doctor.py
scripts/run_clarity_validate.py
.github/workflows/clarity-validate.yml
docs/ai/
progress/
```

## Source Of Truth

Trust-foundation branch runtime authority:

```text
lazy-lock.json
```

Do not keep or commit:

```text
nvim/lazy-lock.json
```

On `codex/20260709-clarity-trust-foundation`:

- lazy.nvim receives root `lazy-lock.json` explicitly;
- `vim.g.lazyvim_json` points LazyVim at root `lazyvim.json` before import;
- nested `nvim/lazyvim.json` is removed;
- the copied-candidate smoke verifies both paths and source/candidate hashes.

The normalized lock snapshot is accepted through the explicit lock transaction.
The branch still lacks remote matrix evidence and has not been merged. The
accepted boundary is recorded in ADR-0001.

Local AI implementation rules:

```text
AGENTS.md
```

`AGENTS.md` is intentionally ignored by `.gitignore`.

## Validation

Primary commands:

```sh
python3 scripts/clarity_doctor.py
python3 scripts/run_clarity_audit.py
python3 scripts/run_clarity_validate.py
python3 scripts/run_clarity_contracts.py
python3 scripts/run_clarity_tests.py fast
nvim --headless -u ./init.lua "+qall"
```

Local safe repair command:

```sh
python3 scripts/clarity_doctor.py --apply
```

The doctor is cross-platform for macOS, Linux, WSL, and Windows. It dry-runs by default, reports exact dependency and parser health findings, and only performs conservative local backup moves with `--apply`.

Inside Neovim:

```vim
:ClarityAudit
:ClarityValidate
:ClarityStart
:ClaritySync
:ClarityClipboard
:ClarityLanguage
:ClarityLog
```

CI:

- `.github/workflows/clarity-validate.yml`
- defines Ubuntu 24.04, Windows 2022, and macOS 14 jobs
- installs checksummed official Neovim 0.12.4, Python 3.12, Node 22, pinned
  provider packages, and `tree-sitter-cli`
- uses isolated config/data/state/cache paths and a copied candidate repository
- has bounded jobs/processes, static checks, immutable action SHAs, and artifacts
- runs audit and runtime validation
- asserts that directory startup opens one Neo-tree and no Snacks Explorer
- executes the code-fold and line-wrap mappings, including state restoration

Important evidence boundary:

- local audit and validation results describe the current local machine and its
  caches; they are not release evidence for a clean clone;
- the public GitHub Actions history inspected on 2026-07-09 has no successful
  completed `clarity-validate` run;
- the historical Windows executable and Ubuntu version/timeout defects are fixed
  in the branch workflow, but no remote matrix has run for this branch;
- audit now separates core, optional profiles, and release quality. A local audit
  never certifies release quality.

## Current Local Validation Snapshot

As of 2026-07-09 on the current macOS runtime:

- `python3 scripts/clarity_doctor.py`: required checks passing; optional warning for `pynvim`
- `python3 scripts/run_clarity_audit.py`: core readiness `ready` (`12/12`), release
  quality `unverified`, provider profile degraded only by missing `pynvim`
- `python3 scripts/run_clarity_validate.py`: required failures `0`
- optional warnings: `1` (`pynvim` is missing for the active Python runtime)
- directory startup: one Neo-tree window and zero Snacks Explorer windows
- natural runtime contracts: empty headless, file headless, and attached-UI file
  startup pass; all 10 config modules are classified
- negative runtimepath fixture: exactly four expected failures for options,
  autocmds, editing defaults, and keymap ownership/behavior
- raw-fold fixture: exactly `CLARITY_RUNTIME_KEYMAP_CONTRACT`; the repaired
  action returns `no_fold` without `E490/E5108` on a plain line
- observability local implementation: 30 Python tests and 7 Lua policy tests
  pass; all 13 current config/action modules are classified; fold is covered by
  success, expected-edge, fault, restoration, and real-input evidence

This snapshot is intentionally local-only. It must not be copied into a public
cross-platform baseline until the clean-archive matrix in the active plan is
green.

Current runtime details:

- Neovim `0.12.4`
- Python `3.14.6`; `pynvim` is not installed for this interpreter
- Node.js `26.5.0` with global `neovim@5.4.0`
- `tree-sitter-cli 0.26.9`

## Local Issue Resolved On 2026-05-05

Observed issue:

- Noice and Neovim displayed repeated Treesitter errors:
  `Invalid node type "tab"`
- Logs implicated `nvim.treesitter.highlighter` and `vim` highlights query.

Root cause:

- stale user-level parser at `/Users/meng/.local/share/nvim/site/parser/vim.so`
- it overrode the Neovim 0.12.2 bundled `vim` parser
- the stale parser did not understand the `"tab"` node expected by the current query

Local remediation:

- moved stale parser to `/Users/meng/.local/share/nvim/site/parser/.clarity-backup-20260505/vim.so`
- moved stale revision marker to `/Users/meng/.local/share/nvim/site/parser-info/.clarity-backup-20260505/vim.revision`
- verified the current bundled parser reports `vim` metadata `0.8.1` and passes query, parser, and highlighter checks for Vimscript samples such as `set tab`

This was a local machine state issue, not a GitHub repository code issue.

Repository-level prevention added after this incident:

- `scripts/clarity_doctor.py` detects stale user-level `vim` parser overrides and supports safe `--apply` backup moves.
- `:ClarityAudit` reports Tree-sitter CLI availability and `vim` parser/query/highlighter health.
- `scripts/run_clarity_validate.py` treats `vim` parser health and stale user-level parser overrides as required validation checks.
- README troubleshooting now starts with the doctor path and documents the `Invalid node type "tab"` recovery flow.

## Linux Parser Runtimepath Fix On 2026-05-28

Observed issue:

- A Linux server showed repeated Noice / Tree-sitter errors:
  `Invalid node type "substitute"`
- The stale user-level parser was backed up with `python3 scripts/clarity_doctor.py --apply`.
- After the stale parser moved, user-config startup still failed parser verification with:
  `No parser for language "vim"`

Root cause:

- The Neovim package bundled `vim.so` under `/usr/lib/x86_64-linux-gnu/nvim/parser/vim.so`.
- `lazy.nvim` reset `runtimepath` during startup and did not preserve that multiarch runtime directory.
- Clean Neovim could see the bundled parser, but Clarity's LazyVim startup could not.

Repository-level prevention added after this incident:

- `nvim/lua/config/lazy.lua` now preserves bundled Neovim parser runtime roots during `lazy.nvim` startup.
- `scripts/clarity_doctor.py --json` records runtimepath, parser candidates, and query candidates.
- Doctor output now distinguishes stale user parser overrides from packaged Linux runtimepath visibility failures.

## Deployment

There is no hosted application deployment.

Distribution path is GitHub clone plus Neovim bootstrap. Public validation is GitHub Actions.

## Documentation Notes

Public documentation currently includes:

- `README.md`
- `doc/clarity_lazyvim_complete_guide_zh.md`
- `doc/clarity_architecture_governance.md`

Canonical refactor documentation:

- `docs/DOCUMENT_INDEX.md`
- `docs/reviews/2026-07-09-clarity-95-quality-review.md`
- `docs/architecture/2026-07-09-clarity-95-refactor-blueprint.md`
- `docs/product/clarity-95-experience-pm.md`
- `progress/2026-07-09-clarity-95-refactor-plan.md`

The older `doc/clarity_architecture_governance.md` is retained for historical
traceability. Its score and platform snapshots are not current authority.

AI workflow documentation lives under:

```text
docs/ai/
progress/
scripts/session-prompt.md
```

`AGENTS.md` remains local-only unless the project owner explicitly changes the ignore policy.

## Active Refactor

The 95+ review and architecture direction were approved on 2026-07-09. The first
trust-foundation batch is implemented locally on
`codex/20260709-clarity-trust-foundation`.

Trust foundation and runtime-contract status:

1. `QA-001` — done locally
2. `VALIDATE-002` — done locally
3. `NVIM-002` — done; normalized lock accepted with an explicit validated,
   backed-up, atomic update transaction
4. `CI-002` — local workflow checks pass; remote three-platform run required
5. `RUNTIME-001` through `RUNTIME-004` — done locally on 2026-07-10; natural
   lifecycle catalog/probe/runner and line-number positive/negative proof pass
6. `RUNTIME-005` — pending owner evidence review
7. `OBS-001` through `OBS-007` — done locally on 2026-07-10; diagnostic commands,
   real-input fold evidence, unified router/artifacts, privacy, and restoration
   hardening pass
8. `OBS-008` — local workflow integration passes; remote Ubuntu/Windows/macOS
   evidence pending
9. `OBS-009` — pending remote evidence and final legacy/ADR closeout

Platform evidence boundary for the next gate:

- Ubuntu GitHub Actions evidence can be evaluated immediately.
- Windows GitHub-hosted runner evidence, if produced, is CI evidence only.
- Real remote Windows/server validation remains pending until the owner provides
  the announced root access; do not mark that environment verified beforehand.

The implementation is stopped at the remote observability CI evidence gate.
Do not close `OBS-008`, begin `OBS-009`, resume `RUNTIME-005`, or start plugin
ownership migration without exact commit-bound platform artifacts. The
`nvim-lspconfig` drift was accepted through the backup-first atomic transaction;
the current lock hash is
`af8ad1dff2b125573e19a37c3a30af25a152450d2b9b1d0320ee78fd35db04d7`.
