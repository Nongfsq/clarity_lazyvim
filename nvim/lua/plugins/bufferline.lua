-- nvim/lua/plugins/bufferline.lua

return {
  "akinsho/bufferline.nvim",
  event = "VeryLazy",
  keys = {
    -- 顶部标签页 (Bufferline) 管理
    { "<leader>1", "<cmd>BufferLineGoToBuffer 1<CR>", desc = "跳转到第 1 个标签页" },
    { "<leader>2", "<cmd>BufferLineGoToBuffer 2<CR>", desc = "跳转到第 2 个标签页" },
    { "<leader>3", "<cmd>BufferLineGoToBuffer 3<CR>", desc = "跳转到第 3 个标签页" },
    { "<leader>4", "<cmd>BufferLineGoToBuffer 4<CR>", desc = "跳转到第 4 个标签页" },
    { "<leader>5", "<cmd>BufferLineGoToBuffer 5<CR>", desc = "跳转到第 5 个标签页" },
    { "<leader>6", "<cmd>BufferLineGoToBuffer 6<CR>", desc = "跳转到第 6 个标签页" },
    { "<leader>7", "<cmd>BufferLineGoToBuffer 7<CR>", desc = "跳转到第 7 个标签页" },
    { "<leader>8", "<cmd>BufferLineGoToBuffer 8<CR>", desc = "跳转到第 8 个标签页" },
    { "<leader>9", "<cmd>BufferLineGoToBuffer 9<CR>", desc = "跳转到最后一个标签页" },
    { "<C-PageUp>", "<cmd>BufferLineCyclePrev<CR>", desc = "上一个标签页" },
    { "<C-PageDown>", "<cmd>BufferLineCycleNext<CR>", desc = "下一个标签页" },
    { "<leader>bq", "<cmd>bdelete<CR>", desc = "[关]闭当前标签页" },
  },
  opts = {
    options = {
      -- 在这里可以添加一些 bufferline 的视觉配置
      -- 例如，让 LSP 诊断信息 (错误、警告) 显示在标签上
      diagnostics = "nvim_lsp",
      diagnostics_indicator = function(count, level, diagnostics_dict, context)
        local icon = level:match "error" and " " or (level:match "warn" and " " or " ")
        return " " .. icon .. count
      end,
      -- 让关闭按钮看起来更现代
      right_mouse_command = "bdelete! %d",
      offsets = {
        {
          filetype = "neo-tree",
          text = "File Explorer",
          text_align = "left",
          separator = true,
        },
      },
    },
  },
}
