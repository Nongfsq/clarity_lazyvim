-- nvim/lua/plugins/git.lua

local i18n = require "config.i18n"

local function setup_hunk_keymaps(bufnr)
  if vim.b[bufnr].clarity_gitsigns_keymaps then
    return
  end

  local gs = package.loaded.gitsigns
  if not gs then
    return
  end

  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc, silent = true })
  end

  local function hunk_nav(next_hunk)
    return function()
      if vim.wo.diff then
        return next_hunk and "]h" or "[h"
      end
      vim.schedule(function()
        if next_hunk then
          gs.next_hunk()
        else
          gs.prev_hunk()
        end
      end)
      return "<Ignore>"
    end
  end

  map("n", "]h", hunk_nav(true), i18n.t "keymaps.next_hunk")
  map("n", "[h", hunk_nav(false), i18n.t "keymaps.prev_hunk")
  map("n", "]c", hunk_nav(true), i18n.t "keymaps.legacy_next_hunk")
  map("n", "[c", hunk_nav(false), i18n.t "keymaps.legacy_prev_hunk")

  map({ "n", "v" }, "<leader>hs", ":Gitsigns stage_hunk<CR>", i18n.t "keymaps.stage_hunk")
  map({ "n", "v" }, "<leader>hr", ":Gitsigns reset_hunk<CR>", i18n.t "keymaps.reset_hunk")
  map("n", "<leader>hS", gs.stage_buffer, i18n.t "keymaps.stage_buffer")
  map("n", "<leader>hR", gs.reset_buffer, i18n.t "keymaps.reset_buffer")
  map("n", "<leader>hu", gs.undo_stage_hunk, i18n.t "keymaps.undo_stage_hunk")

  map("n", "<leader>hp", gs.preview_hunk, i18n.t "keymaps.preview_hunk")
  map("n", "<leader>hb", function()
    gs.blame_line({ full = true })
  end, i18n.t "keymaps.blame_line")
  map("n", "<leader>hd", gs.diffthis, i18n.t "keymaps.diff_this")

  vim.b[bufnr].clarity_gitsigns_keymaps = true
end

return {
  -- GitSigns: Show git diff in the sign column
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
        untracked = { text = "▎" },
      },
      on_attach = function(bufnr)
        setup_hunk_keymaps(bufnr)
      end,
    },
    config = function(_, opts)
      require("gitsigns").setup(opts)

      local function attach_if_ready(bufnr, retries)
        if not vim.api.nvim_buf_is_valid(bufnr) then
          return
        end

        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(bufnr) and vim.b[bufnr].gitsigns_head then
            setup_hunk_keymaps(bufnr)
          elseif retries and retries > 0 then
            vim.defer_fn(function()
              attach_if_ready(bufnr, retries - 1)
            end, 120)
          end
        end)
      end

      local group = vim.api.nvim_create_augroup("clarity_gitsigns_keymaps", { clear = true })
      vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "BufReadPost", "FocusGained" }, {
        group = group,
        callback = function(event)
          attach_if_ready(event.buf, 6)
        end,
      })

      vim.defer_fn(function()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          attach_if_ready(buf, 6)
        end
      end, 200)
    end,
  },
}
