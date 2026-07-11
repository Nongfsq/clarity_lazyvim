local M = {}

local surface_budgets = {
    global_normal_leader = 28,
    full_context_normal_leader = 35,
}

-- Reviewed exclusions are product decisions, not incidental lazy.nvim state.
-- Keep the rationale and the condition that would justify reconsidering each
-- dependency beside the plugin identity so the generated minimal spec and the
-- lock normalizer consume one authoritative registry.
local plugin_exclusions = {
    {
        plugin = "akinsho/bufferline.nvim",
        reason = "Clarity promotes native buffers and one picker instead of a persistent buffer tab bar.",
        revisit_trigger = "Validated user research shows the promoted buffer paths are insufficient.",
    },
    {
        plugin = "catppuccin/nvim",
        reason = "The accessibility-reviewed Clarity theme is the sole product theme.",
        revisit_trigger = "Clarity replaces its owned theme with a reviewed external theme contract.",
    },
    {
        plugin = "nvimdev/dashboard-nvim",
        reason = "Snacks owns the single curated dashboard surface.",
        revisit_trigger = "The Snacks dashboard is removed or cannot satisfy the six-action contract.",
    },
    {
        plugin = "folke/flash.nvim",
        reason = "Advanced jump overlays exceed the small, native-first motion surface.",
        revisit_trigger = "Behavior studies demonstrate a core navigation gap that native motions cannot cover.",
    },
    {
        plugin = "MagicDuck/grug-far.nvim",
        reason = "Repository-wide replacement is a mutation workflow delegated to agents.",
        revisit_trigger = "The product explicitly adopts human-owned repository mutation workflows.",
    },
    {
        plugin = "kdheepak/lazygit.nvim",
        reason = "Git mutation is delegated to agents; Clarity exposes observation only.",
        revisit_trigger = "The approved product boundary expands to interactive Git mutation.",
    },
    {
        plugin = "nvim-mini/mini.ai",
        reason = "Specialist text objects are outside the promoted editing surface.",
        revisit_trigger = "Editing research identifies a frequent job that native text objects cannot serve.",
    },
    {
        plugin = "mfussenegger/nvim-lint",
        reason = "A second diagnostics pipeline would duplicate the host-provided LSP model.",
        revisit_trigger = "LSP-independent linting becomes a documented core capability.",
    },
    {
        plugin = "windwp/nvim-ts-autotag",
        reason = "Automatic paired-tag mutation is not part of the general editing baseline.",
        revisit_trigger = "Web template authoring becomes a tested core workflow.",
    },
    {
        plugin = "folke/persistence.nvim",
        reason = "Automatic session restoration adds hidden state to a predictable startup model.",
        revisit_trigger = "Durable multi-session recovery becomes an approved product requirement.",
    },
    {
        plugin = "folke/todo-comments.nvim",
        reason = "Specialized annotation navigation is outside the core observation surface.",
        revisit_trigger = "TODO annotation review becomes a measured, frequent core job.",
    },
    {
        plugin = "folke/tokyonight.nvim",
        reason = "The accessibility-reviewed Clarity theme is the sole product theme.",
        revisit_trigger = "Clarity replaces its owned theme with a reviewed external theme contract.",
    },
    {
        plugin = "folke/trouble.nvim",
        reason = "Native lists and the curated picker own the single promoted results model.",
        revisit_trigger = "Behavior evidence shows those result surfaces cannot support a core diagnostic job.",
    },
    {
        plugin = "rktjmp/lush.nvim",
        reason = "The static Clarity theme no longer needs a runtime theme-generation dependency.",
        revisit_trigger = "Theme generation becomes dynamic and cannot be expressed with native highlights.",
    },
    {
        plugin = "mason-org/mason.nvim",
        reason = "Language toolchains are owned by the host environment and coding agents.",
        revisit_trigger = "Clarity adopts an approved, user-visible managed-toolchain product policy.",
    },
    {
        plugin = "mason-org/mason-lspconfig.nvim",
        reason = "LSP servers attach directly from the host PATH without an installer bridge.",
        revisit_trigger = "Clarity adopts an approved, user-visible managed-toolchain product policy.",
    },
    {
        plugin = "rafamadriz/friendly-snippets",
        reason = "Native and project-owned snippets avoid a large global snippet corpus.",
        revisit_trigger = "A curated snippet set becomes a tested core editing requirement.",
    },
    {
        plugin = "folke/lazydev.nvim",
        reason = "Neovim configuration development is a maintainer workflow, not a product dependency.",
        revisit_trigger = "Clarity introduces an explicit, isolated maintainer development profile.",
    },
}

