local M = {}
local i18n = require("config.i18n")

local state = {
    buf = nil,
    win = nil,
}

local STARTUP_GUIDE_VERSION = "2026-04-20-startup-guide-v1"

local function repo_root()
    if type(vim.g.clarity_repo_root) == "string" and vim.g.clarity_repo_root ~= "" then
        return vim.g.clarity_repo_root
    end

    return vim.fn.getcwd()
end

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
    local dir = vim.fn.fnamemodify(path, ":h")
    pcall(vim.fn.mkdir, dir, "p")
    pcall(vim.fn.writefile, { STARTUP_GUIDE_VERSION }, path)
end

local function startup_buffer_ready()
    if not is_interactive() or vim.fn.argc() ~= 0 or vim.o.diff then
        return false
    end

    local buf = vim.api.nvim_get_current_buf()
    if not vim.api.nvim_buf_is_valid(buf) then
        return false
    end

    if vim.api.nvim_buf_get_name(buf) ~= "" or vim.bo[buf].modified or vim.bo[buf].buftype ~= "" then
        return false
    end

    return true
end

local function should_show_startup_guide()
    return startup_buffer_ready() and read_startup_state() ~= STARTUP_GUIDE_VERSION
end

local function platform_label()
    local uname = vim.loop.os_uname()
    local sysname = uname.sysname

    if sysname == "Linux" and vim.fn.has("wsl") == 1 then
        sysname = "WSL"
    end

    return string.format("%s %s", sysname, uname.release)
end

local function short_repo_root()
    return vim.fn.fnamemodify(repo_root(), ":~")
end

local function locale_label()
    return i18n.label(i18n.get_state().effective)
end

local function clipboard_provider()
    local ok, provider = pcall(function()
        return vim.fn["provider#clipboard#Executable"]()
    end)

    if not ok or not provider or provider == "" then
        return "missing"
    end

    return provider
end

local function option_contains(option_value, expected)
    if type(option_value) == "string" then
        if option_value == "" then
            return false
        end

        return option_value == expected
    end

    return vim.tbl_contains(option_value or {}, expected)
end

local function clipboard_mode()
    local entries = vim.opt.clipboard:get()
    return option_contains(entries, "unnamedplus") and "unnamedplus" or "manual"
end

local function close_panel()
    if state.win and vim.api.nvim_win_is_valid(state.win) then
        vim.api.nvim_win_close(state.win, true)
    end

    if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
        vim.api.nvim_buf_delete(state.buf, { force = true })
    end

    state.win = nil
    state.buf = nil
end

local function run_after_close(action)
    close_panel()
    vim.schedule(action)
end

local function feedkeys(keys)
    local termcodes = vim.api.nvim_replace_termcodes(keys, true, false, true)
    vim.api.nvim_feedkeys(termcodes, "mt", false)
end

local function open_float(lines, title)
    close_panel()

    local buf = vim.api.nvim_create_buf(false, true)
    local width = math.min(math.max(84, vim.o.columns - 12), 110)
    local height = math.min(#lines + 2, math.max(18, vim.o.lines - 6))
    local row = math.max(1, math.floor((vim.o.lines - height) / 2) - 1)
    local col = math.max(2, math.floor((vim.o.columns - width) / 2))

    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        style = "minimal",
        border = "rounded",
        title = title,
        title_pos = "center",
        width = width,
        height = height,
        row = row,
        col = col,
    })

    state.buf = buf
    state.win = win

    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].swapfile = false
    vim.bo[buf].filetype = "markdown"
    vim.bo[buf].modifiable = true

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    vim.bo[buf].modifiable = false
    vim.wo[win].number = false
    vim.wo[win].relativenumber = false
    vim.wo[win].signcolumn = "no"
    vim.wo[win].cursorline = false
    vim.wo[win].wrap = false
    vim.wo[win].conceallevel = 0

    local function map(lhs, rhs, desc)
        vim.keymap.set("n", lhs, rhs, { buffer = buf, nowait = true, silent = true, desc = desc })
    end

    map("q", close_panel, i18n.t("help.map_close"))
    map("<Esc>", close_panel, i18n.t("help.map_close"))

    return buf
end

