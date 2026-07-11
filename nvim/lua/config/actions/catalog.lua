local M = {}

local groups = {
    { id = "buffer", prefix = "<leader>b", labels = { en = "Buffer", zh = "缓冲区" } },
    { id = "code", prefix = "<leader>c", labels = { en = "Code", zh = "代码" } },
    { id = "explorer", labels = { en = "Explorer", zh = "文件浏览" } },
    { id = "find", prefix = "<leader>f", labels = { en = "Find", zh = "查找" } },
    { id = "git", prefix = "<leader>g", labels = { en = "Git Review", zh = "Git 审阅" } },
    { id = "help", prefix = "<leader>h", labels = { en = "Help", zh = "帮助" } },
    { id = "list", prefix = "<leader>x", labels = { en = "Lists", zh = "列表" } },
    { id = "search", prefix = "<leader>s", labels = { en = "Search", zh = "搜索" } },
    { id = "session", labels = { en = "Session", zh = "会话" } },
    { id = "terminal", prefix = "<leader>t", labels = { en = "Terminal", zh = "终端" } },
    { id = "view", prefix = "<leader>u", labels = { en = "View", zh = "视图" } },
    { id = "window", prefix = "<leader>w", labels = { en = "Window", zh = "窗口" } },
}

local actions = {
    {
        id = "window.split_below",
        job = "layout",
        group = "window",
        label_key = "actions.window_split_below",
        labels = { en = "Split below", zh = "下方分屏" },
        mutability = "ui_state",
        visibility = "global",
        owner = { kind = "upstream_keymap", name = "lazyvim.config.keymaps" },
        bindings = { { mode = "n", lhs = "<leader>-", scope = "global" } },
        contract_id = "CLARITY_ACTION_WINDOW_SPLIT_BELOW",
    },
    {
        id = "window.split_right",
        job = "layout",
        group = "window",
        label_key = "actions.window_split_right",
        labels = { en = "Split right", zh = "右侧分屏" },
        mutability = "ui_state",
        visibility = "global",
        owner = { kind = "upstream_keymap", name = "lazyvim.config.keymaps" },
        bindings = { { mode = "n", lhs = "<leader>|", scope = "global" } },
        contract_id = "CLARITY_ACTION_WINDOW_SPLIT_RIGHT",
    },
    {
        id = "explorer.cwd",
        job = "navigate",
        group = "explorer",
        label_key = "actions.explorer_cwd",
        labels = { en = "Explorer (current directory)", zh = "文件浏览（当前目录）" },
        mutability = "read_only",
        visibility = "global",
        owner = { kind = "lazy_spec", name = "nvim-neo-tree/neo-tree.nvim" },
        bindings = { { mode = "n", lhs = "<leader>E", scope = "global" } },
        contract_id = "CLARITY_ACTION_EXPLORER_CWD",
    },
    {
        id = "explorer.root",
        job = "navigate",
        group = "explorer",
        label_key = "actions.explorer_root",
        labels = { en = "Explorer (project root)", zh = "文件浏览（项目根目录）" },
        mutability = "read_only",
        visibility = "global",
        owner = { kind = "lazy_spec", name = "nvim-neo-tree/neo-tree.nvim" },
        bindings = { { mode = "n", lhs = "<leader>e", scope = "global" } },
        contract_id = "CLARITY_ACTION_EXPLORER_ROOT",
    },
    {
        id = "help.buffer_keymaps",
        job = "discover",
        group = "help",
        label_key = "actions.buffer_keymaps",
        labels = { en = "Buffer keymaps", zh = "当前缓冲区键位" },
        mutability = "read_only",
        visibility = "global",
        owner = { kind = "lazy_spec", name = "folke/which-key.nvim" },
        bindings = { { mode = "n", lhs = "<leader>?", scope = "global" } },
        contract_id = "CLARITY_ACTION_BUFFER_KEYMAPS",
    },
    {
        id = "buffer.delete",
        job = "buffer",
        group = "buffer",
        label_key = "actions.buffer_delete",
        labels = { en = "Delete buffer", zh = "删除缓冲区" },
        mutability = "ui_state",
        visibility = "global",
        owner = { kind = "upstream_keymap", name = "lazyvim.config.keymaps" },
        bindings = { { mode = "n", lhs = "<leader>bd", scope = "global" } },
        contract_id = "CLARITY_ACTION_BUFFER_DELETE",
    },
    {
        id = "code.format",
        job = "edit",
        group = "code",
        label_key = "actions.code_format",
        labels = { en = "Format", zh = "格式化" },
        mutability = "buffer_edit",
        visibility = "global",
        owner = { kind = "upstream_keymap", name = "lazyvim.config.keymaps" },
        bindings = { { mode = { "n", "x" }, lhs = "<leader>cf", scope = "global" } },
        contract_id = "CLARITY_ACTION_CODE_FORMAT",
    },
    {
        id = "code.fold_toggle",
        job = "review",
        group = "code",
        label_key = "actions.code_fold_toggle",
        labels = { en = "Toggle current code fold", zh = "切换当前代码折叠" },
        mutability = "ui_state",
        visibility = "global",
        owner = { kind = "clarity", name = "config.actions.fold" },
        bindings = { { mode = "n", lhs = "<leader>cz", scope = "global" } },
        contract_id = "CLARITY_ACTION_CODE_FOLD_TOGGLE",
    },
    {
        id = "buffer.find",
        job = "navigate",
        group = "buffer",
        label_key = "actions.buffer_find",
        labels = { en = "Find open buffer", zh = "查找已打开缓冲区" },
        mutability = "read_only",
        visibility = "global",
        owner = { kind = "lazy_spec", name = "folke/snacks.nvim" },
        bindings = { { mode = "n", lhs = "<leader>fb", scope = "global" } },
        contract_id = "CLARITY_ACTION_BUFFER_FIND",
    },
    {
        id = "files.find",
        job = "navigate",
        group = "find",
        label_key = "actions.files_find",
        labels = { en = "Find files", zh = "查找文件" },
        mutability = "read_only",
        visibility = "global",
        owner = { kind = "lazy_spec", name = "folke/snacks.nvim" },
        bindings = { { mode = "n", lhs = "<leader>ff", scope = "global" } },
        contract_id = "CLARITY_ACTION_FILES_FIND",
    },
    {
        id = "files.new",
        job = "edit",
        group = "find",
        label_key = "actions.files_new",
        labels = { en = "New file", zh = "新建文件" },
        mutability = "buffer_edit",
        visibility = "global",
        owner = { kind = "upstream_keymap", name = "lazyvim.config.keymaps" },
        bindings = { { mode = "n", lhs = "<leader>fn", scope = "global" } },
        contract_id = "CLARITY_ACTION_FILES_NEW",
    },
    {
        id = "files.recent",
        job = "navigate",
        group = "find",
        label_key = "actions.files_recent",
        labels = { en = "Recent files", zh = "最近文件" },
        mutability = "read_only",
        visibility = "global",
        owner = { kind = "lazy_spec", name = "folke/snacks.nvim" },
        bindings = { { mode = "n", lhs = "<leader>fr", scope = "global" } },
        contract_id = "CLARITY_ACTION_FILES_RECENT",
    },
    {
        id = "search.project_text",
        job = "search",
        group = "search",
        label_key = "actions.search_project_text",
        labels = { en = "Search project text", zh = "搜索项目文本" },
        mutability = "read_only",
        visibility = "global",
        owner = { kind = "clarity", name = "config.keymaps" },
        bindings = {
            { mode = "n", lhs = "<leader>fw", scope = "global" },
            { mode = "x", lhs = "<leader>sw", scope = "global", when = "selection" },
        },
        contract_id = "CLARITY_ACTION_SEARCH_PROJECT_TEXT",
    },
    {
        id = "git.blame_line",
        job = "review",
        group = "git",
        label_key = "actions.git_blame_line",
        labels = { en = "Git line provenance", zh = "Git 当前行来源" },
        mutability = "repository_read",
        visibility = "global",
        owner = { kind = "clarity", name = "config.actions.git" },
        bindings = { { mode = "n", lhs = "<leader>gb", scope = "global" } },
        contract_id = "CLARITY_ACTION_GIT_BLAME_LINE",
    },
    {
        id = "git.diff",
        job = "review",
        group = "git",
        label_key = "actions.git_diff",
        labels = { en = "Git changes", zh = "Git 更改" },
        mutability = "repository_read",
        visibility = "global",
        owner = { kind = "clarity", name = "config.actions.git" },
        bindings = { { mode = "n", lhs = "<leader>gd", scope = "global" } },
        contract_id = "CLARITY_ACTION_GIT_DIFF",
    },
    {
        id = "git.log",
        job = "review",
        group = "git",
        label_key = "actions.git_log",
        labels = { en = "Git recent history", zh = "Git 最近历史" },
        mutability = "repository_read",
        visibility = "global",
        owner = { kind = "clarity", name = "config.actions.git" },
        bindings = { { mode = "n", lhs = "<leader>gl", scope = "global" } },
        contract_id = "CLARITY_ACTION_GIT_LOG",
    },
    {
        id = "git.status",
        job = "review",
        group = "git",
        label_key = "actions.git_status",
        labels = { en = "Git status", zh = "Git 状态" },
        mutability = "repository_read",
        visibility = "global",
        owner = { kind = "clarity", name = "config.actions.git" },
        bindings = { { mode = "n", lhs = "<leader>gs", scope = "global" } },
        contract_id = "CLARITY_ACTION_GIT_STATUS",
    },
    {
        id = "git.branch_graph",
        job = "review",
        group = "git",
        label_key = "actions.git_branch_graph",
        labels = { en = "Git branch graph", zh = "Git 分支图" },
        mutability = "repository_read",
        visibility = "global",
        owner = { kind = "clarity", name = "config.actions.git" },
        bindings = { { mode = "n", lhs = "<leader>gt", scope = "global" } },
        contract_id = "CLARITY_ACTION_GIT_BRANCH_GRAPH",
    },
    {
        id = "health.open",
        job = "recover",
        group = "help",
        label_key = "actions.health_open",
        labels = { en = "Clarity help and health", zh = "Clarity 帮助与健康" },
        mutability = "read_only",
        visibility = "global",
        owner = { kind = "clarity", name = "config.help" },
        bindings = { { mode = "n", lhs = "<leader>hh", scope = "global" } },
        contract_id = "CLARITY_ACTION_HEALTH_OPEN",
    },
    {
        id = "session.quit_all",
        job = "session",
        group = "session",
        label_key = "actions.session_quit_all",
        labels = { en = "Quit all", zh = "全部退出" },
        mutability = "session_control",
        visibility = "global",
        owner = { kind = "upstream_keymap", name = "lazyvim.config.keymaps" },
        bindings = { { mode = "n", lhs = "<leader>qq", scope = "global" } },
        contract_id = "CLARITY_ACTION_SESSION_QUIT_ALL",
    },
    {
        id = "diagnostics.list",
        job = "review",
        group = "search",
        label_key = "actions.diagnostics_list",
        labels = { en = "Diagnostics", zh = "诊断列表" },
        mutability = "read_only",
        visibility = "global",
        owner = { kind = "lazy_spec", name = "folke/snacks.nvim" },
        bindings = { { mode = "n", lhs = "<leader>sd", scope = "global" } },
        contract_id = "CLARITY_ACTION_DIAGNOSTICS_LIST",
    },
    {
        id = "help.keymaps",
        job = "discover",
        group = "search",
        label_key = "actions.help_keymaps",
        labels = { en = "Search keymaps", zh = "搜索键位" },
        mutability = "read_only",
        visibility = "global",
        owner = { kind = "lazy_spec", name = "folke/snacks.nvim" },
        bindings = { { mode = "n", lhs = "<leader>sk", scope = "global" } },
        contract_id = "CLARITY_ACTION_HELP_KEYMAPS",
    },
    {
        id = "terminal.float",
        job = "terminal",
        group = "terminal",
        label_key = "actions.terminal_float",
        labels = { en = "Floating terminal", zh = "浮动终端" },
        mutability = "process_shell",
        visibility = "global",
        owner = { kind = "lazy_spec", name = "plugins.terminal" },
        bindings = { { mode = "n", lhs = "<leader>tf", scope = "global" } },
        contract_id = "CLARITY_ACTION_TERMINAL_FLOAT",
    },
    {
        id = "view.wrap_toggle",
        job = "review",
        group = "view",
        label_key = "actions.view_wrap_toggle",
        labels = { en = "Toggle line wrap", zh = "切换自动换行" },
        mutability = "ui_state",
        visibility = "global",
        owner = { kind = "clarity", name = "config.keymaps" },
        bindings = { { mode = "n", lhs = "<leader>uw", scope = "global" } },
        contract_id = "CLARITY_ACTION_VIEW_WRAP_TOGGLE",
    },
    {
        id = "window.close",
        job = "layout",
        group = "window",
        label_key = "actions.window_close",
        labels = { en = "Close window", zh = "关闭窗口" },
        mutability = "ui_state",
        visibility = "global",
        owner = { kind = "upstream_keymap", name = "lazyvim.config.keymaps" },
        bindings = { { mode = "n", lhs = "<leader>wd", scope = "global" } },
        contract_id = "CLARITY_ACTION_WINDOW_CLOSE",
    },
    {
        id = "window.zoom_toggle",
        job = "layout",
        group = "window",
        label_key = "actions.window_zoom_toggle",
        labels = { en = "Toggle window zoom", zh = "切换窗口放大" },
        mutability = "ui_state",
        visibility = "global",
        owner = { kind = "upstream_keymap", name = "lazyvim.config.keymaps" },
        bindings = { { mode = "n", lhs = "<leader>wm", scope = "global" } },
        contract_id = "CLARITY_ACTION_WINDOW_ZOOM_TOGGLE",
    },
    {
        id = "window.only",
        job = "layout",
        group = "window",
        label_key = "actions.window_only",
        labels = { en = "Keep only current window", zh = "仅保留当前窗口" },
        mutability = "ui_state",
        visibility = "global",
        owner = { kind = "clarity", name = "config.keymaps" },
        bindings = { { mode = "n", lhs = "<leader>wo", scope = "global" } },
        contract_id = "CLARITY_ACTION_WINDOW_ONLY",
    },
    {
        id = "list.quickfix_toggle",
        job = "review",
        group = "list",
        label_key = "actions.list_quickfix_toggle",
        labels = { en = "Quickfix list", zh = "快速修复列表" },
        mutability = "ui_state",
        visibility = "global",
        owner = { kind = "upstream_keymap", name = "lazyvim.config.keymaps" },
        bindings = { { mode = "n", lhs = "<leader>xq", scope = "global" } },
        contract_id = "CLARITY_ACTION_LIST_QUICKFIX_TOGGLE",
    },
    {
        id = "format.auto_buffer_toggle",
        job = "recover",
        group = "view",
        label_key = "actions.format_auto_buffer_toggle",
        labels = { en = "Toggle autoformat for buffer", zh = "切换当前缓冲区自动格式化" },
        mutability = "buffer_edit",
        visibility = "dynamic",
        owner = { kind = "clarity", name = "config.keymaps" },
        bindings = {
            { mode = "n", lhs = "<leader>uF", scope = "buffer", when = "ordinary_editable_buffer" },
        },
        contract_id = "CLARITY_ACTION_FORMAT_AUTO_BUFFER_TOGGLE",
    },
    {
        id = "lsp.inlay_hints_toggle",
        job = "review",
        group = "view",
        label_key = "actions.lsp_inlay_hints_toggle",
        labels = { en = "Toggle inlay hints", zh = "切换内联提示" },
        mutability = "ui_state",
        visibility = "dynamic",
        owner = { kind = "lsp", name = "textDocument/inlayHint" },
        bindings = {
            { mode = "n", lhs = "<leader>uh", scope = "buffer", when = "textDocument/inlayHint" },
        },
        contract_id = "CLARITY_ACTION_LSP_INLAY_HINTS_TOGGLE",
    },
    {
        id = "lsp.code_action",
        job = "edit",
        group = "code",
        label_key = "actions.lsp_code_action",
        labels = { en = "Code action", zh = "代码操作" },
        mutability = "buffer_edit",
        visibility = "dynamic",
        owner = { kind = "lsp", name = "textDocument/codeAction" },
        bindings = {
            { mode = { "n", "x" }, lhs = "<leader>ca", scope = "buffer", when = "textDocument/codeAction" },
        },
        contract_id = "CLARITY_ACTION_LSP_CODE_ACTION",
    },
    {
        id = "lsp.rename_symbol",
        job = "edit",
        group = "code",
        label_key = "actions.lsp_rename_symbol",
        labels = { en = "Rename symbol", zh = "重命名符号" },
        mutability = "buffer_edit",
        visibility = "dynamic",
        owner = { kind = "lsp", name = "textDocument/rename" },
        bindings = { { mode = "n", lhs = "<leader>cr", scope = "buffer", when = "textDocument/rename" } },
        contract_id = "CLARITY_ACTION_LSP_RENAME_SYMBOL",
    },
    {
        id = "git.hunk_preview",
        job = "review",
        group = "git",
        label_key = "actions.git_hunk_preview",
        labels = { en = "Preview Git hunk", zh = "预览 Git 改动块" },
        mutability = "repository_read",
        visibility = "dynamic",
        owner = { kind = "buffer_attach", name = "gitsigns.nvim" },
        bindings = { { mode = "n", lhs = "<leader>ghp", scope = "buffer", when = "gitsigns" } },
        contract_id = "CLARITY_ACTION_GIT_HUNK_PREVIEW",
    },
    {
        id = "lsp.document_symbols",
        job = "navigate",
        group = "search",
        label_key = "actions.lsp_document_symbols",
        labels = { en = "Document symbols", zh = "当前文档符号" },
        mutability = "read_only",
        visibility = "dynamic",
        owner = { kind = "lsp", name = "textDocument/documentSymbol" },
        bindings = {
            { mode = "n", lhs = "<leader>ss", scope = "buffer", when = "textDocument/documentSymbol" },
        },
        contract_id = "CLARITY_ACTION_LSP_DOCUMENT_SYMBOLS",
    },
    {
        id = "lsp.workspace_symbols",
        job = "navigate",
        group = "search",
        label_key = "actions.lsp_workspace_symbols",
        labels = { en = "Workspace symbols", zh = "工作区符号" },
        mutability = "read_only",
        visibility = "dynamic",
        owner = { kind = "lsp", name = "workspace/symbol" },
        bindings = {
            { mode = "n", lhs = "<leader>sS", scope = "buffer", when = "workspace/symbol" },
        },
        contract_id = "CLARITY_ACTION_LSP_WORKSPACE_SYMBOLS",
    },
}

