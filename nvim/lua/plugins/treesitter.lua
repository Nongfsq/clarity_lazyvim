local development_enabled = vim.env.CLARITY_PROFILE == "development" and vim.env.CLARITY_NONINTERACTIVE ~= "1"

local development_parsers = {
    "bash",
    "c",
    "cmake",
    "cpp",
    "javascript",
    "json",
    "lua",
    "markdown",
    "markdown_inline",
    "python",
    "query",
    "rust",
    "tsx",
    "typescript",
    "vim",
    "vimdoc",
}

return {
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            -- The locked main generation is configured by LazyVim's native
            -- setup/start/fold/indent lifecycle. Clarity only owns its parser
            -- profile; legacy module-style options do not belong here.
            opts.ensure_installed = development_enabled and vim.deepcopy(development_parsers) or {}
            return opts
        end,
    },
}
