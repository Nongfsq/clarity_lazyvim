local repo_root = vim.env.CLARITY_REPO_ROOT or vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
package.path = repo_root .. "/nvim/lua/?.lua;" .. repo_root .. "/nvim/lua/?/init.lua;" .. package.path

package.loaded["config.i18n"] = {
    t = function(key)
        return key
    end,
}

local mapped = { n = {}, o = {}, v = {}, x = {} }
local original_keymap_set = vim.keymap.set
local original_keymap_del = vim.keymap.del

local function each_mode(mode, callback)
    for _, item in ipairs(type(mode) == "table" and mode or { mode }) do
        mapped[item] = mapped[item] or {}
        callback(item)
    end
end

vim.keymap.set = function(mode, lhs, rhs)
    each_mode(mode, function(item)
        mapped[item][lhs] = rhs
    end)
end
vim.keymap.del = function(mode, lhs)
    each_mode(mode, function(item)
        mapped[item][lhs] = nil
    end)
end

local navigation = {}
local preview_count = 0
package.loaded.gitsigns = {
    nav_hunk = function(direction)
        table.insert(navigation, direction)
    end,
    preview_hunk_inline = function()
        preview_count = preview_count + 1
    end,
}

local git_optional_locks_before = vim.env.GIT_OPTIONAL_LOCKS
local spec = dofile(repo_root .. "/nvim/lua/plugins/git.lua")[1]
assert(type(spec.opts) == "function", "Gitsigns must extend incoming opts")
assert(spec.config == nil, "Clarity must not override LazyVim's Gitsigns config lifecycle")
assert(spec.event == nil, "Clarity must retain LazyVim's Gitsigns load event")
assert(
    vim.env.GIT_OPTIONAL_LOCKS == git_optional_locks_before,
    "loading the Git profile must not change process-global Git behavior"
)

local attach_order = {}
local mutation_maps = {
    n = {
        "]H",
        "[H",
        "<leader>ghs",
        "<leader>ghr",
        "<leader>ghS",
        "<leader>ghu",
        "<leader>ghR",
        "<leader>ghb",
        "<leader>ghB",
        "<leader>ghd",
        "<leader>ghD",
    },
    x = { "<leader>ghs", "<leader>ghr", "ih" },
    o = { "ih" },
}
local opts = {
    on_attach = function(bufnr)
        attach_order[#attach_order + 1] = "upstream:" .. bufnr
        for mode, keys in pairs(mutation_maps) do
            for _, lhs in ipairs(keys) do
                vim.keymap.set(mode, lhs, "upstream-write-or-duplicate", { buffer = bufnr })
            end
        end
        vim.keymap.set("n", "]h", "upstream-next", { buffer = bufnr })
        vim.keymap.set("n", "[h", "upstream-prev", { buffer = bufnr })
        vim.keymap.set("n", "<leader>ghp", "upstream-preview", { buffer = bufnr })
    end,
}
assert(spec.opts(nil, opts) == opts, "opts extension must preserve the incoming table")

local buffer = vim.api.nvim_create_buf(false, true)
local function assert_read_only_attachment(iteration)
    opts.on_attach(buffer)
    assert(attach_order[#attach_order] == "upstream:" .. buffer, "incoming on_attach must run first")
    assert(type(mapped.n["]h"]) == "function" and type(mapped.n["[h"]) == "function", "hunk navigation missing")
    assert(type(mapped.n["<leader>ghp"]) == "function", "dynamic hunk preview missing")
    for mode, keys in pairs(mutation_maps) do
        for _, lhs in ipairs(keys) do
            assert(mapped[mode][lhs] == nil, iteration .. " retained forbidden map " .. mode .. ":" .. lhs)
        end
    end
    assert(mapped.n["]c"] == nil and mapped.n["[c"] == nil, "Clarity must not override Tree-sitter [c/]c")
end

assert_read_only_attachment("first attach")
assert_read_only_attachment("second attach")
assert(#attach_order == 2, "reattachment fixture must run upstream twice")

vim.wo.diff = false
mapped.n["]h"]()
mapped.n["[h"]()
vim.wait(100, function()
    return #navigation == 2
end)
assert(vim.deep_equal(navigation, { "next", "prev" }), "normal buffers must navigate Gitsigns hunks")
mapped.n["<leader>ghp"]()
assert(preview_count == 1, "hunk preview callback did not execute")

local normal_commands = {}
local original_normal = vim.cmd.normal
vim.cmd.normal = function(command)
    normal_commands[#normal_commands + 1] = command
end
vim.wo.diff = true
mapped.n["]h"]()
mapped.n["[h"]()
vim.wo.diff = false
vim.cmd.normal = original_normal
assert(normal_commands[1][1] == "]c" and normal_commands[1].bang, "diff next-hunk must execute ]c")
assert(normal_commands[2][1] == "[c" and normal_commands[2].bang, "diff previous-hunk must execute [c")

local source = table.concat(vim.fn.readfile(repo_root .. "/nvim/lua/plugins/git.lua"), "\n")
for _, forbidden in ipairs({
    "create_autocmd",
    "defer_fn",
    "nvim_list_bufs",
    'gitsigns").setup',
    "stage_hunk<CR>",
    "reset_hunk<CR>",
    "stage_buffer",
    "reset_buffer",
    "undo_stage_hunk",
    "vim.env.GIT_OPTIONAL_LOCKS",
}) do
    assert(not source:find(forbidden, 1, true), "forbidden Gitsigns ownership or mutation remains: " .. forbidden)
end

vim.keymap.set = original_keymap_set
vim.keymap.del = original_keymap_del
package.loaded.gitsigns = nil
package.loaded["config.i18n"] = nil
vim.api.nvim_buf_delete(buffer, { force = true })

print("Gitsigns config tests: OK")
