local M = {}

local routes = {
    overview = "ClarityStart",
    audit = "ClarityAudit",
    validate = "ClarityValidate",
    clipboard = "ClarityClipboard",
    log = "ClarityLog",
    sync = "ClaritySync",
    language = "ClarityLanguage",
}

function M.open(route)
    route = route == "" and "overview" or route
    local command = routes[route]
    if not command then
        error("Unknown Clarity health view: " .. route)
    end
    vim.cmd(command)
end

function M.setup(opts)
    opts = opts or {}
    local i18n = opts.i18n or require("config.i18n")

    if vim.fn.exists(":ClarityHealth") == 2 then
        return
    end

    vim.api.nvim_create_user_command("ClarityHealth", function(info)
        M.open(info.args)
    end, {
        nargs = "?",
        complete = function()
            return vim.tbl_keys(routes)
        end,
        desc = i18n.t("commands.health"),
    })
end

M.routes = routes

return M
