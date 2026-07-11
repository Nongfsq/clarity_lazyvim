local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
vim.opt.runtimepath:append(repo_root .. "/nvim")

local health = require("config.health")
health._reset()

local active_locale = "en"
local i18n = {
    get_locale = function()
        return active_locale
    end,
    get_state = function()
        return {
            choice = active_locale,
            effective = active_locale,
            source = "runtime",
        }
    end,
    label = function(code)
        local labels = {
            en = active_locale == "zh" and "英文" or "English",
            zh = active_locale == "zh" and "中文" or "Chinese",
        }
        return labels[code] or code
    end,
    t = function(key)
        return key
    end,
}

local events = {
    {
        timestamp = "2026-07-11T00:00:00Z",
        level = "warn",
        event_id = "CLARITY_TEST_EVENT",
        outcome = "degraded",
        context = { scenario = "unit" },
        error = { code = "CLARITY_TEST", message = "injected event" },
    },
}

local audit = {
    get_clipboard_status = function()
        return { present = true, provider = "test-provider", kind = "desktop" }
    end,
    get_report = function()
        return {
            summary = {
                core = { status = "ready" },
                host = { status = "capable" },
                release = { status = "unverified" },
            },
            integrations = {
                lsp = {
                    auto_install = false,
                    servers = {
                        { name = "lua_ls", executable = "lua-language-server", present = false },
                    },
                },
            },
            checks = {
                {
                    id = "lsp_server_lua_ls",
                    status = "warn",
                    detail = "server=lua_ls executable=lua-language-server",
                    impact = "Lua navigation is unavailable.",
                    repair = "Install lua-language-server externally and ensure it is on PATH.",
                    recheck = ":ClarityHealth environment",
                },
            },
        }
    end,
}

local injected_stage

health.setup({
    i18n = i18n,
    diagnostics = {
        events = function()
            return events
        end,
    },
    audit = audit,
    message_reader = function()
        return {
            native = { "native editor message" },
            noice = { "Noice presentation message" },
            noice_active = true,
        }
    end,
    transaction_hook = function(stage)
        if injected_stage == stage then
            error("injected Health transaction failure: " .. stage)
        end
    end,
})
health.setup({ i18n = i18n, audit = audit })

assert(vim.fn.exists(":ClarityHealth") == 2, "unified health command missing")

local function buffer_text(buffer)
    return table.concat(vim.api.nvim_buf_get_lines(buffer, 0, -1, false), "\n")
end

local buffer = health.open("overview")
assert(buffer == vim.api.nvim_get_current_buf(), "Health must open in the current window")
assert(vim.api.nvim_buf_get_name(buffer) == "clarity://health", "Health buffer name drifted")
assert(vim.bo[buffer].buftype == "nofile", "Health must be a scratch buffer")
assert(vim.bo[buffer].filetype == "clarityhealth", "Health filetype drifted")
assert(vim.bo[buffer].readonly and not vim.bo[buffer].modifiable, "Health must remain read-only")
assert(buffer_text(buffer):find("# Clarity Health · Overview", 1, true), "English overview heading missing")

vim.api.nvim_win_set_cursor(0, { 10, 0 })
local cursor_before_repeat = vim.api.nvim_win_get_cursor(0)
local repeated = health.open("overview")
assert(repeated == buffer, "repeated Health opens must reuse one buffer")
assert(
    vim.deep_equal(vim.api.nvim_win_get_cursor(0), cursor_before_repeat),
    "repeated Health opens must preserve cursor state"
)

local expected_headings = {
    overview = "Review-first essentials",
    recovery = "Safe recovery path",
    environment = "Passive environment snapshot",
    clipboard = "Clipboard capability",
    messages = "Native Neovim message history",
    events = "Clarity structured diagnostic events",
    language = "Interface language",
}
for _, route in ipairs(health.route_order) do
    health.open(route)
    assert(vim.b[buffer].clarity_health_route == route, "Health route state drifted: " .. route)
    assert(buffer_text(buffer):find(expected_headings[route], 1, true), "Health route did not render: " .. route)
end

health.open("clipboard")
local english_clipboard = buffer_text(buffer)
assert(english_clipboard:find("Provider: test-provider", 1, true), "Health clipboard provider status missing")
assert(english_clipboard:find("OSC52 is a copy-only path", 1, true), "Health clipboard copy-only boundary missing")
assert(
    english_clipboard:find("Health never reads or records clipboard contents", 1, true),
    "Health clipboard privacy boundary missing"
)

health.open("environment")
local environment = buffer_text(buffer)
assert(environment:find("Enabled LSP readiness", 1, true), "LSP readiness section missing")
assert(environment:find("lua_ls: lua%-language%-server"), "enabled LSP name/executable missing")
assert(environment:find("Install `lua%-language%-server` externally"), "missing LSP repair is not actionable")
assert(environment:find("never installs language servers automatically", 1, true), "no-auto-install policy missing")
assert(environment:find("Current audit findings", 1, true), "environment findings section missing")
assert(environment:find("Status: degraded", 1, true), "audit status value was not localized")
assert(environment:find("Impact: Lua navigation is unavailable.", 1, true), "audit impact missing")
assert(environment:find("Repair: Install lua%-language%-server externally"), "audit repair missing")
assert(environment:find("Recheck: :ClarityHealth environment", 1, true), "audit recheck missing")

health.open("recovery")
local recovery = buffer_text(buffer)
assert(recovery:find("Current audit findings", 1, true), "recovery findings section missing")
assert(recovery:find("server=lua_ls executable=lua%-language%-server"), "recovery finding detail missing")

health.open("messages")
local messages = buffer_text(buffer)
assert(messages:find("native editor message", 1, true), "native message history missing")
assert(messages:find("Noice presentation message", 1, true), "Noice message history missing")
assert(not messages:find("CLARITY_TEST_EVENT", 1, true), "structured events leaked into Messages")

