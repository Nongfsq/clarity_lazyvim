# clarity_lazyvim

A colorblind-friendly, high-contrast Neovim configuration built on [LazyVim](https://www.lazyvim.org/).

`clarity_lazyvim` is designed to be readable first:

- bold, high-contrast syntax groups
- a custom accessibility-focused colorscheme
- curated LazyVim overrides instead of a from-scratch editor stack
- bilingual key descriptions for a clearer `which-key` experience

## Why This Repo Exists

The project is opinionated, but it should not be fragile.

The current repository is structured so it can be cloned directly into the Neovim config path while still keeping the main implementation under `nvim/`. A root `init.lua` now bootstraps that nested config correctly.

Architecture notes and the ongoing remediation plan live in [doc/clarity_architecture_governance.md](doc/clarity_architecture_governance.md).

## Core Features

### Accessibility-first theme

The custom theme in `nvim/colors/custom_colorblind_theme.lua` focuses on:

- high contrast foreground/background pairs
- bold keywords and types
- syntax separation designed for red-green colorblind users

### Curated LazyVim foundation

The configuration extends LazyVim instead of rebuilding editor primitives from zero. This keeps startup and maintenance costs lower while leaving room for strong custom identity.

### Integrated terminal workflow

The repo includes floating, vertical, and horizontal terminal layouts through `toggleterm.nvim`.

Optional extras:

- `lazygit` for Git TUI workflows
- `htop` or `btop` for system monitoring

If those tools are missing, the related mappings now fail gracefully with a helpful warning instead of hard-crashing the flow.

### Built-in audit command

Run `:ClarityAudit` inside Neovim to inspect:

- bootstrap layout correctness
- required external tools
- optional external tools
- overall environment readiness

For a headless audit from the terminal, use:

```powershell
python scripts/run_clarity_audit.py
```

## Prerequisites

### Required

1. Neovim `0.12+`
2. Git
3. A C compiler for `nvim-treesitter`
   - Windows: GCC/Clang or MSVC
   - macOS: `xcode-select --install`
   - Debian/Ubuntu: `sudo apt install build-essential`
   - Arch: `sudo pacman -S base-devel`
4. A Nerd Font for icons

### Recommended

1. `ripgrep`
2. `fd`
3. Node.js and npm
4. Python and pip

### Optional

1. `lazygit`
2. `htop` or `btop`

## Installation

### Windows

Clone into `%LOCALAPPDATA%\nvim`:

```powershell
git clone https://github.com/Nongfsq/clarity_lazyvim.git $env:LOCALAPPDATA\nvim
```

### Linux / macOS

Clone into `~/.config/nvim`:

```sh
git clone https://github.com/Nongfsq/clarity_lazyvim.git ~/.config/nvim
```

### First launch

```sh
nvim
```

On first launch:

1. `lazy.nvim` bootstraps plugins
2. `Mason.nvim` installs configured language servers and formatter tooling
3. `nvim-treesitter` compiles parsers if a compiler is available

## Dependency Strategy

This repository now follows these rules:

1. Shell frameworks such as `oh-my-zsh` are not part of the runtime foundation.
2. Optional tools must remain optional.
3. Formatter choices should prefer stable, documented commands over hidden machine-local assumptions.
4. The canonical plugin lock file is the root [lazy-lock.json](lazy-lock.json).

## Keybindings

The configuration is largely self-documenting via `which-key`, but the most important custom mappings are:

| Keybinding | Description |
| --- | --- |
| `gd` | Go to definition |
| `K` | Hover documentation |
| `gr` | Find references |
| `<leader>ca` | Code action |
| `[d` / `]d` | Previous / next diagnostic |
| `<leader>e` | Toggle Neo-tree in current working directory |
| `<leader>E` | Toggle Neo-tree at detected project root |
| `<leader>gg` | Open LazyGit if installed |
| `<leader>tf` | Floating center terminal |
| `<leader>tr` | Floating right terminal |
| `<leader>tv` | Vertical terminal |
| `<leader>th` | Horizontal terminal |
| `<leader>ht` | System monitor terminal if `htop` or `btop` is installed |

## Project Structure

```text
.
├── init.lua
├── lazy-lock.json
├── doc/
│   └── clarity_architecture_governance.md
├── nvim/
│   ├── colors/
│   ├── init.lua
│   └── lua/
│       ├── config/
│       └── plugins/
└── scripts/
    └── run_clarity_audit.py
```

## Audit and Smoke Test

Inside Neovim:

```vim
:ClarityAudit
```

From the terminal:

```powershell
python scripts/run_clarity_audit.py
```

Minimal smoke test:

```powershell
nvim --headless -u .\init.lua "+qall"
```

## Troubleshooting

### `nvim-treesitter` complains about missing compiler

Install a working C compiler and restart your shell so `gcc`, `clang`, or `cl` is available in `PATH`.

### `:ClarityAudit` reports missing optional tools

That is expected if you have not installed them. The related mappings will warn and degrade gracefully.

### Node.js or Python provider issues

If `:checkhealth` reports provider issues, install the missing provider package:

```sh
npm install -g neovim
pip install pynvim
```

## License

MIT. See [LICENSE](LICENSE).
