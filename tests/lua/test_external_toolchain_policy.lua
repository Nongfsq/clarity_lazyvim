local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")

local tooling = assert(loadfile(repo_root .. "/nvim/lua/plugins/tooling.lua"))()
local treesitter = assert(loadfile(repo_root .. "/nvim/lua/plugins/treesitter.lua"))()

assert(#tooling == 2, "LSP and Mason policy specs are required")
local lsp_opts = tooling[1].opts(nil, {})
local mason_opts = tooling[2].opts(nil, { ensure_installed = { "upstream-default" } })
local treesitter_opts = treesitter[1].opts(nil, { ensure_installed = { "upstream-default" } })
assert(vim.tbl_isempty(lsp_opts.servers), "Clarity must not provision language servers")
assert(vim.tbl_isempty(mason_opts.ensure_installed), "Clarity must not provision Mason tools")
assert(vim.tbl_isempty(treesitter_opts.ensure_installed), "Clarity must not provision parsers")

for _, path in ipairs({
    repo_root .. "/nvim/lua/plugins/tooling.lua",
    repo_root .. "/nvim/lua/plugins/treesitter.lua",
}) do
    local source = table.concat(vim.fn.readfile(path), "\n")
    assert(not source:find("CLARITY_PROFILE", 1, true), "toolchain policy must not have an environment profile")
    for _, forbidden in ipairs({ "bashls", "clangd", "pyright", "rust_analyzer", "ts_ls", "prettier", "stylua" }) do
        assert(not source:find(forbidden, 1, true), "curated global tool remains: " .. forbidden)
    end
end

print("external toolchain policy tests: OK")
