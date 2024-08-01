return {
    {
        "stevearc/conform.nvim",
        opts = {
            formatters_by_ft = {
                c = { "clang-format" },
                cpp = { "clang-format" },
                lua = { "stylua" },
                python = { "yapf", "isort" },
                rust = { "rustfmt" },
                javascript = { "prettier" },
                typescript = { "prettier" },
                json = { "prettier" },
                markdown = { "prettier" },
                cmake = { "cmake_format" },
                sh = { "shfmt" },
            },
            formatters = {
                clang_format = {
                    command = "clang-format",
                    args = { "--style=file" },
                },
                stylua = {
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
                },
                yapf = {
                    prepend_args = {
                        "--style",
                        "{based_on_style: pep8, indent_width: 4, column_limit: 79}",
                    },
                },
                isort = {
                    prepend_args = { "--profile", "black" },
                },
            },
        },
    },
}
