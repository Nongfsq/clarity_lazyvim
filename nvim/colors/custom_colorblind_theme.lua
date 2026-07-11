---@diagnostic disable: undefined-global
vim.cmd("hi clear")
if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
end

vim.o.background = "dark"

vim.g.colors_name = "custom_colorblind_theme"

-- Static values generated from the accepted Lush theme. Keeping the concrete
-- palette removes an eager runtime dependency while preserving exact colors.
local highlights = {
    Normal = { bg = "#272c35", fg = "#c4c9d4" },
    NormalFloat = { bg = "#303541", fg = "#c4c9d4" },
    CursorWord = { bg = "#365463", fg = "#cacfd8" },
    Visual = { bg = "#6b6b47", fg = "#eeeeea" },
    Cursor = { bg = "#ffd500", fg = "#272c35" },
    CursorLine = { bg = "#303541" },
    CursorColumn = { bg = "#303541" },
    LineNr = { fg = "#919bad" },
    CursorLineNr = { fg = "#ffd500", bold = true },
    ["@keyword"] = { fg = "#bf8cd9", bold = true },
    ["@function"] = { fg = "#7db2e8", bold = true },
    ["@string"] = { fg = "#e8c47d" },
    ["@number"] = { fg = "#e085a3" },
    ["@boolean"] = { fg = "#85e0e0" },
    ["@comment"] = { fg = "#85ad85", italic = true },
    ["@type"] = { fg = "#66cc99", bold = true },
    ["@constant"] = { fg = "#e8b37d" },
    ["@special"] = { fg = "#e085e0" },
    StatusLine = { bg = "#383f4c", fg = "#c4c9d4" },
    WinSeparator = { fg = "#4a5264" },
    TabLine = { bg = "#303541", fg = "#adb4c2" },
    TabLineSel = { bg = "#414958", fg = "#c4c9d4", bold = true },
    Pmenu = { bg = "#383f4c", fg = "#c4c9d4" },
    PmenuSel = { bg = "#6b6b47", fg = "#eeeeea" },
    DiagnosticError = { fg = "#ff6b6b" },
    DiagnosticWarn = { fg = "#e0e052" },
    DiagnosticInfo = { fg = "#52b1e0" },
    DiagnosticHint = { fg = "#52e052" },
    Search = { bg = "#d9d926", fg = "#272c35" },
    IncSearch = { bg = "#d97f26", fg = "#272c35" },
    MatchParen = { bg = "#40bfbf", fg = "#272c35", bold = true },
}

for name, value in pairs(highlights) do
    vim.api.nvim_set_hl(0, name, value)
end
