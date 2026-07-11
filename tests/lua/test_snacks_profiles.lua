local repo_root = vim.env.CLARITY_REPO_ROOT or vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
package.path = repo_root .. "/nvim/lua/?.lua;" .. repo_root .. "/nvim/lua/?/init.lua;" .. package.path

local locale = "en"
local previous_i18n = package.loaded["config.i18n"]
package.loaded["config.i18n"] = {
    get_locale = function()
        return locale
    end,
}

local specs = dofile(repo_root .. "/nvim/lua/plugins/ui.lua")
local spec = specs[1]
assert(type(spec.opts) == "function", "Snacks profile must extend upstream opts")
assert(spec.config == nil, "Clarity must retain Snacks config lifecycle ownership")
local which_key_spec = assert(specs[2], "Picker-local WhichKey policy is missing")
assert(which_key_spec[1] == "folke/which-key.nvim", "Picker-local WhichKey policy has the wrong owner")
local which_key_opts = which_key_spec.opts(nil, { disable = { ft = { "keep" }, bt = { "prompt" } } })
assert(vim.tbl_contains(which_key_opts.disable.ft, "keep"), "WhichKey filetype exclusions were discarded")
for _, filetype in ipairs({ "snacks_picker_input", "snacks_picker_list", "snacks_picker_preview" }) do
    assert(vim.tbl_contains(which_key_opts.disable.ft, filetype), "WhichKey remains active in " .. filetype)
end
assert(vim.deep_equal(which_key_opts.disable.bt, { "prompt" }), "WhichKey buffer exclusions were discarded")

local hostile = function() end
local opts = {
    unrelated = { keep = true },
    picker = {
        win = {
            input = { keys = { X = hostile, ["<Tab>"] = "select_and_next" } },
            list = { keys = { X = hostile, dd = "delete" } },
            preview = { keys = { X = hostile, ["<A-w>"] = "cycle_win" } },
        },
        sources = {
            buffers = {
                hidden = true,
                win = {
                    input = { keys = { X = hostile, ["<C-x>"] = "bufdelete" } },
                    list = { keys = { X = hostile, dd = "bufdelete" } },
                },
            },
            keymaps = {
                win = {
                    input = { keys = { ["<A-b>"] = "toggle_buffer", ["<A-g>"] = "toggle_global" } },
                },
            },
        },
    },
    dashboard = {
        preset = {
            header = "keep this header",
            keys = {
                { key = "c", desc = "Config", action = ":Config" },
                { key = "l", desc = "Lazy", action = ":Lazy" },
            },
        },
    },
}

local merged = spec.opts(nil, opts)
assert(merged == opts, "Snacks opts extension must preserve the incoming table identity")
assert(merged.unrelated.keep == true, "unrelated Snacks opts were discarded")
assert(merged.dashboard.preset.header == "keep this header", "unrelated dashboard presentation was discarded")
assert(merged.indent.enabled == false, "Snacks indent guides must stay disabled")
assert(merged.scope.enabled == false, "Snacks scope guides must stay disabled")
assert(merged.scroll.enabled == false, "Snacks animated scrolling must stay disabled")

local input = merged.picker.win.input.keys
local list = merged.picker.win.list.keys
local preview = merged.picker.win.preview.keys
assert(input.X == nil and list.X == nil and preview.X == nil, "hostile inherited core Picker keys survived")

local denied_core = {
    " ",
    '"',
    "'",
    "[",
    "]",
    "`",
    "<S-CR>",
    "<S-Tab>",
    "<Tab>",
    "<A-d>",
    "<A-f>",
    "<A-m>",
    "<A-w>",
    "<C-a>",
    "<C-j>",
    "<C-k>",
    "<C-q>",
    "<C-s>",
    "<C-t>",
    "<C-v>",
    "<C-w>H",
    "<C-w>J",
    "<C-w>K",
    "<C-w>L",
    "g",
    "g'",
    "g`",
    "z",
    "z=",
}
for _, lhs in ipairs(denied_core) do
    if input[lhs] ~= nil then
        assert(input[lhs] == false, "denied input key remains active: " .. lhs)
    end
    if list[lhs] ~= nil then
        assert(list[lhs] == false, "denied list key remains active: " .. lhs)
    end
end
for _, lhs in ipairs({
    "<C-r>",
    "<C-r>#",
    "<C-r>%",
    "<C-r><C-a>",
    "<C-r><C-f>",
    "<C-r><C-l>",
    "<C-r><C-p>",
    "<C-r><C-w>",
}) do
    assert(input[lhs] == false, "Picker register insertion remains configured: " .. lhs)
end

