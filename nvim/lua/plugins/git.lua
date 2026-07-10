-- nvim/lua/plugins/git.lua

local i18n = require("config.i18n")

local function setup_hunk_keymaps(bufnr)
    if vim.b[bufnr].clarity_gitsigns_keymaps then
        return
    end

    local gs = package.loaded.gitsigns
    if not gs then
        return
    end

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

    map({ "n", "v" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", i18n.t("keymaps.stage_hunk"))
    map({ "n", "v" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", i18n.t("keymaps.reset_hunk"))
    map("n", "<leader>ghS", gs.stage_buffer, i18n.t("keymaps.stage_buffer"))
    map("n", "<leader>ghR", gs.reset_buffer, i18n.t("keymaps.reset_buffer"))
    map("n", "<leader>ghu", gs.undo_stage_hunk, i18n.t("keymaps.undo_stage_hunk"))

    map("n", "<leader>ghp", gs.preview_hunk, i18n.t("keymaps.preview_hunk"))
    map("n", "<leader>ghb", function()
        gs.blame_line({ full = true })
    end, i18n.t("keymaps.blame_line"))
    map("n", "<leader>ghd", gs.diffthis, i18n.t("keymaps.diff_this"))

    vim.b[bufnr].clarity_gitsigns_keymaps = true
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
