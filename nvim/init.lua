-- print("1. Start of init.lua")

-- print("2. Before loading LazyVim")
-- 加载 LazyVim 配置
require "config.lazy"
require "lspconfig"
require "mason-lspconfig"
require "dashboard"
require "plugins.formatting"
require "neo-tree"
require "nvim-treesitter"

-- print("3. After loading LazyVim")
-- 加载 Mason 和 LSP 配置
-- print("4. End of init.lua")

-- init.lua or plugins.lua