health.open("events")
local diagnostic_events = buffer_text(buffer)
assert(diagnostic_events:find("CLARITY_TEST_EVENT", 1, true), "structured diagnostic event missing")
assert(diagnostic_events:find('"scenario":"unit"', 1, true), "sanitized diagnostic context missing")
assert(not diagnostic_events:find("native editor message", 1, true), "native messages leaked into Events")

local alias_targets = {
    start = "overview",
    audit = "environment",
    validate = "recovery",
    sync = "recovery",
    log = "events",
}
for alias, target in pairs(alias_targets) do
    health.open(alias)
    assert(vim.b[buffer].clarity_health_route == target, "legacy Health alias drifted: " .. alias)
end

local before_invalid = buffer_text(buffer)
local valid = pcall(health.open, "not-a-real-route")
assert(not valid, "Health must reject unknown routes")
assert(buffer_text(buffer) == before_invalid, "unknown routes must not mutate the Health view")

health.open("overview")
local transaction_before = {
    route = health._test.state.route,
    source_buffer = health._test.state.source_buffer,
    current_buffer = vim.api.nvim_get_current_buf(),
    lines = buffer_text(buffer),
    readonly = vim.bo[buffer].readonly,
    modifiable = vim.bo[buffer].modifiable,
}
injected_stage = "after_lines"
local refreshed = pcall(health.refresh)
injected_stage = nil
assert(not refreshed, "injected refresh failure must propagate")
assert(buffer_text(buffer) == transaction_before.lines, "failed refresh did not restore Health lines")
assert(vim.bo[buffer].readonly == transaction_before.readonly, "failed refresh did not restore readonly")
assert(vim.bo[buffer].modifiable == transaction_before.modifiable, "failed refresh did not restore modifiable")
assert(health._test.state.route == transaction_before.route, "failed refresh changed the route")
assert(health._test.state.source_buffer == transaction_before.source_buffer, "failed refresh changed the source")

injected_stage = "after_switch"
local opened = pcall(health.open, "environment")
injected_stage = nil
assert(not opened, "injected open failure must propagate")
assert(
    vim.api.nvim_get_current_buf() == transaction_before.current_buffer,
    "failed open did not restore current buffer"
)
assert(buffer_text(buffer) == transaction_before.lines, "failed open did not restore Health lines")
assert(vim.bo[buffer].readonly == transaction_before.readonly, "failed open did not restore readonly")
assert(vim.bo[buffer].modifiable == transaction_before.modifiable, "failed open did not restore modifiable")
assert(health._test.state.route == transaction_before.route, "failed open did not restore route")
assert(health._test.state.source_buffer == transaction_before.source_buffer, "failed open did not restore source")

local environment_renderer = health._test.renderers.environment
health._test.renderers.environment = function()
    error("injected render failure")
end
local rendered = pcall(health.open, "environment")
health._test.renderers.environment = environment_renderer
assert(not rendered, "injected render failure must propagate")
assert(vim.api.nvim_get_current_buf() == transaction_before.current_buffer, "render failure switched buffers")
assert(buffer_text(buffer) == transaction_before.lines, "render failure changed Health lines")
assert(health._test.state.route == transaction_before.route, "render failure changed route")
assert(health._test.state.source_buffer == transaction_before.source_buffer, "render failure changed source")

health.open("overview")
vim.api.nvim_win_set_cursor(0, { 10, 0 })
local cursor_before_locale = vim.api.nvim_win_get_cursor(0)
active_locale = "zh"
vim.api.nvim_exec_autocmds("User", { pattern = "ClarityLocaleChanged", modeline = false })
local chinese = buffer_text(buffer)
assert(chinese:find("# Clarity 健康中心 · 概览", 1, true), "open Health view did not refresh to Chinese")
assert(not chinese:find("Review-first essentials", 1, true), "stale English Health body remained")
assert(
    vim.deep_equal(vim.api.nvim_win_get_cursor(0), cursor_before_locale),
    "locale refresh must preserve Health cursor/view state"
)

local one_desc
for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(buffer, "n")) do
    if mapping.lhs == "1" then
        one_desc = mapping.desc
    end
end
assert(one_desc and one_desc:find("概览", 1, true), "Health route map description did not refresh")

health.open("clipboard")
local chinese_clipboard = buffer_text(buffer)
assert(chinese_clipboard:find("## 剪贴板能力", 1, true), "Chinese Health clipboard heading missing")
assert(chinese_clipboard:find("OSC52 只负责复制", 1, true), "Chinese clipboard copy-only boundary missing")
assert(
    chinese_clipboard:find("Health 永远不会读取或记录剪贴板内容", 1, true),
    "Chinese clipboard privacy boundary missing"
)

health.open("environment")
local chinese_environment = buffer_text(buffer)
assert(chinese_environment:find("## 已启用 LSP 就绪度", 1, true), "Chinese LSP heading missing")
assert(chinese_environment:find("## 当前审计发现", 1, true), "Chinese audit heading missing")
assert(chinese_environment:find("状态：降级", 1, true), "Chinese audit status missing")

vim.cmd("ClarityHealth language")
assert(vim.b[buffer].clarity_health_route == "language", "ClarityHealth command route failed")
assert(buffer_text(buffer):find("## 界面语言", 1, true), "command-opened route used stale locale")

local en_keys = vim.tbl_keys(health._test.strings.en)
local zh_keys = vim.tbl_keys(health._test.strings.zh)
table.sort(en_keys)
table.sort(zh_keys)
assert(vim.deep_equal(en_keys, zh_keys), "Health local fallback catalogs must have exact parity")

health._reset()
print("health entry tests: OK")
