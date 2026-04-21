local source = debug.getinfo(1, "S").source:sub(2)
local repo_root = vim.fn.fnamemodify(source, ":p:h"):gsub("\\", "/")

vim.g.clarity_repo_root = repo_root

local nested_init = repo_root .. "/nvim/init.lua"
if vim.fn.filereadable(nested_init) == 1 then
    dofile(nested_init)
    return
end

require("config.lazy")
