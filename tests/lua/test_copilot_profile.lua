local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
local plugin_path = repo_root .. "/nvim/lua/plugins/copilot.lua"

local original_env = vim.env.CLARITY_COPILOT
local original_exepath = vim.fn.exepath

local function load_spec(value)
    vim.env.CLARITY_COPILOT = value
    return assert(loadfile(plugin_path))()[1]
end

local disabled = load_spec(nil)
assert(disabled.cond == false, "Copilot condition must be false in the core profile")
assert(disabled.enabled == nil, "optional Copilot must remain locked for explicit profiles")

local explicit_disabled = load_spec("0")
assert(explicit_disabled.enabled == nil and explicit_disabled.cond == false, "only value 1 may enable Copilot")

local exepath_calls = 0
vim.fn.exepath = function(command)
    exepath_calls = exepath_calls + 1
    assert(command == "node", "Copilot may only resolve the active node executable")
    return "/profile/bin/node"
end

local enabled = load_spec("1")
assert(enabled.enabled == nil and enabled.cond == true, "explicit profile did not enable Copilot")
assert(exepath_calls == 0, "loading the plugin spec must not scan or resolve the host")

local opts = enabled.opts()
assert(opts.copilot_node_command == "/profile/bin/node", "active Node path was not forwarded")
assert(exepath_calls == 1, "Node path must be resolved exactly once during enabled setup")

for _, name in ipairs({ "accept", "accept_word", "accept_line", "next", "prev", "dismiss" }) do
    assert(opts.suggestion.keymap[name] == false, "suggestion key remains claimed: " .. name)
end
for _, name in ipairs({ "jump_prev", "jump_next", "accept", "refresh", "open" }) do
    assert(opts.panel.keymap[name] == false, "panel key remains claimed: " .. name)
end

local source = table.concat(vim.fn.readfile(plugin_path), "\n")
for _, forbidden in ipairs({ "fnm", "vim.fn.glob", "vim.fn.system", "<Tab>", "<C-n>", "<C-p>", "<C-e>", "<leader>co" }) do
    assert(not source:find(forbidden, 1, true), "forbidden Copilot host scan/core key remains: " .. forbidden)
end

local audit_source = table.concat(vim.fn.readfile(repo_root .. "/nvim/lua/config/audit.lua"), "\n")
assert(audit_source:find('CLARITY_COPILOT == "1"', 1, true), "audit must honor the explicit profile")

vim.fn.exepath = original_exepath
vim.env.CLARITY_COPILOT = original_env
print("copilot profile tests: OK")
