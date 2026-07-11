# Current Reality

Last updated: 2026-07-11

## Product

`clarity_lazyvim` is an accessibility-first, high-contrast Neovim distribution built on LazyVim.

The product direction is:

- readable daily editor experience
- agent-output review and precision editing rather than embedded code generation
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
- Snacks picker and floating terminal
- nvim-treesitter
- neo-tree.nvim (the sole file explorer, selected explicitly before LazyVim startup)
- gitsigns.nvim
- conform.nvim

Support scripts:

- Python validation scripts in `scripts/`
- GitHub Actions workflow in `.github/workflows/clarity-validate.yml`

Clarity runtime diagnostics now has a dependency-free first slice:

- `config.diagnostics`: schema-versioned bounded in-memory and JSONL events
- `config.actions.fold`: typed fold outcomes instead of raw `normal! za`
- persistence defaults to WARN/ERROR under isolated/user state roots
- native messages and `vim.notify` present outcomes; diagnostics own truth
- Health is the human renderer for overview, recovery, native/Noice messages,
  structured events, clipboard, environment, and language
- `:ClarityLog path` and `:ClarityLog export` retain stable machine/evidence routes
- `scripts/run_clarity_tests.py` routes fast/contracts/behavior/faults/release

The resolved active and locked set is exactly 18 plugins. Mason,
`mason-lspconfig`, Lush, friendly-snippets, and lazydev are removed after
system-LSP, static-theme, native-snippet, and completion parity gates. Noice and
mini.pairs remain because they own tested presentation and small-edit behavior.

## Directory Map

Important paths:

```text
README.md
init.lua
lazy-lock.json
lazyvim.json
nvim/init.lua
nvim/lua/config/
nvim/lua/plugins/
nvim/colors/custom_colorblind_theme.lua
doc/clarity_lazyvim_complete_guide_zh.md
doc/clarity_architecture_governance.md
scripts/run_clarity_audit.py
scripts/clarity_doctor.py
scripts/run_clarity_validate.py
scripts/run_clarity_action_matrix.py
.github/workflows/clarity-validate.yml
docs/ai/
progress/
```

## Source Of Truth

Runtime authority remains the three-file root contract:

```text
init.lua
lazy-lock.json
lazyvim.json
```

Do not keep or commit:

```text
nvim/lazy-lock.json
```

The implemented root runtime guarantees:

- lazy.nvim receives root `lazy-lock.json` explicitly;
- `vim.g.lazyvim_json` points LazyVim at root `lazyvim.json` before import;
- nested `nvim/lazyvim.json` is removed;
- the copied-candidate smoke verifies all three paths and source/candidate
  hashes, and copies only Git-tracked or non-ignored development files.

