local M = {}

local valid_choices = {
    auto = true,
    en = true,
    zh = true,
}

local state

local strings = {
    en = {
        locale = {
            choice = {
                auto = "Auto",
                en = "English",
                zh = "Chinese",
            },
            source = {
                env = "environment",
                global = "vim.g.clarity_locale",
                persisted = "saved preference",
                auto = "automatic detection",
                runtime = "current session",
            },
            current = "Clarity language choice: %{choice}; effective UI: %{effective}; source: %{source}.",
            usage = "Use `:ClarityLanguage {auto|en|zh}` to change it.",
            updated = "Clarity language preference saved as %{choice}. Effective UI: %{effective}.",
            invalid = "Unsupported locale `%{choice}`. Use one of: auto, en, zh.",
            save_failed = "Clarity could not save the language preference: %{reason}",
        },
        commands = {
            health = "Open the unified Clarity help and health entry",
            audit = "Open Health environment; use ! for machine-readable audit JSON",
            validate = "Open Health recovery; use ! for machine-readable validation JSON",
            start = "Open the Clarity Health overview",
            clipboard = "Open the Health clipboard route",
            sync = "Open the Health recovery route",
            language = "Show or set the Clarity UI language",
            log = "View or export Clarity diagnostic events",
        },
        help = {
            open_failed = "Clarity Health could not open. The first-start guide remains pending; run `:ClarityHealth` to retry.",
        },
        keymaps = {
            next_hunk = "Next Git hunk",
            prev_hunk = "Previous Git hunk",
            preview_hunk = "Hunk: preview hunk",
            explorer_cwd = "Explorer (current working directory)",
            explorer_root = "Explorer (project root)",
            terminal_float_center = "Floating terminal",
            help_start_hub = "Clarity help and health",
        },
        notifications = {
            feature_unavailable = "%{feature} is unavailable because `%{commands}` is not installed.",
            fold_no_fold = "There is no code fold at the cursor.",
            fold_unsupported = "Code folding is unavailable in this window.",
            fold_degraded = "The code-fold provider is not ready for this buffer.",
            fold_failed = "Clarity could not toggle this fold. Open `:ClarityHealth events` for details.",
            fold_toggled = "Code fold toggled.",
            log_path = "Clarity diagnostic log: %{path}",
            log_exported = "Clarity diagnostics exported to %{path}.",
            log_export_failed = "Clarity could not export diagnostics: %{reason}",
            log_usage = "Use `:ClarityLog`, `:ClarityLog tail`, `:ClarityLog path`, or `:ClarityLog export [path]`.",
        },
    },
    zh = {
        locale = {
            choice = {
                auto = "自动",
                en = "英文",
                zh = "中文",
            },
            source = {
                env = "环境变量",
                global = "vim.g.clarity_locale",
                persisted = "已保存偏好",
                auto = "自动检测",
                runtime = "当前会话",
            },
            current = "Clarity 语言选择：%{choice}；当前界面语言：%{effective}；来源：%{source}。",
            usage = "使用 `:ClarityLanguage {auto|en|zh}` 切换界面语言。",
            updated = "Clarity 语言偏好已保存为 %{choice}。当前界面语言：%{effective}。",
            invalid = "不支持的语言 `%{choice}`。可用值：auto、en、zh。",
            save_failed = "Clarity 无法保存语言偏好：%{reason}",
        },
        commands = {
            health = "打开统一的 Clarity 帮助与健康入口",
            audit = "打开 Health 环境页；使用 ! 输出机器可读审计 JSON",
            validate = "打开 Health 恢复页；使用 ! 输出机器可读验证 JSON",
            start = "打开 Clarity Health 总览",
            clipboard = "打开 Health 剪贴板页",
            sync = "打开 Health 恢复页",
            language = "查看或设置 Clarity 界面语言",
            log = "查看或导出 Clarity 诊断事件",
        },
        help = {
            open_failed = "Clarity Health 无法打开。首次引导仍待显示；请运行 `:ClarityHealth` 重试。",
        },
        keymaps = {
            next_hunk = "下一个 Git 改动块",
            prev_hunk = "上一个 Git 改动块",
            preview_hunk = "预览 Git 改动块",
            explorer_cwd = "文件树（当前工作目录）",
            explorer_root = "文件树（项目根目录）",
            terminal_float_center = "浮动终端",
            help_start_hub = "Clarity 帮助与健康",
        },
        notifications = {
            feature_unavailable = "%{feature} 当前不可用，因为没有安装 `%{commands}`。",
            fold_no_fold = "光标所在位置没有可折叠的代码。",
            fold_unsupported = "当前窗口不支持代码折叠。",
            fold_degraded = "当前缓冲区的代码折叠服务尚未就绪。",
            fold_failed = "Clarity 无法切换此折叠。请打开 `:ClarityHealth events` 查看详情。",
            fold_toggled = "代码折叠已切换。",
            log_path = "Clarity 诊断日志：%{path}",
            log_exported = "Clarity 诊断信息已导出到 %{path}。",
            log_export_failed = "Clarity 无法导出诊断信息：%{reason}",
            log_usage = "使用 `:ClarityLog`、`:ClarityLog tail`、`:ClarityLog path` 或 `:ClarityLog export [路径]`。",
        },
    },
}