local removals = {}

local function add(origin, lhs, modes, decision, reason, replacement)
    removals[#removals + 1] = {
        lhs = lhs,
        modes = type(modes) == "table" and modes or { modes or "n" },
        decision = decision,
        origin = origin,
        reason = reason,
        replacement = replacement,
    }
end

local direct = { kind = "direct", owner = "lazyvim.config.keymaps" }
local snacks = { kind = "lazy_spec", owner = "folke/snacks.nvim" }
local neotree = { kind = "lazy_spec", owner = "nvim-neo-tree/neo-tree.nvim" }
local conform = { kind = "lazy_spec", owner = "stevearc/conform.nvim" }
local mason = { kind = "lazy_spec", owner = "mason-org/mason.nvim" }
local noice = { kind = "lazy_spec", owner = "folke/noice.nvim" }
local lsp = { kind = "lsp", owner = "neovim/nvim-lspconfig" }
local gitsigns_attach = { kind = "buffer_attach", owner = "gitsigns.nvim" }

-- Direct LazyVim defaults are loaded immediately before config.keymaps. These
-- exact entries can therefore be removed there without taking plugin lifecycle
-- ownership or sweeping user-defined mappings.
for _, item in ipairs({
    { "<leader>`", "n", "merge", "duplicate buffer path", "buffer.find" },
    { "<leader>bD", "n", "merge", "duplicate buffer/window path", "buffer.delete" },
    { "<leader>bb", "n", "merge", "duplicate buffer path", "buffer.find" },
    { "<leader>bi", "n", "remove", "bulk buffer maintenance" },
    { "<leader>bo", "n", "remove", "bulk buffer maintenance" },
    { "<leader>K", "n", "remove", "native K owns keyword and hover help" },
    { "<leader>L", "n", "remove", "maintainer changelog surface" },
    { "<leader>cd", "n", "remove", "native diagnostics navigation and float" },
    { "<leader>dph", "n", "remove", "maintainer profiler surface" },
    { "<leader>dpp", "n", "remove", "maintainer profiler surface" },
    { "<leader>fT", "n", "merge", "duplicate terminal path", "terminal.float" },
    { "<leader>ft", "n", "merge", "duplicate terminal path", "terminal.float" },
    { "<leader>gB", { "n", "x" }, "remove", "remote browse workflow" },
    { "<leader>gG", "n", "remove", "mutation-heavy Git client" },
    { "<leader>gL", "n", "merge", "duplicate Git history path", "git.log" },
    { "<leader>gY", { "n", "x" }, "remove", "remote browse workflow" },
    { "<leader>gb", "n", "replace", "current picker confirm can checkout historical content", "git.blame_line" },
    { "<leader>gf", "n", "merge", "duplicate Git history path", "git.log" },
    { "<leader>gg", "n", "remove", "mutation-heavy Git client" },
    { "<leader>gl", "n", "replace", "current picker confirm can checkout historical content", "git.log" },
    { "<leader>l", "n", "remove", "dependency maintenance belongs to agents" },
    { "<leader>uA", "n", "remove", "presentation tuning" },
    { "<leader>uD", "n", "remove", "presentation tuning" },
    { "<leader>uF", "n", "relocate", "buffer recovery must not be global", "format.auto_buffer_toggle" },
    { "<leader>uI", "n", "remove", "maintainer syntax inspection" },
    { "<leader>uL", "n", "remove", "absolute line numbers are product policy" },
    { "<leader>uS", "n", "remove", "presentation tuning" },
    { "<leader>uT", "n", "remove", "Tree-sitter recovery belongs in Health" },
    { "<leader>uZ", "n", "merge", "duplicate zoom path", "window.zoom_toggle" },
    { "<leader>ua", "n", "remove", "presentation tuning" },
    { "<leader>ub", "n", "remove", "theme is product policy" },
    { "<leader>uc", "n", "remove", "specialist presentation tuning" },
    { "<leader>ud", "n", "remove", "diagnostics are a trustworthy default" },
    { "<leader>uf", "n", "remove", "global formatting policy is out of scope" },
    { "<leader>ug", "n", "remove", "presentation policy" },
    { "<leader>uh", "n", "relocate", "inlay hints require an attached capability", "lsp.inlay_hints_toggle" },
    { "<leader>ui", "n", "remove", "maintainer syntax inspection" },
    { "<leader>ul", "n", "remove", "absolute line numbers are product policy" },
    { "<leader>ur", "n", "remove", "native redraw and escape paths" },
    { "<leader>us", "n", "remove", "specialist spelling toggle" },
    { "<leader>uz", "n", "remove", "presentation mode" },
    { "<leader>xl", "n", "remove", "one promoted result-list model" },
    { "<leader><Tab><Tab>", "n", "remove", "promoted tab workflow is out of scope" },
    { "<leader><Tab>[", "n", "remove", "promoted tab workflow is out of scope" },
    { "<leader><Tab>]", "n", "remove", "promoted tab workflow is out of scope" },
    { "<leader><Tab>d", "n", "remove", "promoted tab workflow is out of scope" },
    { "<leader><Tab>f", "n", "remove", "promoted tab workflow is out of scope" },
    { "<leader><Tab>l", "n", "remove", "promoted tab workflow is out of scope" },
    { "<leader><Tab>o", "n", "remove", "promoted tab workflow is out of scope" },
    { "<C-Up>", "n", "remove", "terminal portability is poor" },
    { "<C-Down>", "n", "remove", "terminal portability is poor" },
    { "<C-Left>", "n", "remove", "terminal portability is poor" },
    { "<C-Right>", "n", "remove", "terminal portability is poor" },
    { "<A-j>", { "n", "i", "v" }, "remove", "terminal Alt portability is poor" },
    { "<A-k>", { "n", "i", "v" }, "remove", "terminal Alt portability is poor" },
    { "<S-h>", "n", "remove", "restore native screen-top motion" },
    { "<S-l>", "n", "remove", "restore native screen-bottom motion" },
    { "[e", "n", "remove", "duplicate severity-specific diagnostics" },
    { "]e", "n", "remove", "duplicate severity-specific diagnostics" },
    { "[w", "n", "remove", "duplicate severity-specific diagnostics" },
    { "]w", "n", "remove", "duplicate severity-specific diagnostics" },
    { "gcO", "n", "remove", "low-frequency comment alias" },
    { "gco", "n", "remove", "low-frequency comment alias" },
    { "<C-/>", { "n", "t" }, "merge", "one promoted terminal path", "terminal.float" },
    { "<C-_>", { "n", "t" }, "merge", "encoded duplicate terminal path", "terminal.float" },
}) do
    add(direct, item[1], item[2], item[3], item[4], item[5])
