local audit = require("config.audit")
local i18n = require("config.i18n")

local M = {}

local function add_result(results, group, id, ok, detail, required)
    table.insert(results, {
        group = group,
        id = id,
        ok = ok,
        detail = detail,
        required = required ~= false,
        status = ok and "pass" or (required == false and "warn" or "fail"),
    })
end

local function command_exists(name)
    return vim.fn.exists(":" .. name) == 2
end

function M.get_report()
    local results = {}

    add_result(results, "commands", "clarity_health_command", command_exists("ClarityHealth"), ":ClarityHealth")
    add_result(results, "commands", "clarity_language_command", command_exists("ClarityLanguage"), ":ClarityLanguage")

    local audit_report = audit.get_report()
    local integrations = audit_report.integrations or {}
    local clipboard_ready = integrations.clipboard and integrations.clipboard.present or false
    local picker_ready = integrations.picker and integrations.picker.backend == "snacks"

    add_result(
        results,
        "integrations",
        "clipboard_provider_ready",
        clipboard_ready,
        "optional clipboard provider available",
        false
    )
    add_result(
        results,
        "integrations",
        "picker_backend_snacks",
        picker_ready,
        "search backend should resolve to Snacks"
    )
    local i18n_report = i18n.get_validation_report()
    add_result(
        results,
        "i18n",
        "translation_key_parity",
        i18n_report.ok,
        string.format("missing_in_en=%d missing_in_zh=%d", #i18n_report.missing_in_en, #i18n_report.missing_in_zh)
    )
    add_result(results, "i18n", "locale_en_available", vim.tbl_contains(i18n_report.locales, "en"), "en locale present")
    add_result(results, "i18n", "locale_zh_available", vim.tbl_contains(i18n_report.locales, "zh"), "zh locale present")

    local total = #results
    local passed = 0
    local failed = 0
    local warnings = 0
    for _, item in ipairs(results) do
        if item.ok then
            passed = passed + 1
        elseif item.required then
            failed = failed + 1
        else
            warnings = warnings + 1
        end
    end

    return {
        generated_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        platform = vim.loop.os_uname(),
        ok = failed == 0,
        summary = {
            passed = passed,
            failed = failed,
            warnings = warnings,
            total = total,
        },
        checks = results,
        delegated_checks = {
            picker = "CLARITY_RUNTIME_PICKER_CONTRACT",
            explorer = "CLARITY_RUNTIME_EXPLORER_CONTRACT",
            ui = "CLARITY_RUNTIME_UI_CONTRACT",
            help = "CLARITY_RUNTIME_HELP_CONTRACT",
            gitsigns = "CLARITY_RUNTIME_GITSIGNS_CONTRACT",
            terminal = "CLARITY_RUNTIME_TERMINAL_CONTRACT",
            keymap = "CLARITY_RUNTIME_KEYMAP_CONTRACT",
            fold = "CLARITY_RUNTIME_FOLD_CONTRACT",
            wrap = "CLARITY_RUNTIME_WRAP_CONTRACT",
            i18n = "CLARITY_RUNTIME_I18N_CONTRACT",
            lsp = "CLARITY_RUNTIME_LSP_CONTRACT",
        },
        audit = {
            core_status = audit_report.summary and audit_report.summary.core and audit_report.summary.core.status
                or nil,
            host_status = audit_report.summary and audit_report.summary.host and audit_report.summary.host.status
                or nil,
            release_status = audit_report.summary
                    and audit_report.summary.release
                    and audit_report.summary.release.status
                or nil,
        },
    }
end

function M.render_report(report)
    local lines = {
        "Clarity Validate",
        string.format("Checks passed: %d/%d", report.summary.passed, report.summary.total),
        string.format("Checks failed: %d", report.summary.failed),
        string.format("Optional warnings: %d", report.summary.warnings or 0),
    }

    if report.audit.core_status then
        table.insert(lines, string.format("Audit core readiness: %s", report.audit.core_status))
    end

    if report.audit.release_status then
        table.insert(lines, string.format("Audit release quality: %s", report.audit.release_status))
    end

    for _, item in ipairs(report.checks) do
        local marker = item.ok and "OK" or (item.required and "FAIL" or "WARN")
        table.insert(lines, string.format("- [%s] %s (%s): %s", marker, item.id, item.group, item.detail))
    end

    return lines
end

function M.setup()
    if vim.fn.exists(":ClarityValidate") == 2 then
        return
    end

    vim.api.nvim_create_user_command("ClarityValidate", function(info)
        if info.bang then
            local report = M.get_report()
            print(vim.json.encode(report))
            return
        end

        require("config.health").open("recovery")
    end, {
        bang = true,
        desc = i18n.t("commands.validate"),
    })
end

return M
