local development_enabled = vim.env.CLARITY_PROFILE == "development" and vim.env.CLARITY_NONINTERACTIVE ~= "1"

local language_servers = {
    "bashls",
    "clangd",
    "cmake",
    "pyright",
    "rust_analyzer",
    "ts_ls",
}

local mason_tools = {
    "black",
    "clang-format",
    "cmakelang",
    "isort",
    "prettier",
    "shfmt",
    "stylua",
}

return {
    {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
            opts.servers = opts.servers or {}
            if development_enabled then
                for _, server in ipairs(language_servers) do
                    opts.servers[server] = opts.servers[server] or {}
                end
            end
            return opts
        end,
    },
    {
        "mason-org/mason.nvim",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            if development_enabled then
                vim.list_extend(opts.ensure_installed, mason_tools)
            end
            return opts
        end,
    },
}
