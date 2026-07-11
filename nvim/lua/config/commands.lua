local M = {}

local function default_export_path()
    return vim.fs.joinpath(vim.fn.stdpath("state"), "clarity", "export-" .. os.date("!%Y%m%dT%H%M%SZ") .. ".jsonl")
end

function M.setup(opts)
    opts = opts or {}
    local diagnostics = opts.diagnostics or require("config.diagnostics")
    local i18n = opts.i18n or require("config.i18n")
    local notify = opts.notify or vim.notify
    local health = opts.health or require("config.health")

    if vim.fn.exists(":ClarityLog") == 2 then
        return
    end

    vim.api.nvim_create_user_command("ClarityLog", function(info)
        local args = vim.trim(info.args or "")
        if args == "" or args == "tail" then
            health.open("events")
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

function M._reset() end

return M
