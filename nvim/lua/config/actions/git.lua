local M = {}

local DEFAULT_TIMEOUT_MS = 5000
local DEFAULT_MAX_BYTES = 256 * 1024

local state = {
    action = nil,
    buffer = nil,
    outcome = nil,
    window = nil,
}

local labels = {
    en = {
        blame_line = "Git Blame",
        branch_graph = "Git Branch Graph",
        diff = "Git Diff",
        failed = "The Git observation could not finish.",
        log = "Git Recent History",
        missing_git = "Git is unavailable. Install Git and retry.",
        no_output = "No matching Git information was found.",
        not_repo = "The current file or directory is not inside a Git repository.",
        output_limited = "Output reached Clarity's safety limit; partial results are shown.",
        status = "Git Status",
        timeout = "The Git observation timed out; narrow the repository scope and retry.",
    },
    zh = {
        blame_line = "Git 行归属",
        branch_graph = "Git 分支图",
        diff = "Git 差异",
        failed = "Git 查看操作未能完成。",
        log = "Git 最近历史",
        missing_git = "Git 不可用。请安装 Git 后重试。",
        no_output = "没有找到相应的 Git 信息。",
        not_repo = "当前文件或目录不在 Git 仓库中。",
        output_limited = "输出已达到 Clarity 安全上限；当前显示部分结果。",
        status = "Git 状态",
        timeout = "Git 查看操作超时；请缩小仓库范围后重试。",
    },
}

local commands = {
    status = function()
        return { "status", "--short", "--branch", "--untracked-files=all" }
    end,
    diff = function()
        return { "diff", "--no-color", "--no-ext-diff", "--find-renames", "HEAD", "--" }
    end,
    log = function()
        return {
            "log",
            "--decorate=short",
            "--date=short",
            "--pretty=format:%h  %ad  %an  %s",
            "--no-show-signature",
            "--max-count=200",
        }
    end,
    branch_graph = function()
        return {
            "log",
            "--graph",
            "--decorate=short",
            "--oneline",
            "--all",
            "--no-show-signature",
            "--max-count=300",
        }
    end,
    blame_line = function(context)
        return {
            "blame",
            "--date=short",
            "-L",
            string.format("%d,%d", context.line, context.line),
            "--",
            context.relative_file,
        }
    end,
}

local filetypes = {
    blame_line = "git",
    branch_graph = "git",
    diff = "diff",
    log = "git",
    status = "git",
}

local function locale()
    local ok, i18n = pcall(require, "config.i18n")
    if ok then
        if type(i18n.get_state) == "function" then
            local state_ok, value = pcall(i18n.get_state)
            if state_ok and type(value) == "table" and value.effective == "zh" then
                return "zh"
            end
        elseif type(i18n.get_locale) == "function" then
            local locale_ok, value = pcall(i18n.get_locale)
            if locale_ok and value == "zh" then
                return "zh"
            end
        end
    end
    return "en"
end

local function text(key)
    local language = locale()
    return labels[language][key] or labels.en[key] or key
end

local function close_view()
    if state.window and vim.api.nvim_win_is_valid(state.window) then
        vim.api.nvim_win_close(state.window, true)
    end
    if state.buffer and vim.api.nvim_buf_is_valid(state.buffer) then
        vim.api.nvim_buf_delete(state.buffer, { force = true })
    end
    state.buffer = nil
    state.window = nil
    state.action = nil
    state.outcome = nil
end

local localized_outcomes = {
    empty = "no_output",
    failed = "failed",
    missing_git = "missing_git",
    not_repo = "not_repo",
    output_limited = "output_limited",
    timeout = "timeout",
}

