return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        c = { "clang-format" },
        cpp = { "clang-format" },
        lua = { "stylua" },
        python = { "black", "isort" },
        rust = { "rustfmt" },
        javascript = { "eslint_d" },
        typescript = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        typescriptreact = { "eslint_d" },
        json = { "jsonlint" },
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
            "2",
            "--quote-style",
            "AutoPreferDouble",
            "--call-parentheses",
            "None",
          },
        },
        black = {
          prepend_args = { "--line-length", "120" },
        },
        isort = {
          prepend_args = { "--profile", "black" },
        },
        eslint_d = {
          command = "eslint_d",
          args = { "--fix-to-stdout", "--stdin", "--stdin-filename", "$FILENAME" },
          stdin = true,
        },
        jsonlint = {
          command = "jsonlint",
          args = { "--indent", "    ", "--compact" },
        },
        prettier = {
          command = "prettier",
          args = {
            "--print-width",
            "120",
            "--tab-width",
            "4",
            "--use-tabs",
            "false",
            "--end-of-line",
            "crlf",
          },
        },
      },
    },
  },
}
