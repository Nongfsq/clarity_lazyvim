local M = {}

local ROUTE_ORDER = {
    "overview",
    "recovery",
    "environment",
    "clipboard",
    "messages",
    "events",
    "language",
}

local ROUTES = {}
for _, route in ipairs(ROUTE_ORDER) do
    ROUTES[route] = true
end

local ALIASES = {
    start = "overview",
    audit = "environment",
    validate = "recovery",
    sync = "recovery",
    log = "events",
}

local strings = {
    en = {
        title = "# Clarity Health · %{route}",
        intro = "One calm place to understand the editor, recover from faults, and inspect evidence.",
        navigation = "Routes: `1` Overview · `2` Recovery · `3` Environment · `4` Clipboard · `5` Messages · `6` Events · `7` Language",
        controls = "Controls: `r` refresh · `q` or `Esc` return to the previous buffer",
        route_overview = "Overview",
        route_recovery = "Recovery",
        route_environment = "Environment",
        route_clipboard = "Clipboard",
        route_messages = "Messages",
        route_events = "Events",
        route_language = "Language",
        overview_header = "## Review-first essentials",
        overview_body = "Agents handle broad changes; Clarity keeps human review, navigation, and precise correction obvious.",
        overview_find = "- Find files/text: `<leader>ff` / `<leader>fw`",
        overview_review = "- Review diagnostics/Git: `<leader>sd` / `<leader>gs` / `<leader>gd`",
        overview_readability = "- Readability: `<leader>cz` fold / `<leader>uw` wrap; absolute line numbers remain stable",
        overview_help = "- Return here: `<leader>hh` or `:ClarityHealth`",
        overview_locale = "- Interface language: %{locale}",
        recovery_header = "## Safe recovery path",
        recovery_1 = "1. Open `:ClarityHealth messages` for editor and Noice message history.",
        recovery_2 = "2. Open `:ClarityHealth events` for Clarity's structured diagnostic outcomes.",
        recovery_3 = "3. Open `:ClarityHealth environment` for passive readiness and host facts.",
        recovery_4 = "4. Open `:ClarityHealth clipboard` when copy/paste is the only degraded capability.",
        recovery_5 = "5. Restart Neovim only after reviewing the evidence; Health never changes dependencies or project files.",
        recovery_boundary = "The two histories stay separate so presentation noise cannot be mistaken for a structured Clarity failure.",
        findings_header = "## Current audit findings",
        findings_none = "No current audit findings require attention.",
        finding_status = "  Status: %{value}",
        finding_detail = "  Detail: %{value}",
        finding_impact = "  Impact: %{value}",
        finding_repair = "  Repair: %{value}",
        finding_recheck = "  Recheck: %{value}",
        environment_header = "## Passive environment snapshot",
        environment_platform = "- Platform: %{value}",
        environment_nvim = "- Neovim: %{value}",
        environment_repo = "- Repository: %{value}",
        environment_ui = "- Attached UIs: %{value}",
        environment_lsp = "- Active LSP clients: %{value}",
        environment_core = "- Core readiness: %{value}",
        environment_host = "- Host capability: %{value}",
        environment_release = "- Release evidence: %{value}",
        environment_unavailable = "- Audit snapshot unavailable: %{value}",
        environment_note = "This route observes current state. It does not install, update, or repair anything.",
        lsp_header = "## Enabled LSP readiness",
        lsp_none = "No language servers are currently enabled.",
        lsp_item = "- %{server}: %{executable} — %{status}",
        lsp_missing = "  Repair: Install `%{executable}` externally and ensure it is on PATH.",
        lsp_policy = "Clarity never installs language servers automatically; it only reports the current PATH readiness.",
        clipboard_header = "## Clipboard capability",
        clipboard_mode = "- Editor mode: %{value}",
        clipboard_provider = "- Provider: %{value}",
        clipboard_kind = "- Session kind: %{value}",
        clipboard_ready = "- Readiness: %{value}",
        clipboard_copy = "- Normal yanks use the system clipboard when a provider is ready.",
        clipboard_ssh = "- In plain SSH, OSC52 is a copy-only path; terminal paste remains terminal-owned.",
        clipboard_privacy = "Health never reads or records clipboard contents.",
        yes = "ready",
        no = "degraded",
        unknown = "unknown",
        status_pass = "ready",
        status_fail = "blocked",
        status_warn = "degraded",
        status_ready = "ready",
        status_blocked = "blocked",
        status_degraded = "degraded",
        status_capable = "capable",
        status_unverified = "unverified",
        status_not_configured = "not configured",
        status_unknown = "unknown",
        messages_header = "## Native Neovim message history",
        messages_empty = "No native editor messages are currently available.",
        noice_header = "## Noice presentation history",
        noice_empty = "No Noice history is available in this session.",
        noice_inactive = "Noice is not active; native `:messages` remains the message source.",
        messages_boundary = "Clarity structured events are intentionally excluded here. Open `:ClarityHealth events` for typed outcomes.",
        events_header = "## Clarity structured diagnostic events",
        events_empty = "No Clarity diagnostic events have been recorded in this session.",
        events_boundary = "Native/Noice message history is intentionally excluded here. Open `:ClarityHealth messages` for presentation history.",
        event_context = "  context: %{value}",
        event_error = "  error: %{code} — %{message}",
        language_header = "## Interface language",
        language_choice = "- Preference: %{value}",
        language_effective = "- Effective language: %{value}",
        language_source = "- Source: %{value}",
        source_auto = "automatic detection",
        source_env = "environment variable",
        source_global = "vim.g.clarity_locale",
        source_persisted = "saved preference",
        source_runtime = "current session",
        language_usage = "Use `:ClarityLanguage auto`, `:ClarityLanguage en`, or `:ClarityLanguage zh`.",
        language_live = "Open Health views refresh in place when the effective language changes.",
        map_open = "Open %{route}",
        map_refresh = "Refresh Health",
        map_close = "Return from Health",
        unknown_route = "Unknown Clarity Health route: %{route}",
    },
    zh = {
        title = "# Clarity 健康中心 · %{route}",
        intro = "在一个安静、统一的入口中理解编辑器、恢复故障并查看证据。",
        navigation = "页面：`1` 概览 · `2` 恢复 · `3` 环境 · `4` 剪贴板 · `5` 消息 · `6` 事件 · `7` 语言",
        controls = "操作：`r` 刷新 · `q` 或 `Esc` 返回上一个缓冲区",
        route_overview = "概览",
        route_recovery = "恢复",
        route_environment = "环境",
        route_clipboard = "剪贴板",
        route_messages = "消息",
        route_events = "事件",
        route_language = "语言",
        overview_header = "## 以审阅为核心的必要功能",
        overview_body = "智能代理负责大范围修改；Clarity 让人工审阅、导航与精确修正保持清晰。",
        overview_find = "- 查找文件/文本：`<leader>ff` / `<leader>fw`",
        overview_review = "- 审阅诊断/Git：`<leader>sd` / `<leader>gs` / `<leader>gd`",
        overview_readability = "- 可读性：`<leader>cz` 折叠 / `<leader>uw` 换行；绝对行号始终稳定",
        overview_help = "- 返回这里：`<leader>hh` 或 `:ClarityHealth`",
        overview_locale = "- 界面语言：%{locale}",
        recovery_header = "## 安全恢复路径",
        recovery_1 = "1. 使用 `:ClarityHealth messages` 查看编辑器与 Noice 消息历史。",
        recovery_2 = "2. 使用 `:ClarityHealth events` 查看 Clarity 的结构化诊断结果。",
        recovery_3 = "3. 使用 `:ClarityHealth environment` 查看只读的就绪状态与宿主信息。",
        recovery_4 = "4. 只有复制/粘贴能力降级时，使用 `:ClarityHealth clipboard`。",
        recovery_5 = "5. 查看证据后再决定是否重启 Neovim；Health 永远不会修改依赖或项目文件。",
        recovery_boundary = "两类历史彼此分离，避免把界面提示噪音误认为 Clarity 的结构化故障。",
        findings_header = "## 当前审计发现",
        findings_none = "当前没有需要处理的审计发现。",
        finding_status = "  状态：%{value}",
        finding_detail = "  详情：%{value}",
        finding_impact = "  影响：%{value}",
        finding_repair = "  修复：%{value}",
        finding_recheck = "  复查：%{value}",
        environment_header = "## 只读环境快照",
        environment_platform = "- 平台：%{value}",
        environment_nvim = "- Neovim：%{value}",
        environment_repo = "- 仓库：%{value}",
        environment_ui = "- 已连接界面：%{value}",
        environment_lsp = "- 活跃 LSP 客户端：%{value}",
        environment_core = "- 核心就绪度：%{value}",
        environment_host = "- 宿主能力：%{value}",
        environment_release = "- 发布证据：%{value}",
        environment_unavailable = "- 无法取得审计快照：%{value}",
        environment_note = "此页面只观察当前状态，不会安装、更新或修复任何内容。",
        lsp_header = "## 已启用 LSP 就绪度",
        lsp_none = "当前没有启用任何语言服务器。",
        lsp_item = "- %{server}：%{executable} — %{status}",
        lsp_missing = "  修复：请在 Clarity 之外安装 `%{executable}`，并确保它位于 PATH 中。",
        lsp_policy = "Clarity 永远不会自动安装语言服务器；这里只报告当前 PATH 就绪状态。",
        clipboard_header = "## 剪贴板能力",
        clipboard_mode = "- 编辑器模式：%{value}",
        clipboard_provider = "- 提供者：%{value}",
        clipboard_kind = "- 会话类型：%{value}",
        clipboard_ready = "- 就绪度：%{value}",
        clipboard_copy = "- provider 就绪时，普通 yank 会使用系统剪贴板。",
        clipboard_ssh = "- 在纯 SSH 中，OSC52 只负责复制；粘贴仍由终端负责。",
        clipboard_privacy = "Health 永远不会读取或记录剪贴板内容。",
        yes = "就绪",
        no = "降级",
        unknown = "未知",
        status_pass = "就绪",
        status_fail = "阻塞",
        status_warn = "降级",
        status_ready = "就绪",
        status_blocked = "阻塞",
        status_degraded = "降级",
        status_capable = "可用",
        status_unverified = "未验证",
        status_not_configured = "未配置",
        status_unknown = "未知",
        messages_header = "## Neovim 原生消息历史",
        messages_empty = "当前没有可用的原生编辑器消息。",
        noice_header = "## Noice 界面消息历史",
        noice_empty = "当前会话没有可用的 Noice 历史。",
        noice_inactive = "Noice 当前未启用；原生 `:messages` 仍是消息来源。",
        messages_boundary = "这里刻意不显示 Clarity 结构化事件；使用 `:ClarityHealth events` 查看类型化结果。",
        events_header = "## Clarity 结构化诊断事件",
        events_empty = "当前会话尚未记录 Clarity 诊断事件。",
        events_boundary = "这里刻意不显示原生/Noice 消息；使用 `:ClarityHealth messages` 查看界面消息历史。",
        event_context = "  上下文：%{value}",
        event_error = "  错误：%{code} — %{message}",
        language_header = "## 界面语言",
        language_choice = "- 偏好：%{value}",
        language_effective = "- 当前生效语言：%{value}",
        language_source = "- 来源：%{value}",
        source_auto = "自动检测",
        source_env = "环境变量",
        source_global = "vim.g.clarity_locale",
        source_persisted = "已保存偏好",
        source_runtime = "当前会话",
        language_usage = "使用 `:ClarityLanguage auto`、`:ClarityLanguage en` 或 `:ClarityLanguage zh`。",
        language_live = "有效语言改变时，已打开的 Health 页面会原地刷新。",
        map_open = "打开%{route}",
        map_refresh = "刷新 Health",
        map_close = "从 Health 返回",
        unknown_route = "未知的 Clarity Health 页面：%{route}",
    },
}

