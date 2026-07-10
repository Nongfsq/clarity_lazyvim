local M = {}

local state = { buffer = nil }

local function event_lines(events)
    local lines = { "# Clarity Diagnostic Events", "" }
    if #events == 0 then
        table.insert(lines, "No Clarity diagnostic events have been recorded in this session.")
        return lines
    end
    for _, event in ipairs(events) do
        table.insert(
            lines,
            string.format(
                "[%s] %-5s %s — %s",
                event.timestamp or "unknown",
                tostring(event.level or "info"):upper(),
                event.event_id or "CLARITY_EVENT",
                event.outcome or "recorded"
            )
        )
        if event.context and next(event.context) then
            table.insert(lines, "  context: " .. vim.json.encode(event.context))
        end
        if event.error then
            table.insert(
                lines,
                "  error: " .. tostring(event.error.code or "unknown") .. " — " .. event.error.message
            )
        end
    end
    return lines
end

local function open_events(diagnostics, tail)
    local buffer = state.buffer
    if not buffer or not vim.api.nvim_buf_is_valid(buffer) then
        buffer = vim.api.nvim_create_buf(false, true)
        state.buffer = buffer
        vim.api.nvim_buf_set_name(buffer, "clarity://log")
        vim.bo[buffer].buftype = "nofile"
        vim.bo[buffer].bufhidden = "hide"
        vim.bo[buffer].swapfile = false
        vim.bo[buffer].filetype = "claritylog"
    end

    vim.bo[buffer].readonly = false
    vim.bo[buffer].modifiable = true
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, event_lines(diagnostics.events()))
    vim.bo[buffer].modifiable = false
    vim.bo[buffer].readonly = true
    vim.api.nvim_win_set_buf(0, buffer)
    local target_line = tail and vim.api.nvim_buf_line_count(buffer) or 1
    vim.api.nvim_win_set_cursor(0, { target_line, 0 })
end

local function default_export_path()
    return vim.fs.joinpath(vim.fn.stdpath("state"), "clarity", "export-" .. os.date("!%Y%m%dT%H%M%SZ") .. ".jsonl")
end

function M.setup(opts)
    opts = opts or {}
    local diagnostics = opts.diagnostics or require("config.diagnostics")
    local i18n = opts.i18n or require("config.i18n")
    local notify = opts.notify or vim.notify

    if vim.fn.exists(":ClarityLog") == 2 then
        return
    end

    vim.api.nvim_create_user_command("ClarityLog", function(info)
        local args = vim.trim(info.args or "")
        if args == "" then
            open_events(diagnostics, false)
            return
        end
        if args == "tail" then
            open_events(diagnostics, true)
            return
        end
        if args == "path" then
            notify(i18n.t("notifications.log_path", { path = diagnostics.path() }), vim.log.levels.INFO, {
                title = "Clarity",
            })
            return
        end
        if args == "export" or vim.startswith(args, "export ") then
            local target = vim.trim(args:sub(#"export" + 1))
            target = target == "" and default_export_path() or vim.fn.fnamemodify(vim.fn.expand(target), ":p")
            local ok, err = diagnostics.export(target)
            if ok then
                notify(i18n.t("notifications.log_exported", { path = target }), vim.log.levels.INFO, {
                    title = "Clarity",
                })
            else
                notify(i18n.t("notifications.log_export_failed", { reason = err }), vim.log.levels.ERROR, {
                    title = "Clarity",
                })
            end
            return
        end
        notify(i18n.t("notifications.log_usage"), vim.log.levels.WARN, { title = "Clarity" })
    end, {
        nargs = "*",
        complete = function(_, command_line)
            if command_line:match("%s+export%s+") then
                return {}
            end
            return { "tail", "path", "export" }
        end,
        desc = i18n.t("commands.log"),
    })
end

function M._reset()
    state.buffer = nil
end

return M