local function state_path()
    return vim.fn.stdpath("state") .. "/clarity_locale.txt"
end

local function normalize_choice(choice)
    if type(choice) ~= "string" then
        return nil
    end

    local normalized = vim.trim(choice):lower()
    return valid_choices[normalized] and normalized or nil
end

local function read_saved_choice()
    local path = state_path()
    if vim.fn.filereadable(path) ~= 1 then
        return nil
    end

    local ok, lines = pcall(vim.fn.readfile, path)
    if not ok or type(lines) ~= "table" or #lines == 0 then
        return nil
    end

    return normalize_choice(lines[1])
end

local function write_saved_choice(choice)
    local path = state_path()
    local dir = vim.fn.fnamemodify(path, ":h")
    local made_dir, mkdir_result = pcall(vim.fn.mkdir, dir, "p")
    if not made_dir or vim.fn.isdirectory(dir) ~= 1 then
        return false, made_dir and "could not create the state directory" or tostring(mkdir_result)
    end

    local wrote, write_result = pcall(vim.fn.writefile, { choice }, path)
    if not wrote or write_result ~= 0 then
        return false, wrote and "could not write the state file" or tostring(write_result)
    end

    return true
end

local function detect_auto_locale()
    local candidates = {
        vim.env.LC_ALL,
        vim.env.LC_MESSAGES,
        vim.env.LANG,
        vim.env.LANGUAGE,
    }

    for _, candidate in ipairs(candidates) do
        if type(candidate) == "string" and candidate ~= "" then
            local lowered = candidate:lower()
            if lowered:find("zh") then
                return "zh"
            end
        end
    end

    return "en"
end

local function translate(locale, key)
    local cursor = strings[locale]

    for part in key:gmatch("[^%.]+") do
        if type(cursor) ~= "table" then
            return nil
        end
        cursor = cursor[part]
    end

    return cursor
end

local function interpolate(template, vars)
    if type(template) ~= "string" or type(vars) ~= "table" then
        return template
    end

    return (
        template:gsub("%%{(.-)}", function(name)
            local value = vars[name]
            if value == nil then
                return "%{" .. name .. "}"
            end

            return tostring(value)
        end)
    )
end

local function source_label(source, locale)
    local key = "locale.source." .. source
    return translate(locale, key) or translate("en", key) or source
end

local function locale_label(locale_code, locale)
    local key = "locale.choice." .. locale_code
    return translate(locale, key) or translate("en", key) or locale_code
end

local function compute_state()
    local choice
    local source

    choice = normalize_choice(vim.env.CLARITY_LOCALE)
    if choice then
        source = "env"
    else
        choice = normalize_choice(vim.g.clarity_locale)
        if choice then
            source = "global"
        else
            choice = read_saved_choice()
            if choice then
                source = "persisted"
            else
                choice = "auto"
                source = "auto"
            end
        end
    end

    local effective = choice == "auto" and detect_auto_locale() or choice

    return {
        choice = choice,
        effective = effective,
        source = source,
    }
end

local function ensure_state()
    if not state then
        state = compute_state()
    end

    return state