local state = {
    buffer = nil,
    route = "overview",
    source_buffer = nil,
    deps = nil,
}

local route_callbacks = {}
local close_callback
local refresh_callback

local function interpolate(template, vars)
    return (
        template:gsub("%%{([%w_]+)}", function(key)
            return tostring(vars and vars[key] or ("%{" .. key .. "}"))
        end)
    )
end

local function locale()
    local i18n = state.deps and state.deps.i18n
    if i18n and type(i18n.get_locale) == "function" then
        local ok, value = pcall(i18n.get_locale)
        if ok and value == "zh" then
            return "zh"
        end
    end
    if i18n and type(i18n.get_state) == "function" then
        local ok, value = pcall(i18n.get_state)
        if ok and type(value) == "table" and value.effective == "zh" then
            return "zh"
        end
    end
    return "en"
end

local function t(key, vars)
    local language = locale()
    local template = strings[language][key] or strings.en[key] or key
    return interpolate(template, vars)
end

local function route_label(route)
    return t("route_" .. route)
end

local function safe_line(value, limit)
    local line = tostring(value or ""):gsub("[%z\r\n]", " ")
    limit = limit or 500
    if #line > limit then
        return line:sub(1, limit) .. "…"
    end
    return line
end

local function bounded_lines(values, limit)
    local result = {}
    values = type(values) == "table" and values or {}
    local start = math.max(1, #values - (limit or 100) + 1)
    for index = start, #values do
        table.insert(result, safe_line(values[index]))
    end
    return result
end

local function default_message_reader()
    local native = {}
    local ok_native, output = pcall(vim.api.nvim_exec2, "messages", { output = true })
    if ok_native and type(output) == "table" and type(output.output) == "string" and output.output ~= "" then
        native = vim.split(output.output, "\n", { plain = true, trimempty = true })
    end

    local noice = {}
    local noice_active = package.loaded["noice"] ~= nil or package.loaded["noice.config"] ~= nil
    if noice_active then
        local ok_manager, manager = pcall(require, "noice.message.manager")
        if ok_manager and type(manager.get) == "function" then
            local ok_messages, messages = pcall(manager.get, nil, {
                history = true,
                sort = true,
                count = 100,
            })
            if ok_messages then
                for _, message in ipairs(messages or {}) do
                    local ok_content, content = pcall(function()
                        return message:content()
                    end)
                    if ok_content and vim.trim(tostring(content or "")) ~= "" then
                        table.insert(noice, content)
                    end
                end
            end
        end
    end

    return {
        native = bounded_lines(native, 100),
        noice = bounded_lines(noice, 100),
        noice_active = noice_active,
    }
end

local function ensure_deps(opts)
    opts = opts or {}
    state.deps = vim.tbl_extend("force", state.deps or {}, {
        i18n = opts.i18n or (state.deps and state.deps.i18n) or require("config.i18n"),
        diagnostics = opts.diagnostics or (state.deps and state.deps.diagnostics) or require("config.diagnostics"),
        audit = opts.audit or (state.deps and state.deps.audit) or require("config.audit"),
        message_reader = opts.message_reader or (state.deps and state.deps.message_reader) or default_message_reader,
        transaction_hook = opts.transaction_hook or (state.deps and state.deps.transaction_hook),
    })
end

local function clipboard_mode()
    local values = vim.opt.clipboard:get()
    if type(values) == "string" then
        return values == "unnamedplus" and "unnamedplus" or "manual"
    end
    return vim.tbl_contains(values or {}, "unnamedplus") and "unnamedplus" or "manual"
end

local function locale_label(code)
    local i18n = state.deps.i18n
    if type(i18n.label) == "function" then
        local ok, value = pcall(i18n.label, code)
        if ok then
            return value
        end
    end
    return tostring(code or t("unknown"))
end

local function source_label(source)
    local key = "source_" .. tostring(source or "")
    return strings[locale()][key] or strings.en[key] or safe_line(source or t("unknown"))
end

local renderers = {}

function renderers.overview()
    local current = state.deps.i18n.get_state and state.deps.i18n.get_state() or { effective = locale() }
    return {
        t("overview_header"),
        "",
        t("overview_body"),
        "",
        t("overview_find"),
        t("overview_review"),
        t("overview_readability"),
        t("overview_help"),
        t("overview_locale", { locale = locale_label(current.effective) }),
    }
end

local function status_label(status)
    local normalized = tostring(status or "unknown"):lower():gsub("[^%w]+", "_")
    local key = "status_" .. normalized
    return strings[locale()][key] or strings.en[key] or safe_line(status or t("unknown"), 80)
end

local function audit_snapshot()
    local ok, report = pcall(state.deps.audit.get_report)
    if ok and type(report) == "table" then
        return report
    end
    return nil, safe_line(report or t("unknown"), 160)
end

local function append_findings(lines, report)
    vim.list_extend(lines, { "", t("findings_header"), "" })
    local count = 0
    for _, finding in ipairs((report and report.checks) or {}) do
        if finding.status ~= "pass" then
            count = count + 1
            table.insert(lines, string.format("- `%s`", safe_line(finding.id or "unknown", 120)))
            table.insert(lines, t("finding_status", { value = status_label(finding.status) }))
            table.insert(lines, t("finding_detail", { value = safe_line(finding.detail, 500) }))
            table.insert(lines, t("finding_impact", { value = safe_line(finding.impact, 500) }))
            table.insert(lines, t("finding_repair", { value = safe_line(finding.repair, 500) }))
            table.insert(lines, t("finding_recheck", { value = safe_line(finding.recheck, 160) }))
        end
    end
    if count == 0 then
        table.insert(lines, t("findings_none"))
    end
end

local function append_lsp_readiness(lines, report)
    vim.list_extend(lines, { "", t("lsp_header"), "" })
    local lsp = report and report.integrations and report.integrations.lsp or {}
    local servers = type(lsp.servers) == "table" and lsp.servers or {}
    if #servers == 0 then
        table.insert(lines, t("lsp_none"))
    end
    for _, server in ipairs(servers) do
        local executable = safe_line(server.executable or t("unknown"), 160)
        table.insert(
            lines,
            t("lsp_item", {
                server = safe_line(server.name or t("unknown"), 120),
                executable = executable,
                status = status_label(server.present and "pass" or "warn"),
            })
        )
        if not server.present then
            table.insert(lines, t("lsp_missing", { executable = executable }))
        end
    end
    table.insert(lines, "")
    table.insert(lines, t("lsp_policy"))
end

function renderers.recovery()
    local lines = {
        t("recovery_header"),
        "",
        t("recovery_1"),
        t("recovery_2"),
        t("recovery_3"),
        t("recovery_4"),
        t("recovery_5"),
        "",
        t("recovery_boundary"),
    }
    local report, err = audit_snapshot()
    if report then
        append_findings(lines, report)
    else
        vim.list_extend(lines, { "", t("environment_unavailable", { value = err }) })
    end
    return lines
end

local function nvim_version()
    local version = vim.version()
    return string.format("%d.%d.%d", version.major, version.minor, version.patch)
end

function renderers.environment()
    local uname = (vim.uv or vim.loop).os_uname()
    local root = vim.g.clarity_repo_root or vim.fn.getcwd()
    local clients = vim.lsp and vim.lsp.get_clients and vim.lsp.get_clients() or {}
    local lines = {
        t("environment_header"),
        "",
        t("environment_platform", { value = safe_line(uname.sysname .. " " .. uname.release) }),
        t("environment_nvim", { value = nvim_version() }),
        t("environment_repo", { value = safe_line(vim.fn.fnamemodify(root, ":~")) }),
        t("environment_ui", { value = #vim.api.nvim_list_uis() }),
        t("environment_lsp", { value = #clients }),
    }

    local report, err = audit_snapshot()
    if report then
        local summary = report.summary or {}
        table.insert(lines, t("environment_core", { value = status_label((summary.core or {}).status) }))
        table.insert(lines, t("environment_host", { value = status_label((summary.host or {}).status) }))
        table.insert(lines, t("environment_release", { value = status_label((summary.release or {}).status) }))
    else
        table.insert(lines, t("environment_unavailable", { value = err }))
    end
    table.insert(lines, "")
    table.insert(lines, t("environment_note"))
    if report then
        append_lsp_readiness(lines, report)
        append_findings(lines, report)
    end
    return lines
end

function renderers.clipboard()
    local ok, status = pcall(state.deps.audit.get_clipboard_status)
    status = ok and type(status) == "table" and status or {}
    return {
        t("clipboard_header"),
        "",
        t("clipboard_mode", { value = clipboard_mode() }),
        t("clipboard_provider", { value = safe_line(status.provider or t("unknown")) }),
        t("clipboard_kind", { value = safe_line(status.kind or t("unknown")) }),
        t("clipboard_ready", { value = status.present and t("yes") or t("no") }),
        "",
        t("clipboard_copy"),
        t("clipboard_ssh"),
        "",
        t("clipboard_privacy"),
    }
end

function renderers.messages()
    local ok, history = pcall(state.deps.message_reader)
    history = ok and type(history) == "table" and history or {}
    local native = bounded_lines(history.native, 100)
    local noice = bounded_lines(history.noice, 100)
    local lines = { t("messages_header"), "" }
    vim.list_extend(lines, #native > 0 and native or { t("messages_empty") })
    vim.list_extend(lines, { "", t("noice_header"), "" })
    if history.noice_active then
        vim.list_extend(lines, #noice > 0 and noice or { t("noice_empty") })
    else
        table.insert(lines, t("noice_inactive"))
    end
    vim.list_extend(lines, { "", t("messages_boundary") })
    return lines
end

local function encoded_context(context)
    if type(context) ~= "table" or next(context) == nil then
        return nil
    end
    local ok, value = pcall(vim.json.encode, context)
    return ok and safe_line(value) or nil
end

function renderers.events()
    local ok, events = pcall(state.deps.diagnostics.events)
    events = ok and type(events) == "table" and events or {}
    local lines = { t("events_header"), "" }
    if #events == 0 then
        table.insert(lines, t("events_empty"))
    else
        local start = math.max(1, #events - 99)
        for index = start, #events do
            local event = events[index]
            table.insert(
                lines,
                string.format(
                    "[%s] %-5s %s — %s",
                    safe_line(event.timestamp or "unknown", 80),
                    safe_line(event.level or "info", 20):upper(),
                    safe_line(event.event_id or "CLARITY_EVENT", 120),
                    safe_line(event.outcome or "recorded", 120)
                )
            )
            local context = encoded_context(event.context)
            if context then
                table.insert(lines, t("event_context", { value = context }))
            end
            if type(event.error) == "table" then
                table.insert(
                    lines,
                    t("event_error", {
                        code = safe_line(event.error.code or "unknown", 120),
                        message = safe_line(event.error.message or "unknown"),
                    })
                )
            end
        end
    end
    vim.list_extend(lines, { "", t("events_boundary") })
    return lines
end

function renderers.language()
    local current = state.deps.i18n.get_state and state.deps.i18n.get_state()
        or { choice = locale(), effective = locale(), source = "runtime" }
    return {
        t("language_header"),
        "",
        t("language_choice", { value = locale_label(current.choice) }),
        t("language_effective", { value = locale_label(current.effective) }),
        t("language_source", { value = source_label(current.source) }),
        "",
        t("language_usage"),
        t("language_live"),
    }
end

local function view_snapshots(buffer)
    local snapshots = {}
    for _, win in ipairs(vim.fn.win_findbuf(buffer)) do
        local ok, view = pcall(vim.api.nvim_win_call, win, function()
            return vim.fn.winsaveview()
        end)
        if ok then
            snapshots[win] = view
        end
    end
    return snapshots
end

local function restore_views(buffer, snapshots)
    local count = vim.api.nvim_buf_line_count(buffer)
    for win, view in pairs(snapshots or {}) do
        if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buffer then
            view.lnum = math.max(1, math.min(view.lnum or 1, count))
            view.topline = math.max(1, math.min(view.topline or 1, count))
            pcall(vim.api.nvim_win_call, win, function()
                vim.fn.winrestview(view)
            end)
        end
    end
end

local function close_health()
    local current = vim.api.nvim_get_current_buf()
    if current ~= state.buffer then
        return
    end
    if state.source_buffer and vim.api.nvim_buf_is_valid(state.source_buffer) then
        vim.api.nvim_win_set_buf(0, state.source_buffer)
    else
        vim.cmd("enew")
    end
end

local function apply_buffer_maps(buffer)
    for index, route in ipairs(ROUTE_ORDER) do
        route_callbacks[route] = route_callbacks[route] or function()
            M.open(route)
        end
        vim.keymap.set("n", tostring(index), route_callbacks[route], {
            buffer = buffer,
            nowait = true,
            silent = true,
            desc = t("map_open", { route = route_label(route) }),
        })
    end

    close_callback = close_callback or close_health
    refresh_callback = refresh_callback or function()
        M.refresh()
    end
    for _, lhs in ipairs({ "q", "<Esc>" }) do
        vim.keymap.set("n", lhs, close_callback, {
            buffer = buffer,
            nowait = true,
            silent = true,
            desc = t("map_close"),
        })
    end
    vim.keymap.set("n", "r", refresh_callback, {
        buffer = buffer,
        nowait = true,
        silent = true,
        desc = t("map_refresh"),
    })
end

local function ensure_buffer()
    if state.buffer and vim.api.nvim_buf_is_valid(state.buffer) then
        return state.buffer
    end

    local existing = vim.fn.bufnr("clarity://health")
    local buffer = existing >= 0 and vim.api.nvim_buf_is_valid(existing) and existing
        or vim.api.nvim_create_buf(false, true)
    state.buffer = buffer
    if vim.api.nvim_buf_get_name(buffer) == "" then
        vim.api.nvim_buf_set_name(buffer, "clarity://health")
    end
    vim.bo[buffer].buftype = "nofile"
    vim.bo[buffer].bufhidden = "hide"
    vim.bo[buffer].swapfile = false
    vim.bo[buffer].undofile = false
    vim.bo[buffer].filetype = "clarityhealth"
    return buffer
end

local function content(route)
    local lines = {
        t("title", { route = route_label(route) }),
        "",
        t("intro"),
        "",
        t("navigation"),
        t("controls"),
        "",
        "---",
        "",
    }
    return vim.list_extend(lines, renderers[route]())
end

local function buffer_snapshot(buffer)
    return {
        lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false),
        readonly = vim.bo[buffer].readonly,
        modifiable = vim.bo[buffer].modifiable,
        route = vim.b[buffer].clarity_health_route,
    }
end

local function restore_buffer(buffer, snapshot)
    if not vim.api.nvim_buf_is_valid(buffer) then
        return
    end
    pcall(function()
        vim.bo[buffer].readonly = false
        vim.bo[buffer].modifiable = true
        vim.api.nvim_buf_set_lines(buffer, 0, -1, false, snapshot.lines)
        vim.bo[buffer].modifiable = snapshot.modifiable
        vim.bo[buffer].readonly = snapshot.readonly
        vim.b[buffer].clarity_health_route = snapshot.route
    end)
end

local function apply_content(buffer, route, lines)
    vim.bo[buffer].readonly = false
    vim.bo[buffer].modifiable = true
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
    if state.deps.transaction_hook then
        state.deps.transaction_hook("after_lines")
    end
    vim.bo[buffer].modifiable = false
    vim.bo[buffer].readonly = true
    vim.b[buffer].clarity_health_route = route
    apply_buffer_maps(buffer)
end

function M.refresh(opts)
    opts = opts or {}
    ensure_deps()
    local buffer = ensure_buffer()
    local lines = content(state.route)
    local snapshot = buffer_snapshot(buffer)
    local snapshots = opts.preserve == false and {} or view_snapshots(buffer)
    local ok, err = xpcall(function()
        apply_content(buffer, state.route, lines)
        restore_views(buffer, snapshots)
    end, debug.traceback)
    if not ok then
        restore_buffer(buffer, snapshot)
        error(err, 0)
    end
    return buffer
end

function M.open(route)
    ensure_deps()
    route = vim.trim(tostring(route or "")):lower()
    route = route == "" and "overview" or (ALIASES[route] or route)
    if not ROUTES[route] then
        error(t("unknown_route", { route = route }))
    end

    local buffer = ensure_buffer()
    local lines = content(route)
    local current = vim.api.nvim_get_current_buf()
    local preserve = state.route == route
    local previous = {
        route = state.route,
        source_buffer = state.source_buffer,
        buffer = buffer_snapshot(buffer),
        current_buffer = current,
        current_view = vim.fn.winsaveview(),
    }
    local snapshots = preserve and view_snapshots(buffer) or {}
    local ok, err = xpcall(function()
        apply_content(buffer, route, lines)
        if current ~= buffer then
            state.source_buffer = current
        end
        state.route = route
        vim.api.nvim_win_set_buf(0, buffer)
        if state.deps.transaction_hook then
            state.deps.transaction_hook("after_switch")
        end
        if preserve then
            restore_views(buffer, snapshots)
        else
            vim.api.nvim_win_set_cursor(0, { 1, 0 })
        end
    end, debug.traceback)
    if not ok then
        state.route = previous.route
        state.source_buffer = previous.source_buffer
        restore_buffer(buffer, previous.buffer)
        if vim.api.nvim_buf_is_valid(previous.current_buffer) then
            pcall(vim.api.nvim_win_set_buf, 0, previous.current_buffer)
            pcall(vim.fn.winrestview, previous.current_view)
        end
        error(err, 0)
    end
    return buffer
end

function M.setup(opts)
    ensure_deps(opts)

    if vim.fn.exists(":ClarityHealth") ~= 2 then
        vim.api.nvim_create_user_command("ClarityHealth", function(info)
            M.open(info.args)
        end, {
            nargs = "?",
            complete = function(arg_lead)
                return vim.tbl_filter(function(route)
                    return vim.startswith(route, arg_lead)
                end, ROUTE_ORDER)
            end,
            desc = state.deps.i18n.t("commands.health"),
        })
    end

    local group = vim.api.nvim_create_augroup("clarity_health_locale", { clear = true })
    vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "ClarityLocaleChanged",
        callback = function()
            if state.buffer and vim.api.nvim_buf_is_valid(state.buffer) then
                M.refresh({ preserve = true })
            end
        end,
    })
end

function M._reset()
    if state.buffer and vim.api.nvim_buf_is_valid(state.buffer) then
        pcall(vim.api.nvim_buf_delete, state.buffer, { force = true })
    end
    pcall(vim.api.nvim_del_user_command, "ClarityHealth")
    pcall(vim.api.nvim_del_augroup_by_name, "clarity_health_locale")
    state.buffer = nil
    state.route = "overview"
    state.source_buffer = nil
    state.deps = nil
end

M.routes = ROUTES
M.route_order = ROUTE_ORDER
M.aliases = ALIASES
M._test = {
    strings = strings,
    bounded_lines = bounded_lines,
    default_message_reader = default_message_reader,
    renderers = renderers,
    state = state,
}

return M
