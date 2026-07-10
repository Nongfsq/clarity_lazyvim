local M = {}
local i18n = require("config.i18n")
local capabilities = require("config.capabilities")
local tool_specs = capabilities.tool_specs

local function source_path()
    return debug.getinfo(1, "S").source:sub(2)
end

local function get_repo_root()
    if type(vim.g.clarity_repo_root) == "string" and vim.fn.isdirectory(vim.g.clarity_repo_root) == 1 then
        return vim.g.clarity_repo_root
    end

    local file = source_path()
    return vim.fn.fnamemodify(file, ":p:h:h:h:h"):gsub("\\", "/")
end

local function get_nvim_dir()
    if type(vim.g.clarity_nvim_dir) == "string" and vim.fn.isdirectory(vim.g.clarity_nvim_dir) == 1 then
        return vim.g.clarity_nvim_dir
    end

    return get_repo_root() .. "/nvim"
end

local function round(value)
    return math.floor(value + 0.5)
end

local function score(ok_count, total_count)
    if total_count == 0 then
        return 100
    end

    return round((ok_count / total_count) * 100)
end

local function file_exists(path)
    return vim.fn.filereadable(path) == 1
end

local function directory_exists(path)
    return vim.fn.isdirectory(path) == 1
end

local function describe_commands(commands)
    return table.concat(commands, " / ")
end

local function parse_major(version)
    return tonumber(tostring(version):match("^v?(%d+)"))
end

local function sorted_keys(tbl)
    local keys = {}

    for key in pairs(tbl or {}) do
        table.insert(keys, key)
    end

    table.sort(keys)
    return keys
end

local function list_to_set(items)
    local set = {}

    for _, item in ipairs(items or {}) do
        set[item] = true
    end

    return set
end

local function option_contains(option_value, expected)
    if type(option_value) == "string" then
        if option_value == "" then
            return false
        end

        return option_value == expected
    end

    return vim.tbl_contains(option_value or {}, expected)
end

local function find_python_module(module_name)
    for _, command in ipairs({ "python3", "python" }) do
        if vim.fn.executable(command) == 1 then
            vim.fn.system({
                command,
                "-c",
                string.format(
                    "import importlib.util, sys; sys.exit(0 if importlib.util.find_spec(%q) else 1)",
                    module_name
                ),
            })

            if vim.v.shell_error == 0 then
                return true, command
            end
        end
    end

    return false, nil
end

function M.classify_clipboard(input)
    input = input or {}
    local provider = input.provider
    local provider_name = tostring(provider or ""):lower():gsub("%s+", "")
    local ssh = input.ssh == true
    local wsl = input.wsl == true

    if provider_name == "osc52" or (ssh and input.forced_osc52) then
        return "ssh_osc52", true, false
    end
    if wsl and provider and provider ~= "" then
        return "wsl", true, true
    end
    if provider and provider ~= "" then
        return "desktop", true, true
    end
    return "missing", false, false
end

function M.get_clipboard_status(session)
    local ok, provider = pcall(function()
        return vim.fn["provider#clipboard#Executable"]()
    end)
    local clipboard = vim.opt.clipboard:get()
    local unnamedplus = option_contains(clipboard, "unnamedplus")

    session = session or {}
    local ssh = session.ssh or (vim.env.SSH_CONNECTION or "") ~= "" or (vim.env.SSH_TTY or "") ~= ""
    local wsl = session.wsl or vim.fn.has("wsl") == 1
    local configured = vim.g.clipboard
    if configured == "osc52" then
        provider = "osc52"
        ok = true
    end
    local kind, supports_copy, supports_paste = M.classify_clipboard({
        provider = ok and provider or nil,
        ssh = ssh,
        wsl = wsl,
        forced_osc52 = configured == "osc52",
    })

    return {
        present = supports_copy,
        provider = ok and provider ~= "" and provider or nil,
        kind = kind,
        supports_copy = supports_copy,
        supports_paste = supports_paste,
        unnamedplus = unnamedplus,
    }
end

