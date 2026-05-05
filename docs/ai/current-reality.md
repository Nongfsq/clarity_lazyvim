# Current Reality

Last updated: 2026-05-05

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
/Users/meng/Github/clarity_lazyvim
```

Local Neovim config symlink observed during this session:

```text
/Users/meng/.config/nvim -> /Users/meng/Github/clarity_lazyvim/nvim
```

The repository root has `init.lua`, and the nested Neovim runtime lives under `nvim/`.

## Stack

Primary runtime:

- Neovim 0.12+
- Lua
- LazyVim
- lazy.nvim
- Snacks picker
- nvim-treesitter
- neo-tree.nvim
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

## Current Local Validation Snapshot

As of 2026-05-05 after adding cross-platform doctor/repair:

- `python3 scripts/clarity_doctor.py`: no required failures; optional warnings for missing local `tree-sitter` CLI and Python provider package
- `python3 scripts/run_clarity_audit.py`: `Overall readiness: 98/100` on the current macOS machine because `tree-sitter` CLI is an optional diagnostic dependency and is not installed locally
- `python3 scripts/run_clarity_validate.py`: required failures `0`
- optional warning: Python provider module `pynvim` is not installed for the local Python runtime
- optional warning: `tree-sitter` CLI is not installed locally; install with `npm install -g tree-sitter-cli` if parser diagnostics are needed outside CI

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
