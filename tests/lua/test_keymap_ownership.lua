local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
vim.opt.runtimepath:append(repo_root .. "/nvim")

local catalog = require("config.actions.catalog")

package.loaded["config.i18n"] = {
    get_locale = function()
        return "zh"
    end,
    t = function(key)
        return key
    end,
}
package.loaded["config.actions.fold"] = {
    toggle = function() end,
}

local autoformat_toggle_arg
LazyVim = {
    format = {
        toggle = function(buffer_local)
            autoformat_toggle_arg = buffer_local
        end,
    },
}

local leader = vim.g.mapleader or "\\"
local function expanded(lhs)
    return lhs:gsub("<leader>", leader)
end

local function find_global(mode, lhs)
    lhs = expanded(lhs)
    for _, item in ipairs(vim.api.nvim_get_keymap(mode)) do
        if item.lhs == lhs then
            return item
        end
    end
end

local function find_buffer(bufnr, mode, lhs)
    lhs = expanded(lhs)
    for _, item in ipairs(vim.api.nvim_buf_get_keymap(bufnr, mode)) do
        if item.lhs == lhs then
            return item
        end
    end
end

local inherited_callback = function()
    return "inherited"
end
local retained_inherited = {
    "<leader>-",
    "<leader>|",
    "<leader>E",
    "<leader>e",
    "<leader>?",
    "<leader>bd",
    "<leader>cf",
    "<leader>fb",
    "<leader>ff",
    "<leader>fn",
    "<leader>fr",
    "<leader>hh",
    "<leader>qq",
    "<leader>sd",
    "<leader>sk",
    "<leader>tf",
    "<leader>wd",
    "<leader>wm",
    "<leader>xq",
}
local inherited_before = {}
for _, lhs in ipairs(retained_inherited) do
    vim.keymap.set("n", lhs, inherited_callback, {
        desc = "Inherited " .. lhs,
        expr = true,
        nowait = true,
        silent = true,
    })
    inherited_before[lhs] = vim.fn.maparg(lhs, "n", false, true)
end

local lsp_native = { "gD", "gd", "K", "gr", "<leader>ca", "<leader>cr" }
local lsp_before = {}
for _, lhs in ipairs(lsp_native) do
    vim.keymap.set("n", lhs, inherited_callback, { desc = "LSP " .. lhs, silent = true })
    lsp_before[lhs] = vim.fn.maparg(lhs, "n", false, true)
end

local removed_direct = { "<leader>bb", "<leader>bD", "<leader>uF", "<leader>uh", "<leader>uL" }
for _, lhs in ipairs(removed_direct) do
    vim.keymap.set("n", lhs, inherited_callback, { desc = "Reviewed alias " .. lhs })
end

local replaced_before = {}
for _, lhs in ipairs({ "<leader>gb", "<leader>gd", "<leader>gl", "<leader>gs" }) do
    vim.keymap.set("n", lhs, inherited_callback, { desc = "Unsafe inherited Git action" })
    replaced_before[lhs] = vim.fn.maparg(lhs, "n", false, true)
end

local user_callback = function()
    return "user-owned"
end
for _, lhs in ipairs({ "<leader>ga", "<leader>zz" }) do
    vim.keymap.set("n", lhs, user_callback, { desc = "User-owned " .. lhs, silent = true })
end
local user_before = {
    ["<leader>ga"] = vim.fn.maparg("<leader>ga", "n", false, true),
    ["<leader>zz"] = vim.fn.maparg("<leader>zz", "n", false, true),
}

dofile(repo_root .. "/nvim/lua/config/keymaps.lua")

for _, lhs in ipairs(retained_inherited) do
    assert(
        vim.deep_equal(vim.fn.maparg(lhs, "n", false, true), inherited_before[lhs]),
        "Clarity changed a retained inherited mapping: " .. lhs
    )
end
for _, lhs in ipairs(lsp_native) do
    assert(
        vim.deep_equal(vim.fn.maparg(lhs, "n", false, true), lsp_before[lhs]),
        "global pruning changed a native/LSP mapping: " .. lhs
    )
end
for lhs, before in pairs(user_before) do
    assert(vim.deep_equal(vim.fn.maparg(lhs, "n", false, true), before), "user mapping was swept: " .. lhs)
end

for _, lhs in ipairs({ "<leader>bb", "<leader>bD", "<leader>uh", "<leader>uL" }) do
    assert(find_global("n", lhs) == nil, "reviewed direct alias remains global: " .. lhs)
end
assert(find_global("n", "<leader>uF") == nil, "buffer autoformat recovery remains globally exposed")

for _, lhs in ipairs({ "<leader>cz", "<leader>fw", "<leader>uw", "<leader>wo" }) do
    assert(find_global("n", lhs), "missing Clarity-owned global map: " .. lhs)
end
for _, lhs in ipairs({ "<leader>gb", "<leader>gd", "<leader>gl", "<leader>gs", "<leader>gt" }) do
    local current = assert(find_global("n", lhs), "missing read-only Git action: " .. lhs)
    if replaced_before[lhs] then
        assert(current.callback ~= replaced_before[lhs].callback, "unsafe Git action was not replaced: " .. lhs)
    end
