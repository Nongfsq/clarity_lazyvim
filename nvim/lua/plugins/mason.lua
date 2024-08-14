return {
    "williamboman/mason.nvim",
    opts = {
        ui = {
            check_outdated_packages_on_open = true,
            border = "rounded",
            width = 0.8,
            height = 0.8,
            icons = {
                package_installed = "✓",
                package_pending = "➜",
                package_uninstalled = "✗",
            },
        },
        ensure_installed = {
            -- Language servers
            "clangd", -- C/C++
            "rust-analyzer", -- Rust
            "pyright", -- Python
            "lua-language-server", -- Lua
            "typescript-language-server", -- JavaScript/TypeScript

            -- Formatters and linters
            "clang-format", -- C/C++
            "rustfmt", -- Rust
            "stylua", -- Lua
            "yapf", -- Python
            "isort", -- Python (import sorting)
            "prettier", -- JavaScript/TypeScript/JSON/Markdown
            "cmakelint", -- CMake
            "shfmt", -- Shell scripts

            -- Additional tools
            "cmake-language-server", -- CMake (additional support)
        },
    },
    config = function(_, opts)
        require("mason").setup(opts)
        local mr = require "mason-registry"
        local function ensure_installed()
            for _, tool in ipairs(opts.ensure_installed) do
                local p = mr.get_package(tool)
                if not p:is_installed() then
                    p:install()
                end
            end
        end
        if mr.refresh then
            mr.refresh(ensure_installed)
        else
            ensure_installed()
        end
    end,
}