local function get_picker_status(plugin_report)
    local active = list_to_set(plugin_report.active)

    if active["snacks.nvim"] and not active["telescope.nvim"] then
        return {
            backend = "snacks",
            reason = "inferred from active plugin set",
        }
    end

    if active["telescope.nvim"] then
        return {
            backend = "telescope",
            reason = "inferred from active plugin set",
        }
    end

    return {
        backend = "unknown",
        reason = "no known picker plugin detected",
    }
end

local function get_treesitter_status()
    local parser_suffix = vim.fn.has("win32") == 1 and ".dll" or ".so"
    local data_path = vim.fn.stdpath("data")
    local user_parser = data_path .. "/site/parser/vim" .. parser_suffix
    local user_revision = data_path .. "/site/parser-info/vim.revision"
    local ok_inspect, inspect_info = pcall(vim.treesitter.language.inspect, "vim")
    local ok_query, query = pcall(vim.treesitter.query.get, "vim", "highlights")
    local query_ok = ok_query and query ~= nil
    local ok_parser, parser = pcall(vim.treesitter.get_string_parser, "set tab\n", "vim")
    local parse_ok = false
    local parse_error

    if ok_parser then
        local ok_parse, result = pcall(function()
            return parser:parse()
        end)
        parse_ok = ok_parse
        if not ok_parse then
            parse_error = tostring(result)
        end
    end

    local metadata = {}
    local abi_version
    if ok_inspect and type(inspect_info) == "table" then
        metadata = inspect_info.metadata or {}
        abi_version = inspect_info.abi_version
    end

    local user_parser_present = file_exists(user_parser)
    local health_ok = ok_inspect and query_ok and parse_ok
    local stale_user_override = user_parser_present and not health_ok

    return {
        health_ok = health_ok,
        inspect_ok = ok_inspect,
        query_ok = query_ok,
        parse_ok = parse_ok,
        -- Starting a highlighter requires a live buffer and belongs to the
        -- isolated runtime-contract suite, not passive session collection.
        highlighter_ok = nil,
        parser_metadata = metadata,
        abi_version = abi_version,
        user_parser = user_parser,
        user_parser_present = user_parser_present,
        user_revision = user_revision,
        user_revision_present = file_exists(user_revision),
        stale_user_override = stale_user_override,
        error = (not ok_inspect and tostring(inspect_info))
            or (not query_ok and tostring(query))
            or (not ok_parser and tostring(parser))
            or parse_error
            or nil,
        repair_command = "python3 scripts/clarity_doctor.py --apply",
    }
end

function M.has(commands)
    local candidates = type(commands) == "table" and commands or { commands }

    for _, command in ipairs(candidates) do
        if vim.fn.executable(command) == 1 then
            return true, command
        end
    end

    return false, candidates[1]
end

function M.get_command_version(command)
    if not command or command == "" or vim.fn.executable(command) ~= 1 then
        return nil
    end

    local output = vim.fn.system({ command, "--version" })
    if vim.v.shell_error ~= 0 then
        return nil
    end

    return vim.trim(output)
end

function M.get_plugin_report()
    local ok, config = pcall(require, "lazy.core.config")
    if not ok then
        return {
            available = false,
            active = {},
            disabled = {},
            active_count = 0,
            disabled_count = 0,
        }
    end

    local active = {}
    for name, plugin in pairs(config.plugins or {}) do
        if plugin and plugin.enabled ~= false then
            table.insert(active, name)
        end
    end
    table.sort(active)

    local disabled = sorted_keys(config.spec and config.spec.disabled or {})

    return {
        available = true,
        active = active,
        disabled = disabled,
        active_count = #active,
        disabled_count = #disabled,
    }
end

function M.notify_missing(commands, feature, hint)
    local candidates = type(commands) == "table" and commands or { commands }
    local message = i18n.t("notifications.feature_unavailable", {
        feature = feature,
        commands = describe_commands(candidates),
    })

    if hint and hint ~= "" then
        message = message .. " " .. hint
    end

    vim.notify(message, vim.log.levels.WARN)
end

