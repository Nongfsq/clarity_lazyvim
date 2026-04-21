---@diagnostic disable: undefined-global
vim.cmd("hi clear")
if vim.fn.exists("syntax_on") then
    vim.cmd("syntax reset")
end

vim.o.background = "dark"
vim.g.colors_name = "custom_colorblind_theme"

local lush = require("lush")
local hsl = lush.hsl

local theme = lush(function(injected_functions)
    local sym = injected_functions.sym
    local bg = hsl(220, 15, 18)
    local fg = hsl(220, 15, 80)

    return {
        -- Base colors.
        Normal({ bg = bg, fg = fg }), -- Deep blue-gray background with a light foreground.
        NormalFloat({ bg = bg.lighten(5), fg = fg }),

        -- Highlight the word under the cursor.
        CursorWord({ bg = hsl(200, 30, 30), fg = fg.lighten(10) }), -- Soft blue background.

        -- Visual-mode selection.
        Visual({ bg = hsl(60, 20, 35), fg = hsl(60, 10, 90) }), -- Soft amber background with near-white text.
        Cursor({ bg = hsl(50, 100, 50), fg = bg }), -- Cursor.
        CursorLine({ bg = bg.lighten(5) }), -- Current line.
        CursorColumn({ bg = bg.lighten(5) }), -- Current column.
        LineNr({ fg = fg.darken(30) }), -- Line numbers.
        CursorLineNr({ fg = hsl(50, 100, 50), bold = true }), -- Current line number.

        -- Syntax highlighting.
        sym("@keyword")({ fg = hsl(280, 50, 70), bold = true }), -- Keywords: purple.
        sym("@function")({ fg = hsl(210, 70, 70), bold = true }), -- Functions: blue.
        sym("@string")({ fg = hsl(40, 70, 70) }), -- Strings: yellow.
        sym("@number")({ fg = hsl(340, 60, 70) }), -- Numbers: pink.
        sym("@boolean")({ fg = hsl(180, 60, 70) }), -- Booleans: cyan.
        sym("@comment")({ fg = hsl(120, 20, 60), italic = true }), -- Comments: muted green.
        sym("@type")({ fg = hsl(150, 50, 60), bold = true }), -- Types: green.
        sym("@constant")({ fg = hsl(30, 70, 70) }), -- Constants: orange.
        sym("@special")({ fg = hsl(300, 60, 70) }), -- Special characters: bright purple.

        -- Editor UI.
        StatusLine({ bg = bg.lighten(10), fg = fg }),
        WinSeparator({ fg = bg.lighten(20) }),
        TabLine({ bg = bg.lighten(5), fg = fg.darken(10) }),
        TabLineSel({ bg = bg.lighten(15), fg = fg, bold = true }),
        Pmenu({ bg = bg.lighten(10), fg = fg }),
        PmenuSel({ bg = Visual.bg, fg = Visual.fg }),

        -- Diagnostics.
        DiagnosticError({ fg = hsl(0, 70, 60) }),
        DiagnosticWarn({ fg = hsl(60, 70, 60) }),
        DiagnosticInfo({ fg = hsl(200, 70, 60) }),
        DiagnosticHint({ fg = hsl(120, 70, 60) }),

        -- Search and matches.
        Search({ bg = hsl(60, 70, 50), fg = bg }),
        IncSearch({ bg = hsl(30, 70, 50), fg = bg }),
        MatchParen({ bg = hsl(180, 50, 50), fg = bg, bold = true }),
    }
end)

-- Apply the theme.
lush(theme)
