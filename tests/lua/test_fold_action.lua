local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
vim.opt.runtimepath:append(repo_root .. "/nvim")

local fold = require("config.actions.fold")
local events = {}
local notifications = {}
local diagnostics = {
    guard = function(_, callback)
        local ok, result = xpcall(callback, debug.traceback)
        if ok then
            return true, result
        end
        table.insert(events, { level = "error", event_id = "CLARITY_FOLD_ACTION_FAILED", error = result })
        return false, events[#events]
    end,
    emit = function(level, spec)
        table.insert(
            events,
            { level = level, event_id = spec.event_id, outcome = spec.outcome, context = spec.context }
        )
    end,
}
local i18n = {
    t = function(key)
        return key
    end,
}
local function notify(message, level)
    table.insert(notifications, { message = message, level = level })
end
local state = {
    buftype = "",
    filetype = "lua",
    foldmethod = "manual",
    line = 1,
    foldlevel = 1,
    closed = 1,
    toggles = 0,
}
local deps = {
    buftype = function()
        return state.buftype
    end,
    filetype = function()
        return state.filetype
    end,
    foldmethod = function()
        return state.foldmethod
    end,
    line = function()
        return state.line
    end,
    foldlevel = function()
        return state.foldlevel
    end,
    foldclosed = function()
        return state.closed
    end,
    toggle = function()
        state.toggles = state.toggles + 1
        state.closed = state.closed == -1 and 1 or -1
    end,
    restore = function(_, was_closed)
        state.closed = was_closed
    end,
}
local opts = { diagnostics = diagnostics, i18n = i18n, notify = notify, deps = deps }

vim.api.nvim_buf_set_lines(0, 0, -1, false, { "plain line" })
vim.wo.foldmethod = "manual"
local legacy_ok, legacy_error = pcall(vim.cmd, "normal! za")
assert(not legacy_ok and legacy_error:find("E490", 1, true), "raw za baseline must reproduce E490")

assert(fold.toggle(opts) == "toggled", "existing fold should toggle")
assert(state.toggles == 1, "toggle must execute exactly once")

state.foldlevel = 0
assert(fold.toggle(opts) == "no_fold", "plain line should return no_fold")
assert(state.toggles == 1, "no_fold must not mutate fold state")
assert(events[#events].event_id == "CLARITY_FOLD_NO_FOLD", "no_fold event missing")
assert(notifications[#notifications].level == vim.log.levels.INFO, "no_fold must be informational")

for _, buffer_type in ipairs({ "nofile", "help", "terminal" }) do
    state.buftype = buffer_type
    assert(fold.toggle(opts) == "unsupported_buffer", buffer_type .. " buffer should be handled")
    assert(state.toggles == 1, "unsupported buffer must not toggle")
end

state.buftype = ""
state.foldlevel = "not-ready"
assert(fold.toggle(opts) == "degraded", "invalid provider state should degrade")

deps.foldlevel = function()
    error("provider unavailable")
end
assert(fold.toggle(opts) == "degraded", "provider errors should degrade without escaping")

state.foldlevel = 1
state.closed = 1
deps.foldlevel = function()
    return state.foldlevel
end
deps.toggle = function()
    state.closed = -1
    error("injected fold failure")
end
assert(fold.toggle(opts) == "failed", "unexpected exception should return failed")
assert(events[#events].event_id == "CLARITY_FOLD_ACTION_FAILED", "unexpected failure event missing")
assert(state.closed == 1, "failed toggle must restore the prior fold state")

deps.toggle = nil
deps.foldclosed = nil
deps.restore = nil
local actual_buffer = vim.api.nvim_create_buf(false, false)
vim.api.nvim_win_set_buf(0, actual_buffer)
vim.api.nvim_buf_set_lines(actual_buffer, 0, -1, false, { "if true then", "  print(1)", "end", "print(2)" })
vim.wo.foldmethod = "expr"
vim.wo.foldexpr = "getline(v:lnum) =~ '^if' ? '>1' : (getline(v:lnum) =~ '^end' ? '<1' : '=')"
vim.wo.foldenable = true
vim.wo.foldlevel = 0
vim.cmd("normal! zx")
vim.api.nvim_win_set_cursor(0, { 1, 0 })
assert(vim.fn.foldlevel(1) > 0, "expression fold fixture did not create a fold")
assert(fold.toggle({ diagnostics = diagnostics, i18n = i18n, notify = notify }) == "toggled", "expr fold failed")
vim.api.nvim_buf_delete(actual_buffer, { force = true })

print("fold action tests: OK")
