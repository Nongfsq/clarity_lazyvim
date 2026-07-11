local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
local plugin_path = repo_root .. "/nvim/lua/plugins/terminal.lua"

package.loaded["config.i18n"] = {
    t = function(key)
        return key
    end,
}

local calls = {}
_G.Snacks = {
    terminal = {
        toggle = function(cmd, opts)
            table.insert(calls, { cmd = cmd, opts = opts })
        end,
    },
}

local original_getcwd = vim.fn.getcwd
vim.fn.getcwd = function()
    return "/review/project"
end

local spec = assert(loadfile(plugin_path))()[1]
assert(spec[1] == "folke/snacks.nvim", "the required Snacks stack must own the terminal")
assert(#spec.keys == 1 and spec.keys[1][1] == "<leader>tf", "one promoted terminal key is required")
spec.keys[1][2]()

assert(#calls == 1, "terminal action must issue one toggle")
local opts = calls[1].opts
assert(calls[1].cmd == nil, "terminal must use the configured shell")
assert(opts.cwd == "/review/project", "terminal must inherit the current project cwd")
assert(opts.win.position == "float", "terminal must remain a float")
assert(opts.win.width == 0.8 and opts.win.height == 0.8, "terminal must fit small and large UIs proportionally")
for _, key in ipairs({ "term_normal", "nav_left", "nav_down", "nav_up", "nav_right", "nav_prefix" }) do
    assert(opts.win.keys[key] and opts.win.keys[key].mode == "t", "terminal-local navigation missing: " .. key)
end

local source = table.concat(vim.fn.readfile(plugin_path), "\n")
assert(not source:find("toggleterm", 1, true), "ToggleTerm ownership must be removed")

vim.fn.getcwd = original_getcwd
package.loaded["config.i18n"] = nil
_G.Snacks = nil
print("terminal surface tests: OK")
