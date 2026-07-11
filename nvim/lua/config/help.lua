local M = {}
local i18n = require("config.i18n")

local STARTUP_GUIDE_VERSION = "2026-07-11-health-facade-v2"
local HEALTH_LHS = "<leader>hh"

local function is_interactive()
    return vim.env.CLARITY_NONINTERACTIVE ~= "1" and #vim.api.nvim_list_uis() > 0
end

local function startup_state_path()
    return vim.fn.stdpath("state") .. "/clarity_startup_guide_version.txt"
end

local function read_startup_state()
    local path = startup_state_path()
    if vim.fn.filereadable(path) ~= 1 then
        return nil
    end

    local ok, lines = pcall(vim.fn.readfile, path)
    if not ok or type(lines) ~= "table" or #lines == 0 then
        return nil
    end
    return lines[1]
end

local function mark_startup_seen()
    local path = startup_state_path()
    local ok_dir = pcall(vim.fn.mkdir, vim.fn.fnamemodify(path, ":h"), "p")
    if not ok_dir then
        return false
    end
    local ok, result = pcall(vim.fn.writefile, { STARTUP_GUIDE_VERSION }, path)
    return ok and result == 0
end

local function startup_buffer_ready()
    if not is_interactive() or vim.fn.argc() ~= 0 or vim.o.diff then
        return false
    end

    local buffer = vim.api.nvim_get_current_buf()
    return vim.api.nvim_buf_is_valid(buffer)
        and vim.api.nvim_buf_get_name(buffer) == ""
        and not vim.bo[buffer].modified
        and vim.bo[buffer].buftype == ""
end

local function should_show_startup_guide()
    return startup_buffer_ready() and read_startup_state() ~= STARTUP_GUIDE_VERSION
end

local function notify_failure(message)
    vim.notify(message, vim.log.levels.WARN, { title = "Clarity" })
end

local function complete_startup_open(show, mark, notify)
    local ok, buffer = pcall(show, { auto_open = true })
    if not ok or not buffer then
        notify(i18n.t("help.open_failed"))
        return false
    end
    return mark()
end

local function open_health(route)
    return require("config.health").open(route)
end

local function open_health_overview()
    return open_health("overview")
end

local function health_description()
    local ok, catalog = pcall(require, "config.actions.catalog")
    if ok and type(catalog.label) == "function" then
        local locale = type(i18n.get_locale) == "function" and i18n.get_locale() or nil
        local labeled, description = pcall(catalog.label, "health.open", locale)
        if labeled and description then
            return description
        end
    end
    return i18n.t("keymaps.help_start_hub")
end

local function apply_health_mapping()
    vim.keymap.set("n", HEALTH_LHS, open_health_overview, {
        silent = true,
        desc = health_description(),
    })
end

function M.setup()
    if vim.fn.exists(":ClarityStart") ~= 2 then
        vim.api.nvim_create_user_command("ClarityStart", function()
            open_health("overview")
        end, { desc = i18n.t("commands.start") })
    end

    if vim.fn.exists(":ClarityClipboard") ~= 2 then
        vim.api.nvim_create_user_command("ClarityClipboard", function()
            open_health("clipboard")
        end, { desc = i18n.t("commands.clipboard") })
    end

    if vim.fn.exists(":ClaritySync") ~= 2 then
        vim.api.nvim_create_user_command("ClaritySync", function()
            open_health("recovery")
        end, { desc = i18n.t("commands.sync") })
    end

    apply_health_mapping()

    local locale_group = vim.api.nvim_create_augroup("clarity_help_locale", { clear = true })
    vim.api.nvim_create_autocmd("User", {
        group = locale_group,
        pattern = "ClarityLocaleChanged",
        callback = apply_health_mapping,
    })

    local group = vim.api.nvim_create_augroup("clarity_startup_guide", { clear = true })
    vim.api.nvim_create_autocmd("VimEnter", {
        group = group,
        once = true,
        callback = function()
            if not should_show_startup_guide() then
                return
            end
            vim.defer_fn(function()
                if startup_buffer_ready() then
                    complete_startup_open(function()
                        return open_health("overview")
                    end, mark_startup_seen, notify_failure)
                end
            end, 120)
        end,
    })
end

M._test = {
    mark_startup_seen = mark_startup_seen,
    read_startup_state = read_startup_state,
    complete_startup_open = complete_startup_open,
    startup_guide_version = STARTUP_GUIDE_VERSION,
}

return M
