local source = debug.getinfo(1, "S").source:sub(2)
local nvim_dir = vim.fn.fnamemodify(source, ":p:h"):gsub("\\", "/")

vim.g.clarity_nvim_dir = nvim_dir
vim.g.clarity_repo_root = vim.fn.fnamemodify(nvim_dir, ":h")

if vim.fn.isdirectory(nvim_dir .. "/lua") == 1 then
  vim.opt.rtp:prepend(nvim_dir)
end

local lua_paths = {
  nvim_dir .. "/lua/?.lua",
  nvim_dir .. "/lua/?/init.lua",
}

for _, path in ipairs(lua_paths) do
  if not package.path:find(path, 1, true) then
    package.path = path .. ";" .. package.path
  end
end

local function apply_custom_colorscheme()
  local theme_file = nvim_dir .. "/colors/custom_colorblind_theme.lua"
  vim.opt.rtp:append(nvim_dir)

  if vim.fn.filereadable(theme_file) ~= 1 then
    return false
  end

  local ok, err = pcall(dofile, theme_file)
  if not ok then
    vim.schedule(function()
      vim.notify("Failed to load custom_colorblind_theme: " .. err, vim.log.levels.ERROR)
    end)
    return false
  end

  return true
end

require "config.lazy"
require "config.options"

if not apply_custom_colorscheme() then
  pcall(vim.cmd.colorscheme, "habamax")
end