local function action_name(value)
    if type(value) == "string" then
        return value
    end
    if type(value) == "table" then
        return type(value[1]) == "string" and value[1] or nil
    end
end

local allowed_actions = {
    ["<c-s-w>"] = true,
    cancel = true,
    confirm = true,
    focus_input = true,
    history_back = true,
    history_forward = true,
    list_bottom = true,
    list_down = true,
    list_scroll_down = true,
    list_scroll_up = true,
    list_top = true,
    list_up = true,
    preview_scroll_down = true,
    preview_scroll_up = true,
    toggle_focus = true,
    toggle_help_input = true,
    toggle_help_list = true,
    toggle_hidden = true,
    toggle_ignored = true,
    toggle_live = true,
    toggle_preview = true,
    toggle_regex = true,
}
local jobs = {}
local job_alias = {
    ["<c-s-w>"] = "input_editing",
    focus_input = "focus",
    toggle_focus = "focus",
    toggle_help_input = "help",
    toggle_help_list = "help",
}
for _, keys in ipairs({ input, list, preview }) do
    for lhs, value in pairs(keys) do
        if value ~= false then
            local action = action_name(value)
            assert(action and allowed_actions[action], "unapproved Picker action on " .. tostring(lhs))
            jobs[job_alias[action] or action] = true
        end
    end
end
assert(vim.tbl_count(jobs) <= 20, "core Picker profile exceeds its 20-job budget")

