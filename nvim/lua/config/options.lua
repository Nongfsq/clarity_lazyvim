-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local M = {}

function M.configure_clipboard(session)
    session = session
        or {
            ssh = (vim.env.SSH_CONNECTION or "") ~= "" or (vim.env.SSH_TTY or "") ~= "",
            display = (vim.env.DISPLAY or "") ~= "" or (vim.env.WAYLAND_DISPLAY or "") ~= "",
        }

    if session.ssh and not session.display and vim.g.clipboard == nil then
        -- Set this before provider detection. OSC52 reliably supports remote
        -- copy; terminal paste remains the supported inbound path.
        vim.g.clipboard = "osc52"
    end

    vim.opt.clipboard:append("unnamedplus")
    return vim.g.clipboard
end

M.configure_clipboard()

vim.opt.number = true -- Always show absolute line numbers in normal editing windows.
vim.opt.relativenumber = false -- Disable relative line numbers for beginner-friendly navigation.

-- Keep which-key responsive without making leader combos too hard to type.
vim.o.timeoutlen = 200
-- Set timeout for terminal key mappings (in milliseconds)
-- vim.o.ttimeoutlen = 50

-- Number of lines to scroll when cursor is off-screen
-- vim.o.scrolljump = 5

local opt = vim.opt

-- Prefer a stable terminal experience over extra visual effects.
opt.cursorline = false -- Avoid cursorline redraw churn in terminal-based workflows.
opt.list = false -- Hide invisible markers to reduce visual noise and stray separator artifacts.
opt.smoothscroll = false -- Disable smooth scrolling to keep motion snappy in terminals.
opt.statuscolumn = "" -- Use the default status column to avoid custom terminal rendering artifacts.
opt.wrap = true -- Visually wrap long lines without inserting newlines into the file.
opt.linebreak = true -- Prefer wrapping at word boundaries when possible.
opt.breakindent = true -- Preserve indentation on visually wrapped continuation lines.
opt.conceallevel = 0 -- Never hide source characters in ordinary code buffers.

-- Indentation widths and tab/space style belong to project and filetype policy.
opt.autoindent = true -- Copy indent from current line when starting a new line.

return M
