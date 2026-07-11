local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
vim.opt.runtimepath:append(repo_root .. "/nvim")
vim.g.clarity_repo_root = repo_root
vim.g.clarity_nvim_dir = repo_root .. "/nvim"

local audit = require("config.audit")
local validation = require("config.validation")

vim.api.nvim_buf_set_lines(0, 0, -1, false, { "modified validation sentinel", "second line" })
vim.api.nvim_win_set_cursor(0, { 2, 3 })
vim.bo.modified = true
vim.wo.wrap = false
vim.wo.number = true

vim.lsp.config("clarity_missing_test", {
    cmd = { "clarity-definitely-missing-language-server" },
    filetypes = { "clarity-never-matches" },
})
vim.lsp.enable("clarity_missing_test")

-- Warm provider/module discovery before measuring repeatability. Collection may
-- load read-only providers, but subsequent reports must be session-idempotent.
audit.get_report()

local function map_fingerprint()
    local result = {}
    for _, mode in ipairs({ "n", "x", "v", "i", "t" }) do
        for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
            table.insert(
                result,
                table.concat({
                    mode,
                    map.lhs or "",
                    map.rhs or "",
                    map.desc or "",
                    tostring(map.callback),
                    tostring(map.expr),
                    tostring(map.nowait),
                    tostring(map.noremap),
                    tostring(map.silent),
                }, "\0")
            )
        end
    end
    table.sort(result)
    return result
end

local function snapshot()
    return {
        tabs = vim.api.nvim_list_tabpages(),
        wins = vim.api.nvim_list_wins(),
        bufs = vim.api.nvim_list_bufs(),
        current_tab = vim.api.nvim_get_current_tabpage(),
        current_win = vim.api.nvim_get_current_win(),
        current_buf = vim.api.nvim_get_current_buf(),
        cursor = vim.api.nvim_win_get_cursor(0),
        cwd = vim.fn.getcwd(),
        modified = vim.bo.modified,
        lines = vim.api.nvim_buf_get_lines(0, 0, -1, false),
        options = {
            wrap = vim.wo.wrap,
            number = vim.wo.number,
            relativenumber = vim.wo.relativenumber,
            clipboard = vim.o.clipboard,
        },
        maps = map_fingerprint(),
        autocmd_count = #vim.api.nvim_get_autocmds({}),
    }
end

local before = snapshot()
local first_audit = audit.get_report()
local first_validation = validation.get_report()
local second_audit = audit.get_report()
local second_validation = validation.get_report()
assert(first_audit.report_id == second_audit.report_id, "audit report contract changed")
assert(first_validation.summary.total == second_validation.summary.total, "validation report is not repeatable")
assert(vim.deep_equal(snapshot(), before), "passive report collection changed the live session")

local lsp = first_audit.integrations.lsp
assert(lsp.auto_install == false, "audit must never advertise automatic LSP installation")
assert(#lsp.servers == 1 and lsp.servers[1].name == "clarity_missing_test", "enabled LSP name missing")
assert(
    lsp.servers[1].executable == "clarity-definitely-missing-language-server" and not lsp.servers[1].present,
    "enabled LSP executable readiness drifted"
)
local lsp_finding
for _, check in ipairs(first_audit.checks) do
    if check.id == "lsp_server_clarity_missing_test" then
        lsp_finding = check
    end
end
assert(lsp_finding and lsp_finding.status == "warn", "missing enabled LSP must create an audit warning")
assert(lsp_finding.repair:find("never auto%-installs"), "missing enabled LSP repair must state the install policy")

local original_get_report = audit.get_report
audit.get_report = function()
    error("injected passive audit failure")
end
local failure_before = snapshot()
local ok = pcall(validation.get_report)
audit.get_report = original_get_report
assert(not ok, "injected audit failure must propagate")
assert(vim.deep_equal(snapshot(), failure_before), "failed collection changed the live session")

local expected_delegated = {
    explorer = "CLARITY_RUNTIME_EXPLORER_CONTRACT",
    fold = "CLARITY_RUNTIME_FOLD_CONTRACT",
    gitsigns = "CLARITY_RUNTIME_GITSIGNS_CONTRACT",
    help = "CLARITY_RUNTIME_HELP_CONTRACT",
    i18n = "CLARITY_RUNTIME_I18N_CONTRACT",
    keymap = "CLARITY_RUNTIME_KEYMAP_CONTRACT",
    lsp = "CLARITY_RUNTIME_LSP_CONTRACT",
    picker = "CLARITY_RUNTIME_PICKER_CONTRACT",
    terminal = "CLARITY_RUNTIME_TERMINAL_CONTRACT",
    ui = "CLARITY_RUNTIME_UI_CONTRACT",
    wrap = "CLARITY_RUNTIME_WRAP_CONTRACT",
}
assert(vim.deep_equal(first_validation.delegated_checks, expected_delegated), "validation delegation ledger drifted")
assert(first_validation.delegated_checks.leader_hs == nil, "stale leader_hs delegation returned")
assert(first_validation.delegated_checks.leader_ghs == nil, "stale leader_ghs delegation returned")

local command_ids = {}
local clipboard_check
for _, check in ipairs(first_validation.checks) do
    if check.group == "commands" then
        command_ids[#command_ids + 1] = check.id
    elseif check.id == "clipboard_provider_ready" then
        clipboard_check = check
    end
end
table.sort(command_ids)
assert(
    vim.deep_equal(command_ids, { "clarity_health_command", "clarity_language_command" }),
    "validation must promote only Health and Language"
)
assert(clipboard_check and clipboard_check.required == false, "clipboard readiness must be optional")
if not clipboard_check.ok then
    assert(clipboard_check.status == "warn", "missing optional clipboard must be a warning")
end

local opened = {}
package.loaded["config.health"] = {
    open = function(route)
        table.insert(opened, route)
    end,
}
audit.setup()
validation.setup()
vim.cmd("ClarityAudit")
vim.cmd("ClarityValidate")
assert(vim.deep_equal(opened, { "environment", "recovery" }), "legacy commands did not route through Health")

local audit_json = vim.api.nvim_exec2("ClarityAudit!", { output = true }).output
local validate_json = vim.api.nvim_exec2("ClarityValidate!", { output = true }).output
assert(vim.json.decode(audit_json).report_id == "CLARITY-AUDIT-001", "ClarityAudit! JSON contract drifted")
assert(vim.json.decode(validate_json).summary ~= nil, "ClarityValidate! JSON contract drifted")
print("passive validation tests: OK")
