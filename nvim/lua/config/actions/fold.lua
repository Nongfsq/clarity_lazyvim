local M = {}

local function default_notify(message, level)
    vim.notify(message, level, { title = "Clarity" })
end

local function context(result)
    return {
        buffer_type = result.buffer_type,
        filetype = result.filetype,
        foldlevel = result.foldlevel,
        foldmethod = result.foldmethod,
        line = result.line,
        reason = result.reason,
    }
end

function M.toggle(opts)
    opts = opts or {}
    local diagnostics = opts.diagnostics or require("config.diagnostics")
    local i18n = opts.i18n or require("config.i18n")
    local notify = opts.notify or default_notify
    local deps = opts.deps
        or {
            buftype = function()
                return vim.bo.buftype
            end,
            filetype = function()
                return vim.bo.filetype
            end,
            foldmethod = function()
                return vim.wo.foldmethod
            end,
            line = function()
                return vim.fn.line(".")
            end,
            foldlevel = vim.fn.foldlevel,
            foldclosed = vim.fn.foldclosed,
            toggle = function()
                vim.cmd("normal! za")
            end,
            restore = function(line, was_closed)
                local is_closed = vim.fn.foldclosed(line)
                if (was_closed == -1) ~= (is_closed == -1) then
                    vim.cmd("normal! za")
                end
            end,
        }

    local ok, result = diagnostics.guard({
        event_id = "CLARITY_FOLD_ACTION_FAILED",
        error_code = "CLARITY_FOLD_ACTION_FAILED",
        component = "config.actions.fold",
        action = "toggle",
        message_key = "notifications.fold_failed",
        user_message = i18n.t("notifications.fold_failed"),
        notify = notify,
    }, function()
        local buffer_type = deps.buftype()
        local filetype = deps.filetype()
        local foldmethod = deps.foldmethod()
        local line = deps.line()
        if buffer_type ~= "" then
            return {
                outcome = "unsupported_buffer",
                buffer_type = buffer_type,
                filetype = filetype,
                foldmethod = foldmethod,
                line = line,
                foldlevel = 0,
            }
        end

        local fold_ok, foldlevel = pcall(deps.foldlevel, line)
        if not fold_ok or type(foldlevel) ~= "number" then
            return {
                outcome = "degraded",
                buffer_type = buffer_type,
                filetype = filetype,
                foldmethod = foldmethod,
                line = line,
                foldlevel = -1,
                reason = fold_ok and "invalid_foldlevel" or "fold_provider_error",
            }
        end
        if foldlevel <= 0 then
            return {
                outcome = "no_fold",
                buffer_type = buffer_type,
                filetype = filetype,
                foldmethod = foldmethod,
                line = line,
                foldlevel = foldlevel,
            }
        end
        local was_closed = deps.foldclosed and deps.foldclosed(line) or nil
        local toggle_ok, toggle_error = pcall(deps.toggle)
        if not toggle_ok then
            if deps.restore and was_closed ~= nil then
                pcall(deps.restore, line, was_closed)
            end
            error(toggle_error)
        end
        return {
            outcome = "toggled",
            buffer_type = buffer_type,
            filetype = filetype,
            foldmethod = foldmethod,
            line = line,
            foldlevel = foldlevel,
        }
    end)

    if not ok then
        return "failed"
    end

    local messages = {
        no_fold = { "notifications.fold_no_fold", vim.log.levels.INFO },
        unsupported_buffer = { "notifications.fold_unsupported", vim.log.levels.INFO },
        degraded = { "notifications.fold_degraded", vim.log.levels.WARN },
    }
    local presentation = messages[result.outcome]
    if presentation then
        notify(i18n.t(presentation[1]), presentation[2], { title = "Clarity" })
    end
    diagnostics.emit(result.outcome == "degraded" and vim.log.levels.WARN or vim.log.levels.INFO, {
        event_id = "CLARITY_FOLD_" .. result.outcome:upper(),
        component = "config.actions.fold",
        action = "toggle",
        outcome = result.outcome,
        message_key = presentation and presentation[1] or "notifications.fold_toggled",
        context = context(result),
    })
    return result.outcome
end

return M
