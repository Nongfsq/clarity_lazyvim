local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
vim.opt.runtimepath:append(repo_root .. "/nvim")

local commands = require("config.commands")
local temp = vim.fn.tempname()
vim.fn.mkdir(temp, "p")
local export_path = temp .. "/diagnostics.jsonl"
local notifications = {}
local events = {
    {
        timestamp = "2026-07-10T00:00:00Z",
        level = "error",
        event_id = "CLARITY_TEST_EVENT",
        outcome = "failed",
        context = { scenario = "unit" },
        error = { code = "CLARITY_TEST", message = "injected failure" },
    },
}
local diagnostics = {
    events = function()
        return events
    end,
    path = function()
        return temp .. "/events.jsonl"
    end,
    export = function(path)
        return vim.fn.writefile({ vim.json.encode(events[1]) }, path) == 0
    end,
}
local i18n = {
    t = function(key, vars)
        if vars and vars.path then
            return key .. ":" .. vars.path
        end
        return key
    end,
}
commands.setup({
    diagnostics = diagnostics,
    i18n = i18n,
    notify = function(message, level)
        table.insert(notifications, { message = message, level = level })
    end,
})
commands.setup({ diagnostics = diagnostics, i18n = i18n })

assert(vim.fn.exists(":ClarityLog") == 2, "ClarityLog command missing")
vim.cmd("ClarityLog")
local buffer = vim.api.nvim_get_current_buf()
assert(vim.api.nvim_buf_get_name(buffer) == "clarity://log", "log buffer name is unstable")
assert(vim.bo[buffer].modifiable == false and vim.bo[buffer].readonly, "log buffer must be read-only")
assert(
    table.concat(vim.api.nvim_buf_get_lines(buffer, 0, -1, false), "\n"):find("CLARITY_TEST_EVENT", 1, true),
    "event missing from view"
)

vim.cmd("ClarityLog tail")
assert(vim.api.nvim_win_get_cursor(0)[1] == vim.api.nvim_buf_line_count(buffer), "tail must move to latest event")
vim.cmd("ClarityLog path")
assert(notifications[#notifications].message:find("events.jsonl", 1, true), "path notification missing")
vim.cmd("ClarityLog export " .. vim.fn.fnameescape(export_path))
assert(vim.fn.filereadable(export_path) == 1, "diagnostic export missing")
assert(vim.json.decode(vim.fn.readfile(export_path)[1]).event_id == "CLARITY_TEST_EVENT", "export is invalid")

vim.fn.delete(temp, "rf")
print("commands tests: OK")
