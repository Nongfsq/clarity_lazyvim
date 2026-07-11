local repo_root = vim.env.CLARITY_REPO_ROOT or vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
package.path = repo_root .. "/nvim/lua/?.lua;" .. repo_root .. "/nvim/lua/?/init.lua;" .. package.path

local locale = "en"
package.loaded["config.i18n"] = {
    get_locale = function()
        return locale
    end,
    t = function(key)
        return key
    end,
}

local spec = dofile(repo_root .. "/nvim/lua/plugins/neo-tree.lua")[1]
assert(type(spec.opts) == "function", "Neo-tree must extend incoming opts")
assert(spec.config == nil, "Clarity must retain LazyVim's Neo-tree config lifecycle")
assert(spec.lazy == nil, "Clarity must retain LazyVim's Neo-tree lazy-loading policy")
assert(spec.dependencies == nil, "Clarity must retain upstream Neo-tree dependency ownership")

local rename_handler = { event = "file_renamed", handler = function() end }
local move_handler = { event = "file_moved", handler = function() end }
local opts = {
    event_handlers = { rename_handler, move_handler },
    filesystem = { bind_to_cwd = false },
    window = { mappings = { l = "open" } },
}
local merged = spec.opts(nil, opts)
assert(merged == opts, "Neo-tree opts extension must preserve incoming table identity")
assert(merged.event_handlers[1] == rename_handler, "upstream rename handler must be preserved")
assert(merged.event_handlers[2] == move_handler, "upstream move handler must be preserved")
assert(#merged.event_handlers == 3, "Clarity must append exactly one Neo-tree handler")
assert(merged.event_handlers[3].event == "neo_tree_buffer_enter", "buffer-enter handler must be top-level")
assert(merged.default_component_configs.event_handlers == nil, "event handlers must not be nested in components")
assert(merged.filesystem.bind_to_cwd == false, "unrelated upstream filesystem opts must survive")
assert(merged.window.mappings.l == nil, "inherited open alias must be removed")
assert(merged.window.width == 35, "Clarity explorer width must be merged")
assert(merged.use_default_mappings == false, "Neo-tree defaults must not be composed")
assert(vim.deep_equal(merged.sources, { "filesystem" }), "filesystem must be the only reachable source")
assert(vim.tbl_isempty(merged.source_selector.sources), "source selector must not expose Git mutation")

local function keyset(mappings)
    local result = {}
    for lhs in pairs(mappings) do
        if type(lhs) == "string" then
            result[lhs] = true
        end
    end
    return result
end

local base = keyset(merged.window.mappings)
local filesystem = keyset(merged.filesystem.window.mappings)
local expected_base = {
    ["<2-LeftMouse>"] = true,
    ["<cr>"] = true,
    ["<esc>"] = true,
    P = true,
    ["<C-f>"] = true,
    ["<C-b>"] = true,
    C = true,
    z = true,
    R = true,
    q = true,
    ["?"] = true,
    Y = true,
}
local expected_filesystem = {
    H = true,
    ["/"] = true,
    ["<C-x>"] = true,
    ["<bs>"] = true,
    ["."] = true,
    ["[g"] = true,
    ["]g"] = true,
    i = true,
}
assert(vim.deep_equal(base, expected_base), "Neo-tree base profile drifted")
assert(vim.deep_equal(filesystem, expected_filesystem), "Neo-tree filesystem profile drifted")
local unique = vim.tbl_extend("force", {}, base, filesystem)
assert(vim.tbl_count(unique) <= 24, "Neo-tree product profile exceeds its 24-key budget")
for _, lhs in ipairs({ "a", "A", "d", "r", "y", "x", "p", "c", "m", "<", ">", "s", "S", "t" }) do
    assert(not base[lhs] and not filesystem[lhs], "Neo-tree mutation/expert key remains: " .. lhs)
end

local expected_descriptions = {
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

local function assert_profile_descriptions(profile, expected_locale)
    for lhs, value in pairs(profile) do
        assert(type(value) == "table", "Neo-tree mapping lacks a description table: " .. lhs)
        assert(
            value.desc == expected_descriptions[lhs][expected_locale],
            "Neo-tree mapping description drifted for " .. lhs
        )
    end
end

assert_profile_descriptions(merged.window.mappings, "en")
assert_profile_descriptions(merged.filesystem.window.mappings, "en")

local key_by_lhs = {}
for _, key in ipairs(spec.keys) do
    key_by_lhs[key[1]] = key
end
assert(key_by_lhs["<leader>e"] and key_by_lhs["<leader>E"], "localized explorer entry points missing")
assert(key_by_lhs["<leader>fe"] == nil and key_by_lhs["<leader>fE"] == nil, "upstream explorer paths must remain")

local lazy_source = table.concat(vim.fn.readfile(repo_root .. "/nvim/lua/config/lazy.lua"), "\n")
assert(
    lazy_source:find('vim.g.lazyvim_explorer = "neo-tree"', 1, true),
    "Neo-tree must remain the selected sole explorer before LazyVim startup"
)

local source = table.concat(vim.fn.readfile(repo_root .. "/nvim/lua/plugins/neo-tree.lua"), "\n")
for _, forbidden in ipairs({ 'require("neo-tree").setup', "lazy = false", "dependencies =" }) do
    assert(not source:find(forbidden, 1, true), "forbidden Neo-tree lifecycle ownership remains: " .. forbidden)
end

local previous_neo_tree = package.loaded["neo-tree"]
local previous_manager = package.loaded["neo-tree.sources.manager"]
local tree_buf = vim.api.nvim_create_buf(false, true)
local state = {
    bufnr = tree_buf,
    name = "filesystem",
    resolved_mappings = {},
    window = {
        mappings = vim.tbl_deep_extend(
            "force",
            vim.deepcopy(merged.window.mappings),
            vim.deepcopy(merged.filesystem.window.mappings)
        ),
    },
}
local before = {}
for lhs, descriptions in pairs(expected_descriptions) do
    local handler = function() end
    state.resolved_mappings[lhs] = { text = descriptions.en, handler = handler }
    vim.keymap.set("n", lhs, handler, {
        buffer = tree_buf,
        desc = descriptions.en,
        nowait = true,
        silent = true,
    })
    vim.api.nvim_buf_call(tree_buf, function()
        before[lhs] = vim.fn.maparg(lhs, "n", false, true)
    end)
end

local fake_neo_tree = {
    config = {
        window = { mappings = vim.deepcopy(merged.window.mappings) },
        filesystem = { window = { mappings = vim.deepcopy(merged.filesystem.window.mappings) } },
    },
}
package.loaded["neo-tree"] = fake_neo_tree
package.loaded["neo-tree.sources.manager"] = {
    _for_each_state = function(name, callback)
        assert(name == "filesystem", "locale refresh traversed an unexpected Neo-tree source")
        callback(state)
    end,
}

local function assert_live_descriptions(expected_locale)
    local seen = 0
    for lhs, descriptions in pairs(expected_descriptions) do
        seen = seen + 1
        assert(
            state.resolved_mappings[lhs].text == descriptions[expected_locale],
            "Neo-tree help text did not refresh for " .. lhs
        )
        vim.api.nvim_buf_call(tree_buf, function()
            local mapping = vim.fn.maparg(lhs, "n", false, true)
            assert(mapping.desc == descriptions[expected_locale], "actual Neo-tree map did not refresh for " .. lhs)
            assert(
                mapping.callback == before[lhs].callback,
                "Neo-tree callback changed during locale refresh for " .. lhs
            )
            assert(mapping.silent == before[lhs].silent, "Neo-tree silent option changed for " .. lhs)
            assert(mapping.nowait == before[lhs].nowait, "Neo-tree nowait option changed for " .. lhs)
            assert(mapping.noremap == before[lhs].noremap, "Neo-tree remap option changed for " .. lhs)
        end)
    end
    assert(seen == 20, "Neo-tree locale contract must cover exactly 20 curated mappings")
    assert(vim.tbl_count(state.window.mappings) == 20, "active Neo-tree state lost curated mappings")
    assert(
        vim.tbl_count(fake_neo_tree.config.filesystem.window.mappings) == 20,
        "future Neo-tree states lost curated mappings"
    )
    for lhs, mapping in pairs(fake_neo_tree.config.filesystem.window.mappings) do
        assert(
            mapping.desc == expected_descriptions[lhs][expected_locale],
            "future Neo-tree mapping did not refresh for " .. lhs
        )
        assert(
            state.window.mappings[lhs].desc == expected_descriptions[lhs][expected_locale],
            "active Neo-tree state mapping did not refresh for " .. lhs
        )
    end
end

locale = "zh"
vim.api.nvim_exec_autocmds("User", { pattern = "ClarityLocaleChanged", modeline = false })
assert_profile_descriptions(merged.window.mappings, "zh")
assert_profile_descriptions(merged.filesystem.window.mappings, "zh")
assert_live_descriptions("zh")

locale = "en"
vim.api.nvim_exec_autocmds("User", { pattern = "ClarityLocaleChanged", modeline = false })
assert_profile_descriptions(merged.window.mappings, "en")
assert_profile_descriptions(merged.filesystem.window.mappings, "en")
assert_live_descriptions("en")

vim.api.nvim_buf_delete(tree_buf, { force = true })
pcall(vim.api.nvim_del_augroup_by_name, "ClarityNeoTreeLocale")
package.loaded["neo-tree"] = previous_neo_tree
package.loaded["neo-tree.sources.manager"] = previous_manager

package.loaded["config.i18n"] = nil