local function show_clipboard_help()
    local provider = clipboard_provider()
    local mode = clipboard_mode()
    local lines = {
        i18n.t("help.clipboard_header"),
        "",
        i18n.t("help.clipboard_current_mode", { mode = mode }),
        i18n.t("help.clipboard_current_provider", { provider = provider }),
        "",
        i18n.t("help.clipboard_paths_header"),
        "",
        i18n.t("help.clipboard_path_1"),
        i18n.t("help.clipboard_path_1_detail"),
        "",
        i18n.t("help.clipboard_path_2"),
        i18n.t("help.clipboard_path_2_detail"),
        "",
        i18n.t("help.clipboard_path_3"),
        i18n.t("help.clipboard_path_3_detail"),
        "",
        i18n.t("help.clipboard_config_header"),
        "",
        i18n.t("help.clipboard_config_line_1"),
        i18n.t("help.clipboard_config_line_2"),
        "",
        i18n.t("help.clipboard_rule_header"),
        "",
        i18n.t("help.clipboard_rule_line_1"),
        i18n.t("help.clipboard_rule_line_2"),
        i18n.t("help.clipboard_rule_line_3"),
        "",
        i18n.t("help.clipboard_recovery_header"),
        "",
        i18n.t("help.clipboard_recovery_line_1"),
        i18n.t("help.clipboard_recovery_line_2"),
        i18n.t("help.clipboard_recovery_line_3"),
    }

    local buf = open_float(lines, i18n.t("help.clipboard_title"))

    vim.keymap.set("n", "a", function()
        run_after_close(function()
            vim.cmd("ClarityAudit")
        end)
    end, { buffer = buf, nowait = true, silent = true, desc = i18n.t("help.map_run_audit") })

    vim.keymap.set("n", "h", function()
        run_after_close(function()
            vim.cmd("ClarityStart")
        end)
    end, { buffer = buf, nowait = true, silent = true, desc = i18n.t("help.map_return_to_start") })
end

local function show_sync_help()
    local uname = vim.loop.os_uname()
    local platform = string.format("%s %s", uname.sysname, uname.release)
    local current_repo = repo_root()
    local repo_note = uname.sysname == "Windows_NT" and i18n.t("help.sync_repo_note_windows")
        or i18n.t("help.sync_repo_note_wsl")

    local lines = {
        i18n.t("help.sync_header"),
        "",
        i18n.t("help.sync_platform", { platform = platform }),
        i18n.t("help.sync_repo", { repo = current_repo }),
        repo_note,
        "",
        i18n.t("help.sync_rule_header"),
        "",
        i18n.t("help.sync_rule_1"),
        i18n.t("help.sync_rule_2"),
        i18n.t("help.sync_rule_3"),
        "",
        i18n.t("help.sync_update_header"),
        "",
        i18n.t("help.sync_update_1"),
        i18n.t("help.sync_update_2"),
        i18n.t("help.sync_update_3"),
        "",
        i18n.t("help.sync_stale_header"),
        "",
        i18n.t("help.sync_stale_1"),
        i18n.t("help.sync_stale_2"),
        i18n.t("help.sync_stale_3"),
        "",
        i18n.t("help.sync_recovery_header"),
        "",
        i18n.t("help.sync_recovery_line_1"),
        i18n.t("help.sync_recovery_line_2"),
        i18n.t("help.sync_recovery_line_3"),
    }

    local buf = open_float(lines, i18n.t("help.sync_title"))

    vim.keymap.set("n", "a", function()
        run_after_close(function()
            vim.cmd("ClarityAudit")
        end)
    end, { buffer = buf, nowait = true, silent = true, desc = i18n.t("help.map_run_audit") })

    vim.keymap.set("n", "h", function()
        run_after_close(function()
            vim.cmd("ClarityStart")
        end)
    end, { buffer = buf, nowait = true, silent = true, desc = i18n.t("help.map_return_to_start") })
end