function M.get_report()
    local repo_root = get_repo_root()
    local nvim_dir = get_nvim_dir()
    local root_lock = repo_root .. "/lazy-lock.json"
    local nested_lock = nvim_dir .. "/lazy-lock.json"
    local root_json = repo_root .. "/lazyvim.json"
    local nested_json = nvim_dir .. "/lazyvim.json"
    local checks = {}

    local function add_check(spec)
        table.insert(checks, capabilities.check(spec))
    end

    local report = {
        report_id = "CLARITY-AUDIT-001",
        generated_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        platform = vim.loop.os_uname(),
        nvim = vim.version(),
        paths = {
            repo_root = repo_root,
            nvim_dir = nvim_dir,
        },
        layout = {
            root_init = file_exists(repo_root .. "/init.lua"),
            nested_init = file_exists(nvim_dir .. "/init.lua"),
            root_lock = file_exists(root_lock),
            nested_lock = file_exists(nested_lock),
            duplicate_lockfiles = file_exists(root_lock) and file_exists(nested_lock),
            root_json = file_exists(root_json),
            nested_json = file_exists(nested_json),
            duplicate_json = file_exists(root_json) and file_exists(nested_json),
            nvim_dir_present = directory_exists(nvim_dir),
        },
        plugins = M.get_plugin_report(),
        tools = {},
        checks = checks,
    }

    local nvim_supported = capabilities.nvim_supported(report.nvim)
    add_check({
        id = "nvim_version",
        profile = "core",
        required = true,
        status = nvim_supported and "pass" or "fail",
        detail = string.format(
            "%d.%d.%d (requires >=%d.%d.%d)",
            report.nvim.major,
            report.nvim.minor,
            report.nvim.patch,
            capabilities.minimum_nvim.major,
            capabilities.minimum_nvim.minor,
            capabilities.minimum_nvim.patch
        ),
        impact = "Clarity and the locked LazyVim generation may fail at startup or behave incorrectly.",
        repair = "Install the supported Neovim release and rerun the audit.",
    })

    local layout_checks = {
        {
            id = "root_init",
            ok = report.layout.root_init,
            detail = repo_root .. "/init.lua",
            impact = "The public repository entrypoint is missing.",
        },
        {
            id = "nested_runtime",
            ok = report.layout.nested_init and report.layout.nvim_dir_present,
            detail = nvim_dir .. "/init.lua",
            impact = "The Clarity runtime cannot be loaded from the repository entrypoint.",
        },
        {
            id = "canonical_lockfile",
            ok = report.layout.root_lock and not report.layout.duplicate_lockfiles,
            detail = root_lock,
            impact = "Plugin versions are not controlled by one repository lockfile.",
        },
        {
            id = "canonical_lazyvim_json",
            ok = report.layout.root_json and not report.layout.duplicate_json,
            detail = root_json,
            impact = "LazyVim extras/state can drift between root and nested files.",
        },
    }
    for _, item in ipairs(layout_checks) do
        add_check({
            id = item.id,
            profile = "core",
            required = true,
            status = item.ok and "pass" or "fail",
            detail = item.detail,
            impact = item.impact,
            repair = "Restore the tracked repository layout and rerun :ClarityAudit.",
        })
    end

    local ok_lazy, lazy_config = pcall(require, "lazy.core.config")
    local actual_lock = ok_lazy and lazy_config.options and lazy_config.options.lockfile or nil
    local actual_json = LazyVim and LazyVim.config and LazyVim.config.json and LazyVim.config.json.path or nil
    local expected_lock = vim.fs.normalize(root_lock)
    local expected_json = vim.fs.normalize(root_json)
    local lock_matches = actual_lock and vim.fs.normalize(actual_lock) == expected_lock or false
    local json_matches = actual_json and vim.fs.normalize(actual_json) == expected_json or false
    report.paths.lockfile = actual_lock
    report.paths.lazyvim_json = actual_json

    add_check({
        id = "runtime_lockfile_authority",
        profile = "core",
        required = true,
        status = lock_matches and "pass" or "fail",
        detail = string.format("expected=%s actual=%s", expected_lock, actual_lock or "missing"),
        impact = "The running plugin set may not match the repository lockfile.",
        repair = "Use the repository bootstrap, which must pass the root lockfile explicitly to lazy.nvim.",
    })
    add_check({
        id = "runtime_lazyvim_json_authority",
        profile = "core",
        required = true,
        status = json_matches and "pass" or "fail",
        detail = string.format("expected=%s actual=%s", expected_json, actual_json or "missing"),
        impact = "The running LazyVim extras/state may differ from the committed repository contract.",
        repair = "Set vim.g.lazyvim_json to the repository root file before importing LazyVim.",
    })

    for _, spec in ipairs(tool_specs) do
        local present, detected = M.has(spec.commands)
        local version = present and M.get_command_version(detected) or nil
        local version_major = parse_major(version)

        if present and spec.minimum_major and (not version_major or version_major < spec.minimum_major) then
            present = false
        end

        local entry = {
            id = spec.id,
            required = spec.required,
            profile = spec.profile,
            commands = spec.commands,
            feature = spec.feature,
            present = present,
            detected = detected,
            version = version,
            minimum_major = spec.minimum_major,
        }

        table.insert(report.tools, entry)

        add_check({
            id = "tool_" .. spec.id,
            profile = spec.profile,
            required = spec.required,
            status = present and "pass" or (spec.required and "fail" or "warn"),
            detail = present and string.format("%s%s", detected, version and (" " .. version) or "") or "missing",
            impact = spec.impact,
            repair = spec.repair,
        })
    end

    local clipboard = M.get_clipboard_status()
    local python_provider_present, python_interpreter = find_python_module("pynvim")
    local picker = get_picker_status(report.plugins)
    local treesitter = get_treesitter_status()

    report.integrations = {
        clipboard = clipboard,
        python_provider = {
            present = python_provider_present,
            interpreter = python_interpreter,
            module = "pynvim",
        },
        picker = picker,
        treesitter = treesitter,
    }

    add_check({
        id = "picker_backend",
        profile = "core",
        required = true,
        status = picker.backend == "snacks" and "pass" or "fail",
        detail = picker.backend .. ": " .. picker.reason,
        impact = "The promoted file/text search workflows do not have their expected backend.",
        repair = "Restore the locked Snacks picker configuration and rerun the audit.",
    })
    add_check({
        id = "treesitter_vim_health",
        profile = "core",
        required = true,
        status = treesitter.health_ok and "pass" or "fail",
        detail = treesitter.health_ok and "parser/query ready; highlighter behavior delegated to runtime contracts"
            or (treesitter.error or "health check failed"),
        impact = "Core syntax parsing can fail or emit repeated runtime errors.",
        repair = treesitter.repair_command,
    })
    add_check({
        id = "clipboard_provider",
        profile = "clipboard",
        required = true,
        status = clipboard.present and "pass" or "fail",
        detail = clipboard.provider or "missing",
        impact = "System clipboard integration is unavailable in this host/session.",
        repair = "Run :ClarityClipboard for platform-specific setup guidance.",
    })
    add_check({
        id = "clipboard_unnamedplus",
        profile = "clipboard",
        required = true,
        status = clipboard.unnamedplus and "pass" or "fail",
        detail = clipboard.unnamedplus and "enabled" or "disabled",
        impact = "Clarity's documented clipboard mode is not active.",
        repair = "Restore the Clarity clipboard option and rerun the audit.",
    })
    add_check({
        id = "provider_python",
        profile = "providers",
        required = false,
        status = python_provider_present and "pass" or "warn",
        detail = python_provider_present and (python_interpreter or "python") or "pynvim missing",
        impact = "Optional Python-backed integrations are unavailable.",
        repair = "Install pynvim for the active Python interpreter when needed.",
    })
    report.summary = capabilities.summarize(checks)
    report.summary.required = {
        ok = report.summary.core.passed,
        total = report.summary.core.total,
    }
    report.summary.scores = {
        core = score(report.summary.core.passed, report.summary.core.total),
    }
    report.ok = report.summary.core.status == "ready"

    return report
