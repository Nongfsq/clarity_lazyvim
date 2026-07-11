local WIDTH = 35
local i18n = require("config.i18n")

local mapping_labels = {
    ["<2-LeftMouse>"] = { en = "Open", zh = "打开" },
    ["<cr>"] = { en = "Open", zh = "打开" },
    ["<esc>"] = { en = "Cancel", zh = "取消" },
    P = { en = "Toggle preview", zh = "切换预览" },
    ["<C-f>"] = { en = "Scroll preview up", zh = "向上滚动预览" },
    ["<C-b>"] = { en = "Scroll preview down", zh = "向下滚动预览" },
    C = { en = "Close node", zh = "关闭节点" },
    z = { en = "Close all nodes", zh = "关闭所有节点" },
    R = { en = "Refresh explorer", zh = "刷新文件浏览" },
    q = { en = "Close explorer", zh = "关闭文件浏览" },
    ["?"] = { en = "Show explorer help", zh = "显示文件浏览帮助" },
    Y = { en = "Copy displayed path", zh = "复制显示路径" },
    H = { en = "Toggle hidden files", zh = "切换隐藏文件" },
    ["/"] = { en = "Filter files", zh = "筛选文件" },
    ["<C-x>"] = { en = "Clear file filter", zh = "清除文件筛选" },
    ["<bs>"] = { en = "Go to parent directory", zh = "前往上级目录" },
    ["."] = { en = "Set directory as root", zh = "将目录设为根目录" },
    ["[g"] = { en = "Previous Git change", zh = "上一个 Git 更改" },
    ["]g"] = { en = "Next Git change", zh = "下一个 Git 更改" },
    i = { en = "Show file details", zh = "显示文件详情" },
}

local function copy_path(state)
    local node = state.tree:get_node()
    local path = node:get_id()
    vim.fn.setreg("+", path, "c")
end

-- This is a complete product profile, not a delta on Neo-tree's defaults.
-- File creation/move/delete and the Git source belong to external agents.
local base_mapping_templates = {
    ["<2-LeftMouse>"] = "open",
    ["<cr>"] = "open",
    ["<esc>"] = "cancel",
    P = { "toggle_preview", config = { use_float = false } },
    ["<C-f>"] = { "scroll_preview", config = { direction = -10 } },
    ["<C-b>"] = { "scroll_preview", config = { direction = 10 } },
    C = "close_node",
    z = "close_all_nodes",
    R = "refresh",
    q = "close_window",
    ["?"] = "show_help",
    Y = { copy_path },
}

local filesystem_mapping_templates = {
    H = "toggle_hidden",
    ["/"] = "fuzzy_finder",
    ["<C-x>"] = "clear_filter",
    ["<bs>"] = "navigate_up",
    ["."] = "set_root",
    ["[g"] = "prev_git_modified",
    ["]g"] = "next_git_modified",
    i = "show_file_details",
}

local function localized_mappings(templates, locale)
    local mappings = vim.deepcopy(templates)
    for lhs, value in pairs(mappings) do
        local labels = assert(mapping_labels[lhs], "missing Neo-tree mapping label: " .. lhs)
        local desc = labels[locale] or labels.en
        if type(value) == "table" then
            value.desc = desc
        else
            mappings[lhs] = { value, desc = desc }
        end
    end
    return mappings
end

local function combined_mappings(locale)
    return vim.tbl_deep_extend(
        "force",
        localized_mappings(base_mapping_templates, locale),
        localized_mappings(filesystem_mapping_templates, locale)
    )
end

local fuzzy_finder_mappings = {
    ["<down>"] = "move_cursor_down",
    ["<up>"] = "move_cursor_up",
    ["<Esc>"] = "close",
    ["<CR>"] = "close_clear_filter",
    ["<S-CR>"] = "close_keep_filter",
    {
        n = {
            j = "move_cursor_down",
            k = "move_cursor_up",
            ["<esc>"] = "close",
            ["<cr>"] = "close_clear_filter",
            ["<s-cr>"] = "close_keep_filter",
        },
    },
}

local function on_buffer_enter()
    vim.wo.number = false
    vim.wo.relativenumber = false
    vim.wo.signcolumn = "auto"
    vim.cmd("vertical resize " .. WIDTH)
end

local function append_buffer_enter_handler(opts)
    opts.event_handlers = opts.event_handlers or {}
    for _, handler in ipairs(opts.event_handlers) do
        if handler.event == "neo_tree_buffer_enter" and handler.handler == on_buffer_enter then
            return
        end
    end
    table.insert(opts.event_handlers, { event = "neo_tree_buffer_enter", handler = on_buffer_enter })
