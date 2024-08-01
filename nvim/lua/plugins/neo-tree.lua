local WIDTH = 35 -- neo-tree 左侧与线的宽度

return {
  "nvim-neo-tree/neo-tree.nvim",
  lazy = false,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  keys = {
    {
      "<leader>e",
      function()
        vim.cmd("Neotree toggle " .. vim.fn.getcwd())
      end,
      desc = "Explorer NeoTree (cwd)",
    },
    {
      "<leader>E",
      function()
        vim.cmd("Neotree toggle " .. vim.fn.finddir(".git/..", vim.fn.getcwd() .. ";"))
      end,
      desc = "Explorer NeoTree (project root)",
    },
    { "<leader>fe", false },
    { "<leader>fE", false },
  },
  config = function()
    vim.g.neo_tree_remove_legacy_commands = 1
    vim.g.neo_tree_migrations_silent = true

    -- 设置垂直分隔符为一条实线
    vim.opt.fillchars:append({ vert = "┃" })

    require("neo-tree").setup({
      close_if_last_window = false,
      popup_border_style = "rounded",
      enable_git_status = true,
      enable_diagnostics = true,
      filesystem = {
        filtered_items = {
          visible = true,
          hide_dotfiles = false,
          hide_gitignored = false,
        },
        follow_current_file = {
          enabled = true,
        },
        hijack_netrw_behavior = "open_default", -- 这里改为 "open_default"
        use_libuv_file_watcher = true,
      },
      window = {
        position = "left",
        width = WIDTH,
        mapping_options = {
          noremap = true,
          nowait = true,
        },
      },
      default_component_configs = {
        indent = {
          --indent_size = 2,
          --padding = 1,
          --with_markers = true,
          --indent_marker = "│",
          --last_indent_marker = "└",
          --highlight = "NeoTreeIndentMarker",
        },
        icon = {
          --folder_closed = "",
          --folder_open = "",
          --folder_empty = "ﰊ",
          --default = "*",
        },
        name = {
          trailing_slash = false,
          use_git_status_colors = true,
        },
        -- 添加以下配置
        event_handlers = {
          {
            event = "neo_tree_buffer_enter",
            handler = function()
              vim.cmd([[
              setlocal nonumber
              setlocal norelativenumber
              setlocal signcolumn=auto
            ]])
              -- 确保宽度正确
              vim.cmd("vertical resize " .. WIDTH)
            end,
          },
        },
      },
    })

    -- 在打开目录时自动启动 Neotree
    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function(data)
        -- 检查是否以目录作为参数启动
        local directory = vim.fn.isdirectory(data.file) == 1

        if not directory then
          return
        end

        -- 改变到该目录
        vim.cmd.cd(data.file)

        -- 打开 Neotree
        vim.cmd("Neotree")
        -- 设置 Neotree 窗口的选项
        vim.schedule(function()
          -- 找到 Neotree 窗口
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            local buf = vim.api.nvim_win_get_buf(win)
            if vim.bo[buf].filetype == "neo-tree" then
              -- 设置窗口选项
              vim.wo[win].number = false
              vim.wo[win].relativenumber = false
              vim.wo[win].signcolumn = "auto"
              -- 如果需要，设置窗口宽度
              vim.api.nvim_win_set_width(win, WIDTH) -- 或者您想要的任何宽度
              break
            end
          end
        end)
      end,
    })
  end,
}
