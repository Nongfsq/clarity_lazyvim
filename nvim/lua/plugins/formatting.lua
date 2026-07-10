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

            opts.formatters["clang-format"] = { prepend_args = { "--style=file" } }
            opts.formatters.stylua = {
                prepend_args = {
                    "--indent-type",
                    "Spaces",
                    "--indent-width",
                    "4",
                    "--quote-style",
                    "AutoPreferDouble",
                    "--call-parentheses",
                    "None",
                },
            }
            opts.formatters.black = { prepend_args = { "--line-length", "120" } }
            opts.formatters.isort = { prepend_args = { "--profile", "black" } }
            opts.formatters.prettier = {
                prepend_args = {
                    "--print-width",
                    "120",
                    "--tab-width",
                    "4",
                    "--use-tabs",
                    "false",
                    "--end-of-line",
                    "lf",
                },
            }
            opts.formatters.cmake_format = { command = "cmake-format" }
            return opts
        end,
    },
}