end

local configured_opts

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

local function apply_configured_profile(opts, locale)
    if not opts then
        return
    end
    opts.window.mappings = localized_mappings(base_mapping_templates, locale)
    opts.filesystem.window.mappings = localized_mappings(filesystem_mapping_templates, locale)
end

local function refresh_neotree_locale()
    local locale = i18n.get_locale()
    apply_configured_profile(configured_opts, locale)

    local neo_tree = package.loaded["neo-tree"]
    local manager = package.loaded["neo-tree.sources.manager"]
    if type(neo_tree) ~= "table" or type(neo_tree.config) ~= "table" then
        return
    end

    neo_tree.config.window = neo_tree.config.window or {}
    neo_tree.config.window.mappings = localized_mappings(base_mapping_templates, locale)
    neo_tree.config.filesystem = neo_tree.config.filesystem or {}
    neo_tree.config.filesystem.window = neo_tree.config.filesystem.window or {}
    neo_tree.config.filesystem.window.mappings = combined_mappings(locale)

    if type(manager) ~= "table" then
        return
    end
    if type(manager._for_each_state) ~= "function" then
        return
    end

    manager._for_each_state("filesystem", function(state)
        state.window = state.window or {}
        state.window.mappings = combined_mappings(locale)
        for lhs, labels in pairs(mapping_labels) do
            local desc = labels[locale] or labels.en
            if state.resolved_mappings and state.resolved_mappings[lhs] then
                state.resolved_mappings[lhs].text = desc
                replace_mapping_description(state.bufnr, "n", lhs, desc)
            end
        end
    end)
end

local function install_locale_refresh()
    local group = vim.api.nvim_create_augroup("ClarityNeoTreeLocale", { clear = true })
    vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "ClarityLocaleChanged",
        callback = refresh_neotree_locale,
    })
end

return {
    {
        "nvim-neo-tree/neo-tree.nvim",
        keys = {
            {
                "<leader>e",
                function()
                    require("neo-tree.command").execute({ toggle = true, dir = LazyVim.root() })
                end,
                desc = i18n.t("keymaps.explorer_root"),
            },
            {
                "<leader>E",
                function()
                    require("neo-tree.command").execute({ toggle = true, dir = vim.uv.cwd() })
                end,
                desc = i18n.t("keymaps.explorer_cwd"),
            },
        },
        opts = function(_, opts)
            vim.opt.fillchars:append({ vert = "┃" })

            local locale = i18n.get_locale()

            local delta = {
                sources = { "filesystem" },
                default_source = "filesystem",
                use_default_mappings = false,
                close_if_last_window = false,
                popup_border_style = "rounded",
                enable_git_status = true,
                enable_diagnostics = true,
                filesystem = {
                    filtered_items = {
                        visible = true,
                        hide_dotfiles = false,
                        hide_gitignored = false,
                    },
                    follow_current_file = { enabled = true },
                    hijack_netrw_behavior = "open_default",
                    use_libuv_file_watcher = true,
                    window = {
                        mappings = localized_mappings(filesystem_mapping_templates, locale),
                        fuzzy_finder_mappings = fuzzy_finder_mappings,
                    },
                },
                window = {
                    position = "left",
                    width = WIDTH,
                    mapping_options = {
                        noremap = true,
                        nowait = true,
                    },
                    mappings = localized_mappings(base_mapping_templates, locale),
                },
                source_selector = {
                    winbar = false,
                    statusline = false,
                    sources = {},
                },
                default_component_configs = {
                    name = {
                        trailing_slash = false,
                        use_git_status_colors = true,
                    },
                },
            }

            local merged = vim.tbl_deep_extend("force", opts, delta)
            for key in pairs(opts) do
                opts[key] = nil
            end
            for key, value in pairs(merged) do
                opts[key] = value
            end
            -- vim.tbl_deep_extend merges mapping dictionaries. Replace these
            -- tables explicitly so late upstream defaults cannot restore file
            -- or repository mutation controls.
            opts.sources = { "filesystem" }
            opts.window.mappings = localized_mappings(base_mapping_templates, locale)
            opts.filesystem.window.mappings = localized_mappings(filesystem_mapping_templates, locale)
            opts.filesystem.window.fuzzy_finder_mappings = vim.deepcopy(fuzzy_finder_mappings)
            opts.source_selector.sources = {}
            append_buffer_enter_handler(opts)
            configured_opts = opts
            install_locale_refresh()
            return opts
        end,
    },
}
