-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.relativenumber = false -- Show numberline instead of relative number

-- Set timeout for key mappings (in milliseconds)
-- vim.o.timeoutlen = 100
-- Set timeout for terminal key mappings (in milliseconds)
-- vim.o.ttimeoutlen = 50

-- Number of lines to scroll when cursor is off-screen
-- vim.o.scrolljump = 5

-- --- Indentation Settings ---
local opt = vim.opt

opt.tabstop = 4 -- Number of spaces that a <Tab> in the file counts for.
opt.softtabstop = 4 -- Number of spaces that a <Tab> counts for while performing editing operations.
opt.shiftwidth = 4 -- Number of spaces to use for each step of (auto)indent.
opt.expandtab = true -- Use spaces instead of tabs.
opt.smartindent = true -- Makes indenting smart.
opt.autoindent = true -- Copy indent from current line when starting a new line.

