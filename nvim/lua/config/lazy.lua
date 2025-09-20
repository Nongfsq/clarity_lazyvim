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

require("lazy").setup({
  spec = {
    {
      "LazyVim/LazyVim",
      import = "lazyvim.plugins",
      opts = {
        -- 在这里配置 Mason
        mason = {
          ensure_installed = {
            "lua_ls", "clangd", "rust_analyzer", "pyright", "tsserver", "bashls", "cmake",
            "stylua", "clang-format", "rustfmt", "black", "isort", "prettier", "shfmt", "cmake-format",
          },
        },
        
        
        
        -- 在这里定义所有的全局快捷键
        keys = {
          -- LSP & 诊断
          { "gD", "<cmd>lua vim.lsp.buf.declaration()<cr>", desc = "跳转到 [声]明处" },
          { "gd", "<cmd>lua vim.lsp.buf.definition()<cr>", desc = "跳转到 [定]义处" },
          { "K", "<cmd>lua vim.lsp.buf.hover()<cr>", desc = "[查]看文档 (Hover)" },
          { "gi", "<cmd>lua vim.lsp.buf.implementation()<cr>", desc = "跳转到 [实]现处" },
          { "gr", "<cmd>lua vim.lsp.buf.references()<cr>", desc = "查找所有[引]用" },
          { "<leader>cr", "<cmd>lua vim.lsp.buf.rename()<cr>", desc = "💡 [重]命名" },
          { "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<cr>", desc = "💡 代码[操]作", mode = { "n", "v" } },
          { "gl", "<cmd>lua vim.diagnostic.open_float()<cr>", desc = "查看单行[错]误" },
          { "[d", "<cmd>lua vim.diagnostic.goto_prev()<cr>", desc = "上一个[错]吾" },
          { "]d", "<cmd>lua vim.diagnostic.goto_next()<cr>", desc = "下一个[错]误" },
          
          -- 窗口管理
          { "<leader>w-", "<C-w>s", desc = "[窗]口 - 水平分割" },
          { "<leader>w|", "<C-w>v", desc = "[窗]口 - 垂直分割" },
          { "<leader>wc", "<C-w>c", desc = "[窗]口 - 关闭当前" },
          { "<leader>wo", "<C-w>o", desc = "[窗]口 - 仅保留当前" },

          -- 缓冲区 (Tabs) 管理
          { "<leader>bn", "<cmd>bnext<CR>", desc = "[标]签页 - 下一个" },
          { "<leader>bp", "<cmd>bprevious<CR>", desc = "[标]签页 - 上一个" },
          { "<leader>bc", "<cmd>bdelete<CR>", desc = "[标]签页 - [关]闭当前" },
        },
      },
    },

    -- 导入你的所有自定义插件
    { import = "plugins" },
  },

  -- 其他 Lazy 配置
  defaults = { lazy = false, version = false },
  install = { colorscheme = { "tokyonight", "habamax" } },
  checker = { enabled = true },
  performance = {
    rtp = {
      disabled_plugins = { "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin" },
    },
  },
})