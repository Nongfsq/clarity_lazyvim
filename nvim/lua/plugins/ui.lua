local catalog = require("config.actions.catalog")
local i18n = require("config.i18n")

local picker_action_labels = {
    ["<c-s-w>"] = { en = "Delete word", zh = "删除单词" },
    cancel = { en = "Cancel", zh = "取消" },
    confirm = { en = "Confirm selection", zh = "确认选择" },
    focus_input = { en = "Focus search input", zh = "聚焦搜索输入框" },
    history_back = { en = "Previous search query", zh = "上一条搜索查询" },
    history_forward = { en = "Next search query", zh = "下一条搜索查询" },
    list_bottom = { en = "Go to list bottom", zh = "前往列表底部" },
    list_down = { en = "Next result", zh = "下一个结果" },
    list_scroll_down = { en = "Scroll results down", zh = "向下滚动结果" },
    list_scroll_up = { en = "Scroll results up", zh = "向上滚动结果" },
    list_top = { en = "Go to list top", zh = "前往列表顶部" },
    list_up = { en = "Previous result", zh = "上一个结果" },
    preview_scroll_down = { en = "Scroll preview down", zh = "向下滚动预览" },
    preview_scroll_up = { en = "Scroll preview up", zh = "向上滚动预览" },
    toggle_focus = { en = "Switch search and results", zh = "切换搜索框与结果列表" },
    toggle_help_input = { en = "Show search-input help", zh = "显示搜索输入帮助" },
    toggle_help_list = { en = "Show result-list help", zh = "显示结果列表帮助" },
    toggle_hidden = { en = "Toggle hidden items", zh = "切换隐藏项目" },
    toggle_ignored = { en = "Toggle ignored items", zh = "切换忽略项目" },
    toggle_live = { en = "Toggle live search", zh = "切换实时搜索" },
    toggle_preview = { en = "Toggle preview", zh = "切换预览" },
    toggle_regex = { en = "Toggle regular expression", zh = "切换正则表达式" },
}

local function action_name(value)
    if type(value) == "string" then
        return value
    end
    if type(value) == "table" then
        return type(value[1]) == "string" and value[1] or nil
    end
end

local function action_description(action, locale)
    local labels = assert(picker_action_labels[action], "missing Snacks Picker action label: " .. tostring(action))
    return labels[locale] or labels.en
end

local function localized_keys(templates, locale)
    local keys = vim.deepcopy(templates)
    for lhs, value in pairs(keys) do
        if value ~= false then
            local action = assert(action_name(value), "missing Snacks Picker action for " .. tostring(lhs))
            local desc = action_description(action, locale)
            if type(value) == "table" then
                value.desc = desc
            else
                keys[lhs] = { value, desc = desc }
            end
        end
    end
    return keys
end

