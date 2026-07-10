local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
local nvim_root = repo_root .. "/nvim"
vim.opt.runtimepath:prepend(nvim_root)

local init_source = table.concat(vim.fn.readfile(nvim_root .. "/init.lua"), "\n")
local spec_source = table.concat(vim.fn.readfile(nvim_root .. "/lua/plugins/colorscheme.lua"), "\n")
assert(not init_source:find("dofile", 1, true), "init must not source a colorscheme directly")
assert(
    spec_source:find('colorscheme = "custom_colorblind_theme"', 1, true),
    "LazyVim must own the custom colorscheme selection"
)
assert(not spec_source:find('colorscheme = "habamax"', 1, true), "habamax must only be a failure fallback")

-- The policy runner intentionally starts with a clean runtimepath. Runtime
-- color assertions run when the locked Lush dependency is available; static
-- lifecycle assertions above remain mandatory in every environment.
if not pcall(require, "lush") then
    print("theme contract tests: OK (runtime highlights delegated to integration)")
    return
end

local events = 0
local group = vim.api.nvim_create_augroup("clarity_theme_contract_test", { clear = true })
vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function(event)
        if event.match == "custom_colorblind_theme" then
            events = events + 1
        end
    end,
})

vim.cmd.colorscheme("custom_colorblind_theme")
assert(vim.g.colors_name == "custom_colorblind_theme", "custom colorscheme did not become active")
assert(events == 1, "one colorscheme command must emit one matching ColorScheme event")

local required = { "Normal", "NormalFloat", "Visual", "LineNr", "DiagnosticError", "Search" }
local first = {}
for _, name in ipairs(required) do
    local highlight = vim.api.nvim_get_hl(0, { name = name, link = false })
    assert(next(highlight) ~= nil, name .. " must resolve to concrete attributes")
    first[name] = highlight
end
assert(first.Normal.fg and first.Normal.bg, "Normal must resolve foreground and background colors")
assert(first.DiagnosticError.fg, "DiagnosticError must provide a non-color-independent foreground")

vim.cmd.colorscheme("custom_colorblind_theme")
assert(events == 2, "each explicit reload must emit exactly one matching ColorScheme event")
for _, name in ipairs(required) do
    local reloaded = vim.api.nvim_get_hl(0, { name = name, link = false })
    assert(vim.deep_equal(reloaded, first[name]), name .. " changed after a stable reload")
end

print("theme contract tests: OK")
