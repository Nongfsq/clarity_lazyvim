local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
vim.opt.runtimepath:append(repo_root .. "/nvim")

local translations = {
    ["keymaps.toggle_fold"] = "Toggle Fold",
    ["keymaps.keep_only_window"] = "Keep Only Window",
    ["keymaps.search_text"] = "Search Text",
    ["keymaps.toggle_wrap"] = "Toggle Wrap",
}

package.loaded["config.i18n"] = {
    get_locale = function()
        return "zh"
    end,
    t = function(key)
        return translations[key] or key
    end,
}
package.loaded["config.actions.fold"] = {
    toggle = function() end,
}

local inherited_lhs = { "gD", "gd", "K", "gi", "gr", "<leader>cr", "<leader>ca", "gl", "[d", "]d" }
local inherited_before = {}
for _, lhs in ipairs(inherited_lhs) do
    inherited_before[lhs] = vim.fn.maparg(lhs, "n", false, true)
end

dofile(repo_root .. "/nvim/lua/config/keymaps.lua")

for _, lhs in ipairs({ "<leader>cz", "<leader>fw", "<leader>uw", "<leader>wo" }) do
    assert(not vim.tbl_isempty(vim.fn.maparg(lhs, "n", false, true)), "missing Clarity-owned map: " .. lhs)
end

for _, lhs in ipairs(inherited_lhs) do
    assert(
        vim.deep_equal(vim.fn.maparg(lhs, "n", false, true), inherited_before[lhs]),
        "Clarity changed an inherited mapping: " .. lhs
    )
end

local callback = function() end
vim.keymap.set("n", "<leader>ff", callback, {
    desc = "Find Files (Root Dir)",
    expr = true,
    nowait = true,
    silent = true,
})
local before = vim.fn.maparg("<leader>ff", "n", false, true)
local registrations = {}
package.loaded["which-key"] = {
    add = function(spec)
        table.insert(registrations, spec)
    end,
}

package.loaded["config.menu_i18n"] = nil
require("config.menu_i18n").apply()

local after = vim.fn.maparg("<leader>ff", "n", false, true)
for _, field in ipairs({ "callback", "rhs", "expr", "nowait", "noremap", "silent", "buffer" }) do
    assert(after[field] == before[field], "which-key metadata changed mapping field: " .. field)
end
assert(after.desc == before.desc, "which-key metadata must not rewrite the native mapping description")

local translated
for _, batch in ipairs(registrations) do
    for _, item in ipairs(batch) do
        if item.desc == "查找文件（项目根目录）" and item.mode == "n" then
            translated = item.desc
        end
    end
end
assert(translated == "查找文件（项目根目录）", "translated which-key metadata missing")

local validation = table.concat(vim.fn.readfile(repo_root .. "/nvim/lua/config/validation.lua"), "\n")
assert(
    validation:find('lsp_gd = "CLARITY_RUNTIME_KEYMAP_CONTRACT"', 1, true),
    "passive validation must delegate the gd behavior contract"
)
assert(
    validation:find('leader_cz = "CLARITY_RUNTIME_KEYMAP_CONTRACT"', 1, true),
    "passive validation must delegate promoted key behavior"
)
assert(not validation:find('has_map("<leader>gd", "n")', 1, true), "stale <leader>gd validation remains")

print("keymap ownership tests: OK")
