return {
    {
        "stevearc/conform.nvim",
        opts = function(_, opts)
            opts.formatters_by_ft = opts.formatters_by_ft or {}
            opts.formatters = opts.formatters or {}
            opts.default_format_opts = opts.default_format_opts or {}

            -- Formatter names are configuration, not startup-time capability
            -- checks. Conform resolves availability when formatting is requested.
            local by_ft = {
                c = { "clang-format" },
                cpp = { "clang-format" },
                lua = { "stylua" },
                python = { "isort", "black" },
                rust = { "rustfmt" },
                javascript = { "prettier" },
                typescript = { "prettier" },
                javascriptreact = { "prettier" },
                typescriptreact = { "prettier" },
                json = { "prettier" },
                markdown = { "prettier" },
                cmake = { "cmake_format" },
                sh = { "shfmt" },
            }
            for filetype, formatters in pairs(by_ft) do
                opts.formatters_by_ft[filetype] = formatters
            end

            -- Preserve LazyVim's formatting pipeline and use LSP only when no
            -- configured external formatter is available.
            opts.default_format_opts.lsp_format = "fallback"

            -- Clarity owns formatter routing, not repository style. Project
            -- configuration and formatter defaults decide indentation, line
            -- width, quotes, and line endings so a review session cannot create
            -- unrelated formatting churn.
            opts.formatters.cmake_format = { command = "cmake-format" }
            return opts
        end,
    },
}