local picker_descriptions = {
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

local function mapping_modes(value)
    if type(value.mode) == "table" then
        return value.mode
    end
    return { value.mode or "n" }
end

local function assert_key_descriptions(keys, expected_locale)
    for lhs, value in pairs(keys) do
        if value ~= false then
            assert(type(value) == "table", "active Picker mapping lacks structured metadata: " .. lhs)
            local action = assert(action_name(value), "active Picker mapping lacks an action: " .. lhs)
            assert(picker_descriptions[action], "active Picker action lacks bilingual labels: " .. action)
            assert(
                value.desc == picker_descriptions[action][expected_locale],
                "Picker description drifted for " .. lhs .. " (" .. action .. ")"
            )
        end
    end
end

local function assert_per_mode_budget(keys, context)
    local counts = {}
    for _, value in pairs(keys) do
        if value ~= false then
            for _, mode in ipairs(mapping_modes(value)) do
                counts[mode] = (counts[mode] or 0) + 1
            end
        end
    end
    for mode, count in pairs(counts) do
        assert(count <= 20, ("%s exposes %d actual %s-mode mappings (budget: 20)"):format(context, count, mode))
    end
end

for name, keys in pairs({ input = input, list = list, preview = preview }) do
    assert_key_descriptions(keys, "en")
    assert_per_mode_budget(keys, "core Picker " .. name)
    assert(keys.q == false, "Picker q alias must stay disabled in " .. name)
end
assert(vim.deep_equal(input["<Down>"].mode, "i"), "input Down alias must not occupy normal mode")
assert(vim.deep_equal(input["<Up>"].mode, "i"), "input Up alias must not occupy normal mode")

assert(action_name(input["<CR>"]) == "confirm" and action_name(list["<CR>"]) == "confirm", "confirm path is missing")
assert(action_name(list["<2-LeftMouse>"]) == "confirm", "mouse confirm accessibility path is missing")
assert(action_name(input["<Esc>"]) == "cancel" and action_name(list["<Esc>"]) == "cancel", "cancel path is missing")
assert(
    action_name(input["<C-n>"]) == "list_down" and action_name(input["<C-p>"]) == "list_up",
    "insert navigation is missing"
)
assert(action_name(input.j) == "list_down" and action_name(input.k) == "list_up", "normal input navigation is missing")
assert(action_name(list.j) == "list_down" and action_name(list.k) == "list_up", "normal list navigation is missing")
assert(action_name(input["<C-Up>"]) == "history_back", "query history-back is missing")
assert(action_name(input["<C-Down>"]) == "history_forward", "query history-forward is missing")
assert(action_name(input["<C-b>"]) == "preview_scroll_up", "preview scroll-up is missing")
assert(action_name(input["<C-f>"]) == "preview_scroll_down", "preview scroll-down is missing")
for _, action in ipairs({ "toggle_hidden", "toggle_ignored", "toggle_regex", "toggle_live" }) do
    assert(jobs[action], "capability toggle is missing: " .. action)
end

local promoted = {
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
for _, name in ipairs(promoted) do
    local source = assert(merged.picker.sources[name], "promoted Picker source is not hardened: " .. name)
    assert(source.win.input.keys.X == nil, "hostile source input key survived: " .. name)
    assert(source.win.list.keys.X == nil, "hostile source list key survived: " .. name)
    assert(source.win.input.keys["<C-x>"] == false, "source mutation key remains: " .. name)
    assert(source.win.input.keys["<A-b>"] == false, "source scope toggle remains: " .. name)
    assert(source.win.input.keys["<A-g>"] == false, "source scope toggle remains: " .. name)
    assert(source.win.list.keys.dd == false, "source deletion key remains: " .. name)
    assert_key_descriptions(source.win.input.keys, "en")
    assert_key_descriptions(source.win.list.keys, "en")
    assert_key_descriptions(source.win.preview.keys, "en")
    assert_per_mode_budget(source.win.input.keys, name .. " Picker input")
    assert_per_mode_budget(source.win.list.keys, name .. " Picker list")
    assert_per_mode_budget(source.win.preview.keys, name .. " Picker preview")
end
assert(merged.picker.sources.buffers.hidden == true, "non-key buffer Picker opts were discarded")
assert(
    action_name(merged.picker.sources.buffers.win.input.keys["<A-h>"]) == "toggle_hidden",
    "buffer hidden toggle is missing"
)
assert(
    merged.picker.sources.buffers.win.input.keys["<A-i>"] == false,
    "buffer ignored toggle lacks a source capability"
)
assert(merged.picker.sources.buffers.win.input.keys["<C-g>"] == false, "buffer live toggle lacks a source capability")
assert(
    action_name(merged.picker.sources.files.win.input.keys["<A-i>"]) == "toggle_ignored",
    "file ignored toggle is missing"
)
assert(action_name(merged.picker.sources.files.win.input.keys["<C-g>"]) == "toggle_live", "file live toggle is missing")
assert(merged.picker.sources.files.win.list.keys["<C-g>"] == false, "list print-path key was repurposed")
assert(
    action_name(merged.picker.sources.lsp_workspace_symbols.win.input.keys["<C-g>"]) == "toggle_live",
    "workspace-symbol live toggle is missing"
)
assert(
    merged.picker.sources.lsp_definitions.win.input.keys["<C-g>"] == false,
    "definition picker exposes an unsupported live toggle"
)

local dashboard_keys = assert(merged.dashboard.preset.keys, "dashboard key generator is missing")
assert(type(dashboard_keys) == "function", "dashboard descriptions must resolve at render time")
local expected_dashboard = { "f", "g", "r", "n", "h", "q" }
local expected_en = {
    f = "Find files",
    g = "Search project text",
    r = "Recent files",
    n = "New file",
    h = "Clarity help and health",
    q = "Quit all",
}
local expected_zh = {
    f = "查找文件",
    g = "搜索项目文本",
    r = "最近文件",
    n = "新建文件",
    h = "Clarity 帮助与健康",
    q = "全部退出",
}

local function assert_dashboard(items, descriptions)
    assert(#items == 6, "dashboard must expose exactly six actions")
    for index, key in ipairs(expected_dashboard) do
        local item = items[index]
        assert(item.key == key, "dashboard action order drifted at " .. index)
        assert(item.desc == descriptions[key], "dashboard description drifted for " .. key)
    end
    for _, item in ipairs(items) do
        assert(not vim.tbl_contains({ "c", "x", "l", "s", "p" }, item.key), "maintenance dashboard action remains")
    end
end

assert_dashboard(dashboard_keys(), expected_en)
locale = "zh"
assert_dashboard(dashboard_keys(), expected_zh)

local previous_snacks = rawget(_G, "Snacks")
local previous_dashboard = package.loaded["snacks.dashboard"]
local previous_picker = package.loaded["snacks.picker"]
local updates = {}

local function build_fake_win(keys)
    local buf = vim.api.nvim_create_buf(false, true)
    local win = {
        buf = buf,
        keys = {},
        opts = { keys = vim.deepcopy(keys) },
        before = {},
    }
    for lhs, value in pairs(keys) do
        if value ~= false then
            local action = assert(action_name(value))
            local spec = { lhs, action, desc = value.desc, mode = vim.deepcopy(value.mode) }
            win.keys[#win.keys + 1] = spec
            for _, mode in ipairs(mapping_modes(value)) do
                local callback = function() end
                vim.keymap.set(mode, lhs, callback, {
                    buffer = buf,
                    desc = value.desc,
                    nowait = true,
                    silent = true,
                })
                vim.api.nvim_buf_call(buf, function()
                    win.before[mode .. "\0" .. lhs] = vim.fn.maparg(lhs, mode, false, true)
                end)
            end
        end
    end
    return win
end

local active_picker = {
    input = { win = build_fake_win(input) },
    list = { win = build_fake_win(list) },
    preview = { win = build_fake_win(preview) },
}

_G.Snacks = {
    config = { picker = vim.deepcopy(merged.picker) },
    dashboard = {
        update = function()
            updates[#updates + 1] = dashboard_keys()
        end,
    },
}
package.loaded["snacks.dashboard"] = _G.Snacks.dashboard
package.loaded["snacks.picker"] = {
    get = function(options)
        assert(options.tab == false, "locale refresh must include pickers outside the current tab")
        return { active_picker }
    end,
}

local function assert_active_win(win, expected_locale)
    for _, spec in ipairs(win.keys) do
        local action = assert(action_name(spec[2]))
        local expected = picker_descriptions[action][expected_locale]
        assert(spec.desc == expected, "active Picker spec did not refresh: " .. spec[1])
        local modes = type(spec.mode) == "table" and spec.mode or { spec.mode or "n" }
        for _, mode in ipairs(modes) do
            vim.api.nvim_buf_call(win.buf, function()
                local mapping = vim.fn.maparg(spec[1], mode, false, true)
                local before_mapping = win.before[mode .. "\0" .. spec[1]]
                assert(mapping.desc == expected, "actual active Picker map did not refresh: " .. spec[1])
                assert(mapping.callback == before_mapping.callback, "Picker callback changed during locale refresh")
                assert(mapping.silent == before_mapping.silent, "Picker silent option changed during locale refresh")
                assert(mapping.nowait == before_mapping.nowait, "Picker nowait option changed during locale refresh")
                assert(mapping.noremap == before_mapping.noremap, "Picker remap option changed during locale refresh")
            end)
        end
    end
end

local function assert_active_picker(expected_locale)
    assert_active_win(active_picker.input.win, expected_locale)
    assert_active_win(active_picker.list.win, expected_locale)
    assert_active_win(active_picker.preview.win, expected_locale)
end

local function assert_future_picker(expected_locale)
    assert_key_descriptions(Snacks.config.picker.win.input.keys, expected_locale)
    assert_key_descriptions(Snacks.config.picker.win.list.keys, expected_locale)
    assert_key_descriptions(Snacks.config.picker.win.preview.keys, expected_locale)
    for _, name in ipairs(promoted) do
        local source_profile = Snacks.config.picker.sources[name]
        assert_key_descriptions(source_profile.win.input.keys, expected_locale)
        assert_key_descriptions(source_profile.win.list.keys, expected_locale)
        assert_key_descriptions(source_profile.win.preview.keys, expected_locale)
    end
end

locale = "en"
vim.api.nvim_exec_autocmds("User", { pattern = "ClarityLocaleChanged", modeline = false })
assert_active_picker("en")
assert_future_picker("en")
locale = "zh"
vim.api.nvim_exec_autocmds("User", { pattern = "ClarityLocaleChanged", modeline = false })
assert_active_picker("zh")
assert_future_picker("zh")
locale = "en"
vim.api.nvim_exec_autocmds("User", { pattern = "ClarityLocaleChanged", modeline = false })
assert_active_picker("en")
assert_future_picker("en")
assert(#updates == 3, "loaded Snacks dashboard did not refresh for each locale change")
assert_dashboard(updates[1], expected_en)
assert_dashboard(updates[2], expected_zh)
assert_dashboard(updates[3], expected_en)

package.loaded["snacks.dashboard"] = nil
package.loaded["snacks.picker"] = nil
locale = "zh"
vim.api.nvim_exec_autocmds("User", { pattern = "ClarityLocaleChanged", modeline = false })
assert(#updates == 3, "locale refresh eagerly loaded the Snacks dashboard")
assert(package.loaded["snacks.picker"] == nil, "locale refresh eagerly loaded the Snacks Picker")

local source = table.concat(vim.fn.readfile(repo_root .. "/nvim/lua/plugins/ui.lua"), "\n")
assert(not source:find('require("snacks").setup', 1, true), "Clarity took Snacks setup lifecycle ownership")
assert(not source:find("Snacks.setup", 1, true), "Clarity took Snacks setup lifecycle ownership")

pcall(vim.api.nvim_del_augroup_by_name, "ClaritySnacksDashboardLocale")
package.loaded["snacks.dashboard"] = previous_dashboard
package.loaded["snacks.picker"] = previous_picker
package.loaded["config.i18n"] = previous_i18n
_G.Snacks = previous_snacks
for _, win in ipairs({ active_picker.input.win, active_picker.list.win, active_picker.preview.win }) do
    vim.api.nvim_buf_delete(win.buf, { force = true })
end

print("Snacks Picker and dashboard profile tests: OK")
