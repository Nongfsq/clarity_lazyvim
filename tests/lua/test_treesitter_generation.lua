local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")

local function resolve(profile, noninteractive)
    vim.env.CLARITY_PROFILE = profile
    vim.env.CLARITY_NONINTERACTIVE = noninteractive
    local spec = dofile(repo_root .. "/nvim/lua/plugins/treesitter.lua")[1]
    local opts = {
        highlight = { enable = true },
        indent = { enable = true },
        folds = { enable = true },
        ensure_installed = { "upstream" },
    }
    local resolved = spec.opts(nil, opts)
    return spec, opts, resolved
end

local core_spec, core_opts, core_resolved = resolve(nil, nil)
assert(core_resolved == core_opts, "Tree-sitter must preserve incoming opts identity")
assert(core_spec.config == nil, "LazyVim must retain Tree-sitter setup ownership")
assert(vim.deep_equal(core_opts.ensure_installed, {}), "core profile must not start parser installs")
assert(core_opts.highlight.enable and core_opts.indent.enable and core_opts.folds.enable, "upstream features lost")

local _, dev_opts = resolve("development", nil)
for _, parser in ipairs({ "bash", "c", "cmake", "cpp", "lua", "python", "rust", "typescript", "vim" }) do
    assert(vim.tbl_contains(dev_opts.ensure_installed, parser), "development parser missing: " .. parser)
end

local _, test_opts = resolve("development", "1")
assert(vim.deep_equal(test_opts.ensure_installed, {}), "noninteractive profile must not install parsers")

local source = table.concat(vim.fn.readfile(repo_root .. "/nvim/lua/plugins/treesitter.lua"), "\n")
for _, legacy in ipairs({ "context_commentstring", "incremental_selection", "additional_vim_regex_highlighting" }) do
    assert(not source:find(legacy, 1, true), "legacy Tree-sitter option remains: " .. legacy)
end

vim.env.CLARITY_PROFILE = nil
vim.env.CLARITY_NONINTERACTIVE = nil
print("Tree-sitter generation tests: OK")
