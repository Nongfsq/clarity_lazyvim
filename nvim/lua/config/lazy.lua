-- Final integrated lazy.nvim bootstrap for the Clarity runtime.

-- Clarity owns Neo-tree as its only file explorer. LazyVim 8 otherwise selects
-- Snacks Explorer by default, which makes both explorers handle directory startup.
vim.g.lazyvim_explorer = "neo-tree"

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local noninteractive = vim.env.CLARITY_NONINTERACTIVE == "1" or #vim.api.nvim_list_uis() == 0
local function bundled_runtime_paths()
    local paths = {}
    local seen = {}

    local function add(path)
        if path and path ~= "" and vim.fn.isdirectory(path) == 1 and not seen[path] then
            seen[path] = true
            table.insert(paths, path)
        end
    end

    local parser_suffix = vim.fn.has("win32") == 1 and ".dll" or ".so"
    for _, parser in ipairs(vim.api.nvim_get_runtime_file("parser/vim" .. parser_suffix, true)) do
        add(vim.fn.fnamemodify(parser, ":p:h:h"))
    end

    local lib = vim.fn.fnamemodify(vim.v.progpath, ":p:h:h") .. "/lib"
    if vim.uv.fs_stat(lib .. "64") then
        lib = lib .. "64"
    end
    add(lib .. "/nvim")

    for _, pattern in ipairs({
        "/usr/lib/*/nvim",
        "/usr/local/lib/*/nvim",
        "/usr/lib/nvim",
        "/usr/local/lib/nvim",
        "/opt/homebrew/lib/nvim",
    }) do
        for _, path in ipairs(vim.fn.glob(pattern, false, true)) do
            add(path)
        end
    end

    return paths
end

local mason_packages = {
    "lua_ls",
    "clangd",
    "rust_analyzer",
    "pyright",
    "ts_ls",
    "bashls",
    "cmake",
    "stylua",
    "clang-format",
    "rustfmt",
    "black",
    "isort",
    "prettier",
    "shfmt",
    "cmake-format",
}

if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    spec = {
        {
            "LazyVim/LazyVim",
            import = "lazyvim.plugins",
            opts = {
                -- Configure Mason-managed tools here.
                mason = {
                    ensure_installed = noninteractive and {} or mason_packages,
                },
            },
        },

        -- Aggregate repo-owned plugins explicitly so nested config roots still load reliably.
        require("plugins"),
    },

    -- Remaining lazy.nvim defaults.
    defaults = { lazy = false, version = false },
    install = { colorscheme = { "habamax" } },
    checker = { enabled = not noninteractive },
    performance = {
        rtp = {
            paths = bundled_runtime_paths(),
            disabled_plugins = { "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin" },
        },
    },
})

require("config.i18n").setup()
require("config.menu_i18n").setup()
require("config.audit").setup()
require("config.help").setup()
require("config.validation").setup()
