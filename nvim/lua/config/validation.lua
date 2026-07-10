local audit = require("config.audit")
local i18n = require("config.i18n")

local M = {}

local function add_result(results, group, id, ok, detail)
    table.insert(results, {
        group = group,
        id = id,
        ok = ok,
        detail = detail,
    })
end

local function command_exists(name)
    return vim.fn.exists(":" .. name) == 2
end

function M.get_report()
    local results = {}

    add_result(results, "commands", "clarity_audit_command", command_exists("ClarityAudit"), ":ClarityAudit")
    add_result(results, "commands", "clarity_start_command", command_exists("ClarityStart"), ":ClarityStart")
    add_result(
        results,
        "commands",
        "clarity_clipboard_command",
        command_exists("ClarityClipboard"),
        ":ClarityClipboard"
    )
    add_result(results, "commands", "clarity_sync_command", command_exists("ClaritySync"), ":ClaritySync")
    add_result(results, "commands", "clarity_validate_command", command_exists("ClarityValidate"), ":ClarityValidate")
    add_result(results, "commands", "clarity_language_command", command_exists("ClarityLanguage"), ":ClarityLanguage")

    local audit_report = audit.get_report()
    local integrations = audit_report.integrations or {}
    local clipboard_ready = integrations.clipboard and integrations.clipboard.present or false
    local picker_ready = integrations.picker and integrations.picker.backend == "snacks"

    add_result(results, "integrations", "clipboard_provider_ready", clipboard_ready, "clipboard provider available")
    add_result(
        results,
        "integrations",
        "picker_backend_snacks",
        picker_ready,
        "search backend should resolve to Snacks"
    )
    if integrations.copilot and integrations.copilot.enabled then
        add_result(
            results,
            "integrations",
            "copilot_node_ready",
            integrations.copilot.satisfied,
            "Enabled Copilot profile requires Node >=22"
        )
    end

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
    for _, item in ipairs(results) do
        if item.ok then
            passed = passed + 1
        end
    end

    return {
        generated_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        platform = vim.loop.os_uname(),
        ok = passed == total,
        summary = {
            passed = passed,
            failed = total - passed,
            total = total,
        },
        checks = results,
        delegated_checks = {
            leader_ff = "CLARITY_RUNTIME_PICKER_CONTRACT",
            leader_fw = "CLARITY_RUNTIME_KEYMAP_CONTRACT",
            leader_cz = "CLARITY_RUNTIME_KEYMAP_CONTRACT",
            leader_uw = "CLARITY_RUNTIME_KEYMAP_CONTRACT",
            leader_tf = "CLARITY_RUNTIME_TERMINAL_CONTRACT",
            leader_hh = "CLARITY_RUNTIME_HELP_CONTRACT",
            lsp_gd = "CLARITY_RUNTIME_KEYMAP_CONTRACT",
            leader_hs = "CLARITY_RUNTIME_GITSIGNS_CONTRACT",
            leader_ghs = "CLARITY_RUNTIME_GITSIGNS_CONTRACT",
            dashboard_numbers_hidden = "CLARITY_RUNTIME_UI_CONTRACT",
            neo_tree_numbers_hidden = "CLARITY_RUNTIME_EXPLORER_CONTRACT",
            toggleterm_defaults = "CLARITY_RUNTIME_TERMINAL_CONTRACT",
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
    }

    if report.audit.core_status then
        table.insert(lines, string.format("Audit core readiness: %s", report.audit.core_status))
    end

    if report.audit.release_status then
        table.insert(lines, string.format("Audit release quality: %s", report.audit.release_status))
    end

    for _, item in ipairs(report.checks) do
        local marker = item.ok and "OK" or "FAIL"
        table.insert(lines, string.format("- [%s] %s (%s): %s", marker, item.id, item.group, item.detail))
    end

    return lines
end

function M.setup()
    if vim.fn.exists(":ClarityValidate") == 2 then
        return
    end

    vim.api.nvim_create_user_command("ClarityValidate", function(info)
        local report = M.get_report()

        if info.bang then
            print(vim.json.encode(report))
            return
        end

        for _, line in ipairs(M.render_report(report)) do
            print(line)
        end
    end, {
        bang = true,
        desc = i18n.t("commands.validate"),
    })
end

return M