end

-- Lazy key handlers must be disabled at spec-merge time. Deleting only their
-- temporary mappings would let them reappear when the owning plugin loads.
for _, item in ipairs({
    { "<leader>,", "n", "merge", "duplicate buffer path", "buffer.find" },
    { "<leader>/", "n", "merge", "duplicate search path", "search.project_text" },
    { "<leader>:", "n", "remove", "native command history" },
    { "<leader><space>", "n", "merge", "duplicate file path", "files.find" },
    { "<leader>.", "n", "remove", "scratch workflow is out of scope" },
    { "<leader>S", "n", "remove", "scratch workflow is out of scope" },
    { "<leader>dps", "n", "remove", "maintainer profiler surface" },
    { "<leader>fB", "n", "merge", "duplicate buffer path", "buffer.find" },
    { "<leader>fF", "n", "merge", "duplicate file path", "files.find" },
    { "<leader>fR", "n", "merge", "duplicate recent-file path", "files.recent" },
    { "<leader>fc", "n", "remove", "configuration maintenance belongs to agents" },
    { "<leader>fg", "n", "merge", "duplicate file path", "files.find" },
    { "<leader>fp", "n", "remove", "multi-project launcher is out of scope" },
    { "<leader>gD", "n", "merge", "one Git diff action owns base selection", "git.diff" },
    { "<leader>gI", "n", "remove", "forge workflow belongs to agents" },
    { "<leader>gP", "n", "remove", "forge workflow belongs to agents" },
    { "<leader>gS", "n", "remove", "repository mutation" },
    { "<leader>gd", "n", "replace", "picker exposes stage and restore", "git.diff" },
    { "<leader>gi", "n", "remove", "forge workflow belongs to agents" },
    { "<leader>gp", "n", "remove", "forge workflow belongs to agents" },
    { "<leader>gs", "n", "replace", "picker exposes stage and restore", "git.status" },
    { "<leader>n", "n", "merge", "messages belong in Health", "health.open" },
    { '<leader>s"', "n", "remove", "native registers" },
    { "<leader>s/", "n", "remove", "native search history" },
    { "<leader>sB", "n", "merge", "duplicate search scope", "search.project_text" },
    { "<leader>sC", "n", "remove", "native command line" },
    { "<leader>sD", "n", "merge", "one diagnostics list owns scope", "diagnostics.list" },
    { "<leader>sG", "n", "merge", "duplicate search scope", "search.project_text" },
    { "<leader>sH", "n", "remove", "maintainer highlight inspection" },
    { "<leader>sM", "n", "remove", "specialist lookup" },
    { "<leader>sR", "n", "remove", "hidden picker state is out of scope" },
    { "<leader>sW", { "n", "x" }, "merge", "duplicate search scope", "search.project_text" },
    { "<leader>sa", "n", "remove", "maintainer autocmd inspection" },
    { "<leader>sb", "n", "remove", "native buffer search" },
    { "<leader>sc", "n", "remove", "native command history" },
    { "<leader>sg", "n", "merge", "duplicate search scope", "search.project_text" },
    { "<leader>sh", "n", "remove", "Clarity Health and native help own this job" },
    { "<leader>si", "n", "remove", "maintainer icon inspection" },
    { "<leader>sj", "n", "remove", "native jump list" },
    { "<leader>sl", "n", "remove", "one promoted result-list model" },
    { "<leader>sm", "n", "remove", "native marks" },
    { "<leader>sp", "n", "remove", "plugin maintenance belongs to agents" },
    { "<leader>sq", "n", "merge", "duplicate result-list path", "list.quickfix_toggle" },
    { "<leader>su", "n", "remove", "specialist undo inspection" },
    { "<leader>sw", "n", "merge", "word search is not a second global path", "search.project_text" },
    { "<leader>uC", "n", "remove", "theme is product policy" },
    { "<leader>un", "n", "remove", "messages belong in Health" },
}) do
    add(snacks, item[1], item[2], item[3], item[4], item[5])
