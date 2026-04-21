-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.number = true -- Always show absolute line numbers in normal editing windows.
vim.opt.relativenumber = false -- Disable relative line numbers for beginner-friendly navigation.

-- Keep which-key responsive without making leader combos too hard to type.
vim.o.timeoutlen = 200
-- Set timeout for terminal key mappings (in milliseconds)
-- vim.o.ttimeoutlen = 50

-- Number of lines to scroll when cursor is off-screen
-- vim.o.scrolljump = 5

-- --- Indentation Settings ---
local opt = vim.opt

-- Prefer a stable terminal experience over extra visual effects.
opt.cursorline = false -- Avoid cursorline redraw churn in terminal-based workflows.
opt.list = false -- Hide invisible markers to reduce visual noise and stray separator artifacts.
opt.smoothscroll = false -- Disable smooth scrolling to keep motion snappy in terminals.
opt.statuscolumn = "" -- Use the default status column to avoid custom terminal rendering artifacts.

opt.tabstop = 4 -- Number of spaces that a <Tab> in the file counts for.
opt.softtabstop = 4 -- Number of spaces that a <Tab> counts for while performing editing operations.
opt.shiftwidth = 4 -- Number of spaces to use for each step of (auto)indent.
opt.expandtab = true -- Use spaces instead of tabs.
opt.smartindent = true -- Makes indenting smart.
opt.autoindent = true -- Copy indent from current line when starting a new line.
