local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
local lazy_source = table.concat(vim.fn.readfile(repo_root .. "/nvim/lua/config/lazy.lua"), "\n")
local terminal_source = table.concat(vim.fn.readfile(repo_root .. "/nvim/lua/plugins/terminal.lua"), "\n")

assert(lazy_source:find("defaults = { lazy = true", 1, true), "lazy.nvim default must preserve lazy handlers")
assert(not lazy_source:find("defaults = { lazy = false", 1, true), "blanket eager-loading remains")
assert(lazy_source:find("checker = { enabled = false }", 1, true), "background dependency checker must stay off")
assert(terminal_source:find('"<leader>tf"', 1, true), "Snacks terminal requires an explicit key load handler")

print("lazy-loading policy tests: OK")
