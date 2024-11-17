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
    # Options1: Linux
    sudo add-apt-repository ppa:neovim-ppa/unstable
    sudo apt update
    sudo apt install neovim
    nvim --version

    # Options2: macOS
    git clone https://github.com/neovim/neovim.git
    cd neovim
    git checkout release-0.11
    make CMAKE_BUILD_TYPE=RelWithDebInfo
    sudo make install
    nvim --version
    ```
    
    Dependencies
    ```sh
    # Update package list and install basic dependencies
    # Options1: Linux
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

    # Install Julia
    curl -fsSL https://install.julialang.org | sh
    
    # Install LazyGit (fetch the latest version automatically)
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit /usr/local/bin
    
    # Install LuaRocks (for Lua dependencies)
    sudo apt install -y luarocks
    
    # Reinstall Node.js support for Neovim plugins (if needed)
    sudo npm install -g neovim


    #Options2: macOS
    brew install neovim node npm python3 git ripgrep fd
    python3 -m venv ~/.neovim_env
    source ~/.neovim_env/bin/activate
    pip install pynvim
    python -m pip show pynvim
     # Install Node.js support for Neovim plugins
    npm install -g neovim
    
    # Install language servers
    npm install -g pyright typescript typescript-language-server
    
    # Install Rust toolchain (including rust-analyzer)
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
    rustup component add rust-analyzer
    brew install lua@5.3 luarocks llvm cmake lazygit && \
    luarocks install lua-lsp && \
    curl -fsSL https://install.julialang.org | sh && \
    npm install -g neovim && \
    echo 'export PATH="/opt/homebrew/opt/llvm/bin:$HOME/.julia/bin:$PATH"' >> ~/.zshrc && \
    source ~/.zshrc
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
