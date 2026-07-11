local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
local spec = dofile(repo_root .. "/nvim/lua/plugins/formatting.lua")[1]

assert(type(spec.opts) == "function", "Conform must extend inherited opts")
assert(spec.config == nil, "Clarity must not own Conform setup")

local inherited_ft = { go = { "gofmt" } }
local inherited_formatter = { command = "existing" }
local opts = {
    formatters_by_ft = inherited_ft,
    formatters = { inherited = inherited_formatter },
    default_format_opts = { timeout_ms = 321 },
}
local resolved = spec.opts(nil, opts)
assert(resolved == opts, "Conform extension must preserve incoming opts identity")
assert(resolved.formatters_by_ft.go == inherited_ft.go, "inherited filetype formatter must survive")
assert(resolved.formatters.inherited == inherited_formatter, "inherited formatter must survive")
assert(resolved.default_format_opts.timeout_ms == 321, "inherited format options must survive")
assert(resolved.default_format_opts.lsp_format == "fallback", "LSP fallback must remain enabled")
assert(vim.deep_equal(resolved.formatters_by_ft.python, { "isort", "black" }), "Python chain missing")
assert(vim.deep_equal(resolved.formatters_by_ft.lua, { "stylua" }), "Lua formatter missing")
for _, formatter in ipairs({ "clang-format", "stylua", "black", "isort", "prettier" }) do
    assert(resolved.formatters[formatter] == nil, "Clarity must not own style arguments for " .. formatter)
end
assert(resolved.formatters.cmake_format.command == "cmake-format", "cmake-format executable route missing")

local source = table.concat(vim.fn.readfile(repo_root .. "/nvim/lua/plugins/formatting.lua"), "\n")
assert(not source:find("vim.fn.executable", 1, true), "formatter availability must not freeze at startup")
for _, forbidden in ipairs({ "prepend_args", "--line-length", "--print-width", "--indent-width", "--style=file" }) do
    assert(not source:find(forbidden, 1, true), "global formatter style remains: " .. forbidden)
end

local options_source = table.concat(vim.fn.readfile(repo_root .. "/nvim/lua/config/options.lua"), "\n")
for _, forbidden in ipairs({ "opt.tabstop", "opt.softtabstop", "opt.shiftwidth", "opt.expandtab", "opt.smartindent" }) do
    assert(not options_source:find(forbidden, 1, true), "global indentation style remains: " .. forbidden)
end
print("formatting ownership tests: OK")