local function render(action, root, lines, outcome)
    close_view()

    local buffer = vim.api.nvim_create_buf(false, true)
    local width = math.max(1, math.min(100, vim.o.columns - 4))
    local height = math.max(1, math.min(math.max(#lines, 4), vim.o.lines - 4))
    local window = vim.api.nvim_open_win(buffer, true, {
        relative = "editor",
        style = "minimal",
        border = "rounded",
        title = " " .. text(action) .. " ",
        title_pos = "center",
        width = width,
        height = height,
        row = math.max(0, math.floor((vim.o.lines - height - 2) / 2)),
        col = math.max(0, math.floor((vim.o.columns - width - 2) / 2)),
    })

    state.buffer = buffer
    state.window = window
    state.action = action
    state.outcome = outcome
    vim.api.nvim_buf_set_name(buffer, "clarity://git/" .. action)
    vim.bo[buffer].buftype = "nofile"
    vim.bo[buffer].bufhidden = "wipe"
    vim.bo[buffer].swapfile = false
    vim.bo[buffer].filetype = filetypes[action]
    vim.bo[buffer].modifiable = true
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
    vim.bo[buffer].modifiable = false
    vim.bo[buffer].readonly = true
    vim.wo[window].number = false
    vim.wo[window].relativenumber = false
    vim.wo[window].signcolumn = "no"
    vim.wo[window].wrap = true
    vim.wo[window].linebreak = true
    vim.wo[window].breakindent = true

    local map_opts = { buffer = buffer, nowait = true, silent = true }
    vim.keymap.set("n", "q", close_view, vim.tbl_extend("force", map_opts, { desc = "Close Git observation" }))
    vim.keymap.set("n", "<Esc>", close_view, vim.tbl_extend("force", map_opts, { desc = "Close Git observation" }))
    vim.keymap.set("n", "<C-d>", "<C-d>", vim.tbl_extend("force", map_opts, { desc = "Scroll down" }))
    vim.keymap.set("n", "<C-u>", "<C-u>", vim.tbl_extend("force", map_opts, { desc = "Scroll up" }))

    return { buffer = buffer, window = window, root = root }
end

local function refresh_locale()
    if not state.action or not state.window or not vim.api.nvim_win_is_valid(state.window) then
        return
    end

    local config = vim.api.nvim_win_get_config(state.window)
    config.title = " " .. text(state.action) .. " "
    vim.api.nvim_win_set_config(state.window, config)

    local key = localized_outcomes[state.outcome]
    if key and state.buffer and vim.api.nvim_buf_is_valid(state.buffer) then
        vim.bo[state.buffer].modifiable = true
        vim.api.nvim_buf_set_lines(state.buffer, 0, 1, false, { text(key) })
        vim.bo[state.buffer].modifiable = false
    end
end

local locale_group = vim.api.nvim_create_augroup("clarity_git_observation_locale", { clear = true })
vim.api.nvim_create_autocmd("User", {
    group = locale_group,
    pattern = "ClarityLocaleChanged",
    callback = refresh_locale,
})

local function default_start()
    local name = vim.api.nvim_buf_get_name(0)
    if name ~= "" then
        return vim.fs.dirname(vim.fs.normalize(name)), vim.fs.normalize(name)
    end
    return vim.uv.cwd(), nil
end

local function default_root(start)
    return start and vim.fs.root(start, { ".git" }) or nil
end

local function relative_file(root, file)
    if not file or file == "" then
        return nil
    end
    local relative = vim.fs.relpath(root, file)
    if not relative or relative == ".." or vim.startswith(relative, "../") or vim.startswith(relative, "..\\") then
        return nil
    end
    return relative
end

local function default_notify(message, level)
    vim.notify(message, level, { title = "Clarity" })
end

local function default_deps()
    return {
        diagnostics = require("config.diagnostics"),
        executable = vim.fn.executable,
        notify = default_notify,
        render = render,
        root = default_root,
        schedule = vim.schedule,
        start = default_start,
        system = vim.system,
    }
end

local function event_id(action, outcome)
    return "CLARITY_GIT_" .. action:upper() .. "_" .. outcome:upper()
end

local function emit(deps, action, result, level)
    deps.diagnostics.emit(level, {
        event_id = event_id(action, result.outcome),
        component = "config.actions.git",
        action = action,
        outcome = result.outcome,
        message_key = "git." .. result.outcome,
        context = {
            reason = result.reason,
            scope = result.root and "repository" or "none",
        },
    })
end

local function complete(opts, result)
    if opts.on_complete then
        opts.on_complete(result)
    end
    return result
end

local function immediate(opts, deps, action, outcome, message, level, root)
    local result = { action = action, outcome = outcome, root = root, reason = outcome }
    if message then
        result.view = deps.render(action, root, { message }, outcome)
    end
    emit(deps, action, result, level)
    if message then
        deps.notify(message, level)
    end
    return complete(opts, result)
end

local function output_lines(value)
    value = (value or ""):gsub("\r\n", "\n"):gsub("\r", "\n")
    local lines = vim.split(value, "\n", { plain = true })
    while #lines > 0 and lines[#lines] == "" do
        table.remove(lines)
    end
    return lines
end

local function observe(action, opts)
    opts = opts or {}
    local deps = vim.tbl_extend("force", default_deps(), opts.deps or {})
    local levels = vim.log.levels

    if deps.executable("git") ~= 1 then
        return immediate(opts, deps, action, "missing_git", text("missing_git"), levels.WARN)
    end

    local start, file = deps.start()
    local root = deps.root(start)
    if not root then
        return immediate(opts, deps, action, "not_repo", text("not_repo"), levels.INFO)
    end

    local context = { root = root }
    if action == "blame_line" then
        context.line = math.max(1, tonumber(opts.line) or vim.api.nvim_win_get_cursor(0)[1])
        context.relative_file = relative_file(root, file)
        if not context.relative_file then
            return immediate(opts, deps, action, "not_repo", text("not_repo"), levels.INFO, root)
        end
    end

    local argv = {
        "git",
        "--no-pager",
        "--no-optional-locks",
        "-c",
        "core.quotepath=false",
        "-c",
        "color.ui=false",
    }
    vim.list_extend(argv, commands[action](context))

    local max_bytes = opts.max_bytes or DEFAULT_MAX_BYTES
    local stdout, stderr = {}, {}
    local bytes = 0
    local limited = false
    local process
    local pending_kill = false

    local function collect(target, error_message, data)
        if error_message and error_message ~= "" then
            data = (data or "") .. error_message
        end
        if not data or data == "" or limited then
            return
        end
        local remaining = max_bytes - bytes
        if remaining > 0 then
            target[#target + 1] = data:sub(1, remaining)
            bytes = bytes + math.min(#data, remaining)
        end
        if #data > remaining then
            limited = true
            if process then
                process:kill(15)
            else
                pending_kill = true
            end
        end
    end

    local function finish(system_result)
        deps.schedule(function()
            local result = {
                action = action,
                argv = argv,
                code = system_result.code,
                root = root,
            }
            local lines
            local level = levels.INFO
            if limited then
                result.outcome = "output_limited"
                result.reason = "max_bytes"
                level = levels.WARN
                lines = output_lines(table.concat(stdout))
                table.insert(lines, 1, text("output_limited"))
                deps.notify(text("output_limited"), level)
            elseif system_result.code == 124 then
                result.outcome = "timeout"
                result.reason = "timeout"
                level = levels.WARN
                lines = { text("timeout") }
                deps.notify(text("timeout"), level)
            elseif system_result.code ~= 0 then
                result.outcome = "failed"
                result.reason = "exit_" .. tostring(system_result.code)
                level = levels.ERROR
                lines = output_lines(table.concat(stderr))
                if #lines == 0 then
                    lines = { text("failed") }
                else
                    table.insert(lines, 1, text("failed"))
                end
                deps.notify(text("failed"), level)
            else
                lines = output_lines(table.concat(stdout))
                if #lines == 0 then
                    result.outcome = "empty"
                    lines = { text("no_output") }
                else
                    result.outcome = "rendered"
                end
            end
            result.view = deps.render(action, root, lines, result.outcome)
            emit(deps, action, result, level)
            complete(opts, result)
        end)
    end

    local ok, system_or_error = pcall(deps.system, argv, {
        cwd = root,
        env = {
            GIT_OPTIONAL_LOCKS = "0",
            LANGUAGE = "C",
            LC_ALL = "C",
        },
        stdout = function(error_message, data)
            collect(stdout, error_message, data)
        end,
        stderr = function(error_message, data)
            collect(stderr, error_message, data)
        end,
        text = true,
        timeout = opts.timeout_ms or DEFAULT_TIMEOUT_MS,
    }, finish)
    if not ok or not system_or_error then
        return immediate(opts, deps, action, "failed", text("failed"), levels.ERROR, root)
    end
    process = system_or_error
    if pending_kill then
        process:kill(15)
    end

    return { action = action, argv = argv, outcome = "started", root = root }
end

function M.status(opts)
    return observe("status", opts)
end

function M.diff(opts)
    return observe("diff", opts)
end

function M.log(opts)
    return observe("log", opts)
end

function M.branch_graph(opts)
    return observe("branch_graph", opts)
end

function M.blame_line(opts)
    return observe("blame_line", opts)
end

return M
