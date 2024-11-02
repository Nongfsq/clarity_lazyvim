# clarity_lazyvim 🌈✨

This configuration is highly friendly to colorblind users, especially those with red-green color blindness, and ensures color contrast without straining the eyes. It works best on macOS, providing highlights and bold keywords for better readability.

## Features 🌟

- **LazyVim**: Minimal and powerful configuration framework.
- **LSP Support**: Comprehensive language server integration.
- **Telescope**: Intuitive fuzzy finder.
- **Treesitter**: Enhanced syntax highlighting.
- **Autocompletion**: Smart coding suggestions.
- **Status Line**: Informative and aesthetic status line.
- **File Explorer**: Efficient file navigation.
- **Git Integration**: Seamless version control.
- **nvim-cursorword**: Only highlight the word under the cursor.
- **Theming**: Beautiful color schemes and icons.

## Installation 🛠️
0. **Ensure your Neovim version is 0.11.x or higher and install the following packages:**

Neovim
```sh
sudo add-apt-repository ppa:neovim-ppa/unstable
sudo apt update
sudo apt install neovim
nvim --version
```

Dependencies
```sh
# Update package list and install basic dependencies
sudo apt update && sudo apt install -y \
  neovim \
  nodejs npm \
  python3 python3-pip \
  git \
  ripgrep \
  fd-find \
  fonts-powerline \
  fonts-noto-color-emoji

# Install pynvim
pip install pynvim

# Install Node.js support for Neovim plugins
npm install -g neovim

# Install language servers
npm install -g pyright typescript typescript-language-server

# Install Rust toolchain (including rust-analyzer)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env
rustup component add rust-analyzer

# Install lua_ls
sudo apt install -y lua5.3
luarocks install lua-lsp

# Install clangd and cmake LSP
sudo apt install -y clangd cmake
```
1. **Backup Current Config**:
   ```sh
   mv ~/.config/nvim ~/.config/nvim_backup
   ```

2. **Clone Repository**:
   ```sh
   git clone https://github.com/Nongfsq/clarity_lazyvim.git
   ```
   then...
   ```sh
   mv ./clarity_lazyvim/nvim ~/.config/
   ```

3. **Install Plugins**:
    ```sh
    rm -rf ~/.local/share/
    rm -rf ~/.cache/nvim/
    nvim
    ```
## Key Bindings ⌨️

1. Open Neovim, and with any file open, 
       simply press <leader> (usually the space key) to view all the shortcut key descriptions.

2. clarity_lazyvim/nvim/lua/plugins/lsp.lua

## License 📄

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

Happy coding! 🚀