local function show_start(opts)
    opts = opts or {}

    local intro = opts.auto_open and i18n.t("help.start_intro_auto") or i18n.t("help.start_intro_manual")
    local lines = {
        i18n.t("help.start_header"),
        "",
        intro,
        i18n.t("help.start_reopen"),
        "",
        i18n.t("help.start_locale", { locale = locale_label() }),
        i18n.t("help.start_platform", { platform = platform_label() }),
        i18n.t("help.start_clipboard_provider", { provider = clipboard_provider() }),
        i18n.t("help.start_repo_root", { root = short_repo_root() }),
        "",
        i18n.t("help.start_actions_header"),
        "",
        i18n.t("help.start_action_1"),
        i18n.t("help.start_action_2"),
        i18n.t("help.start_action_3"),
        i18n.t("help.start_action_4"),
        i18n.t("help.start_action_5"),
        i18n.t("help.start_action_6"),
        i18n.t("help.start_action_7"),
        i18n.t("help.start_action_8"),
        i18n.t("help.start_action_9"),
        i18n.t("help.start_action_10"),
        "",
        i18n.t("help.start_recovery_header"),
        "",
        i18n.t("help.start_recovery_keymaps"),
        i18n.t("help.start_recovery_audit"),
        i18n.t("help.start_recovery_validate"),
        i18n.t("help.start_recovery_clipboard"),
        i18n.t("help.start_recovery_sync"),
        i18n.t("help.start_recovery_language"),
        "",
        i18n.t("help.start_stale_header"),
        "",
        i18n.t("help.start_stale_line_1"),
        i18n.t("help.start_stale_line_2"),
        "",
        i18n.t("help.start_close_header"),
        "",
        i18n.t("help.start_close_line"),
    }

    local buf = open_float(lines, opts.auto_open and i18n.t("help.start_first_title") or i18n.t("help.start_title"))

    local actions = {
        f = function()
            run_after_close(function()
                require("lazyvim.util.pick").open("files")
            end)
        end,
        w = function()
            run_after_close(function()
                require("lazyvim.util.pick").open("live_grep")
            end)
        end,
        e = function()
            run_after_close(function()
                vim.cmd("Neotree toggle " .. vim.fn.getcwd())
            end)
        end,
        b = function()
            run_after_close(function()
                require("lazyvim.util.pick").open("buffers")
            end)
        end,
        t = function()
            run_after_close(function()
                feedkeys("<leader>tf")
            end)
        end,
        k = function()
            run_after_close(function()
                feedkeys("<leader>sk")
            end)
        end,
        a = function()
            run_after_close(function()
                vim.cmd("ClarityAudit")
            end)
        end,
        v = function()
            run_after_close(function()
                vim.cmd("ClarityValidate")
            end)
        end,
        c = show_clipboard_help,
        s = show_sync_help,
        l = function()
            run_after_close(function()
                vim.cmd("ClarityLanguage")
            end)
        end,
    }

    for lhs, action in pairs(actions) do
        vim.keymap.set("n", lhs, action, {
            buffer = buf,
            nowait = true,
            silent = true,
            desc = i18n.t("help.map_start_action"),
        })
    end
end

function M.setup()
    if vim.fn.exists(":ClarityStart") ~= 2 then
        vim.api.nvim_create_user_command("ClarityStart", show_start, {
            desc = i18n.t("commands.start"),
        })
    end

    if vim.fn.exists(":ClarityClipboard") ~= 2 then
        vim.api.nvim_create_user_command("ClarityClipboard", show_clipboard_help, {
            desc = i18n.t("commands.clipboard"),
        })
    end

    if vim.fn.exists(":ClaritySync") ~= 2 then
        vim.api.nvim_create_user_command("ClaritySync", show_sync_help, {
            desc = i18n.t("commands.sync"),
        })
    end

    vim.keymap.set("n", "<leader>hh", function()
        vim.cmd("ClarityStart")
    end, { desc = i18n.t("keymaps.help_start_hub") })

    local group = vim.api.nvim_create_augroup("clarity_startup_guide", { clear = true })
    vim.api.nvim_create_autocmd("VimEnter", {
        group = group,
        once = true,
        callback = function()
            if not should_show_startup_guide() then
                return
            end

            mark_startup_seen()

            vim.defer_fn(function()
                if startup_buffer_ready() then
                    show_start({ auto_open = true })
                end
            end, 120)
        end,
    })
end

return M