local input_keys = {
    [" "] = false,
    ['"'] = false,
    ["'"] = false,
    ["/"] = { "toggle_focus", mode = "n" },
    ["["] = false,
    ["]"] = false,
    ["`"] = false,
    ["<C-Down>"] = { "history_forward", mode = { "i", "n" } },
    ["<C-Up>"] = { "history_back", mode = { "i", "n" } },
    ["<C-c>"] = false,
    ["<C-w>"] = { "<c-s-w>", mode = "i", expr = true, desc = "delete word" },
    ["<CR>"] = { "confirm", mode = { "n", "i" } },
    ["<Down>"] = { "list_down", mode = "i" },
    ["<Esc>"] = { "cancel", mode = { "n", "i" } },
    ["<S-CR>"] = false,
    ["<S-Tab>"] = false,
    ["<Tab>"] = false,
    ["<Up>"] = { "list_up", mode = "i" },
    ["<A-d>"] = false,
    ["<A-f>"] = false,
    ["<A-h>"] = { "toggle_hidden", mode = { "n", "i" } },
    ["<A-i>"] = { "toggle_ignored", mode = { "n", "i" } },
    ["<A-m>"] = false,
    ["<A-p>"] = { "toggle_preview", mode = { "n", "i" } },
    ["<A-r>"] = { "toggle_regex", mode = { "n", "i" } },
    ["<A-w>"] = false,
    ["<C-a>"] = false,
    ["<C-b>"] = { "preview_scroll_up", mode = { "n", "i" } },
    ["<C-d>"] = { "list_scroll_down", mode = { "n", "i" } },
    ["<C-f>"] = { "preview_scroll_down", mode = { "n", "i" } },
    ["<C-g>"] = { "toggle_live", mode = { "n", "i" } },
    ["<C-j>"] = false,
    ["<C-k>"] = false,
    ["<C-n>"] = { "list_down", mode = "i" },
    ["<C-p>"] = { "list_up", mode = "i" },
    ["<C-q>"] = false,
    ["<C-s>"] = false,
    ["<C-t>"] = false,
    ["<C-u>"] = { "list_scroll_up", mode = { "n", "i" } },
    ["<C-v>"] = false,
    ["<C-r>"] = false,
    ["<C-r>#"] = false,
    ["<C-r>%"] = false,
    ["<C-r><C-a>"] = false,
    ["<C-r><C-f>"] = false,
    ["<C-r><C-l>"] = false,
    ["<C-r><C-p>"] = false,
    ["<C-r><C-w>"] = false,
    ["<C-w>H"] = false,
    ["<C-w>J"] = false,
    ["<C-w>K"] = false,
    ["<C-w>L"] = false,
    ["?"] = "toggle_help_input",
    G = "list_bottom",
    g = false,
    ["g'"] = false,
    ["g`"] = false,
    gg = "list_top",
    j = "list_down",
    k = "list_up",
    q = false,
    z = false,
    ["z="] = false,
}

local list_keys = {
    ["/"] = "toggle_focus",
    ["<2-LeftMouse>"] = "confirm",
    ["<CR>"] = "confirm",
    ["<Down>"] = "list_down",
    ["<Esc>"] = "cancel",
    ["<S-CR>"] = false,
    ["<S-Tab>"] = false,
    ["<Tab>"] = false,
    ["<Up>"] = "list_up",
    ["<A-d>"] = false,
    ["<A-f>"] = false,
    ["<A-h>"] = "toggle_hidden",
    ["<A-i>"] = "toggle_ignored",
    ["<A-m>"] = false,
    ["<A-p>"] = "toggle_preview",
    ["<A-r>"] = "toggle_regex",
    ["<A-w>"] = false,
    ["<C-a>"] = false,
    ["<C-b>"] = "preview_scroll_up",
    ["<C-d>"] = "list_scroll_down",
    ["<C-f>"] = "preview_scroll_down",
    ["<C-g>"] = false,
    ["<C-j>"] = false,
    ["<C-k>"] = false,
    ["<C-n>"] = false,
    ["<C-p>"] = false,
    ["<C-q>"] = false,
    ["<C-s>"] = false,
    ["<C-t>"] = false,
    ["<C-u>"] = "list_scroll_up",
    ["<C-v>"] = false,
    ["<C-w>H"] = false,
    ["<C-w>J"] = false,
    ["<C-w>K"] = false,
    ["<C-w>L"] = false,
    ["?"] = "toggle_help_list",
    G = "list_bottom",
    gg = "list_top",
    i = "focus_input",
    j = "list_down",
    k = "list_up",
    q = false,
    zb = false,
    zt = false,
    zz = false,
}

local preview_keys = {
    ["<Esc>"] = "cancel",
    ["<A-w>"] = false,
    i = "focus_input",
    q = false,
}

local promoted_sources = {
    "buffers",
    "diagnostics",
    "files",
    "grep",
    "keymaps",
    "lsp_definitions",
    "lsp_references",
    "lsp_symbols",
    "lsp_workspace_symbols",
    "recent",
}