end

for _, item in ipairs({
    { "<leader>be", "n", "merge", "one explorer owns navigation", "explorer.root" },
    { "<leader>fE", "n", "merge", "duplicate explorer path", "explorer.cwd" },
    { "<leader>fe", "n", "merge", "duplicate explorer path", "explorer.root" },
    { "<leader>ge", "n", "remove", "Neo-tree Git source exposes repository mutation" },
}) do
    add(neotree, item[1], item[2], item[3], item[4], item[5])
end

add(conform, "<leader>cF", { "n", "x" }, "remove", "specialist injected-language format path")
add(mason, "<leader>cm", "n", "remove", "toolchain maintenance belongs to agents")

for _, lhs in ipairs({ "<leader>sn", "<leader>sna", "<leader>snd", "<leader>snh", "<leader>snl", "<leader>snt" }) do
    add(noice, lhs, "n", "remove", "message recovery belongs in Health")
end

for _, item in ipairs({
    { "<leader>cA", "n", "remove", "specialist source action" },
    { "<leader>cC", "n", "remove", "specialist code lens action" },
    { "<leader>cR", "n", "remove", "workspace file mutation belongs to agents" },
    { "<leader>cc", { "n", "x" }, "remove", "specialist code lens action" },
    { "<leader>cl", "n", "merge", "capability recovery belongs in Health", "health.open" },
    { "<leader>co", "n", "remove", "specialist workspace edit" },
    { "gI", "n", "merge", "native gri owns implementation navigation" },
    { "gy", "n", "merge", "native grt owns type navigation" },
    { "gD", "n", "merge", "one definition path plus native LSP actions" },
    { "gK", "n", "remove", "insert signature help owns the editing job" },
    { "<A-n>", "n", "merge", "duplicate reference navigation" },
    { "<A-p>", "n", "merge", "duplicate reference navigation" },
    { "gai", "n", "remove", "specialist call hierarchy" },
    { "gao", "n", "remove", "specialist call hierarchy" },
}) do
    add(lsp, item[1], item[2], item[3], item[4], item[5])
