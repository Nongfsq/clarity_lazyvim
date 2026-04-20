-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
-- nvim/lua/config/keymaps.lua (添加在文件末尾)

local map = vim.keymap.set
local opts = { remap = true, desc = "" }

-- 模式: n=Normal, i=Insert, v=Visual, x=Visual Block, o=Operator pending

local function pick(command, pick_opts)
  return function()
    require("lazyvim.util.pick").open(command, pick_opts)
  end
end

-- LSP & 诊断
opts.desc = "跳转到 [声]明处"
map("n", "gD", vim.lsp.buf.declaration, opts)
opts.desc = "跳转到 [定]义处"
map("n", "gd", vim.lsp.buf.definition, opts)
opts.desc = "[查]看文档 (Hover)"
map("n", "K", vim.lsp.buf.hover, opts)
opts.desc = "跳转到 [实]现处"
map("n", "gi", vim.lsp.buf.implementation, opts)
opts.desc = "查找所有[引]用"
map("n", "gr", vim.lsp.buf.references, opts)
opts.desc = "💡 [重]命名"
map("n", "<leader>cr", vim.lsp.buf.rename, opts)
opts.desc = "💡 代码[操]作"
map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
opts.desc = "查看单行[错]误"
map("n", "gl", vim.diagnostic.open_float, opts)
opts.desc = "上一个[错]误"
map("n", "[d", vim.diagnostic.goto_prev, opts)
opts.desc = "下一个[错]误"
map("n", "]d", vim.diagnostic.goto_next, opts)

-- 窗口管理
-- `<leader>-` / `<leader>|` / `<leader>wd` 由 LazyVim 默认映射提供主路径。
-- 这里只保留 `<leader>wo`，因为它表达的是“仅保留当前窗口”。
opts.desc = "[窗]口 - 仅保留当前"
map("n", "<leader>wo", "<C-w>o", opts)

-- 搜索
-- `<leader>ff` / `<leader>fg` 由 LazyVim 默认搜索器接管。
-- 这里只保留 `<leader>fw` 作为中文工作流里的文本搜索别名。
opts.desc = "🔍 [查]找 - [文]本内容"
map("n", "<leader>fw", pick("live_grep"), opts)
