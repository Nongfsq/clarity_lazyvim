local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
vim.opt.runtimepath:append(repo_root .. "/nvim")

local diagnostics = require("config.diagnostics")
local temp = vim.fn.tempname()
vim.fn.mkdir(temp, "p")
local path = temp .. "/events.jsonl"
local clock_index = 0
local logger = diagnostics.new({
    path = path,
    session_id = "unit-session",
    capacity = 2,
    max_bytes = 1024,
    persist_level = "warn",
    redact_values = { "fixture-secret" },
    clock = function()
        clock_index = clock_index + 1
        return "2026-07-10T00:00:0" .. clock_index .. "Z"
    end,
})

local info = logger:emit(vim.log.levels.INFO, {
    event_id = "INFO_EVENT",
    component = "test",
    action = "observe",
    outcome = "ok",
    message_key = "test.info",
    context = { line = 1, token = "must-not-appear" },
})
assert(info.persisted ~= true, "INFO should remain memory-only by default")
assert(info.context.token == nil, "unsafe context must be dropped")

local warning = logger:emit(vim.log.levels.WARN, {
    event_id = "WARN_EVENT",
    component = "test",
    action = "observe",
    outcome = "warned",
    message_key = "test.warn",
    context = { path = (vim.env.HOME or "") .. "/secret/project.lua", reason = "fixture" },
})
assert(warning.persisted, "WARN should persist")
assert(warning.context.path:sub(1, 1) == "~", "HOME path must be normalized")

local windows_path = logger:emit(vim.log.levels.WARN, {
    event_id = "WINDOWS_PATH",
    component = "test",
    action = "observe",
    outcome = "warned",
    message_key = "test.windows_path",
    context = { path = "C:\\Users\\测试 User\\project\\init.lua" },
    error = { message = "fixture-secret must be hidden", traceback = "fixture-secret traceback" },
})
assert(windows_path.context.path == "C:/Users/测试 User/project/init.lua", "Windows path must normalize")
assert(not windows_path.error.message:find("fixture-secret", 1, true), "explicit secret leaked from error")

logger:emit(vim.log.levels.ERROR, {
    event_id = "ERROR_EVENT",
    component = "test",
    action = "observe",
    outcome = "failed",
    message_key = "test.error",
})
assert(#logger:events() == 2, "ring capacity must be enforced")
local persisted = vim.fn.readfile(path)
assert(#persisted == 3, "WARN and ERROR should produce three JSONL records")
for _, line in ipairs(persisted) do
    local decoded = vim.json.decode(line)
    assert(decoded.schema_version == 1 and decoded.session_id == "unit-session", "invalid persisted event")
    assert(not line:find("must%-not%-appear"), "unsafe data leaked")
    assert(not line:find("fixture%-secret"), "explicit secret leaked")
end

local failed_logger = diagnostics.new({
    path = temp .. "/denied/events.jsonl",
    persist_level = "warn",
    writer = function()
        return false, "injected writer failure"
    end,
})
local failed_event = failed_logger:emit(vim.log.levels.ERROR, {
    event_id = "WRITER_FAILURE",
    component = "test",
    action = "write",
    outcome = "failed",
    message_key = "test.writer_failure",
})
assert(failed_event.persisted == false, "writer failure must be recorded")
assert(failed_event.persist_error:find("injected writer failure", 1, true), "writer error must be actionable")
assert(#failed_logger:events() == 1, "writer failure must not recurse")

local rotating = diagnostics.new({
    path = temp .. "/rotate/events.jsonl",
    persist_level = "warn",
    max_bytes = 1,
    rotations = 2,
})
for index = 1, 2 do
    rotating:emit(vim.log.levels.WARN, {
        event_id = "ROTATE_" .. index,
        component = "test",
        action = "rotate",
        outcome = "warned",
        message_key = "test.rotate",
    })
end
assert(vim.fn.filereadable(rotating.path) == 1, "active rotated log missing")
assert(vim.fn.filereadable(rotating.path .. ".1") == 1, "first rotated log missing")
assert(vim.json.decode(vim.fn.readfile(rotating.path)[1]).event_id == "ROTATE_2", "active rotation is wrong")
assert(vim.json.decode(vim.fn.readfile(rotating.path .. ".1")[1]).event_id == "ROTATE_1", "archive is wrong")

local guard_notifications = 0
local guard_ok, guard_event = failed_logger:guard({
    event_id = "GUARD_FAILURE",
    component = "test",
    action = "guard",
    message_key = "test.guard",
    user_message = "bounded failure",
    notify = function()
        guard_notifications = guard_notifications + 1
    end,
}, function()
    error("injected guarded error at " .. (vim.env.HOME or "") .. "/private.lua")
end)
assert(not guard_ok and guard_event.event_id == "GUARD_FAILURE", "guard must return its failure event")
assert(guard_notifications == 1, "guard must notify exactly once")
local home = vim.env.HOME or vim.env.USERPROFILE or ""
if home ~= "" then
    assert(not guard_event.error.message:find(home, 1, true), "guard error must redact HOME")
end

vim.fn.delete(temp, "rf")
print("diagnostics tests: OK")
