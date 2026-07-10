local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
vim.opt.runtimepath:append(repo_root .. "/nvim")

local health = require("config.health")
local calls = {}
local original_cmd = vim.cmd

vim.cmd = setmetatable({}, {
    __call = function(_, command)
        table.insert(calls, command)
    end,
})

health.setup({ i18n = {
    t = function(key)
        return key
    end,
} })
assert(vim.fn.exists(":ClarityHealth") == 2, "unified health command missing")

for view, command in pairs(health.routes) do
    health.open(view)
    assert(calls[#calls] == command, "health route drifted: " .. view)
end

vim.cmd = original_cmd
print("health entry tests: OK")