end

for _, item in ipairs({
    { "<leader>ghB", "n", "remove", "line provenance is sufficient" },
    { "<leader>ghD", "n", "merge", "global Git diff owns base selection", "git.diff" },
    { "<leader>ghR", "n", "remove", "repository mutation" },
    { "<leader>ghS", "n", "remove", "repository mutation" },
    { "<leader>ghb", "n", "merge", "duplicate blame path", "git.blame_line" },
    { "<leader>ghd", "n", "merge", "duplicate diff path", "git.diff" },
    { "<leader>ghr", { "n", "x" }, "remove", "repository mutation" },
    { "<leader>ghs", { "n", "x" }, "remove", "repository mutation" },
    { "<leader>ghu", "n", "remove", "repository mutation" },
    { "[H", "n", "remove", "low-frequency hunk endpoint" },
    { "]H", "n", "remove", "low-frequency hunk endpoint" },
    { "ih", { "o", "x" }, "remove", "specialist hunk textobject" },
}) do
    add(gitsigns_attach, item[1], item[2], item[3], item[4], item[5])
end

-- These mappings are installed from plugin config code rather than lazy key
-- specs, so they are removed immediately and again after the named LazyLoad.
add({ kind = "post_load", owner = "gitsigns.nvim" }, "<leader>uG", "n", "remove", "Git signs are a product default")
add(
    { kind = "post_load", owner = "mini.pairs" },
    "<leader>up",
    "n",
    "remove",
    "pair behavior is policy, not a public toggle"
)

local function copy(value)
    return vim.deepcopy(value)
end

