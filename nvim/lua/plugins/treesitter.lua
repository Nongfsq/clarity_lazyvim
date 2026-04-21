return {
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function()
            local noninteractive = vim.env.CLARITY_NONINTERACTIVE == "1" or #vim.api.nvim_list_uis() == 0

            return {
                ensure_installed = noninteractive and {} or {
                    "c",
                    "cpp",
                    "cmake",
                    "lua",
                    "rust",
                    "typescript",
                    "javascript",
                    "python",
                    "json",
                },
                highlight = {
                    enable = true,
                    additional_vim_regex_highlighting = false,
                },
                indent = { enable = true },
                context_commentstring = { enable = true, enable_autocmd = false },
                incremental_selection = {
                    enable = true,
                    keymaps = {
                        init_selection = "<C-space>",
                        node_incremental = "<C-space>",
                        scope_incremental = "<nop>",
                        node_decremental = "<bs>",
                    },
                },
            }
        end,
    },
}
