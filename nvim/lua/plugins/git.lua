-- nvim/lua/plugins/git.lua

local i18n = require("config.i18n")
local product_policy = require("config.product_policy")
local function remove_inherited_maps(bufnr)
    for _, removal in ipairs(product_policy.buffer_attach_removals("gitsigns.nvim")) do
        for _, mode in ipairs(removal.modes) do
            local lhs = removal.lhs
            pcall(vim.keymap.del, mode, lhs, { buffer = bufnr })
        end
    end
end

local function setup_hunk_keymaps(bufnr)
    local gs = package.loaded.gitsigns
    if not gs then
        return
    end

    -- LazyVim owns attachment. Clarity prunes its write/duplicate surface after
    -- every attachment so a detach/reattach cannot restore repository mutation.
    remove_inherited_maps(bufnr)

    local function map(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc, silent = true })
    end

    local function hunk_nav(next_hunk)
        return function()
            if vim.wo.diff then
                vim.cmd.normal({ next_hunk and "]c" or "[c", bang = true })
                return
            end
            vim.schedule(function()
                gs.nav_hunk(next_hunk and "next" or "prev")
            end)
        end
    end

    map("n", "]h", hunk_nav(true), i18n.t("keymaps.next_hunk"))
    map("n", "[h", hunk_nav(false), i18n.t("keymaps.prev_hunk"))
    local preview = gs.preview_hunk_inline or gs.preview_hunk
    if preview then
        map("n", "<leader>ghp", preview, i18n.t("keymaps.preview_hunk"))
    end
end

return {
    {
        "lewis6991/gitsigns.nvim",
        opts = function(_, opts)
            local upstream_on_attach = opts.on_attach
            opts.on_attach = function(bufnr)
                if upstream_on_attach then
                    upstream_on_attach(bufnr)
                end
                setup_hunk_keymaps(bufnr)
            end
            return opts
        end,
    },
}
