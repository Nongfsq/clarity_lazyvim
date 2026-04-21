local M = {}
local i18n = require("config.i18n")

local tool_specs = {
    { id = "git", required = true, commands = { "git" }, feature = "bootstrap lazy.nvim and clone plugins" },
    {
        id = "compiler",
        required = true,
        commands = { "cl", "gcc", "clang", "cc", "zig" },
        feature = "build Treesitter parsers",
    },
    { id = "ripgrep", required = false, commands = { "rg" }, feature = "fast text search" },
    { id = "fd", required = false, commands = { "fd", "fdfind" }, feature = "fast file search" },
    {
        id = "node",
        required = false,
        commands = { "node" },
        feature = "Node provider and Copilot runtime",
        minimum_major = 22,
    },
    { id = "npm", required = false, commands = { "npm" }, feature = "install provider packages manually" },
    {
        id = "python",
        required = false,
        commands = { "python3", "python" },
        feature = "Python provider and Python-based tools",
    },
    {
        id = "pip",
        required = false,
        commands = { "pip3", "pip" },
        feature = "install Python provider packages manually",
    },
    { id = "system_monitor", required = false, commands = { "htop", "btop" }, feature = "system monitor terminal" },
}

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

local function find_global_npm_package(package_name)
    if vim.fn.executable("npm") ~= 1 then
        return false, nil
    end

    local output = vim.fn.system({ "npm", "list", "-g", package_name, "--depth=0", "--json" })
    local ok, data = pcall(vim.json.decode, output)

    if not ok or type(data) ~= "table" then
        return false, nil
    end

    local dependency = data.dependencies and data.dependencies[package_name]
    if dependency and dependency.version then
        return true, dependency.version
    end

    return false, nil
end

local function get_clipboard_status()
    local ok, provider = pcall(function()
        return vim.fn["provider#clipboard#Executable"]()
    end)
    local clipboard = vim.opt.clipboard:get()
    local unnamedplus = option_contains(clipboard, "unnamedplus")

    if not ok or not provider or provider == "" then
        return {
            present = false,
            provider = nil,
            unnamedplus = unnamedplus,
        }
    end

    return {
        present = true,
        provider = provider,
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
    pcall(vim.cmd, "doautocmd User VeryLazy")
    vim.wait(100)

    local repo_root = get_repo_root()
    local nvim_dir = get_nvim_dir()
    local root_lock = repo_root .. "/lazy-lock.json"
    local nested_lock = nvim_dir .. "/lazy-lock.json"

    local report = {
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
            nvim_dir_present = directory_exists(nvim_dir),
        },
        plugins = M.get_plugin_report(),
        tools = {},
    }

    local required_total = 0
    local required_ok = 0
    local optional_total = 0
    local optional_ok = 0
    local node_entry

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
            commands = spec.commands,
            feature = spec.feature,
            present = present,
            detected = detected,
            version = version,
            minimum_major = spec.minimum_major,
        }

        table.insert(report.tools, entry)

        if spec.id == "node" then
            node_entry = entry
        end

        if spec.required then
            required_total = required_total + 1
            if present then
                required_ok = required_ok + 1
            end
        else
            optional_total = optional_total + 1
            if present then
                optional_ok = optional_ok + 1
            end
        end
    end

    local clipboard = get_clipboard_status()
    local python_provider_present, python_interpreter = find_python_module("pynvim")
    local node_provider_present, node_provider_version = find_global_npm_package("neovim")
    local picker = get_picker_status(report.plugins)

    report.integrations = {
        clipboard = clipboard,
        python_provider = {
            present = python_provider_present,
            interpreter = python_interpreter,
            module = "pynvim",
        },
        node_provider = {
            present = node_provider_present,
            manager = "npm",
            package = "neovim",
            version = node_provider_version,
        },
        picker = picker,
        copilot = {
            present = node_entry and node_entry.present or false,
            satisfied = node_entry and node_entry.present or false,
            detected = node_entry and node_entry.detected or nil,
            version = node_entry and node_entry.version or nil,
            minimum_major = 22,
        },
    }

    local integration_total = 6
    local integration_ok = 0

    if report.integrations.clipboard.present then
        integration_ok = integration_ok + 1
    end
    if report.integrations.clipboard.unnamedplus then
        integration_ok = integration_ok + 1
    end
    if report.integrations.python_provider.present then
        integration_ok = integration_ok + 1
    end
    if report.integrations.node_provider.present then
        integration_ok = integration_ok + 1
    end
    if report.integrations.picker.backend == "snacks" then
        integration_ok = integration_ok + 1
    end
    if report.integrations.copilot.satisfied then
        integration_ok = integration_ok + 1
    end

    local layout_score = 100
    if not report.layout.root_init then
        layout_score = layout_score - 40
    end
    if not report.layout.nested_init then
        layout_score = layout_score - 20
    end
    if report.layout.duplicate_lockfiles then
        layout_score = layout_score - 25
    end
    if not report.layout.nvim_dir_present then
        layout_score = layout_score - 15
    end
    layout_score = math.max(layout_score, 0)

    report.summary = {
        required = { ok = required_ok, total = required_total },
        optional = { ok = optional_ok, total = optional_total },
        integrations = { ok = integration_ok, total = integration_total },
        scores = {
            required = score(required_ok, required_total),
            optional = score(optional_ok, optional_total),
            layout = layout_score,
            integrations = score(integration_ok, integration_total),
        },
    }

    report.summary.scores.overall = round(
        (report.summary.scores.required * 0.5)
            + (report.summary.scores.optional * 0.2)
            + (report.summary.scores.layout * 0.3)
    )

    return report
