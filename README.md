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

If you want the new beginner-friendly Chinese guide, start with [doc/clarity_lazyvim_complete_guide_zh.md](doc/clarity_lazyvim_complete_guide_zh.md).

If you want the current product evaluation and architecture report, read [doc/clarity_architecture_governance.md](doc/clarity_architecture_governance.md).

If you want the root execution documents for future AI-driven work, read [REQUIREMENTS.md](REQUIREMENTS.md), [PLAN.md](PLAN.md), and [TASKS.md](TASKS.md).

## Core Features

### Accessibility-first theme

The custom theme in `nvim/colors/custom_colorblind_theme.lua` focuses on:

- high contrast foreground/background pairs
- bold keywords and types
- syntax separation designed for red-green colorblind users

### Curated LazyVim foundation

The configuration extends LazyVim instead of rebuilding editor primitives from zero. This keeps startup and maintenance costs lower while leaving room for strong custom identity.

### Minimal necessary plugin set

The public distribution now keeps only the plugin layers that directly support the product story:

- LazyVim core for LSP, completion, Snacks-based picking, Mason, and statusline foundations
- `lush.nvim` plus the custom accessibility theme
- `neo-tree.nvim` for project navigation
- `toggleterm.nvim` for integrated terminal workflows
- `gitsigns.nvim` for inline Git feedback
- `conform.nvim` for formatter orchestration
- `nvim-treesitter` for syntax intelligence
- `copilot.lua` as the single AI-assist layer

Non-essential extras such as dashboard, bufferline, LazyGit integration, alternate colorschemes, and several inherited power-user plugins are intentionally disabled to keep the stack leaner and easier to audit.

### Integrated terminal workflow

The repo includes floating, vertical, and horizontal terminal layouts through `toggleterm.nvim`.

Optional extras:

- `htop` or `btop` for system monitoring

If those tools are missing, the related mappings now fail gracefully with a helpful warning instead of hard-crashing the flow.

### Built-in audit command

Run `:ClarityAudit` inside Neovim to inspect:

- bootstrap layout correctness
- required external tools
- optional external tools
- active plugin inventory
- plugins disabled by the minimal-set policy
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
3. Node.js `22+` and npm
4. Python and pip

### Optional

1. `htop` or `btop`

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
4. `copilot.lua` uses a Node.js `22+` runtime and prefers an `fnm`-managed Node automatically when available

## Dependency Strategy

This repository now follows these rules:

1. Shell frameworks such as `oh-my-zsh` are not part of the runtime foundation.
2. Optional tools must remain optional.
3. Formatter choices should prefer stable, documented commands over hidden machine-local assumptions.
4. The canonical plugin lock file is the root [lazy-lock.json](lazy-lock.json).
5. The active-vs-disabled plugin policy is defined in `nvim/lua/plugins/minimal.lua`, not inferred from lockfile entries alone.

## Keybindings

The configuration is largely self-documenting via `which-key`, but the most important custom mappings are:

| Keybinding | Description |
| --- | --- |
| `gd` | Go to definition |
| `K` | Hover documentation |
| `gr` | Find references |
| `<leader>ca` | Code action |
| `[d` / `]d` | Previous / next diagnostic |
| `<leader>ff` | Find files from project root |
| `<leader>fb` | Open buffer list |
| `<leader>fg` | Find tracked Git files |
| `<leader>fw` | Search text in project |
| `<leader>bd` | Delete current buffer |
| `<leader>e` | Toggle Neo-tree in current working directory |
| `<leader>E` | Toggle Neo-tree at detected project root |
| `<leader>-` / `<leader>|` | Split current window |
| `<leader>wd` | Close current window |
| `<leader>gd` / `<leader>gs` | Git diff list / Git status |
| `<leader>tf` | Floating center terminal |
| `<leader>tr` | Floating right terminal |
| `<leader>tv` | Vertical terminal |
| `<leader>th` | Horizontal terminal |
| `<leader>ht` | System monitor terminal if `htop` or `btop` is installed |
| `[h` / `]h` | Previous / next Git hunk |
| `<leader>hs` / `<leader>hr` | Stage / reset current Git hunk |
| `<leader>hp` | Preview current Git hunk |

## Project Structure

```text
.
├── init.lua
├── lazy-lock.json
├── REQUIREMENTS.md
├── PLAN.md
├── TASKS.md
├── doc/
│   ├── clarity_architecture_governance.md
│   └── clarity_lazyvim_complete_guide_zh.md
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

### `copilot.lua` says Node.js `22+` is required

This config expects a modern Node runtime for Copilot. If your shell still exposes an older system Node, install a current LTS release with a version manager such as `fnm`, `nvm`, or `volta`.

When `fnm` is present, `clarity_lazyvim` now prefers the newest `fnm`-managed Node binary automatically before falling back to `node` from `PATH`.

## License

MIT. See [LICENSE](LICENSE).