end

local function notify(message, level)
    if vim.env.CLARITY_NONINTERACTIVE == "1" or #vim.api.nvim_list_uis() == 0 then
        print(message)
        return
    end

    vim.notify(message, level or vim.log.levels.INFO)
end

local function flatten_keys(tbl, prefix, acc)
    acc = acc or {}
    prefix = prefix or ""

    for key, value in pairs(tbl or {}) do
        local path = prefix == "" and key or (prefix .. "." .. key)
        if type(value) == "table" then
            flatten_keys(value, path, acc)
        else
            acc[path] = true
        end
    end

    return acc
end

function M.get_state()
    local current = ensure_state()
    return {
        choice = current.choice,
        effective = current.effective,
        source = current.source,
    }
end

function M.get_locale()
    return ensure_state().effective
end

function M.label(locale_code, locale_override)
    local locale = locale_override or M.get_locale()
    return locale_label(locale_code, locale)
end

function M.t(key, vars, locale_override)
    local locale = locale_override or M.get_locale()
    local template = translate(locale, key) or translate("en", key) or key
    return interpolate(template, vars)
end

function M.set_choice(choice, opts)
    opts = opts or {}

    local normalized = normalize_choice(choice)
    if not normalized then
        local fallback_locale = state and state.effective or detect_auto_locale()
        local message = M.t("locale.invalid", { choice = tostring(choice) }, fallback_locale)
        if not opts.silent then
            notify(message, vim.log.levels.ERROR)
        end
        return false, message
    end

    local previous = ensure_state()

    if opts.persist ~= false then
        local persisted, persist_error = write_saved_choice(normalized)
        if not persisted then
            local message = M.t("locale.save_failed", { reason = persist_error }, previous.effective)
            if not opts.silent then
                notify(message, vim.log.levels.ERROR)
            end
            return false, message
        end
    end

    state = {
        choice = normalized,
        effective = normalized == "auto" and detect_auto_locale() or normalized,
        source = "runtime",
    }
    local current = ensure_state()

    if previous.effective ~= current.effective then
        vim.api.nvim_exec_autocmds("User", {
            pattern = "ClarityLocaleChanged",
            modeline = false,
            data = {
                previous = previous.effective,
                current = current.effective,
                choice = current.choice,
                source = current.source,
            },
        })
    end

    if not opts.silent then
        notify(
            M.t("locale.updated", {
                choice = M.label(normalized),
                effective = M.label(current.effective),
            }),
            vim.log.levels.INFO
        )
    end

    return true, M.get_state()
end

function M.show_status()
    local current = M.get_state()
    local locale = current.effective
    local lines = {
        M.t("locale.current", {
            choice = locale_label(current.choice, locale),
            effective = locale_label(current.effective, locale),
            source = source_label(current.source, locale),
        }),
        M.t("locale.usage", nil, locale),
    }

    notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

function M.get_validation_report()
    local en_keys = flatten_keys(strings.en)
    local zh_keys = flatten_keys(strings.zh)
    local missing_in_en = {}
    local missing_in_zh = {}

    for key in pairs(en_keys) do
        if not zh_keys[key] then
            table.insert(missing_in_zh, key)
        end
    end

    for key in pairs(zh_keys) do
        if not en_keys[key] then
            table.insert(missing_in_en, key)
        end
    end

    table.sort(missing_in_en)
    table.sort(missing_in_zh)

    local current = M.get_state()
    return {
        ok = #missing_in_en == 0 and #missing_in_zh == 0,
        locales = { "en", "zh" },
        missing_in_en = missing_in_en,
        missing_in_zh = missing_in_zh,
        choice = current.choice,
        effective = current.effective,
    }
end

function M.setup()
    ensure_state()

    if vim.fn.exists(":ClarityLanguage") == 2 then
        return
    end

    vim.api.nvim_create_user_command("ClarityLanguage", function(info)
        local choice = info.args and vim.trim(info.args) or ""

        if choice == "" then
            M.show_status()
            return
        end

        M.set_choice(choice)
    end, {
        nargs = "?",
        complete = function()
            return { "auto", "en", "zh" }
        end,
        desc = M.t("commands.language"),
    })
end

return M
