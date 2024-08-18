return {
  -- 其他插件
  {
    "xiyaowong/nvim-cursorword",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      -- 可选：这里可以添加任何你想要的配置
      vim.api.nvim_command "highlight CursorWord cterm=underline gui=underline"
    end,
  },
  -- 其他插件
}
