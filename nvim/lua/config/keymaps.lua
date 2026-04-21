-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set
local i18n = require "config.i18n"
local opts = { remap = true, desc = "" }

-- Modes: n=Normal, i=Insert, v=Visual, x=Visual Block, o=Operator pending.

local function pick(command, pick_opts)
  return function()
    require("lazyvim.util.pick").open(command, pick_opts)
  end
end

-- LSP and diagnostics.
opts.desc = i18n.t "keymaps.declaration"
map("n", "gD", vim.lsp.buf.declaration, opts)
opts.desc = i18n.t "keymaps.definition"
map("n", "gd", vim.lsp.buf.definition, opts)
opts.desc = i18n.t "keymaps.hover"
map("n", "K", vim.lsp.buf.hover, opts)
opts.desc = i18n.t "keymaps.implementation"
map("n", "gi", vim.lsp.buf.implementation, opts)
opts.desc = i18n.t "keymaps.references"
map("n", "gr", vim.lsp.buf.references, opts)
opts.desc = i18n.t "keymaps.rename"
map("n", "<leader>cr", vim.lsp.buf.rename, opts)
opts.desc = i18n.t "keymaps.code_action"
map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
opts.desc = i18n.t "keymaps.line_diagnostic"
map("n", "gl", vim.diagnostic.open_float, opts)
opts.desc = i18n.t "keymaps.prev_diagnostic"
map("n", "[d", vim.diagnostic.goto_prev, opts)
opts.desc = i18n.t "keymaps.next_diagnostic"
map("n", "]d", vim.diagnostic.goto_next, opts)

-- Window management.
-- `<leader>-` / `<leader>|` / `<leader>wd` remain the primary paths from LazyVim.
-- Keep `<leader>wo` because it expresses a distinct "only keep current window" intent.
opts.desc = i18n.t "keymaps.keep_only_window"
map("n", "<leader>wo", "<C-w>o", opts)

-- Search.
-- `<leader>ff` / `<leader>fg` are still owned by the default LazyVim picker.
-- Keep `<leader>fw` as the repo-owned primary text-search path.
opts.desc = i18n.t "keymaps.search_text"
map("n", "<leader>fw", pick("live_grep"), opts)
