return {
    {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
            opts.servers = opts.servers or {}
            return opts
        end,
    },
    {
        "mason-org/mason.nvim",
        opts = function(_, opts)
            opts.ensure_installed = {}
            return opts
        end,
    },
}