The normalized 18-entry lock snapshot is accepted through explicit backup-first
transactions. Commit-bound macOS evidence uses official Neovim 0.12.4, isolated
roots, a copied candidate, and first/restart/offline-restart phases. Earlier
manual Ubuntu evidence is for an older commit and does not certify this
candidate. Exact-commit Ubuntu, Windows, WSL, and GitHub-hosted evidence remains
unverified. The authority boundary is recorded in ADR-0001.

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
uv run --with pynvim==0.6.0 python scripts/run_clarity_action_matrix.py
python3 scripts/run_clarity_tests.py fast
nvim --headless -u ./init.lua "+qall"
```

Local safe repair command:

```sh
python3 scripts/clarity_doctor.py --apply
```

The doctor is designed and statically tested for macOS, Linux, WSL, and Windows.
It dry-runs by default, reports exact dependency and parser health findings, and
only performs conservative local backup moves with `--apply`; this does not
substitute for exact-commit platform evidence.

Inside Neovim:

```vim
:ClarityHealth
:ClarityLanguage
```

Audit, validation, Start, Sync, Clipboard, and log-view commands are temporary,
unpromoted one-release compatibility routes into Health. Bang JSON and
log path/export contracts remain stable for agents and scripts.

CI:

- `.github/workflows/clarity-validate.yml`
- defines Ubuntu 24.04, Windows 2022, and macOS 14 jobs
- installs checksummed official Neovim 0.12.4, Python 3.12, and the pinned Python
  provider package
- uses isolated config/data/state/cache paths and a copied candidate repository
- has bounded jobs/processes, static checks, immutable action SHAs, and artifacts
- runs audit and runtime validation
- asserts that directory startup opens one Neo-tree and no Snacks Explorer
- executes independent fold, wrap, keymap, LSP, Gitsigns, localization,
  component, Health, Git-observation, formatting, dependency, theme, and
  terminal behavior contracts

Important evidence boundary:

- local audit and validation results describe the current local machine and its
  caches; they are not release evidence for a clean clone;
- the public GitHub Actions history inspected on 2026-07-09 has no successful
  completed `clarity-validate` run;
- the historical Windows executable and Ubuntu version/timeout defects are fixed
  in the workflow source, but no authorized GitHub-hosted matrix has run for the
  observation-surface candidate;
- audit now separates core, optional profiles, and release quality. A local audit
  never certifies release quality.

## Current Local Validation Snapshot

The observation runtime is implemented through `596cffa`; trust-gap hardening,
exact i18n pruning, and the real-input matrix are in `21f8d29`. A clean,
commit-bound release passed for `69ecfbf1872446287c1ec849e432b8d78fe48934`
with owner-only artifact
`~/.local/state/clarity_lazyvim/release-evidence/20260711-69ecfbf`:

- release manifest: clean worktree, Neovim 0.12.4, isolated config/data/state/
  cache, owner-only persistent artifacts
- 60 Python tests and 26 Lua policy/behavior files pass
- empty headless, file headless, and attached-UI scenarios pass; all 17 config/
  action modules are classified and all 14 cataloged capabilities are covered
- exact normal leader surface: 28 global + seven context-scoped = 35; the latter
  are five LSP, one Git hunk preview, and one editable-buffer format recovery
- four retained native/diagnostic actions also pass through real input: `gd`,
  `gr`, `K`, and `[d`/`]d`; code action and rename apply real WorkspaceEdits and
  restore buffer/cursor/modified state
- Neo-tree exposes exactly 20 local mappings; files Picker exposes input
  19 normal/18 insert, list 20 normal, preview two normal; dashboard exposes six
- five Git observation views, removed mutation keys, and full HEAD/refs/index/
  worktree/lock snapshots prove repository immutability
- system `lua-language-server` attaches naturally; missing server schedules no
  Mason/install path; native snippets, blink.cmp, and mini.pairs behavior pass
- project `nvim/stylua.toml` controls formatting; missing formatter is explicit and
  leaves the buffer stable; Clarity supplies no global style arguments
- static theme reload and 4.5:1 normal-text contrast checks pass without Lush
- raw-fold injection fails only `CLARITY_RUNTIME_FOLD_CONTRACT`; positive and
  no-fold paths remain typed, visible, and free of E490/E5108
- both attached sessions start without captured errors; injected cleanup restores
  diagnostics, quickfix, cursor, and UI callbacks; all three fake LSP processes
  exit; serialized matrix evidence contains no fixture/home absolute paths
- the active bilingual i18n catalog contains exactly 39 consumed keys per locale;
  retired help panels and Git-mutation labels cannot return silently
- first boot, restart, and proxy/PATH-blocked offline restart resolve exactly the
  same 18 active and locked plugins without authority-file drift

This snapshot is intentionally local-only. It must not be copied into a public
cross-platform baseline until the separately authorized clean-archive remote
matrix and real-WSL evidence are green.

Current runtime details:

- Neovim `0.12.4`
- Python `3.14.6`; attached UI is pinned to ephemeral `pynvim==0.6.0` through
  the test router
- local formatter/LSP/parser installations remain user/project-owned and outside
  automatic Clarity provisioning

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
- `:ClarityAudit` reports `vim` parser/query/highlighter health without requiring
  Clarity-managed parser installation.
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

Distribution path is GitHub clone plus Neovim bootstrap. A GitHub Actions
workflow is defined, but run evidence requires separate owner authorization.

## Documentation Notes

Public documentation currently includes:

- `README.md`
- `doc/clarity_lazyvim_complete_guide_zh.md`
- `doc/clarity_architecture_governance.md`

Canonical refactor documentation:

- `docs/DOCUMENT_INDEX.md`
- `docs/reviews/2026-07-11-observation-surface-implementation-review.md`
- `docs/architecture/2026-07-11-agent-era-observation-surface-blueprint.md`
- `docs/product/clarity-observation-surface-pm.md`
- `progress/2026-07-11-agent-era-observation-surface-plan.md`

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

The owner approved full local execution of the observation-surface plan on
2026-07-11. `LOCK-001` and `SURFACE-001` through `SURFACE-009` are complete for
the authorized local boundary. Documentation reconciliation and branch push are
tracked in `SURFACE-010`.

Active execution plan:

```text
progress/2026-07-11-agent-era-observation-surface-plan.md
```

The accepted lock hash is
`e158ec437e8cdd2ada480aa6f01e11479db7d322e4f16ad21d1626f5340c57ca`.
The reviewed exclusion registry contains 18 product-policy records with a
rationale and revisit trigger. `minimal.lua` is generated from that registry;
lock normalization removes only registry entries confirmed runtime-disabled and
does not prune unrelated conditional plugins.

GitHub Actions must not be triggered without a separate explicit request. The
current full-rubric assessment remains below a release-grade 95 because the
required remote Ubuntu/Windows/macOS matrix, real WSL evidence, and branch
protection are outside this authorized local execution. Do not convert the
owner-provided macOS pass into a cross-platform claim.
