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
python3 scripts/run_clarity_audit.py
python3 scripts/run_clarity_validate.py
nvim --headless -u ./init.lua "+qall"
```

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

As of 2026-05-05 after local parser remediation:

- `python3 scripts/run_clarity_audit.py`: `Overall readiness: 100/100`
- `python3 scripts/run_clarity_validate.py`: required failures `0`
- optional warning: Python provider module `pynvim` is not installed for the local Python runtime

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
- verified the current bundled parser reports `vim` metadata `0.8.1` and supports `"tab"`

This was a local machine state issue, not a GitHub repository code issue.

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
