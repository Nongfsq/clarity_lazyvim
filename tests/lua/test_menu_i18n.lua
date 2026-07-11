local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
vim.opt.runtimepath:append(repo_root .. "/nvim")

local original_locale = vim.env.CLARITY_LOCALE
local original_lang = vim.env.LANG
local original_global = vim.g.clarity_locale

vim.env.CLARITY_LOCALE = "en"
vim.env.LANG = "en_US.UTF-8"
vim.g.clarity_locale = nil

package.loaded["config.i18n"] = nil
package.loaded["config.menu_i18n"] = nil

local i18n = require("config.i18n")
local menu = require("config.menu_i18n")

local function mode_contains(value, expected)
    if type(value) == "table" then
        return vim.tbl_contains(value, expected)
    end
    return value == expected
end

local function find_action_spec(spec, lhs, mode)
    for _, item in ipairs(spec) do
        if item[1] == lhs and type(item.desc) == "function" and mode_contains(item.mode, mode) then
            return item
        end
    end
end

local function find_group_spec(spec, prefix)
    for _, item in ipairs(spec) do
        if item[1] == prefix and type(item.group) == "function" then
            return item
        end
    end
end

local spec = menu.spec()
assert(#spec > 0, "catalog-backed which-key metadata is empty")

for _, item in ipairs(spec) do
    assert(item[2] == nil, "menu metadata must not supply a mapping rhs: " .. tostring(item[1]))
    assert(
        item.callback == nil and item.rhs == nil,
        "menu metadata must not own mapping behavior: " .. tostring(item[1])
    )
end

local code_group = assert(find_group_spec(spec, "<leader>c"), "code group metadata is missing")
local format = assert(find_action_spec(spec, "<leader>cf", "n"), "format metadata is missing")
local code_action = assert(find_action_spec(spec, "<leader>ca", "n"), "code-action metadata is missing")
local rename = assert(find_action_spec(spec, "<leader>cr", "n"), "rename metadata is missing")
local files = assert(find_action_spec(spec, "<leader>ff", "n"), "find-files metadata is missing")

assert(code_group.group() == "Code", "English code group label is wrong")
assert(format.desc() == "Format", "English format label is wrong")
assert(code_action.desc() == "Code action", "English code-action label is wrong")
assert(files.desc() == "Find files", "English find-files label is wrong")
assert(format.real == nil, "global metadata must not require an existing buffer-local mapping")
assert(code_action.real == true and rename.real == true, "buffer-local LSP metadata must use real=true")

local format_desc = format.desc
local group_label = code_group.group
local ok = i18n.set_choice("zh", { persist = false, silent = true })
assert(ok, "live switch to Chinese failed")
assert(group_label() == "代码", "existing group metadata did not switch to Chinese")
assert(format_desc() == "格式化", "existing action metadata did not switch to Chinese")
assert(code_action.desc() == "代码操作", "existing dynamic metadata did not switch to Chinese")
assert(files.desc() == "查找文件", "catalog label did not switch to Chinese")

ok = i18n.set_choice("en", { persist = false, silent = true })
assert(ok, "live switch back to English failed")
assert(group_label() == "Code" and format_desc() == "Format", "existing metadata did not switch back to English")

for _, lhs in ipairs({
    "<leader>uF",
    "<leader>uh",
    "<leader>ca",
    "<leader>cr",
    "<leader>ghp",
    "<leader>ss",
    "<leader>sS",
}) do
    local item = assert(find_action_spec(spec, lhs, "n"), "dynamic metadata is missing: " .. lhs)
    assert(item.real == true, "dynamic metadata must use real=true: " .. lhs)
end

local callback = function()
    return "mapping-owned behavior"
end
vim.keymap.set("n", "<leader>cf", callback, {
    desc = "Native mapping description",
    expr = true,
    nowait = true,
    silent = true,
})
local before = vim.fn.maparg("<leader>cf", "n", false, true)

local calls = 0
local registered
local registration_opts
local fake_which_key = {
    add = function(batch, opts)
        calls = calls + 1
        registered = batch
        registration_opts = opts
    end,
}

assert(menu.apply(fake_which_key) == true, "first which-key metadata registration failed")
assert(menu.apply(fake_which_key) == false, "which-key metadata must register only once")
assert(calls == 1 and registered ~= nil, "which-key received an unexpected number of metadata batches")
assert(registration_opts.create == false, "which-key metadata must not create native mappings")

local after = vim.fn.maparg("<leader>cf", "n", false, true)
for _, field in ipairs({ "callback", "rhs", "expr", "nowait", "noremap", "silent", "buffer", "desc" }) do
    assert(after[field] == before[field], "which-key metadata changed native mapping field: " .. field)
end

local source = table.concat(vim.fn.readfile(repo_root .. "/nvim/lua/config/menu_i18n.lua"), "\n")
assert(not source:find("desc_translations", 1, true), "legacy exact-English translation table remains")
assert(not source:find("nvim_get_keymap", 1, true), "menu localization still scans native mappings")
assert(not source:find("Find Files (Root Dir)", 1, true), "menu localization still depends on upstream English prose")

vim.keymap.del("n", "<leader>cf")
vim.env.CLARITY_LOCALE = original_locale
vim.env.LANG = original_lang
vim.g.clarity_locale = original_global

print("menu i18n tests: OK")
