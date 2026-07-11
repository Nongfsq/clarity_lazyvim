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
assert(not spec_source:find('colorscheme = "habamax"', 1, true), "custom theme must not need a fallback")
local theme_source = table.concat(vim.fn.readfile(nvim_root .. "/colors/custom_colorblind_theme.lua"), "\n")
assert(not theme_source:find('require("lush")', 1, true), "static theme must not require Lush")
assert(theme_source:find('Normal = { bg = "#272c35", fg = "#c4c9d4" }', 1, true), "accepted palette drifted")

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

local function channel(value)
    value = value / 255
    return value <= 0.04045 and value / 12.92 or ((value + 0.055) / 1.055) ^ 2.4
end

local function luminance(color)
    local red = bit.band(bit.rshift(color, 16), 0xff)
    local green = bit.band(bit.rshift(color, 8), 0xff)
    local blue = bit.band(color, 0xff)
    return 0.2126 * channel(red) + 0.7152 * channel(green) + 0.0722 * channel(blue)
end

local function contrast(foreground, background)
    local lighter = math.max(luminance(foreground), luminance(background))
    local darker = math.min(luminance(foreground), luminance(background))
    return (lighter + 0.05) / (darker + 0.05)
end

local normal_background = first.Normal.bg
for _, name in ipairs({ "Normal", "NormalFloat", "Visual", "LineNr", "DiagnosticError" }) do
    local highlight = first[name]
    local background = highlight.bg or normal_background
    assert(
        contrast(assert(highlight.fg, name .. " must resolve a foreground"), background) >= 4.5,
        name .. " must meet the 4.5:1 normal-text contrast contract"
    )
end
for _, name in ipairs({ "Search" }) do
    local highlight = first[name]
    assert(contrast(highlight.fg, highlight.bg) >= 4.5, name .. " text must meet the 4.5:1 contrast contract")
end

vim.cmd.colorscheme("custom_colorblind_theme")
assert(events == 2, "each explicit reload must emit exactly one matching ColorScheme event")
for _, name in ipairs(required) do
    local reloaded = vim.api.nvim_get_hl(0, { name = name, link = false })
    assert(vim.deep_equal(reloaded, first[name]), name .. " changed after a stable reload")
end

print("theme contract tests: OK")
