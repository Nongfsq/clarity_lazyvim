# clarity_lazyvim 🌈✨

A Neovim configuration meticulously designed for clarity, with special attention to colorblind-friendliness.

Built upon the powerful and performant [LazyVim](https://www.lazyvim.org/) framework, `clarity_lazyvim` is engineered to provide a high-contrast, distraction-free editing environment. By emphasizing readability through bolding and carefully selected colors for key syntax elements, it ensures a comfortable and productive coding experience, even during long sessions.

## Philosophy

*   **Readability First**: The core of this configuration is a custom color scheme optimized for red-green color blindness, ensuring that every piece of syntax is distinct and legible.
*   **Intelligent & Automated**: This setup uses [Mason.nvim](https://github.com/williamboman/mason.nvim) to automatically install and manage all necessary language servers, formatters, and linters on the first run.
*   **Modern & Performant**: By leveraging LazyVim, you get blazing-fast startup times and a modular structure that is simple to understand and extend.

## Key Features & Customizations

This is more than just a collection of plugins; it's a cohesive, customized editing experience. Here’s what makes `clarity_lazyvim` unique:

### 🎨 Custom Color Scheme
The heart of this project is the `custom_colorblind_theme.lua`. It's a theme built from the ground up using `lush.nvim` with a specific focus on:
- **High Contrast**: Dark backgrounds with vibrant, easily distinguishable foreground colors.
- **Bold Keywords**: Important keywords like `function`, `if`, and `return` are bolded to guide the eye.
- **Accessibility**: Colors were chosen to be clear for users with red-green color blindness.

### 🤖 AI-Powered Completion
- **GitHub Copilot**: Integrated via `copilot.lua`.
- **Custom Highlighting**: AI suggestions appear with an underline and a color that matches the theme's comments, making them clear but unobtrusive, upholding the project's design philosophy.

###  TERMINAL Integrated Terminal
- **ToggleTerm**: A powerful, flexible terminal is integrated directly into Neovim.
- **Easy Access**: Launch a floating terminal anytime with `<leader>ft`.
- **Git Integration**: A dedicated terminal for the `lazygit` interface is available for a seamless version control workflow.

###  dashboards Custom Dashboard
- The startup screen features custom ASCII art, immediately signaling that you're in the `clarity_lazyvim` environment.

### ⌨️ Bilingual Keymap Descriptions
- All custom keybindings have been given clear, bilingual (Chinese/English) descriptions, making the `which-key.nvim` pop-up menu exceptionally helpful.

## Prerequisites

Before installing, please ensure your system has the following core dependencies:

1.  **Neovim (v0.11.x or newer)**
2.  **Git**
3.  **A C Compiler** (for `nvim-treesitter`)
    -   **macOS**: `xcode-select --install`
    -   **Debian / Ubuntu**: `sudo apt install build-essential`
    -   **Arch Linux**: `sudo pacman -S base-devel`
4.  **A Nerd Font** (e.g., [FiraCode Nerd Font](https://www.nerdfonts.com/font-downloads))

> All other development tools (Language Servers, Linters, Formatters) will be installed **automatically** by `Mason.nvim`.

## Installation

1.  **Backup Your Current Configuration**:
    ```sh
    mv ~/.config/nvim ~/.config/nvim.bak
    ```
2.  **Clone the Repository**:
    ```sh
    git clone https://github.com/Nongfsq/clarity_lazyvim.git ~/.config/nvim
    ```
3.  **Launch Neovim**:
    ```sh
    nvim
    ```
    On first launch, `lazy.nvim` will install all plugins, and `Mason.nvim` will then install all language tools.

## Keybinding Quick Reference

This configuration is **self-documenting**. Press `<leader>` (`Space`) and wait a moment for a pop-up menu. Below is a reference for the most important custom keybindings.

| Keybinding                  | Description                           | Context / Plugin       |
| --------------------------- | ------------------------------------- | ---------------------- |
| **--- General ---**         |                                       |                        |
| `<leader>ff`                | Find Files                            | Telescope              |
| `<leader>fw`                | Find Word (Live Grep)                 | Telescope              |
| `<leader>fb`                | Find in Open Buffers                  | Telescope              |
| **--- Tabs / Bufferline ---** |                                       |                        |
| `<C-PageUp>` / `<C-PageDown>` | Cycle Through Tabs                    | Bufferline             |
| `<leader>` + `[1-9]`        | Go to Tab Number [1-9]                | Bufferline             |
| `<leader>bq`                | Close Current Tab                     | Bufferline             |
| **--- LSP ---**             | (Language Intelligence)               |                        |
| `gd`                        | Go to Definition                      | LSP                    |
| `K`                         | Hover to Show Documentation           | LSP                    |
| `gr`                        | Find References                       | LSP                    |
| `<leader>ca`                | Code Actions                          | LSP                    |
| `[d` / `]d`                 | Previous / Next Diagnostic            | LSP                    |
| **--- Git ---**             |                                       |                        |
| `<leader>gg`                | Open LazyGit                          | LazyGit                |
| `<leader>gs`                | Stage Current Hunk                    | Gitsigns               |
| `<leader>gr`                | Reset Current Hunk                    | Gitsigns               |
| `<leader>gb`                | Blame Current Line                    | Gitsigns               |
| **--- Terminal ---**        |                                       |                        |
| `<leader>\`                 | Toggle Centered 'HUD' Terminal        | ToggleTerm             |
| `<leader>ft`                | Toggle Floating Terminal              | ToggleTerm             |
| `<leader>vt`                | Toggle Vertical Terminal              | ToggleTerm             |## Project Structure Explained

The file structure is logical and easy to extend.

```
nvim
├── colors/
│   └── custom_colorblind_theme.lua  -- The unique, custom-built color scheme.
├── init.lua                         -- The main entry point. DO NOT EDIT.
├── lua/
│   ├── config/
│   │   ├── lazy.lua                 -- The heart of the configuration. Defines core settings, global keymaps, and Mason packages.
│   │   └── options.lua              -- Global Neovim options (`vim.opt`).
│   └── plugins/                     -- **Your customization area!** Add or override plugin configs here.
│       └── ...                      -- Each file is a plugin spec.
└── stylua.toml                      -- Code style configuration for this project's Lua files.
```

To add your own plugins, simply create a new file in the `lua/plugins/` directory.

## Troubleshooting

If `:checkhealth` reports issues with **Python** or **Node.js providers**, fix it by running:

```sh
npm install -g neovim
pip install pynvim
```

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
