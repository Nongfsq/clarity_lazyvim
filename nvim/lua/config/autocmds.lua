-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

local absolute_line_numbers = vim.api.nvim_create_augroup("clarity_absolute_line_numbers", { clear = true })
local numberless_filetypes = {
  alpha = true,
  dashboard = true,
  ministarter = true,
  snacks_dashboard = true,
}

local function disable_line_numbers(win)
  if not vim.api.nvim_win_is_valid(win) then
    return
  end

  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
end

local function disable_line_numbers_for_buffer(buf)
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    disable_line_numbers(win)
  end
end

local function enforce_absolute_line_numbers(buf, win)
  buf = buf or vim.api.nvim_get_current_buf()
  win = win or vim.api.nvim_get_current_win()

  if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_win_is_valid(win) then
    return
  end

  local buftype = vim.bo[buf].buftype
  if buftype ~= "" then
    return
  end

  if numberless_filetypes[vim.bo[buf].filetype] then
    disable_line_numbers(win)
    return
  end

  vim.wo[win].number = true
  vim.wo[win].relativenumber = false
end

vim.api.nvim_create_autocmd("FileType", {
  group = absolute_line_numbers,
  pattern = vim.tbl_keys(numberless_filetypes),
  callback = function(event)
    disable_line_numbers_for_buffer(event.buf)
  end,
})

vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "WinEnter", "FocusGained" }, {
  group = absolute_line_numbers,
  callback = function(event)
    enforce_absolute_line_numbers(event.buf, vim.api.nvim_get_current_win())
  end,
})

vim.api.nvim_create_autocmd({ "User", "VimEnter" }, {
  group = absolute_line_numbers,
  pattern = { "VeryLazy", "*" },
  callback = function()
    vim.schedule(function()
      vim.opt.number = true
      vim.opt.relativenumber = false

      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        enforce_absolute_line_numbers(buf, win)
      end
    end)
  end,
})
