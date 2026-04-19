-- nvim/lua/config/lazy.lua (最终的、整合的、黄金标准版本)

local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup {
  spec = {
    {
      "LazyVim/LazyVim",
      import = "lazyvim.plugins",
      opts = {
        -- 在这里配置 Mason
        mason = {
          ensure_installed = {
            "lua_ls",
            "clangd",
            "rust_analyzer",
            "pyright",
            "ts_ls",
            "bashls",
            "cmake",
            "stylua",
            "clang-format",
            "rustfmt",
            "black",
            "isort",
            "prettier",
            "shfmt",
            "cmake-format",
          },
        },
      },
    },

    -- 显式聚合自定义插件，避免在非标准 config 根目录下导入失败
    require "plugins",
  },

  -- 其他 Lazy 配置
  defaults = { lazy = false, version = false },
  install = { colorscheme = { "habamax" } },
  checker = { enabled = true },
  performance = {
    rtp = {
      disabled_plugins = { "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin" },
    },
  },
}

require("config.audit").setup()

