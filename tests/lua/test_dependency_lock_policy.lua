local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
vim.opt.runtimepath:append(repo_root .. "/nvim")

local policy = require("config.product_policy")
local specs = assert(loadfile(repo_root .. "/nvim/lua/plugins/minimal.lua"))()
local lock = vim.json.decode(table.concat(vim.fn.readfile(repo_root .. "/lazy-lock.json"), "\n"))

local expected = {
    ["bufferline.nvim"] = true,
    catppuccin = true,
    ["dashboard-nvim"] = true,
    ["flash.nvim"] = true,
    ["grug-far.nvim"] = true,
    ["lazygit.nvim"] = true,
    ["mini.ai"] = true,
    ["nvim-lint"] = true,
    ["nvim-ts-autotag"] = true,
    ["persistence.nvim"] = true,
    ["todo-comments.nvim"] = true,
    ["tokyonight.nvim"] = true,
    ["trouble.nvim"] = true,
    ["lush.nvim"] = true,
    ["mason.nvim"] = true,
    ["mason-lspconfig.nvim"] = true,
    ["friendly-snippets"] = true,
    ["lazydev.nvim"] = true,
}

local function lock_name(repo)
    local owner, name = repo:match("^([^/]+)/(.+)$")
    return name == "nvim" and owner or name
end

local policy_ok, policy_report = policy.validate()
assert(policy_ok, "product policy registry failed validation: " .. table.concat(policy_report.issues, "; "))
assert(policy_report.exclusion_count == 18, "reviewed product-policy exclusion count drifted")

local registry = {}
for _, item in ipairs(policy.plugin_exclusions()) do
    assert(type(item.plugin) == "string" and item.plugin ~= "", "registry exclusion lacks a plugin name")
    assert(type(item.reason) == "string" and item.reason ~= "", "registry exclusion lacks a reason: " .. item.plugin)
    assert(
        type(item.revisit_trigger) == "string" and item.revisit_trigger ~= "",
        "registry exclusion lacks a revisit trigger: " .. item.plugin
    )
    assert(not registry[item.plugin], "duplicate registry exclusion: " .. item.plugin)
    registry[item.plugin] = true
end

local actual = {}
for _, spec in ipairs(specs) do
    local name = lock_name(spec[1])
    assert(registry[spec[1]], "minimal spec was not generated from the reviewed registry: " .. spec[1])
    assert(expected[name], "unexpected product-policy exclusion: " .. name)
    assert(spec.enabled == false, "product-policy exclusion must use enabled=false: " .. name)
    assert(lock[name] == nil, "disabled product-policy plugin must not remain locked: " .. name)
    actual[name] = true
end

assert(vim.deep_equal(actual, expected), "product-policy exclusion set drifted")
assert(vim.tbl_count(registry) == #specs, "registry and generated minimal spec counts differ")
local expected_names = vim.tbl_keys(expected)
table.sort(expected_names)
assert(vim.deep_equal(policy.plugin_exclusion_names(), expected_names), "lock-name registry drifted")
assert(lock["copilot.lua"] == nil, "embedded AI must not remain in the product lock")
assert(lock["toggleterm.nvim"] == nil, "dedicated terminal dependency must not remain locked")
assert(vim.tbl_count(lock) == 18, "lock must contain active dependencies only")

print("dependency lock policy tests: OK")
