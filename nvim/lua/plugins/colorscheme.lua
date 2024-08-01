--第一套方案
--[[return {
  {
    "ellisonleao/gruvbox.nvim",
    opts = {
      undercurl = true,
      underline = true,
      bold = true,
      italic = {
        strings = true,
        comments = true,
        operators = false,
        folds = true,
      },
      strikethrough = true,
      invert_selection = false,
      invert_signs = false,
      invert_tabline = false,
      invert_intend_guides = false,
      inverse = true,
      contrast = "hard",
      palette_overrides = {
        dark0_hard = "#1d2b1b", -- 深绿色背景
        dark0 = "#1d2b1b",
        dark0_soft = "#1d2b1b",
        dark1 = "#2d3b2b",
        dark2 = "#3d4b3b",
        dark3 = "#4d5b4b",
        dark4 = "#5d6b5b",
        light0_hard = "#e5d8c5",
        light0 = "#e5d8c5",
        light0_soft = "#e5d8c5",
        light1 = "#d5c8b5",
        light2 = "#c5b8a5",
        light3 = "#b5a895",
        light4 = "#a59885",
        bright_red = "#f4a460", -- 砂褐色
        bright_green = "#9acd32", -- 黄绿色
        bright_yellow = "#ffd700", -- 金色
        bright_blue = "#87ceeb", -- 天蓝色
        bright_purple = "#dda0dd", -- 淡紫色
        bright_aqua = "#40e0d0", -- 青绿色
        bright_orange = "#ff7f50", -- 珊瑚色
        neutral_red = "#cd5c5c", -- 印度红
        neutral_green = "#32cd32", -- 酸橙绿
        neutral_yellow = "#f0e68c", -- 卡其色
        neutral_blue = "#4169e1", -- 皇家蓝
        neutral_purple = "#8a2be2", -- 紫罗兰色
        neutral_aqua = "#48d1cc", -- 中绿松石
        neutral_orange = "#ff6347", -- 番茄色
      },
      overrides = {
        SignColumn = { bg = "#1d2b1b" },
        GruvboxGreenSign = { bg = "#1d2b1b", fg = "#9acd32" },
        GruvboxAquaSign = { bg = "#1d2b1b", fg = "#40e0d0" },
        GruvboxRedSign = { bg = "#1d2b1b", fg = "#f4a460" },
        GruvboxBlueSign = { bg = "#1d2b1b", fg = "#87ceeb" },
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruvbox",
    },
  },
}
]]
--

-- 第二套方案
--[[return {
  {
    "folke/tokyonight.nvim",
    lazy = true,
    opts = {
      style = "night",
      light_style = "day",
      transparent = false,
      terminal_colors = true,
      styles = {
        comments = { italic = true },
        keywords = { italic = true },
        functions = { bold = true },
        variables = {},
        sidebars = "dark",
        floats = "dark",
      },
      sidebars = { "qf", "help" },
      day_brightness = 0.3,
      hide_inactive_statusline = false,
      dim_inactive = false,
      lualine_bold = false,

      on_colors = function(colors)
        colors.bg = "#1E2A3A" -- 深蓝色背景，柔和不刺眼
        colors.bg_dark = "#18232F" -- 稍暗的背景色，用于侧边栏等
        colors.bg_highlight = "#2A3A4F" -- 高亮背景色
        colors.fg = "#D8E3F0" -- 浅蓝白色前景，对比度适中
        colors.fg_dark = "#B8C7D8" -- 稍暗的前景色
        colors.fg_gutter = "#4A6484" -- 行号等元素的颜色
        colors.comment = "#6A89AD" -- 注释颜色，柔和的蓝灰色

        -- 主要语法高亮颜色
        colors.blue = "#4AA5E3" -- 蓝色，用于函数名
        colors.cyan = "#34D3FB" -- 青色，用于特殊关键字
        colors.purple = "#A292E3" -- 紫色，用于控制流关键字
        colors.orange = "#FFAA33" -- 橙色，用于常量
        colors.yellow = "#FDE047" -- 黄色，用于字符串
        colors.green = "#7AE582" -- 绿色，用于方法名（偏蓝的绿色，更易辨识）
        colors.magenta = "#FF84CD" -- 品红色，用于数字
        colors.red = "#FF7A84" -- 红色，用于错误提示（偏橙的红色）
      end,

      on_highlights = function(hl, c)
        hl.CursorLine = { bg = c.bg_highlight }
        hl.LineNr = { fg = c.fg_gutter }
        hl.CursorLineNr = { fg = c.orange }
        hl.DiagnosticError = { fg = c.red }
        hl.DiagnosticWarn = { fg = c.yellow }
        hl.DiagnosticInfo = { fg = c.blue }
        hl.DiagnosticHint = { fg = c.green }

        -- 自定义一些高亮组
        hl.Function = { fg = c.blue, bold = true }
        hl.Keyword = { fg = c.purple, italic = true }
        hl.String = { fg = c.yellow }
        hl.Number = { fg = c.magenta }
        hl.Constant = { fg = c.orange }
        hl.Type = { fg = c.green }
        hl.Special = { fg = c.cyan }
      end,
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight",
    },
  },
}
]]
--

-- 第三套
--[[return {
  {
    "folke/tokyonight.nvim",
    lazy = true,
    opts = {
      style = "storm",
      light_style = "day",
      transparent = false,
      terminal_colors = true,
      styles = {
        comments = { italic = true },
        keywords = { bold = true },
        functions = { bold = true },
        variables = {},
        sidebars = "dark",
        floats = "dark",
      },
      sidebars = { "qf", "help" },
      day_brightness = 0.3,
      hide_inactive_statusline = false,
      dim_inactive = false,
      lualine_bold = false,

      on_colors = function(colors)
        colors.bg = "#1A1A1A" -- 深灰色背景
        colors.bg_dark = "#141414" -- 更深的背景色，用于侧边栏等
        colors.bg_highlight = "#2A2A2A" -- 高亮背景色
        colors.fg = "#E0E0E0" -- 浅灰色前景，提供高对比度
        colors.fg_dark = "#BDBDBD" -- 稍深的前景色
        colors.fg_gutter = "#757575" -- 行号等元素的颜色
        colors.comment = "#9E9E9E" -- 注释颜色，中等灰色

        -- 主要语法高亮颜色
        colors.blue = "#64B5F6" -- 亮蓝色，用于函数名
        colors.cyan = "#4DD0E1" -- 亮青色，用于特殊关键字
        colors.purple = "#BA68C8" -- 亮紫色，用于控制流关键字
        colors.orange = "#FFB74D" -- 亮橙色，用于常量
        colors.yellow = "#FFF176" -- 亮黄色，用于字符串
        colors.green = "#81C784" -- 亮绿色，用于方法名
        colors.magenta = "#F06292" -- 亮品红色，用于数字
        colors.red = "#E57373" -- 亮红色，用于错误提示
      end,

      on_highlights = function(hl, c)
        hl.CursorLine = { bg = c.bg_highlight }
        hl.LineNr = { fg = c.fg_gutter }
        hl.CursorLineNr = { fg = c.orange, bold = true }
        hl.DiagnosticError = { fg = c.red }
        hl.DiagnosticWarn = { fg = c.yellow }
        hl.DiagnosticInfo = { fg = c.blue }
        hl.DiagnosticHint = { fg = c.green }

        -- 自定义一些高亮组
        hl.Function = { fg = c.blue, bold = true }
        hl.Keyword = { fg = c.purple, bold = true }
        hl.String = { fg = c.yellow }
        hl.Number = { fg = c.magenta }
        hl.Constant = { fg = c.orange }
        hl.Type = { fg = c.green, bold = true }
        hl.Special = { fg = c.cyan }

        -- 增强可读性的额外设置
        hl.MatchParen = { bg = c.bg_highlight, bold = true }
        hl.Search = { bg = c.yellow, fg = c.bg }
        hl.IncSearch = { bg = c.orange, fg = c.bg }
        hl.Visual = { bg = c.bg_highlight, fg = c.fg }
      end,
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight",
    },
  },
} ]]
--

-- No.4
--[[return {
  {
    "folke/tokyonight.nvim",
    lazy = true,
    opts = {
      style = "night",
      light_style = "day",
      transparent = false,
      terminal_colors = true,
      styles = {
        comments = { italic = true },
        keywords = { bold = true },
        functions = { bold = true },
        variables = {},
        sidebars = "dark",
        floats = "dark",
      },
      sidebars = { "qf", "help" },
      day_brightness = 0.3,
      hide_inactive_statusline = false,
      dim_inactive = false,
      lualine_bold = false,

      on_colors = function(colors)
        colors.bg = "#0A0E14" -- 非常深的蓝黑色背景
        colors.bg_dark = "#050709" -- 更深的背景色，用于侧边栏等
        colors.bg_highlight = "#1A2A3A" -- 高亮背景色
        colors.fg = "#E6F0FF" -- 非常浅的蓝白色前景，提供极高对比度
        colors.fg_dark = "#B0C4DE" -- 稍深的前景色
        colors.fg_gutter = "#4A6484" -- 行号等元素的颜色
        colors.comment = "#64B5F6" -- 注释颜色，明亮的蓝色

        -- 主要语法高亮颜色
        colors.blue = "#40C4FF" -- 亮蓝色，用于函数名
        colors.cyan = "#00E5FF" -- 亮青色，用于特殊关键字
        colors.purple = "#B388FF" -- 亮紫色，用于控制流关键字
        colors.orange = "#FFD54F" -- 亮橙黄色，用于常量
        colors.yellow = "#FFFF8D" -- 亮黄色，用于字符串
        colors.green = "#B9F6CA" -- 非常浅的绿色，用于方法名
        colors.magenta = "#FF80AB" -- 亮粉色，用于数字
        colors.red = "#FF8A80" -- 亮珊瑚色，用于错误提示
      end,

      on_highlights = function(hl, c)
        hl.CursorLine = { bg = c.bg_highlight }
        hl.LineNr = { fg = c.fg_gutter }
        hl.CursorLineNr = { fg = c.orange, bold = true }
        hl.DiagnosticError = { fg = c.red, bold = true }
        hl.DiagnosticWarn = { fg = c.yellow, bold = true }
        hl.DiagnosticInfo = { fg = c.blue, bold = true }
        hl.DiagnosticHint = { fg = c.green, bold = true }

        -- 自定义一些高亮组
        hl.Function = { fg = c.blue, bold = true }
        hl.Keyword = { fg = c.purple, bold = true }
        hl.String = { fg = c.yellow }
        hl.Number = { fg = c.magenta }
        hl.Constant = { fg = c.orange, bold = true }
        hl.Type = { fg = c.green, bold = true }
        hl.Special = { fg = c.cyan, bold = true }

        -- 增强可读性的额外设置
        hl.MatchParen = { bg = c.orange, fg = c.bg, bold = true }
        hl.Search = { bg = c.yellow, fg = c.bg, bold = true }
        hl.IncSearch = { bg = c.orange, fg = c.bg, bold = true }
        hl.Visual = { bg = "#3A4A5A", fg = c.fg, bold = true } -- 更明显的选中颜色
        hl.Comment = { fg = c.comment, italic = true, bold = true } -- 更明显的注释
      end,
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight",
    },
  },
} ]]
--

-- No.5
--[[return {
  {
    "folke/tokyonight.nvim",
    lazy = true,
    opts = {
      style = "night",
      light_style = "day",
      transparent = false,
      terminal_colors = true,
      styles = {
        comments = { italic = true },
        keywords = { bold = true },
        functions = { bold = true },
        variables = {},
        sidebars = "dark",
        floats = "dark",
      },
      sidebars = { "qf", "help" },
      day_brightness = 0.3,
      hide_inactive_statusline = false,
      dim_inactive = false,
      lualine_bold = false,

      on_colors = function(colors)
        colors.bg = "#1A1E24" -- 深蓝灰色背景
        colors.bg_dark = "#15191E" -- 更深的背景色，用于侧边栏等
        colors.bg_highlight = "#252B33" -- 高亮背景色
        colors.fg = "#B0C4DE" -- 柔和的浅蓝灰色前景
        colors.fg_dark = "#8CA2BE" -- 稍深的前景色
        colors.fg_gutter = "#4A5A6A" -- 行号等元素的颜色
        colors.comment = "#607D8B" -- 注释颜色，柔和的蓝灰色

        -- 主要语法高亮颜色
        colors.blue = "#5B9BD5" -- 柔和的蓝色，用于函数名
        colors.cyan = "#4DB6AC" -- 柔和的青色，用于特殊关键字
        colors.purple = "#8E7CC3" -- 柔和的紫色，用于控制流关键字
        colors.orange = "#E6B98B" -- 柔和的橙色，用于常量
        colors.yellow = "#D4CE66" -- 柔和的黄色，用于字符串
        colors.green = "#7CBAA2" -- 柔和的绿色，用于方法名
        colors.magenta = "#C58ED3" -- 柔和的粉色，用于数字
        colors.red = "#E68A8A" -- 柔和的红色，用于错误提示
      end,

      on_highlights = function(hl, c)
        hl.CursorLine = { bg = c.bg_highlight }
        hl.LineNr = { fg = c.fg_gutter }
        hl.CursorLineNr = { fg = c.orange, bold = true }
        hl.DiagnosticError = { fg = c.red, bold = true }
        hl.DiagnosticWarn = { fg = c.yellow, bold = true }
        hl.DiagnosticInfo = { fg = c.blue, bold = true }
        hl.DiagnosticHint = { fg = c.green, bold = true }

        -- 自定义一些高亮组
        hl.Function = { fg = c.blue, bold = true }
        hl.Keyword = { fg = c.purple, bold = true }
        hl.String = { fg = c.yellow }
        hl.Number = { fg = c.magenta }
        hl.Constant = { fg = c.orange, bold = true }
        hl.Type = { fg = c.green, bold = true }
        hl.Special = { fg = c.cyan, bold = true }

        -- 增强可读性的额外设置
        hl.MatchParen = { bg = c.orange, fg = c.bg, bold = true }
        hl.Search = { bg = c.yellow, fg = c.bg, bold = true }
        hl.IncSearch = { bg = c.orange, fg = c.bg, bold = true }
        hl.Visual = { bg = "#323A45", fg = c.fg, bold = true } -- 柔和但明显的选中颜色
        hl.Comment = { fg = c.comment, italic = true } -- 柔和的注释
      end,
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight",
    },
  },
} ]]
--
-- no.6
--[[return {
  {
    "folke/tokyonight.nvim",
    lazy = true,
    opts = {
      style = "storm",
      light_style = "day",
      transparent = false,
      terminal_colors = true,
      styles = {
        comments = { italic = true },
        keywords = { bold = true },
        functions = { bold = true },
        variables = {},
        sidebars = "dark",
        floats = "dark",
      },
      sidebars = { "qf", "help" },
      day_brightness = 0.3,
      hide_inactive_statusline = false,
      dim_inactive = false,
      lualine_bold = false,

      on_colors = function(colors)
        colors.bg = "#1E2330" -- 深蓝色背景，略微调亮
        colors.bg_dark = "#181C28" -- 更深的背景色，用于侧边栏等
        colors.bg_highlight = "#2C3142" -- 高亮背景色
        colors.fg = "#C8D0E0" -- 亮一些的前景色
        colors.fg_dark = "#A0ACC0" -- 稍深的前景色
        colors.fg_gutter = "#5A6377" -- 行号等元素的颜色
        colors.comment = "#7A88A8" -- 注释颜色，更明显的蓝灰色

        -- 主要语法高亮颜色
        colors.blue = "#82AAFF" -- 更亮的蓝色，用于函数名
        colors.cyan = "#5FE7FA" -- 更亮的青色，用于特殊关键字
        colors.purple = "#B48EAD" -- 更明显的紫色，用于控制流关键字
        colors.orange = "#F0A56B" -- 更亮的橙色，用于常量
        colors.yellow = "#EBCB8B" -- 更亮的黄色，用于字符串
        colors.green = "#8DCEA5" -- 更亮的绿色，用于方法名
        colors.magenta = "#D787E2" -- 更亮的粉色，用于数字
        colors.red = "#FF7A85" -- 更亮的红色，用于错误提示
      end,

      on_highlights = function(hl, c)
        hl.CursorLine = { bg = c.bg_highlight }
        hl.LineNr = { fg = c.fg_gutter }
        hl.CursorLineNr = { fg = c.orange, bold = true }
        hl.DiagnosticError = { fg = c.red, bold = true }
        hl.DiagnosticWarn = { fg = c.yellow, bold = true }
        hl.DiagnosticInfo = { fg = c.blue, bold = true }
        hl.DiagnosticHint = { fg = c.green, bold = true }

        -- 自定义一些高亮组
        hl.Function = { fg = c.blue, bold = true }
        hl.Keyword = { fg = c.purple, bold = true }
        hl.String = { fg = c.yellow }
        hl.Number = { fg = c.magenta }
        hl.Constant = { fg = c.orange, bold = true }
        hl.Type = { fg = c.green, bold = true }
        hl.Special = { fg = c.cyan, bold = true }

        -- 增强可读性的额外设置
        hl.MatchParen = { bg = c.orange, fg = c.bg, bold = true }
        hl.Search = { bg = c.yellow, fg = c.bg, bold = true }
        hl.IncSearch = { bg = c.orange, fg = c.bg, bold = true }
        hl.Visual = { bg = "#3A4466", fg = c.fg, bold = true } -- 更明显的选中颜色
        hl.Comment = { fg = c.comment, italic = true }

        -- 添加一些额外的高亮组以增加区分度
        hl.Operator = { fg = c.cyan }
        hl.Delimiter = { fg = c.fg }
        hl.Statement = { fg = c.purple, bold = true }
        hl.PreProc = { fg = c.magenta }
        hl.Title = { fg = c.orange, bold = true }
        hl.SpecialComment = { fg = c.yellow, italic = true, bold = true }
      end,
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight",
    },
  },
} ]]
--

--[[return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "custom_colorblind_theme",
    },
  },
  {
    "norcalli/nvim-colorizer.lua",
    config = function()
      require("colorizer").setup()
    end,
  },
  {
    "rktjmp/lush.nvim",
  },
  {
    "custom-colorblind-theme",
    name = "custom_colorblind_theme",
    lazy = false,
    priority = 1000,
    config = function()
      local lush = require("lush")
      local hsl = lush.hsl

      local theme = lush(function()
        return {
          -- 基础颜色
          Normal({ bg = hsl(220, 15, 18), fg = hsl(220, 15, 80) }), -- 深蓝灰背景，浅灰前景
          NormalFloat({ bg = Normal.bg.lighten(5), fg = Normal.fg }),
          Visual({ bg = hsl(220, 20, 30), fg = Normal.fg.lighten(10) }), -- 选中区域
          Cursor({ bg = hsl(50, 100, 50), fg = Normal.bg }), -- 光标
          CursorLine({ bg = Normal.bg.lighten(5) }), -- 当前行
          LineNr({ fg = Normal.fg.darken(30) }), -- 行号
          CursorLineNr({ fg = hsl(50, 100, 50), gui = "bold" }), -- 当前行号

          -- 语法高亮
          Keyword({ fg = hsl(280, 50, 70), gui = "bold" }), -- 关键字：紫色
          Function({ fg = hsl(210, 70, 70), gui = "bold" }), -- 函数：蓝色
          String({ fg = hsl(40, 70, 70) }), -- 字符串：黄色
          Number({ fg = hsl(340, 60, 70) }), -- 数字：粉红色
          Boolean({ fg = hsl(180, 60, 70) }), -- 布尔值：青色
          Comment({ fg = hsl(120, 20, 60), gui = "italic" }), -- 注释：灰绿色
          Type({ fg = hsl(150, 50, 60), gui = "bold" }), -- 类型：绿色
          Constant({ fg = hsl(30, 70, 70) }), -- 常量：橙色
          Special({ fg = hsl(300, 60, 70) }), -- 特殊字符：亮紫色

          -- 编辑器界面
          StatusLine({ bg = Normal.bg.lighten(10), fg = Normal.fg }),
          VertSplit({ fg = Normal.bg.lighten(20) }),
          TabLine({ bg = Normal.bg.lighten(5), fg = Normal.fg.darken(10) }),
          TabLineSel({ bg = Normal.bg.lighten(15), fg = Normal.fg, gui = "bold" }),
          Pmenu({ bg = Normal.bg.lighten(10), fg = Normal.fg }),
          PmenuSel({ bg = Visual.bg, fg = Visual.fg }),

          -- 诊断信息
          DiagnosticError({ fg = hsl(0, 70, 60) }),
          DiagnosticWarn({ fg = hsl(60, 70, 60) }),
          DiagnosticInfo({ fg = hsl(200, 70, 60) }),
          DiagnosticHint({ fg = hsl(120, 70, 60) }),

          -- 搜索和匹配
          Search({ bg = hsl(60, 70, 50), fg = Normal.bg }),
          IncSearch({ bg = hsl(30, 70, 50), fg = Normal.bg }),
          MatchParen({ bg = hsl(180, 50, 50), fg = Normal.bg, gui = "bold" }),
        }
      end)

      -- 应用主题
      lush(theme)
    end,
  },
} ]]--


-- final
return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "custom_colorblind_theme",
    },
  },
  {
    "rktjmp/lush.nvim",
    lazy = false,
    priority = 1000,
  },
}
