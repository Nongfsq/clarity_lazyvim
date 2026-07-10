local repo_root = vim.env.CLARITY_REPO_ROOT or vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
package.path = repo_root .. "/nvim/lua/?.lua;" .. repo_root .. "/nvim/lua/?/init.lua;" .. package.path

package.loaded["config.i18n"] = {
    t = function(key)
        return key
    end,
}

local created = 0
local toggled = 0
package.loaded["toggleterm.terminal"] = {
    Terminal = {
        new = function(_, opts)
            created = created + 1
            assert(opts.direction == "float", "the sole terminal instance must be floating")
            return {
                toggle = function()
                    toggled = toggled + 1
                end,
            }
        end,
    },
}

local spec = dofile(repo_root .. "/nvim/lua/plugins/toggleterm.lua")[1]
assert(#spec.keys == 1, "ToggleTerm must expose exactly one product key")
assert(spec.keys[1][1] == "<leader>tf", "the sole terminal entry must be <leader>tf")
assert(spec.opts.open_mapping == nil, "raw <C-\\> product toggle must be removed")

spec.keys[1][2]()
spec.keys[1][2]()
assert(created == 1, "the floating terminal instance must be reused")
assert(toggled == 2, "the reused terminal must toggle on each invocation")

local setup_opts
package.loaded.toggleterm = {
    setup = function(opts)
        setup_opts = opts
    end,
}
local autocmd_event
local autocmd_opts
local original_create_autocmd = vim.api.nvim_create_autocmd
vim.api.nvim_create_autocmd = function(event, opts)
    autocmd_event = event
    autocmd_opts = opts
end
spec.config(nil, spec.opts)
vim.api.nvim_create_autocmd = original_create_autocmd
assert(setup_opts == spec.opts, "ToggleTerm setup must receive the declared opts")
assert(autocmd_event == "FileType", "terminal mappings must not use a generic TermOpen autocmd")
assert(autocmd_opts.pattern == "toggleterm", "terminal mappings must be scoped to ToggleTerm buffers")

local mapped = {}
local original_keymap_set = vim.keymap.set
vim.keymap.set = function(mode, lhs, _, opts)
    table.insert(mapped, { mode = mode, lhs = lhs, buffer = opts.buffer })
end
autocmd_opts.callback({ buf = 42 })
vim.keymap.set = original_keymap_set
assert(#mapped == 6, "only required terminal exit/window mappings should remain")
for _, mapping in ipairs(mapped) do
    assert(mapping.mode == "t" and mapping.buffer == 42, "terminal mappings must be buffer-local")
    assert(mapping.lhs ~= "jk", "the undocumented jk terminal escape must be removed")
end

local source = table.concat(vim.fn.readfile(repo_root .. "/nvim/lua/plugins/toggleterm.lua"), "\n")
for _, forbidden in ipairs({
    "<leader>tr",
    "<leader>tv",
    "<leader>th",
    "<leader>ht",
    "system_monitor",
    "nvim-web-devicons",
    '"TermOpen"',
}) do
    assert(not source:find(forbidden, 1, true), "removed terminal surface remains: " .. forbidden)
end

package.loaded.toggleterm = nil
package.loaded["toggleterm.terminal"] = nil
package.loaded["config.i18n"] = nil
