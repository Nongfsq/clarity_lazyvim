local M = {}

M.minimum_nvim = { major = 0, minor = 12, patch = 0 }

M.tool_specs = {
    {
        id = "git",
        profile = "core",
        required = true,
        commands = { "git" },
        feature = "bootstrap lazy.nvim and clone locked plugins",
        impact = "Clarity cannot install or restore its plugin set.",
        repair = "Install Git 2.19+ and ensure `git` is on PATH.",
    },
    {
        id = "ripgrep",
        profile = "core",
        required = true,
        commands = { "rg" },
        feature = "primary project text search",
        impact = "The promoted project text-search workflow is unavailable.",
        repair = "Install ripgrep and ensure `rg` is on PATH.",
    },
    {
        id = "compiler",
        profile = "development",
        required = true,
        commands = { "cl", "gcc", "clang", "cc", "zig" },
        feature = "build Tree-sitter parsers and native extensions",
        impact = "Language parsers or native plugin extensions may not install.",
        repair = "Install a supported C compiler or Zig and ensure it is on PATH.",
    },
    {
        id = "tree_sitter_cli",
        profile = "development",
        required = true,
        commands = { "tree-sitter" },
        feature = "install and diagnose current Tree-sitter parsers",
        impact = "Parser installation and parser diagnostics may fail.",
        repair = "Install tree-sitter-cli and ensure `tree-sitter` is on PATH.",
    },
    {
        id = "fd",
        profile = "utilities",
        required = false,
        commands = { "fd", "fdfind" },
        feature = "accelerated file discovery",
        impact = "File discovery may use a slower fallback.",
        repair = "Install fd when faster file discovery is desired.",
    },
    {
        id = "node",
        profile = "copilot",
        required = true,
        commands = { "node" },
        feature = "optional Copilot runtime",
        minimum_major = 22,
        impact = "The optional Copilot profile is unavailable.",
        repair = "Install Node.js 22+ or disable the Copilot profile.",
    },
    {
        id = "npm",
        profile = "providers",
        required = false,
        commands = { "npm" },
        feature = "optional Node provider package management",
        impact = "Node provider packages cannot be installed from npm.",
        repair = "Install npm only when the Node provider is needed.",
    },
    {
        id = "python",
        profile = "providers",
        required = false,
        commands = { "python3", "python" },
        feature = "optional Python provider and Python tools",
        impact = "Python-backed Neovim integrations are unavailable.",
        repair = "Install Python only when Python-backed integrations are needed.",
    },
    {
        id = "pip",
        profile = "providers",
        required = false,
        commands = { "pip3", "pip" },
        feature = "optional Python provider package management",
        impact = "Python provider packages cannot be installed with pip.",
        repair = "Install pip only when Python provider packages are needed.",
    },
    {
        id = "system_monitor",
        profile = "utilities",
        required = false,
        commands = { "htop", "btop" },
        feature = "optional system monitor terminal",
        impact = "The optional system-monitor shortcut shows install guidance.",
        repair = "Install htop or btop only when this optional utility is desired.",
    },
}

local function compare_version(left, right)
    for _, key in ipairs({ "major", "minor", "patch" }) do
        local left_value = tonumber(left[key]) or 0
        local right_value = tonumber(right[key]) or 0
        if left_value ~= right_value then
            return left_value > right_value and 1 or -1
        end
    end
    return 0
end

function M.nvim_supported(version)
    return compare_version(version or {}, M.minimum_nvim) >= 0
end

function M.check(spec)
    return {
        id = assert(spec.id),
        profile = spec.profile or "core",
        required = spec.required == true,
        status = assert(spec.status),
        detail = spec.detail or "",
        impact = spec.impact or "",
        repair = spec.repair or "",
        recheck = spec.recheck or ":ClarityAudit",
    }
end

local function summarize_group(checks, profile)
    local summary = { status = "ready", passed = 0, failed = 0, warnings = 0, total = 0 }
    for _, check in ipairs(checks) do
        if check.profile == profile then
            summary.total = summary.total + 1
            if check.status == "pass" then
                summary.passed = summary.passed + 1
            elseif check.status == "fail" then
                summary.failed = summary.failed + 1
            else
                summary.warnings = summary.warnings + 1
            end
        end
    end

    if summary.failed > 0 then
        summary.status = "blocked"
    elseif summary.warnings > 0 then
        summary.status = "degraded"
    elseif summary.total == 0 then
        summary.status = "not-configured"
    end
    return summary
end

function M.summarize(checks)
    local profiles = {}
    for _, profile in ipairs({ "development", "copilot", "providers", "clipboard", "utilities" }) do
        profiles[profile] = summarize_group(checks, profile)
    end

    local core = summarize_group(checks, "core")
    return {
        core = core,
        host = {
            status = core.status,
            explanation = core.status == "ready" and "The host satisfies the Clarity core profile."
                or "One or more Clarity core capabilities are blocked.",
        },
        profiles = profiles,
        release = {
            status = "unverified",
            explanation = "Release quality is proven by commit-bound CI artifacts, not by a local audit.",
        },
    }
end

return M
