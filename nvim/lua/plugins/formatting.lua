return {
  {
    "stevearc/conform.nvim",
    opts = function()
      local function has(command)
        return vim.fn.executable(command) == 1
      end

      local function enabled(formatter_specs)
        local active = {}

        for _, spec in ipairs(formatter_specs) do
          local formatter = spec
          local command = spec

          if type(spec) == "table" then
            formatter = spec.formatter
            command = spec.command
          end

          if has(command) then
            table.insert(active, formatter)
          end
        end

        return active
      end

      local formatters_by_ft = {
        c = enabled { "clang-format" },
        cpp = enabled { "clang-format" },
        lua = enabled { "stylua" },
        python = enabled { "isort", "black" },
        rust = enabled { "rustfmt" },
        javascript = enabled { "prettier" },
        typescript = enabled { "prettier" },
        javascriptreact = enabled { "prettier" },
        typescriptreact = enabled { "prettier" },
        json = enabled { "prettier" },
        markdown = enabled { "prettier" },
        cmake = enabled { { formatter = "cmake_format", command = "cmake-format" } },
        sh = enabled { "shfmt" },
      }

      return {
        formatters_by_ft = formatters_by_ft,
        formatters = {
          ["clang-format"] = {
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
              "lf",
            },
          },
          cmake_format = {
            command = "cmake-format",
          },
        },
      }
    end,
  },
}
