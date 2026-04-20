-- nvim/lua/config/lazy.lua (最终的、整合的、黄金标准版本)

local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
local noninteractive = vim.env.CLARITY_NONINTERACTIVE == "1" or #vim.api.nvim_list_uis() == 0
local mason_packages = {
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
}

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
          ensure_installed = noninteractive and {} or mason_packages,
        },
      },
    },

    -- 显式聚合自定义插件，避免在非标准 config 根目录下导入失败
    require "plugins",
  },

  -- 其他 Lazy 配置
  defaults = { lazy = false, version = false },
  install = { colorscheme = { "habamax" } },
  checker = { enabled = not noninteractive },
  performance = {
    rtp = {
      disabled_plugins = { "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin" },
    },
  },
}

require("config.audit").setup()
require("config.help").setup()
require("config.validation").setup()