local valid_mutability = {
    buffer_edit = true,
    process_shell = true,
    read_only = true,
    repository_read = true,
    session_control = true,
    ui_state = true,
}

local valid_visibility = { dynamic = true, global = true }

local function copy(value)
    return vim.deepcopy(value)
end

local function modes(binding)
    return type(binding.mode) == "table" and binding.mode or { binding.mode }
end

local function matches(value, expected)
    return expected == nil or value == expected
end

local function flattened_bindings(filter)
    filter = filter or {}
    local result = {}
    for _, action in ipairs(actions) do
        if matches(action.visibility, filter.visibility) and matches(action.group, filter.group) then
            for _, binding in ipairs(action.bindings) do
                if matches(binding.scope, filter.scope) then
                    for _, mode in ipairs(modes(binding)) do
                        if matches(mode, filter.mode) then
                            result[#result + 1] = {
                                action_id = action.id,
                                group = action.group,
                                lhs = binding.lhs,
                                mode = mode,
                                scope = binding.scope,
                                visibility = action.visibility,
                                when = binding.when,
                            }
                        end
                    end
                end
            end
        end
    end
    return result
end

local function action_index()
    local index = {}
    for _, action in ipairs(actions) do
        index[action.id] = action
    end
    return index
end

local function group_index()
    local index = {}
    for _, group in ipairs(groups) do
        index[group.id] = group
    end
    return index
