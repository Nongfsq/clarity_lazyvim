# Current Reality

Last updated: 2026-07-09

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

Plugin lockfile source of truth:

```text
lazy-lock.json
```

Do not keep or commit:

```text
nvim/lazy-lock.json
```

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
nvim --headless -u ./init.lua "+qall"
```

Local safe repair command:

```sh
python3 scripts/clarity_doctor.py --apply
```

The doctor is cross-platform for macOS, Linux, and WSL. It dry-runs by default, reports exact dependency and parser health findings, and only performs conservative local backup moves with `--apply`.

Inside Neovim:

```vim
:ClarityAudit
:ClarityValidate
:ClarityStart
:ClaritySync
:ClarityClipboard
:ClarityLanguage
```

CI:

- `.github/workflows/clarity-validate.yml`
- runs on Ubuntu and Windows
- installs Neovim, Python, Node 22, provider packages, and `tree-sitter-cli`
- runs audit and runtime validation
- asserts that directory startup opens one Neo-tree and no Snacks Explorer
- executes the code-fold and line-wrap mappings, including state restoration

## Current Local Validation Snapshot

As of 2026-07-09 on the current macOS runtime:

- `python3 scripts/clarity_doctor.py`: required checks passing; optional warning for `pynvim`
- `python3 scripts/run_clarity_audit.py`: `Overall readiness: 100/100`
- `python3 scripts/run_clarity_validate.py`: required failures `0`
- optional warnings: `1` (`pynvim` is missing for the active Python runtime)
- directory startup: one Neo-tree window and zero Snacks Explorer windows

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

AI workflow documentation lives under:

```text
docs/ai/
progress/
scripts/session-prompt.md
```

`AGENTS.md` remains local-only unless the project owner explicitly changes the ignore policy.
