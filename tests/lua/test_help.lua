local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
vim.opt.runtimepath:append(repo_root .. "/nvim")

local help = require("config.help")
local test = help._test

local function assert_layout(columns, lines)
    local layout = test.float_layout(columns, lines, 80)
    assert(layout.width > 0 and layout.height > 0, "help dimensions must be positive")
    assert(layout.col >= 0 and layout.row >= 0, "help origin must be non-negative")
    assert(layout.col + layout.width + 2 <= columns, "help width must fit the UI")
    assert(layout.row + layout.height + 2 <= lines, "help height must fit the UI")
end

assert_layout(60, 16)
assert_layout(80, 24)
assert_layout(180, 60)

local marks = 0
local notices = 0
assert(
    test.complete_startup_open(function(opts)
        assert(opts.auto_open, "automatic guide flag missing")
    end, function()
        marks = marks + 1
        return true
    end, function()
        notices = notices + 1
    end),
    "successful UI creation should persist seen state"
)
assert(marks == 1 and notices == 0, "successful UI creation must mark once without warning")

assert(not test.complete_startup_open(function()
    error("injected UI creation failure")
end, function()
    marks = marks + 1
    return true
end, function()
    notices = notices + 1
end), "failed UI creation must remain pending")
assert(marks == 1 and notices == 1, "failed UI creation must not mark seen and must notify once")

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

print("help tests: OK")
