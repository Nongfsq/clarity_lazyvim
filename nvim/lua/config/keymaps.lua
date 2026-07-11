-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set
local catalog = require("config.actions.catalog")
local i18n = require("config.i18n")
local policy = require("config.product_policy")
local opts = { remap = true, desc = "" }

-- Modes: n=Normal, i=Insert, v=Visual, x=Visual Block, o=Operator pending.

local function pick(command, pick_opts)
    return function()
        require("lazyvim.util.pick").open(command, pick_opts)
    end
end

local function label(action_id)
    return catalog.label(action_id, i18n.get_locale())
end

local function remove_global(items)
    for _, item in ipairs(items) do
        for _, mode in ipairs(item.modes) do
            pcall(vim.keymap.del, mode, item.lhs)
        end
    end
end

-- LazyVim loads its direct defaults immediately before this file. Remove only
-- the reviewed keys listed in product policy; never sweep unknown or user maps.
remove_global(policy.direct_removals())

local function clear_post_load(owner)
    remove_global(policy.post_load_removals(owner))
end

for _, owner in ipairs(policy.post_load_owners()) do
    clear_post_load(owner)
end

local surface_group = vim.api.nvim_create_augroup("clarity_action_surface", { clear = true })
vim.api.nvim_create_autocmd("User", {
    group = surface_group,
    pattern = "LazyLoad",
    callback = function(event)
        if type(event.data) == "string" then
            clear_post_load(event.data)
        end
    end,
})

-- LazyVim owns LSP and diagnostic mappings through buffer-local, capability-aware
-- handlers. Clarity only adds product-specific editing actions here.
opts.desc = label("code.fold_toggle")
map("n", "<leader>cz", require("config.actions.fold").toggle, opts)

-- Window management.
-- `<leader>-` / `<leader>|` / `<leader>wd` remain the primary paths from LazyVim.
-- Keep `<leader>wo` because it expresses a distinct "only keep current window" intent.
opts.desc = label("window.only")
map("n", "<leader>wo", "<C-w>o", opts)

-- Search.
-- `<leader>ff` / `<leader>fg` are still owned by the default LazyVim picker.
-- Keep `<leader>fw` as the repo-owned primary text-search path.
opts.desc = label("search.project_text")
map("n", "<leader>fw", pick("live_grep"), opts)

-- Keep the inherited LazyVim path stable while making the behavior Clarity-owned.
opts.desc = label("view.wrap_toggle")
map("n", "<leader>uw", function()
    vim.wo.wrap = not vim.wo.wrap
end, opts)

local function git_action(name)
    return function()
        return require("config.actions.git")[name]()
    end
end

for _, spec in ipairs({
    { "<leader>gb", "git.blame_line", "blame_line" },
    { "<leader>gd", "git.diff", "diff" },
    { "<leader>gl", "git.log", "log" },
    { "<leader>gs", "git.status", "status" },
    { "<leader>gt", "git.branch_graph", "branch_graph" },
}) do
    map("n", spec[1], git_action(spec[3]), { desc = label(spec[2]), silent = true })
end

local function ordinary_editable_buffer(bufnr)
    return vim.api.nvim_buf_is_valid(bufnr)
        and vim.bo[bufnr].buftype == ""
        and vim.bo[bufnr].modifiable
        and not vim.bo[bufnr].readonly
end

local function reconcile_buffer_autoformat_toggle(bufnr)
    if not ordinary_editable_buffer(bufnr) then
        pcall(vim.keymap.del, "n", "<leader>uF", { buffer = bufnr })
        return
    end
    map("n", "<leader>uF", function()
        LazyVim.format.toggle(true)
    end, {
        buffer = bufnr,
        desc = label("format.auto_buffer_toggle"),
        silent = true,
    })
end

vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, {
    group = surface_group,
    callback = function(event)
        reconcile_buffer_autoformat_toggle(event.buf)
    end,
})

vim.api.nvim_create_autocmd("OptionSet", {
    group = surface_group,
    pattern = { "buftype", "modifiable", "readonly" },
    callback = function(event)
        local bufnr = event.buf ~= 0 and event.buf or vim.api.nvim_get_current_buf()
        reconcile_buffer_autoformat_toggle(bufnr)
    end,
})

reconcile_buffer_autoformat_toggle(vim.api.nvim_get_current_buf())
