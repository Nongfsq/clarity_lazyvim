---@diagnostic disable: undefined-global
vim.cmd "hi clear"
if vim.fn.exists "syntax_on" then
  vim.cmd "syntax reset"
end

vim.o.background = "dark"
vim.g.colors_name = "custom_colorblind_theme"

local lush = require "lush"
local hsl = lush.hsl

local theme = lush(function(injected_functions)
  local sym = injected_functions.sym
  local bg = hsl(220, 15, 18)
  local fg = hsl(220, 15, 80)

  return {
    -- 基础颜色
    Normal { bg = bg, fg = fg }, -- 深蓝灰背景，浅灰前景
    NormalFloat { bg = bg.lighten(5), fg = fg },

    -- 光标移动到单词上的高亮
    CursorWord { bg = hsl(200, 30, 30), fg = fg.lighten(10) }, -- 柔和的蓝色背景

    -- Visual 模式选中
    Visual { bg = hsl(60, 20, 35), fg = hsl(60, 10, 90) }, -- 柔和的黄褐色背景，近白色文本
    Cursor { bg = hsl(50, 100, 50), fg = bg }, -- 光标
    CursorLine { bg = bg.lighten(5) }, -- 当前行
    CursorColumn { bg = bg.lighten(5) }, -- 当前列
    LineNr { fg = fg.darken(30) }, -- 行号
    CursorLineNr { fg = hsl(50, 100, 50), bold = true }, -- 当前行号

    -- 语法高亮
    sym "@keyword" { fg = hsl(280, 50, 70), bold = true }, -- 关键字：紫色
    sym "@function" { fg = hsl(210, 70, 70), bold = true }, -- 函数：蓝色
    sym "@string" { fg = hsl(40, 70, 70) }, -- 字符串：黄色
    sym "@number" { fg = hsl(340, 60, 70) }, -- 数字：粉红色
    sym "@boolean" { fg = hsl(180, 60, 70) }, -- 布尔值：青色
    sym "@comment" { fg = hsl(120, 20, 60), italic = true }, -- 注释：灰绿色
    sym "@type" { fg = hsl(150, 50, 60), bold = true }, -- 类型：绿色
    sym "@constant" { fg = hsl(30, 70, 70) }, -- 常量：橙色
    sym "@special" { fg = hsl(300, 60, 70) }, -- 特殊字符：亮紫色

    -- 编辑器界面
    StatusLine { bg = bg.lighten(10), fg = fg },
    WinSeparator { fg = bg.lighten(20) },
    TabLine { bg = bg.lighten(5), fg = fg.darken(10) },
    TabLineSel { bg = bg.lighten(15), fg = fg, bold = true },
    Pmenu { bg = bg.lighten(10), fg = fg },
    PmenuSel { bg = Visual.bg, fg = Visual.fg },

    -- 诊断信息
    DiagnosticError { fg = hsl(0, 70, 60) },
    DiagnosticWarn { fg = hsl(60, 70, 60) },
    DiagnosticInfo { fg = hsl(200, 70, 60) },
    DiagnosticHint { fg = hsl(120, 70, 60) },

    -- 搜索和匹配
    Search { bg = hsl(60, 70, 50), fg = bg },
    IncSearch { bg = hsl(30, 70, 50), fg = bg },
    MatchParen { bg = hsl(180, 50, 50), fg = bg, bold = true },
  }
end)

-- 应用主题
lush(theme)
