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

local original_get_report = audit.get_report
audit.get_report = function()
    error("injected passive audit failure")
end
local failure_before = snapshot()
local ok = pcall(validation.get_report)
audit.get_report = original_get_report
assert(not ok, "injected audit failure must propagate")
assert(vim.deep_equal(snapshot(), failure_before), "failed collection changed the live session")

assert(first_validation.delegated_checks.lsp_gd == "CLARITY_RUNTIME_KEYMAP_CONTRACT")
assert(first_validation.delegated_checks.neo_tree_numbers_hidden == "CLARITY_RUNTIME_EXPLORER_CONTRACT")
print("passive validation tests: OK")
