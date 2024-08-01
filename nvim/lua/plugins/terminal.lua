return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    opts = {
      size = function(term)
        if term.direction == "horizontal" then
          return 15
        elseif term.direction == "vertical" then
          return vim.o.columns * 0.4
        end
      end,
      open_mapping = [[<C-\>]],
      hide_numbers = true,
      shade_terminals = true,
      shading_factor = 2,
      start_in_insert = true,
      insert_mappings = true,
      persist_size = true,
      direction = "float",
      close_on_exit = true,
      shell = vim.o.shell,
      float_opts = {
        border = "curved",
        winblend = 5,
        highlights = {
          border = "Normal",
          background = "Normal",
        },
      },
    },
    config = function(_, opts)
      require("toggleterm").setup(opts)

      function _G.set_terminal_keymaps()
        local opts = { buffer = 0 }
        vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], opts)
        vim.keymap.set("t", "jk", [[<C-\><C-n>]], opts)
        vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], opts)
        vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], opts)
        vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], opts)
        vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], opts)
        vim.keymap.set("t", "<C-w>", [[<C-\><C-n><C-w>]], opts)
      end

      vim.cmd("autocmd! TermOpen term://* lua set_terminal_keymaps()")

      local Terminal = require("toggleterm.terminal").Terminal

      -- 中央半透明浮动终端
      local float_center = Terminal:new({
        direction = "float",
        float_opts = {
          border = "curved",
          winblend = 10, -- 增加透明度
          highlights = {
            border = "Normal",
            background = "Normal",
          },
        },
      })

      -- 右侧不透明终端，使用不同颜色
      local float_right = Terminal:new({
        direction = "float",
        float_opts = {
          border = "double",
          width = function()
            return math.floor(vim.o.columns * 0.4)
          end,
          height = function()
            return math.floor(vim.o.lines * 0.8)
          end,
          col = function()
            return vim.o.columns
          end,
          row = 1,
          highlights = {
            border = "SpecialComment",
            background = "NormalFloat",
          },
        },
      })

      -- lazygit 终端
      local lazygit = Terminal:new({
        cmd = "lazygit",
        dir = "git_dir",
        direction = "float",
        float_opts = {
          border = "double",
        },
        -- 函数以确保每次都在正确的目录中打开 lazygit
        on_open = function(term)
          vim.cmd("startinsert!")
          vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
        end,
        on_close = function(_)
          vim.cmd("checktime")
        end,
      })

      -- htop 终端
      local htop = Terminal:new({
        cmd = "htop",
        direction = "float",
        float_opts = {
          border = "curved",
        },
        on_open = function(term)
          vim.cmd("startinsert!")
          vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
        end,
      })

      -- 定义切换函数
      function _FLOAT_CENTER()
        float_center:toggle()
      end

      function _FLOAT_RIGHT()
        float_right:toggle()
      end

      function _VERTICAL_TOGGLE()
        local term = Terminal:new({
          direction = "vertical",
          on_open = function(term)
            vim.cmd("startinsert!")
            vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
          end,
        })
        term:toggle(vim.o.columns * 0.4)
      end

      function _HORIZONTAL_TOGGLE()
        local term = Terminal:new({
          direction = "horizontal",
          on_open = function(term)
            vim.cmd("startinsert!")
            vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
          end,
        })
        term:toggle(15)
      end

      function _LAZYGIT_TOGGLE()
        lazygit:toggle()
      end

      function _HTOP_TOGGLE()
        htop:toggle()
      end

      -- 设置快捷键
      vim.api.nvim_set_keymap(
        "n",
        "<leader>tf",
        "<cmd>lua _FLOAT_CENTER()<CR>",
        { noremap = true, silent = true, desc = "Float Center Terminal" }
      )
      vim.api.nvim_set_keymap(
        "n",
        "<leader>tr",
        "<cmd>lua _FLOAT_RIGHT()<CR>",
        { noremap = true, silent = true, desc = "Float Right Terminal" }
      )
      vim.api.nvim_set_keymap(
        "n",
        "<leader>tv",
        "<cmd>lua _VERTICAL_TOGGLE()<CR>",
        { noremap = true, silent = true, desc = "Vertical Terminal" }
      )
      vim.api.nvim_set_keymap(
        "n",
        "<leader>th",
        "<cmd>lua _HORIZONTAL_TOGGLE()<CR>",
        { noremap = true, silent = true, desc = "Horizontal Terminal" }
      )
      vim.api.nvim_set_keymap(
        "n",
        "<leader>tg",
        "<cmd>lua _LAZYGIT_TOGGLE()<CR>",
        { noremap = true, silent = true, desc = "Lazygit" }
      )
      vim.api.nvim_set_keymap(
        "n",
        "<leader>ht",
        "<cmd>lua _HTOP_TOGGLE()<CR>",
        { noremap = true, silent = true, desc = "htop" }
      )
    end,
  },
  -- 添加 gitsigns 插件以增强 git 支持
  {
    "lewis6991/gitsigns.nvim",
    config = true,
  },
  -- 添加 nvim-web-devicons 插件以支持更多图标
  {
    "nvim-tree/nvim-web-devicons",
    config = function()
      require("nvim-web-devicons").setup({
        override = {
          zsh = {
            icon = "",
            color = "#428850",
            name = "Zsh",
          },
        },
        color_icons = true,
        default = true,
      })
    end,
  },
  -- nvim v0.8.0
  {
    "kdheepak/lazygit.nvim",
    cmd = {
      "LazyGit",
      "LazyGitConfig",
      "LazyGitCurrentFile",
      "LazyGitFilter",
      "LazyGitFilterCurrentFile",
    },
    -- optional for floating window border decoration
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    -- setting the keybinding for LazyGit with 'keys' is recommended in
    -- order to load the plugin when the command is run for the first time
    keys = {
      { "<leader>lg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
    },
  },
}