local function filter(kind, owner)
    local result = {}
    for _, item in ipairs(removals) do
        if item.origin.kind == kind and (owner == nil or item.origin.owner == owner) then
            result[#result + 1] = copy(item)
        end
    end
    return result
end

local function key_overrides(kind, owner)
    local result = {}
    for _, item in ipairs(filter(kind, owner)) do
        result[#result + 1] = { item.lhs, false, mode = item.modes }
    end
    return result
end

function M.budgets()
    return copy(surface_budgets)
end

local function lock_name(plugin)
    local owner, name = plugin:match("^([^/]+)/(.+)$")
    if name == "nvim" then
        return owner
    end
    return name
end

function M.plugin_exclusions()
    return copy(plugin_exclusions)
end

function M.plugin_exclusion_names()
    local result = {}
    for _, item in ipairs(plugin_exclusions) do
        result[#result + 1] = lock_name(item.plugin)
    end
    table.sort(result)
    return result
end

function M.plugin_exclusion_specs()
    local result = {}
    for _, item in ipairs(plugin_exclusions) do
        result[#result + 1] = { item.plugin, enabled = false }
    end
    return result
end

function M.removals()
    return copy(removals)
end

function M.direct_removals()
    return filter("direct")
end

function M.lazy_key_owners()
    local seen = {}
    local result = {}
    for _, item in ipairs(removals) do
        if item.origin.kind == "lazy_spec" and not seen[item.origin.owner] then
            seen[item.origin.owner] = true
            result[#result + 1] = item.origin.owner
        end
    end
    table.sort(result)
    return result
end

function M.lazy_key_overrides(owner)
    return key_overrides("lazy_spec", owner)
end

function M.lsp_key_overrides()
    return key_overrides("lsp", "neovim/nvim-lspconfig")
end

function M.post_load_removals(owner)
    return filter("post_load", owner)
end

function M.post_load_owners()
    local seen = {}
    local result = {}
    for _, item in ipairs(removals) do
        if item.origin.kind == "post_load" and not seen[item.origin.owner] then
            seen[item.origin.owner] = true
            result[#result + 1] = item.origin.owner
        end
    end
    table.sort(result)
    return result
end

function M.buffer_attach_removals(owner)
    return filter("buffer_attach", owner)
end

function M.validation_report()
    local issues = {}
    local seen = {}
    local seen_plugins = {}
    local seen_lock_names = {}
    local valid_decisions = { merge = true, relocate = true, remove = true, replace = true }
    for index, item in ipairs(plugin_exclusions) do
        local prefix = "plugin exclusion #" .. index
        if type(item.plugin) ~= "string" or not item.plugin:match("^[^/]+/[^/]+$") then
            issues[#issues + 1] = prefix .. " has an invalid plugin name"
        else
            local name = lock_name(item.plugin)
            if seen_plugins[item.plugin] then
                issues[#issues + 1] = "duplicate plugin exclusion: " .. item.plugin
            end
            if seen_lock_names[name] then
                issues[#issues + 1] = "duplicate plugin lock name: " .. name
            end
            seen_plugins[item.plugin] = true
            seen_lock_names[name] = true
        end
        if type(item.reason) ~= "string" or item.reason == "" then
            issues[#issues + 1] = prefix .. " is missing a reason"
        end
        if type(item.revisit_trigger) ~= "string" or item.revisit_trigger == "" then
            issues[#issues + 1] = prefix .. " is missing a revisit trigger"
        end
    end
    for _, item in ipairs(removals) do
        if not valid_decisions[item.decision] then
            issues[#issues + 1] = "invalid decision: " .. tostring(item.decision)
        end
        if type(item.reason) ~= "string" or item.reason == "" then
            issues[#issues + 1] = "missing reason: " .. item.lhs
        end
        if type(item.origin.owner) ~= "string" or item.origin.owner == "" then
            issues[#issues + 1] = "missing owner: " .. item.lhs
        end
        for _, mode in ipairs(item.modes) do
            local key = table.concat({ item.origin.kind, item.origin.owner, mode, item.lhs }, "\0")
            if seen[key] then
                issues[#issues + 1] = "duplicate removal: " .. mode .. ":" .. item.lhs
            end
            seen[key] = true
        end
    end
    table.sort(issues)
    return {
        ok = #issues == 0,
        issues = issues,
        exclusion_count = #plugin_exclusions,
        removal_count = #removals,
    }
end

function M.validate()
    local report = M.validation_report()
    return report.ok, report
end

return M
