-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set
local i18n = require("config.i18n")
local opts = { remap = true, desc = "" }

-- Modes: n=Normal, i=Insert, v=Visual, x=Visual Block, o=Operator pending.

local function pick(command, pick_opts)
    return function()
        require("lazyvim.util.pick").open(command, pick_opts)
    end
end

-- LazyVim owns LSP and diagnostic mappings through buffer-local, capability-aware
-- handlers. Clarity only adds product-specific editing actions here.
opts.desc = i18n.t("keymaps.toggle_fold")
map("n", "<leader>cz", require("config.actions.fold").toggle, opts)

-- Window management.
-- `<leader>-` / `<leader>|` / `<leader>wd` remain the primary paths from LazyVim.
-- Keep `<leader>wo` because it expresses a distinct "only keep current window" intent.
opts.desc = i18n.t("keymaps.keep_only_window")
map("n", "<leader>wo", "<C-w>o", opts)

-- Search.
-- `<leader>ff` / `<leader>fg` are still owned by the default LazyVim picker.
-- Keep `<leader>fw` as the repo-owned primary text-search path.
opts.desc = i18n.t("keymaps.search_text")
map("n", "<leader>fw", pick("live_grep"), opts)

-- Keep the inherited LazyVim path stable while making the behavior Clarity-owned.
opts.desc = i18n.t("keymaps.toggle_wrap")
map("n", "<leader>uw", function()
    vim.wo.wrap = not vim.wo.wrap
end, opts)