local source_capabilities = {
    buffers = { hidden = true, regex = true },
    diagnostics = { regex = true },
    files = { hidden = true, ignored = true, live = true, regex = true },
    grep = { hidden = true, ignored = true, live = true, regex = true },
    keymaps = { regex = true },
    lsp_definitions = { regex = true },
    lsp_references = { regex = true },
    lsp_symbols = { regex = true },
    lsp_workspace_symbols = { live = true, regex = true },
    recent = { regex = true },
}

local function source_input_keys(name, locale)
    local keys = localized_keys(input_keys, locale)
    local capabilities = source_capabilities[name] or {}
    keys["<A-b>"] = false
    keys["<A-g>"] = false
    keys["<A-h>"] = capabilities.hidden and keys["<A-h>"] or false
    keys["<A-i>"] = capabilities.ignored and keys["<A-i>"] or false
    keys["<A-r>"] = capabilities.regex and keys["<A-r>"] or false
    keys["<C-g>"] = capabilities.live and keys["<C-g>"] or false
    keys["<C-x>"] = false
    return keys
end

local function source_list_keys(name, locale)
    local keys = localized_keys(list_keys, locale)
    local capabilities = source_capabilities[name] or {}
    keys["<A-h>"] = capabilities.hidden and keys["<A-h>"] or false
    keys["<A-i>"] = capabilities.ignored and keys["<A-i>"] or false
    keys["<A-r>"] = capabilities.regex and keys["<A-r>"] or false
    keys.dd = false
    return keys
end

local dashboard_actions = {
    { icon = " ", key = "f", action_id = "files.find", action = ":lua Snacks.dashboard.pick('files')" },
    {
        icon = " ",
        key = "g",
        action_id = "search.project_text",
        action = ":lua Snacks.dashboard.pick('live_grep')",
    },
    {
        icon = " ",
        key = "r",
        action_id = "files.recent",
        action = ":lua Snacks.dashboard.pick('oldfiles')",
    },
    { icon = " ", key = "n", action_id = "files.new", action = ":ene | startinsert" },
    { icon = "󰋖 ", key = "h", action_id = "health.open", action = ":ClarityHealth" },
    { icon = " ", key = "q", action_id = "session.quit_all", action = ":qa" },
}

local function dashboard_keys()
    local locale = i18n.get_locale()
    local result = {}

    for _, item in ipairs(dashboard_actions) do
        result[#result + 1] = {
            icon = item.icon,
            key = item.key,
            desc = catalog.label(item.action_id, locale) or item.action_id,
            action = item.action,
        }
    end

    return result
end

local configured_picker

local function apply_picker_profiles(picker, locale)
    picker.win = picker.win or {}
    picker.win.input = picker.win.input or {}
    picker.win.input.keys = localized_keys(input_keys, locale)
    picker.win.list = picker.win.list or {}
    picker.win.list.keys = localized_keys(list_keys, locale)
    picker.win.preview = picker.win.preview or {}
    picker.win.preview.keys = localized_keys(preview_keys, locale)

    picker.sources = picker.sources or {}
    for _, name in ipairs(promoted_sources) do
        local source = picker.sources[name] or {}
        source.win = source.win or {}
        source.win.input = source.win.input or {}
        source.win.input.keys = source_input_keys(name, locale)
        source.win.list = source.win.list or {}
        source.win.list.keys = source_list_keys(name, locale)
        source.win.preview = source.win.preview or {}
        source.win.preview.keys = localized_keys(preview_keys, locale)
        picker.sources[name] = source
    end
end

local function maparg_for_buffer(buf, mode, lhs)
    local result
    vim.api.nvim_buf_call(buf, function()
        result = vim.fn.maparg(lhs, mode, false, true)
    end)
    return result
end

