return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    opts = {
      suggestion = {
        accept_keys = { "Tab", false },
        auto_trigger = true,
        keymap = {
          accept = "<Tab>",
          next = "<C-n>",
          prev = "<C-p>",
          dismiss = "<C-e>",
        },
      },
      panel = {
        enabled = true,
        auto_refresh = true,
        keymap = {
          jump_prev = "[[",
          jump_next = "]]",
          accept = "<CR>",
          refresh = "gr",
          open = "<leader>co",
        },
      },
    },
    -- ！！！添加下面这个 init 函数！！！
    init = function()
      -- 获取你自定义主题的颜色，确保风格统一
      local comment_fg = vim.api.nvim_get_hl(0, { name = "Comment" }).fg

      -- 自定义 Copilot 建议的颜色
      -- 我们让它的颜色更接近注释的颜色，但使用下划线来区分
      vim.api.nvim_set_hl(0, "CopilotSuggestion", {
        fg = comment_fg,
        underline = true, -- 使用下划线来明确标识是建议
      })
    end,
  },
}