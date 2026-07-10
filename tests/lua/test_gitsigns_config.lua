local repo_root = vim.env.CLARITY_REPO_ROOT or vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
package.path = repo_root .. "/nvim/lua/?.lua;" .. repo_root .. "/nvim/lua/?/init.lua;" .. package.path

package.loaded["config.i18n"] = {
    t = function(key)
        return key
    end,
}

local mapped = {}
local original_keymap_set = vim.keymap.set
vim.keymap.set = function(_, lhs, rhs)
    mapped[lhs] = rhs
end

local navigation = {}
package.loaded.gitsigns = {
    nav_hunk = function(direction)
        table.insert(navigation, direction)
    end,
    stage_buffer = function() end,
    reset_buffer = function() end,
    undo_stage_hunk = function() end,
    preview_hunk = function() end,
    blame_line = function() end,
    diffthis = function() end,
}

local spec = dofile(repo_root .. "/nvim/lua/plugins/git.lua")[1]
assert(type(spec.opts) == "function", "Gitsigns must extend incoming opts")
assert(spec.config == nil, "Clarity must not override LazyVim's Gitsigns config lifecycle")
assert(spec.event == nil, "Clarity must retain LazyVim's Gitsigns load event")

local attach_order = {}
local opts = {
    on_attach = function(bufnr)
        table.insert(attach_order, "upstream:" .. bufnr)
    end,
}
assert(spec.opts(nil, opts) == opts, "opts extension must preserve the incoming table")

local buffer = vim.api.nvim_create_buf(false, true)
opts.on_attach(buffer)
assert(attach_order[1] == "upstream:" .. buffer, "incoming on_attach must run before Clarity mappings")
assert(type(mapped["]h"]) == "function" and type(mapped["[h"]) == "function", "hunk navigation mappings missing")
assert(mapped["]c"] == nil and mapped["[c"] == nil, "Clarity must not override Tree-sitter [c/]c mappings")
for _, lhs in ipairs({
    "<leader>ghs",
    "<leader>ghr",
    "<leader>ghS",
    "<leader>ghR",
    "<leader>ghu",
    "<leader>ghp",
    "<leader>ghb",
    "<leader>ghd",
}) do
    assert(mapped[lhs] ~= nil, "Git hunk namespace mapping missing: " .. lhs)
end
for _, lhs in ipairs({ "<leader>hs", "<leader>hr", "<leader>hp", "<leader>hb", "<leader>hd" }) do
    assert(mapped[lhs] == nil, "legacy mixed Clarity/Git namespace remains: " .. lhs)
end

vim.wo.diff = false
mapped["]h"]()
mapped["[h"]()
vim.wait(100, function()
    return #navigation == 2
end)
assert(vim.deep_equal(navigation, { "next", "prev" }), "normal buffers must navigate Gitsigns hunks")

local normal_commands = {}
local original_normal = vim.cmd.normal
vim.cmd.normal = function(command)
    table.insert(normal_commands, command)
end
vim.wo.diff = true
mapped["]h"]()
mapped["[h"]()
vim.wo.diff = false
vim.cmd.normal = original_normal
assert(normal_commands[1][1] == "]c" and normal_commands[1].bang, "diff next-hunk must execute ]c")
assert(normal_commands[2][1] == "[c" and normal_commands[2].bang, "diff previous-hunk must execute [c")

local source = table.concat(vim.fn.readfile(repo_root .. "/nvim/lua/plugins/git.lua"), "\n")
for _, forbidden in ipairs({ "create_autocmd", "defer_fn", "nvim_list_bufs", 'gitsigns").setup' }) do
    assert(not source:find(forbidden, 1, true), "forbidden polling/lifecycle override remains: " .. forbidden)
end

vim.keymap.set = original_keymap_set
package.loaded.gitsigns = nil
package.loaded["config.i18n"] = nil
vim.api.nvim_buf_delete(buffer, { force = true })