end

local ordinary = vim.api.nvim_get_current_buf()
local buffer_autoformat = assert(find_buffer(ordinary, "n", "<leader>uF"), "ordinary buffer lacks autoformat recovery")
assert(type(buffer_autoformat.callback) == "function", "buffer autoformat recovery is not callable")
buffer_autoformat.callback()
assert(autoformat_toggle_arg == true, "buffer autoformat recovery changed global policy")
assert(find_buffer(ordinary, "n", "<leader>uh") == nil, "inlay hints appeared without an LSP capability")

local transitioned = vim.api.nvim_create_buf(true, false)
vim.api.nvim_set_current_buf(transitioned)
vim.api.nvim_exec_autocmds("BufEnter", { buffer = transitioned })
assert(find_buffer(transitioned, "n", "<leader>uF"), "ordinary transition buffer lacks autoformat recovery")
vim.cmd("setlocal readonly")
assert(find_buffer(transitioned, "n", "<leader>uF") == nil, "readonly transition left a stale autoformat map")
vim.cmd("setlocal noreadonly")
assert(find_buffer(transitioned, "n", "<leader>uF"), "editable transition did not restore autoformat recovery")
vim.cmd("setlocal nomodifiable")
assert(find_buffer(transitioned, "n", "<leader>uF") == nil, "unmodifiable transition left a stale autoformat map")
vim.cmd("setlocal modifiable")
assert(find_buffer(transitioned, "n", "<leader>uF"), "modifiable transition did not restore autoformat recovery")
vim.cmd("setlocal buftype=nofile")
assert(find_buffer(transitioned, "n", "<leader>uF") == nil, "nofile transition left a stale autoformat map")
vim.cmd("setlocal buftype=")
assert(find_buffer(transitioned, "n", "<leader>uF"), "ordinary transition did not restore autoformat recovery")
vim.api.nvim_set_current_buf(ordinary)

local nofile = vim.api.nvim_create_buf(false, true)
vim.bo[nofile].buftype = "nofile"
vim.api.nvim_set_current_buf(nofile)
vim.api.nvim_exec_autocmds("FileType", { buffer = nofile })
assert(find_buffer(nofile, "n", "<leader>uF") == nil, "special buffer exposes autoformat recovery")

local readonly = vim.api.nvim_create_buf(false, true)
vim.bo[readonly].readonly = true
vim.api.nvim_set_current_buf(readonly)
vim.api.nvim_exec_autocmds("FileType", { buffer = readonly })
assert(find_buffer(readonly, "n", "<leader>uF") == nil, "read-only buffer exposes autoformat recovery")
vim.api.nvim_set_current_buf(ordinary)

vim.keymap.set("n", "<leader>uG", inherited_callback, { desc = "Late Gitsigns toggle" })
vim.keymap.set("n", "<leader>up", inherited_callback, { desc = "Late pairs toggle" })
vim.api.nvim_exec_autocmds("User", { pattern = "LazyLoad", data = "gitsigns.nvim" })
assert(find_global("n", "<leader>uG") == nil, "late Gitsigns toggle was not removed")
assert(find_global("n", "<leader>up"), "unrelated late owner was removed too early")
vim.api.nvim_exec_autocmds("User", { pattern = "LazyLoad", data = "mini.pairs" })
assert(find_global("n", "<leader>up") == nil, "late mini.pairs toggle was not removed")
for lhs, before in pairs(user_before) do
    assert(vim.deep_equal(vim.fn.maparg(lhs, "n", false, true), before), "late cleanup swept user map: " .. lhs)
end

local ff_before = vim.fn.maparg("<leader>ff", "n", false, true)
local registered
package.loaded["which-key"] = {
    add = function(spec)
        registered = spec
    end,
}
package.loaded["config.menu_i18n"] = nil
assert(require("config.menu_i18n").apply(), "catalog-backed menu metadata did not register")
local ff_after = vim.fn.maparg("<leader>ff", "n", false, true)
assert(vim.deep_equal(ff_after, ff_before), "menu metadata rewrote the find-files mapping")

local translated
for _, item in ipairs(registered or {}) do
    if item[1] == "<leader>ff" and type(item.desc) == "function" then
        translated = item.desc()
        break
    end
end
assert(translated == catalog.label("files.find", "zh"), "catalog-backed Chinese metadata is missing")

local validation = table.concat(vim.fn.readfile(repo_root .. "/nvim/lua/config/validation.lua"), "\n")
assert(
    validation:find('lsp = "CLARITY_RUNTIME_LSP_CONTRACT"', 1, true),
    "passive validation must delegate the LSP behavior contract"
)
assert(
    validation:find('fold = "CLARITY_RUNTIME_FOLD_CONTRACT"', 1, true),
    "passive validation must delegate promoted fold behavior"
)
assert(not validation:find('has_map("<leader>gd", "n")', 1, true), "stale <leader>gd validation remains")

print("keymap ownership tests: OK")