end

function M.render_report(report)
    local lines = {
        "Clarity Audit",
        string.format(
            "Core readiness: %s (%d/%d checks)",
            report.summary.core.status,
            report.summary.core.passed,
            report.summary.core.total
        ),
        string.format("Host capability: %s", report.summary.host.status),
        string.format("Release quality: %s — %s", report.summary.release.status, report.summary.release.explanation),
        string.format("Repository root: %s", report.paths.repo_root),
        string.format("Plugin lockfile: %s", report.paths.lockfile or "missing"),
        string.format("LazyVim state: %s", report.paths.lazyvim_json or "missing"),
    }

    for _, profile in ipairs({ "providers", "clipboard", "utilities" }) do
        local item = report.summary.profiles[profile]
        table.insert(
            lines,
            string.format(
                "Profile %s: %s (%d passed, %d failed, %d warnings)",
                profile,
                item.status,
                item.passed,
                item.failed,
                item.warnings
            )
        )
    end

    if report.plugins and report.plugins.available then
        table.insert(lines, string.format("Active plugins: %d", report.plugins.active_count))
        table.insert(lines, string.format("Disabled by policy: %d", report.plugins.disabled_count))

        if report.plugins.disabled_count > 0 then
            table.insert(lines, string.format("Disabled plugin set: %s", table.concat(report.plugins.disabled, ", ")))
        end
    end

    if report.layout.duplicate_lockfiles then
        table.insert(lines, "Warning: duplicate lock files detected.")
    end

    local clipboard_provider = report.integrations.clipboard.provider or "missing"
    table.insert(
        lines,
        string.format(
            "Clipboard provider: %s (unnamedplus=%s)",
            clipboard_provider,
            report.integrations.clipboard.unnamedplus and "on" or "off"
        )
    )

    local python_status = report.integrations.python_provider.present
            and string.format("OK -> %s", report.integrations.python_provider.interpreter)
        or "MISSING"
    table.insert(lines, string.format("Python provider package (pynvim): %s", python_status))

    table.insert(
        lines,
        string.format("Search backend: %s (%s)", report.integrations.picker.backend, report.integrations.picker.reason)
    )

    local ts_status = report.integrations.treesitter.health_ok and "OK" or "CHECK"
    local ts_metadata = report.integrations.treesitter.parser_metadata or {}
    local ts_version = string.format(
        "%s.%s.%s",
        ts_metadata.major_version or 0,
        ts_metadata.minor_version or 0,
        ts_metadata.patch_version or 0
    )
    table.insert(
        lines,
        string.format(
            "Tree-sitter vim parser: %s (metadata=%s, user_override=%s)",
            ts_status,
            ts_version,
            report.integrations.treesitter.user_parser_present and "yes" or "no"
        )
    )
    if report.integrations.treesitter.stale_user_override then
        table.insert(
            lines,
            string.format(
                "Warning: user-level vim parser appears stale. Run `%s`.",
                report.integrations.treesitter.repair_command
            )
        )
    elseif report.integrations.treesitter.user_parser_present then
        table.insert(lines, "Note: a user-level vim parser is present and overrides the Neovim bundled parser.")
    end

    for _, tool in ipairs(report.tools) do
        local marker = tool.present and "OK" or "MISSING"
        local kind = string.format("%s/%s", tool.profile, tool.required and "required" or "optional")
        local detected = tool.present and string.format(" -> %s", tool.detected) or ""
        local version = tool.version and string.format(" (%s)", tool.version) or ""
        local minimum = tool.minimum_major and string.format("; requires >=%d", tool.minimum_major) or ""
        table.insert(
            lines,
            string.format("- [%s] %s (%s): %s%s%s%s", marker, tool.id, kind, tool.feature, detected, version, minimum)
        )
    end

    for _, check in ipairs(report.checks or {}) do
        if check.status ~= "pass" then
            table.insert(
                lines,
                string.format(
                    "- [%s] %s: %s | Impact: %s | Repair: %s | Recheck: %s",
                    check.status:upper(),
                    check.id,
                    check.detail,
                    check.impact,
                    check.repair,
                    check.recheck
                )
            )
        end
    end

    return lines
end

function M.setup()
    if vim.fn.exists(":ClarityAudit") == 2 then
        return
    end

    vim.api.nvim_create_user_command("ClarityAudit", function(info)
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
        desc = i18n.t("commands.audit"),
    })
end

return M
