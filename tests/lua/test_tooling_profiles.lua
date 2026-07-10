local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")

local function load_specs(profile, noninteractive)
    vim.env.CLARITY_PROFILE = profile
    vim.env.CLARITY_NONINTERACTIVE = noninteractive
    return dofile(repo_root .. "/nvim/lua/plugins/tooling.lua")
end

local function resolve(profile, noninteractive)
    local specs = load_specs(profile, noninteractive)
    local lsp = { servers = { lua_ls = {} } }
    local mason = { ensure_installed = { "existing-tool" } }
    specs[1].opts(nil, lsp)
    specs[2].opts(nil, mason)
    return lsp, mason
end

local core_lsp, core_mason = resolve(nil, nil)
assert(core_lsp.servers.lua_ls, "inherited core server must remain")
assert(vim.tbl_count(core_lsp.servers) == 1, "core profile must not add language servers")
assert(vim.deep_equal(core_mason.ensure_installed, { "existing-tool" }), "core profile must not add tools")

local dev_lsp, dev_mason = resolve("development", nil)
for _, server in ipairs({ "bashls", "clangd", "cmake", "pyright", "rust_analyzer", "ts_ls" }) do
    assert(dev_lsp.servers[server], "development server missing: " .. server)
end
for _, tool in ipairs({ "black", "clang-format", "cmakelang", "isort", "prettier", "shfmt", "stylua" }) do
    assert(vim.tbl_contains(dev_mason.ensure_installed, tool), "development tool missing: " .. tool)
end
assert(not vim.tbl_contains(dev_mason.ensure_installed, "rustfmt"), "rustfmt belongs to the Rust toolchain")

local test_lsp, test_mason = resolve("development", "1")
assert(vim.tbl_count(test_lsp.servers) == 1, "noninteractive startup must not add servers")
assert(
    vim.deep_equal(test_mason.ensure_installed, { "existing-tool" }),
    "noninteractive startup must not install tools"
)

vim.env.CLARITY_PROFILE = nil
vim.env.CLARITY_NONINTERACTIVE = nil
print("tooling profile tests: OK")
