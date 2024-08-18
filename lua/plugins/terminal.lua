return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    opts = function()
      local function get_size(term)
        if term.direction == "horizontal" then
          return 15
        elseif term.direction == "vertical" then
          return vim.o.columns * 0.4
        end
      end

      return {
        size = get_size,
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
      }
    end,
    config = function(_, opts)
      require("toggleterm").setup(opts)

      -- Terminal keymaps
      vim.api.nvim_create_autocmd("TermOpen", {
        pattern = "term://*",
        callback = function()
          local opts = { buffer = 0 }
          vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], opts)
          vim.keymap.set("t", "jk", [[<C-\><C-n>]], opts)
          vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], opts)
          vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], opts)
          vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], opts)
          vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], opts)
          vim.keymap.set("t", "<C-w>", [[<C-\><C-n><C-w>]], opts)
        end,
      })

      local Terminal = require("toggleterm.terminal").Terminal

      -- Terminal configurations
      local terminals = {
        float_center = {
          direction = "float",
          float_opts = {
            border = "curved",
            winblend = 10,
          },
        },
        float_right = {
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
        },
        lazygit = {
          cmd = "lazygit",
          dir = "git_dir",
          direction = "float",
          float_opts = { border = "double" },
          on_open = function(term)
            vim.cmd "startinsert!"
            vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
          end,
          on_close = function(_)
            vim.cmd "checktime"
          end,
        },
        htop = {
          cmd = "htop",
          direction = "float",
          float_opts = { border = "curved" },
          on_open = function(term)
            vim.cmd "startinsert!"
            vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
          end,
        },
      }

      -- Create terminal instances
      local term_instances = {}
      for name, config in pairs(terminals) do
        term_instances[name] = Terminal:new(config)
      end

      -- Toggle functions
      local function create_toggle_func(term_name)
        return function()
          term_instances[term_name]:toggle()
        end
      end

      -- Special toggle functions
      local function toggle_vertical()
        Terminal:new({
          direction = "vertical",
          on_open = function(term)
            vim.cmd "startinsert!"
            vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
          end,
        }):toggle(vim.o.columns * 0.4)
      end

      local function toggle_horizontal()
        Terminal:new({
          direction = "horizontal",
          on_open = function(term)
            vim.cmd "startinsert!"
            vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
          end,
        }):toggle(15)
      end

      -- Keymaps
      local keymaps = {
        { "<leader>tf", create_toggle_func "float_center", "Float Center Terminal" },
        { "<leader>tr", create_toggle_func "float_right", "Float Right Terminal" },
        { "<leader>tv", toggle_vertical, "Vertical Terminal" },
        { "<leader>th", toggle_horizontal, "Horizontal Terminal" },
        { "<leader>ht", create_toggle_func "htop", "htop" },
      }

      for _, keymap in ipairs(keymaps) do
        vim.keymap.set("n", keymap[1], keymap[2], { noremap = true, silent = true, desc = keymap[3] })
      end
    end,
  },
  {
    "lewis6991/gitsigns.nvim",
    config = true,
  },
  {
    "nvim-tree/nvim-web-devicons",
    config = function()
      require("nvim-web-devicons").setup {
        override = {
          zsh = {
            icon = "",
            color = "#428850",
            name = "Zsh",
          },
        },
        color_icons = true,
        default = true,
      }
    end,
  },
}
