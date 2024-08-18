-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.opt.relativenumber = false
-- 调整普通按键映射的超时时间（单位为毫秒）
-- vim.o.timeoutlen = 100
-- 调整终端键映射的超时时间（单位为毫秒）
-- vim.o.ttimeoutlen = 50
-- 在你的 init.lua 文件中添加以下设置
-- vim.o.scrolljump = 5
-- ⭐
-- 将 Tab 键映射为 4 个空格
local opt = vim.opt

opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.smartindent = true
opt.autoindent = true