end

function M.render_report(report)
    local lines = {
        "Clarity Audit",
        string.format("Overall readiness: %d/100", report.summary.scores.overall),
        string.format("Required tools: %d/%d", report.summary.required.ok, report.summary.required.total),
        string.format("Optional tools: %d/%d", report.summary.optional.ok, report.summary.optional.total),
        string.format("Layout hygiene: %d/100", report.summary.scores.layout),
        string.format(
            "Integration readiness: %d/100 (%d/%d)",
            report.summary.scores.integrations,
            report.summary.integrations.ok,
            report.summary.integrations.total
        ),
        string.format("Repository root: %s", report.paths.repo_root),
        string.format("Nested nvim dir: %s", report.paths.nvim_dir),
    }

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

    local node_provider_status = report.integrations.node_provider.present
            and string.format(
                "OK -> npm %s (%s)",
                report.integrations.node_provider.package,
                report.integrations.node_provider.version
            )
        or "MISSING"
    table.insert(lines, string.format("Node provider package (neovim): %s", node_provider_status))

    table.insert(
        lines,
        string.format("Search backend: %s (%s)", report.integrations.picker.backend, report.integrations.picker.reason)
    )

    local copilot_status = report.integrations.copilot.satisfied and "OK" or "MISSING"
    local copilot_version = report.integrations.copilot.version and (" (" .. report.integrations.copilot.version .. ")")
        or ""
    table.insert(
        lines,
        string.format(
            "Copilot node runtime: %s -> %s%s; requires >=%d",
            copilot_status,
            report.integrations.copilot.detected or "node",
            copilot_version,
            report.integrations.copilot.minimum_major
        )
    )

    for _, tool in ipairs(report.tools) do
        local marker = tool.present and "OK" or "MISSING"
        local kind = tool.required and "required" or "optional"
        local detected = tool.present and string.format(" -> %s", tool.detected) or ""
        local version = tool.version and string.format(" (%s)", tool.version) or ""
        local minimum = tool.minimum_major and string.format("; requires >=%d", tool.minimum_major) or ""
        table.insert(
            lines,
            string.format("- [%s] %s (%s): %s%s%s%s", marker, tool.id, kind, tool.feature, detected, version, minimum)
        )
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
