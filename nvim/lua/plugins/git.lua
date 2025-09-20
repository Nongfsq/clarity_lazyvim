-- nvim/lua/plugins/git.lua

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
        local gs = package.loaded.gitsigns
        local function map(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
        end

        -- 跳转 (Hunks)
        map("n", "]c", function()
          if vim.wo.diff then return "]c" end
          vim.schedule(function() gs.next_hunk() end)
          return "<Ignore>"
        end, "下一个 [代]码块 (Hunk)")

        map("n", "[c", function()
          if vim.wo.diff then return "[c" end
          vim.schedule(function() gs.prev_hunk() end)
          return "<Ignore>"
        end, "上一个 [代]码块 (Hunk)")

        -- 操作 (Actions)
        map({ "n", "v" }, "<leader>gs", ":Gitsigns stage_hunk<CR>", "暂存 [当]前代码块 (Stage)")
        map({ "n", "v" }, "<leader>gr", ":Gitsigns reset_hunk<CR>", "重置 [当]前代码块 (Reset)")
        map("n", "<leader>gS", gs.stage_buffer, "暂存 [全]部代码 (Stage Buffer)")
        map("n", "<leader>gR", gs.reset_buffer, "重置 [全]部代码 (Reset Buffer)")
        map("n", "<leader>gu", gs.undo_stage_hunk, "[撤]销上次暂存 (Undo Stage)")
        
        -- 查看 (View)
        map("n", "<leader>gp", gs.preview_hunk, "[预]览代码块改动")
        map("n", "<leader>gb", function() gs.blame_line({ full = true }) end, "[查]看行历史 (Blame)")
        map("n", "<leader>gd", gs.diffthis, "[查]看文件差异 (Diff)")
      end,
    },
  },

  -- Lazygit
  {
    "kdheepak/lazygit.nvim",
    cmd = {
      "LazyGit",
      "LazyGitConfig",
      "LazyGitCurrentFile",
      "LazyGitFilter",
      "LazyGitFilterCurrentFile",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    -- use keys to lazy-load the plugin
    keys = {
      { "<leader>gg", "<cmd>LazyGit<cr>", desc = "打开 [G]it 管理 (LazyGit)" },
    },
  },
}