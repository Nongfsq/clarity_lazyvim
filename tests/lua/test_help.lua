local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
vim.opt.runtimepath:append(repo_root .. "/nvim")

local opened = {}
package.loaded["config.health"] = {
    open = function(route)
        table.insert(opened, route)
        return vim.api.nvim_get_current_buf()
    end,
}

local help = require("config.help")
local test = help._test

local marks = 0
local notices = 0
assert(
    test.complete_startup_open(function(opts)
        assert(opts.auto_open, "automatic guide flag missing")
        return 1
    end, function()
        marks = marks + 1
        return true
    end, function()
        notices = notices + 1
    end),
    "successful Health creation should persist seen state"
)
assert(marks == 1 and notices == 0, "successful Health creation must mark once without warning")

assert(not test.complete_startup_open(function()
    error("injected UI creation failure")
end, function()
    marks = marks + 1
    return true
end, function()
    notices = notices + 1
end), "failed UI creation must remain pending")
assert(marks == 1 and notices == 1, "failed UI creation must not mark seen and must notify once")

assert(not test.complete_startup_open(function()
    return nil
end, function()
    marks = marks + 1
    return true
end, function()
    notices = notices + 1
end), "a missing Health buffer must remain pending")
assert(marks == 1 and notices == 2, "missing Health buffer must not mark seen")

local temp = vim.fn.tempname()
vim.fn.mkdir(temp, "p")
local original_stdpath = vim.fn.stdpath
vim.fn.stdpath = function(kind)
    if kind == "state" then
        return temp
    end
    return original_stdpath(kind)
end

assert(test.read_startup_state() == nil, "fresh startup state must be unseen")
assert(test.mark_startup_seen(), "successful startup state write must report success")
assert(test.read_startup_state() == test.startup_guide_version, "successful write must persist the version")

vim.fn.delete(temp, "rf")
local original_writefile = vim.fn.writefile
vim.fn.writefile = function()
    error("injected write failure")
end
assert(not test.mark_startup_seen(), "failed state write must report failure")
assert(test.read_startup_state() == nil, "failed state write must remain unseen")

vim.fn.writefile = original_writefile
vim.fn.stdpath = original_stdpath
vim.fn.delete(temp, "rf")

help.setup()
assert(vim.fn.exists(":ClarityStart") == 2, "legacy ClarityStart alias missing")
assert(vim.fn.exists(":ClarityClipboard") == 2, "legacy ClarityClipboard alias missing")
assert(vim.fn.exists(":ClaritySync") == 2, "legacy ClaritySync alias missing")

vim.cmd("ClarityStart")
vim.cmd("ClarityClipboard")
vim.cmd("ClaritySync")
assert(vim.deep_equal(opened, { "overview", "clipboard", "recovery" }), "legacy help aliases drifted")

local health_mapping = vim.fn.maparg("<leader>hh", "n", false, true)
assert(type(health_mapping.callback) == "function", "config.help must own the Health mapping callback")
assert(
    health_mapping.desc == require("config.actions.catalog").label("health.open", require("config.i18n").get_locale()),
    "Health mapping must use its catalog/i18n label"
)
health_mapping.callback()
assert(opened[#opened] == "overview", "<leader>hh must open the Health overview")

local callback_before_locale = health_mapping.callback
local runtime_i18n = require("config.i18n")
local next_locale = runtime_i18n.get_locale() == "zh" and "en" or "zh"
assert(runtime_i18n.set_choice(next_locale, { persist = false, silent = true }), "test locale change failed")
local refreshed_mapping = vim.fn.maparg("<leader>hh", "n", false, true)
assert(rawequal(refreshed_mapping.callback, callback_before_locale), "locale refresh changed the Health callback")
assert(
    refreshed_mapping.desc == require("config.actions.catalog").label("health.open", next_locale),
    "locale refresh did not update the Health mapping label"
)

print("help tests: OK")