end

function M.actions()
    return copy(actions)
end

function M.groups()
    return copy(groups)
end

function M.get(id)
    local action = action_index()[id]
    return action and copy(action) or nil
end

function M.lookup(mode, lhs, scope)
    local found
    for _, binding in ipairs(flattened_bindings({ mode = mode, scope = scope })) do
        if binding.lhs == lhs then
            found = M.get(binding.action_id)
            break
        end
    end
    return found
end

function M.label(id, locale)
    local action = action_index()[id]
    locale = locale == "zh" and "zh" or "en"
    return action and action.labels[locale] or nil
end

function M.group_label(id, locale)
    local group = group_index()[id]
    locale = locale == "zh" and "zh" or "en"
    return group and group.labels[locale] or nil
end

function M.bindings(filter)
    return copy(flattened_bindings(filter))
end

local function manifest(visibility)
    local result = {}
    for _, binding in ipairs(flattened_bindings({ visibility = visibility, mode = "n" })) do
        result[#result + 1] = binding.lhs
    end
    table.sort(result)
    return result
end

function M.global_normal_manifest()
    return manifest("global")
end

function M.dynamic_normal_manifest()
    return manifest("dynamic")
end

function M.which_key_specs(locale, filter)
    filter = filter or {}
    local specs = {}
    for _, binding in ipairs(flattened_bindings(filter)) do
        specs[#specs + 1] = {
            binding.lhs,
            desc = M.label(binding.action_id, locale),
            mode = binding.mode,
        }
    end
    return specs
end

function M.validation_report()
    local issues = {}
    local ids = {}
    local contract_ids = {}
    local bindings_seen = {}
    local known_groups = group_index()

    for _, action in ipairs(actions) do
        if ids[action.id] then
            issues[#issues + 1] = "duplicate action id: " .. action.id
        end
        ids[action.id] = true
        if not known_groups[action.group] then
            issues[#issues + 1] = "unknown action group: " .. action.id .. ":" .. tostring(action.group)
        end
        if not valid_mutability[action.mutability] then
            issues[#issues + 1] = "invalid mutability: " .. action.id
        end
        if not valid_visibility[action.visibility] then
            issues[#issues + 1] = "invalid visibility: " .. action.id
        end
        if type(action.label_key) ~= "string" or action.label_key == "" then
            issues[#issues + 1] = "missing label key: " .. action.id
        end
        if type(action.labels.en) ~= "string" or action.labels.en == "" then
            issues[#issues + 1] = "missing English label: " .. action.id
        end
        if type(action.labels.zh) ~= "string" or action.labels.zh == "" then
            issues[#issues + 1] = "missing Chinese label: " .. action.id
        end
        if type(action.contract_id) ~= "string" or action.contract_id == "" then
            issues[#issues + 1] = "missing contract id: " .. action.id
        elseif contract_ids[action.contract_id] then
            issues[#issues + 1] = "duplicate contract id: " .. action.contract_id
        else
            contract_ids[action.contract_id] = true
        end
        if
            type(action.owner) ~= "table"
            or type(action.owner.kind) ~= "string"
            or action.owner.kind == ""
            or type(action.owner.name) ~= "string"
            or action.owner.name == ""
        then
            issues[#issues + 1] = "missing owner: " .. action.id
        end
        if type(action.bindings) ~= "table" or #action.bindings == 0 then
            issues[#issues + 1] = "missing binding: " .. action.id
        end
        for _, binding in ipairs(action.bindings) do
            if type(binding.lhs) ~= "string" or binding.lhs == "" then
                issues[#issues + 1] = "invalid binding lhs: " .. action.id
            end
            if binding.scope ~= "global" and binding.scope ~= "buffer" then
                issues[#issues + 1] = "invalid binding scope: " .. action.id
            end
            for _, mode in ipairs(modes(binding)) do
                local key = table.concat({ mode, binding.scope, binding.lhs }, "\0")
                if bindings_seen[key] then
                    issues[#issues + 1] = "duplicate binding: " .. mode .. ":" .. binding.scope .. ":" .. binding.lhs
                end
                bindings_seen[key] = action.id
            end
        end
    end

    table.sort(issues)
    return {
        ok = #issues == 0,
        issues = issues,
        action_count = #actions,
        global_normal_count = #M.global_normal_manifest(),
        dynamic_normal_count = #M.dynamic_normal_manifest(),
    }
end

function M.validate()
    local report = M.validation_report()
    return report.ok, report
end

return M
