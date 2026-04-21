local WIDTH = 35 -- Width of neo-tree (left side and line)
local i18n = require "config.i18n"

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
      desc = i18n.t "keymaps.explorer_cwd",
    },
    {
      "<leader>E",
      function()
        vim.cmd("Neotree toggle " .. vim.fn.finddir(".git/..", vim.fn.getcwd() .. ";"))
      end,
      desc = i18n.t "keymaps.explorer_root",
    },
    { "<leader>fe", false },
    { "<leader>fE", false },
  },
  config = function()
    vim.g.neo_tree_remove_legacy_commands = 1
    vim.g.neo_tree_migrations_silent = true

    -- Use a solid vertical separator.
    vim.opt.fillchars:append { vert = "┃" }

    require("neo-tree").setup {
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
        hijack_netrw_behavior = "open_default",
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
          -- indent_size = 2,
          -- padding = 1,
          -- with_markers = true,
          --indent_marker = "│",
          --last_indent_marker = "└",
          -- highlight = "NeoTreeIndentMarker",
        },
        icon = {
          -- folder_closed = "",
          -- folder_open = "",
          --folder_empty = "ﰊ",
          -- default = "*",
        },
        name = {
          trailing_slash = false,
          use_git_status_colors = true,
        },
        -- Keep the Neo-tree buffer numberless and preserve the intended width.
        event_handlers = {
          {
            event = "neo_tree_buffer_enter",
            handler = function()
              vim.cmd [[
              setlocal nonumber
              setlocal norelativenumber
              setlocal signcolumn=auto
            ]]
              -- Keep the configured width stable after the window opens.
              vim.cmd("vertical resize " .. WIDTH)
            end,
          },
        },
      },
    }

    -- Open Neo-tree automatically when Neovim starts on a directory.
    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function(data)
        -- Check whether Neovim was launched with a directory path.
        local directory = vim.fn.isdirectory(data.file) == 1

        if not directory then
          return
        end

        -- Change into that directory.
        vim.cmd.cd(data.file)

        -- Open Neo-tree.
        vim.cmd "Neotree"
        vim.schedule(function()
          -- Find the Neo-tree window and enforce numberless UI state.
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            local buf = vim.api.nvim_win_get_buf(win)
            if vim.bo[buf].filetype == "neo-tree" then
              vim.wo[win].number = false
              vim.wo[win].relativenumber = false
              vim.wo[win].signcolumn = "auto"
              vim.api.nvim_win_set_width(win, WIDTH)
              break
            end
          end
        end)
      end,
    })
  end,
}
