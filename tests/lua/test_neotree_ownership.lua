local repo_root = vim.env.CLARITY_REPO_ROOT or vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
package.path = repo_root .. "/nvim/lua/?.lua;" .. repo_root .. "/nvim/lua/?/init.lua;" .. package.path

package.loaded["config.i18n"] = {
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
assert(merged.window.mappings.l == "open", "upstream Neo-tree mappings must survive")
assert(merged.window.width == 35, "Clarity explorer width must be merged")

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

package.loaded["config.i18n"] = nil