local function replace_mapping_description(buf, mode, lhs, desc)
    if not (buf and vim.api.nvim_buf_is_valid(buf)) then
        return
    end

    local mapping = maparg_for_buffer(buf, mode, lhs)
    if type(mapping) ~= "table" or vim.tbl_isempty(mapping) or mapping.buffer ~= 1 then
        return
    end

    local rhs = mapping.callback or mapping.rhs
    if rhs == nil or rhs == "" then
        return
    end

    vim.keymap.set(mode, lhs, rhs, {
        buffer = buf,
        desc = desc,
        expr = mapping.expr == 1,
        nowait = mapping.nowait == 1,
        remap = mapping.noremap == 0,
        replace_keycodes = mapping.replace_keycodes == 1,
        script = mapping.script == 1,
        silent = mapping.silent == 1,
    })
end

local function refresh_win_descriptions(win, locale)
    if type(win) ~= "table" or type(win.keys) ~= "table" then
        return
    end

    for _, spec in pairs(win.keys) do
        local action = type(spec) == "table" and action_name(spec[2]) or nil
        if action and picker_action_labels[action] then
            local desc = action_description(action, locale)
            spec.desc = desc
            local modes = type(spec.mode) == "table" and spec.mode or { spec.mode or "n" }
            for _, mode in ipairs(modes) do
                replace_mapping_description(win.buf, mode, spec[1], desc)
            end
        end
    end

    if type(win.opts) == "table" and type(win.opts.keys) == "table" then
        for _, value in pairs(win.opts.keys) do
            local action = action_name(value)
            if action and picker_action_labels[action] and type(value) == "table" then
                value.desc = action_description(action, locale)
            end
        end
    end
end

local function refresh_active_pickers(locale)
    local picker_module = package.loaded["snacks.picker"]
    if type(picker_module) ~= "table" or type(picker_module.get) ~= "function" then
        return
    end

    local ok, pickers = pcall(picker_module.get, { tab = false })
    if not ok or type(pickers) ~= "table" then
        return
    end
    for _, picker in ipairs(pickers) do
        refresh_win_descriptions(picker.input and picker.input.win, locale)
        refresh_win_descriptions(picker.list and picker.list.win, locale)
        refresh_win_descriptions(picker.preview and picker.preview.win, locale)
    end
end

local function install_locale_refresh()
    local group = vim.api.nvim_create_augroup("ClaritySnacksDashboardLocale", { clear = true })
    vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "ClarityLocaleChanged",
        callback = function()
            local locale = i18n.get_locale()
            apply_picker_profiles(configured_picker, locale)
            if _G.Snacks and type(Snacks.config) == "table" and type(Snacks.config.picker) == "table" then
                apply_picker_profiles(Snacks.config.picker, locale)
            end
            refresh_active_pickers(locale)
            if package.loaded["snacks.dashboard"] and _G.Snacks and type(Snacks.dashboard.update) == "function" then
                Snacks.dashboard.update()
            end
        end,
    })
end

return {
    {
        "snacks.nvim",
        opts = function(_, opts)
            opts = opts or {}
            opts.indent = opts.indent or {}
            opts.indent.enabled = false
            opts.scope = opts.scope or {}
            opts.scope.enabled = false
            opts.scroll = opts.scroll or {}
            opts.scroll.enabled = false

            opts.picker = opts.picker or {}
            apply_picker_profiles(opts.picker, i18n.get_locale())
            configured_picker = opts.picker

            opts.dashboard = opts.dashboard or {}
            opts.dashboard.preset = opts.dashboard.preset or {}
            opts.dashboard.preset.keys = dashboard_keys

            install_locale_refresh()
            return opts
        end,
    },
    {
        "folke/which-key.nvim",
        opts = function(_, opts)
            opts.disable = opts.disable or {}
            opts.disable.ft = opts.disable.ft or {}
            for _, filetype in ipairs({ "snacks_picker_input", "snacks_picker_list", "snacks_picker_preview" }) do
                if not vim.tbl_contains(opts.disable.ft, filetype) then
                    table.insert(opts.disable.ft, filetype)
                end
            end
            return opts
        end,
    },
}
