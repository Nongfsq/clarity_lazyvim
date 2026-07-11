local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
vim.opt.runtimepath:append(repo_root .. "/nvim")

local commands = require("config.commands")
local temp = vim.fn.tempname()
vim.fn.mkdir(temp, "p")
local export_path = temp .. "/diagnostics.jsonl"
local notifications = {}
local health_routes = {}
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
    health = {
        open = function(route)
            table.insert(health_routes, route)
        end,
    },
})
commands.setup({ diagnostics = diagnostics, i18n = i18n })

assert(vim.fn.exists(":ClarityLog") == 2, "ClarityLog command missing")
vim.cmd("ClarityLog")
vim.cmd("ClarityLog tail")
assert(vim.deep_equal(health_routes, { "events", "events" }), "legacy log views must route through Health events")
vim.cmd("ClarityLog path")
assert(notifications[#notifications].message:find("events.jsonl", 1, true), "path notification missing")
vim.cmd("ClarityLog export " .. vim.fn.fnameescape(export_path))
assert(vim.fn.filereadable(export_path) == 1, "diagnostic export missing")
assert(vim.json.decode(vim.fn.readfile(export_path)[1]).event_id == "CLARITY_TEST_EVENT", "export is invalid")

vim.fn.delete(temp, "rf")
print("commands tests: OK")
