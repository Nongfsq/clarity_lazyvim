local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
vim.opt.runtimepath:append(repo_root .. "/nvim")

local temp = vim.fn.tempname()
vim.fn.mkdir(temp, "p")

local original_stdpath = vim.fn.stdpath
local original_writefile = vim.fn.writefile
local original_locale = vim.env.CLARITY_LOCALE
local original_lang = vim.env.LANG
local original_global = vim.g.clarity_locale

vim.fn.stdpath = function(kind)
    if kind == "state" then
        return temp
    end
    return original_stdpath(kind)
end
vim.env.CLARITY_LOCALE = "en"
vim.env.LANG = "en_US.UTF-8"
vim.g.clarity_locale = nil

package.loaded["config.i18n"] = nil
local i18n = require("config.i18n")
assert(i18n.get_locale() == "en", "test must start in English")

local events = {}
local group = vim.api.nvim_create_augroup("clarity_i18n_test", { clear = true })
vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "ClarityLocaleChanged",
    callback = function(args)
        table.insert(events, {
            data = vim.deepcopy(args.data),
            effective = i18n.get_locale(),
            translated = i18n.t("commands.health"),
        })
    end,
})

local ok, current = i18n.set_choice("zh", { persist = false, silent = true })
assert(ok and current.choice == "zh" and current.effective == "zh", "live Chinese choice failed")
assert(current.source == "runtime", "live choice must own the current-session state")
assert(#events == 1, "effective locale change must emit exactly one event")
assert(events[1].data.previous == "en" and events[1].data.current == "zh", "event transition is wrong")
assert(events[1].data.choice == "zh" and events[1].data.source == "runtime", "event state is incomplete")
assert(events[1].effective == "zh", "new locale must be visible inside the event callback")
assert(events[1].translated == "打开统一的 Clarity 帮助与健康入口", "event callback saw stale translations")

ok = i18n.set_choice("zh", { persist = false, silent = true })
assert(ok and #events == 1, "same effective locale must not emit another event")

local invalid_ok = i18n.set_choice("unsupported", { persist = false, silent = true })
assert(not invalid_ok and #events == 1, "invalid choice must fail without an event")
assert(i18n.get_locale() == "zh", "invalid choice changed live state")

ok, current = i18n.set_choice("auto", { persist = false, silent = true })
assert(ok and current.choice == "auto" and current.effective == "en", "auto detection did not update live state")
assert(
    #events == 2 and events[2].data.previous == "zh" and events[2].data.current == "en",
    "auto transition event is wrong"
)

ok, current = i18n.set_choice("en", { persist = false, silent = true })
assert(ok and current.choice == "en" and current.effective == "en", "same-effective choice failed")
assert(#events == 2, "choice-only change must not emit an effective-locale event")

ok = i18n.set_choice("zh", { silent = true })
assert(ok, "persisted language choice failed")
local saved_path = temp .. "/clarity_locale.txt"
assert(vim.fn.filereadable(saved_path) == 1, "language preference file was not created")
assert(vim.fn.readfile(saved_path)[1] == "zh", "language preference contains the wrong choice")
assert(#events == 3, "persisted effective change must emit one event")

vim.fn.writefile = function()
    error("injected persistence failure")
end
local failed, message = i18n.set_choice("en", { silent = true })
assert(not failed, "persistence failure must fail the language transaction")
assert(message:find("injected persistence failure", 1, true), "persistence failure reason is missing")
assert(i18n.get_locale() == "zh", "failed persistence changed live state")
assert(#events == 3, "failed persistence must not emit a locale event")

local report = i18n.get_validation_report()
assert(report.ok, "English and Chinese i18n catalogs must have exact runtime parity")

for _, key in ipairs({
    "locale.current",
    "commands.start",
    "commands.clipboard",
    "commands.sync",
    "help.open_failed",
    "keymaps.preview_hunk",
    "notifications.fold_toggled",
}) do
    assert(i18n.t(key, nil, "en") ~= key, "retained English translation is missing: " .. key)
    assert(i18n.t(key, nil, "zh") ~= key, "retained Chinese translation is missing: " .. key)
end

for _, key in ipairs({
    "locale.restart",
    "help.start_header",
    "help.clipboard_header",
    "help.sync_header",
    "keymaps.stage_hunk",
    "keymaps.reset_hunk",
    "keymaps.stage_buffer",
    "keymaps.reset_buffer",
    "keymaps.undo_stage_hunk",
}) do
    assert(i18n.t(key, nil, "en") == key, "retired English translation returned: " .. key)
    assert(i18n.t(key, nil, "zh") == key, "retired Chinese translation returned: " .. key)
end

vim.api.nvim_del_augroup_by_id(group)
vim.fn.writefile = original_writefile
vim.fn.stdpath = original_stdpath
vim.env.CLARITY_LOCALE = original_locale
vim.env.LANG = original_lang
vim.g.clarity_locale = original_global
vim.fn.delete(temp, "rf")

print("i18n locale-change tests: OK")
