local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
vim.opt.runtimepath:append(repo_root .. "/nvim")

local catalog = require("config.actions.catalog")
local policy = require("config.product_policy")

local function sorted(values)
    local result = vim.deepcopy(values)
    table.sort(result)
    return result
end

local function assert_list(actual, expected, message)
    assert(vim.deep_equal(sorted(actual), sorted(expected)), message .. ": " .. vim.inspect(actual))
end

local ok, report = catalog.validate()
assert(ok, "action catalog validation failed: " .. table.concat(report.issues, "; "))
assert(report.action_count == 35, "action catalog must contain exactly 35 actions")
assert(report.global_normal_count == 28, "global normal leader budget must be exactly 28")
assert(report.dynamic_normal_count == 7, "dynamic normal leader budget must be exactly seven")

local policy_ok, policy_report = policy.validate()
assert(policy_ok, "product policy validation failed: " .. table.concat(policy_report.issues, "; "))

local expected_global = {
    "<leader>-",
    "<leader>|",
    "<leader>E",
    "<leader>e",
    "<leader>?",
    "<leader>bd",
    "<leader>cf",
    "<leader>cz",
    "<leader>fb",
    "<leader>ff",
    "<leader>fn",
    "<leader>fr",
    "<leader>fw",
    "<leader>gb",
    "<leader>gd",
    "<leader>gl",
    "<leader>gs",
    "<leader>gt",
    "<leader>hh",
    "<leader>qq",
    "<leader>sd",
    "<leader>sk",
    "<leader>tf",
    "<leader>uw",
    "<leader>wd",
    "<leader>wm",
    "<leader>wo",
    "<leader>xq",
}
local expected_dynamic = {
    "<leader>uF",
    "<leader>uh",
    "<leader>ca",
    "<leader>cr",
    "<leader>ghp",
    "<leader>ss",
    "<leader>sS",
}

assert_list(catalog.global_normal_manifest(), expected_global, "global action manifest drifted")
assert_list(catalog.dynamic_normal_manifest(), expected_dynamic, "dynamic action manifest drifted")

local budgets = policy.budgets()
assert(budgets.global_normal_leader == 28, "policy global action budget drifted")
assert(budgets.full_context_normal_leader == 35, "policy full-context action budget drifted")
assert(
    #catalog.global_normal_manifest() + #catalog.dynamic_normal_manifest() <= budgets.full_context_normal_leader,
    "full-context action surface exceeds its budget"
)

local ids = {}
local contracts = {}
for _, action in ipairs(catalog.actions()) do
    assert(not ids[action.id], "duplicate action id: " .. action.id)
    assert(not contracts[action.contract_id], "duplicate contract id: " .. action.contract_id)
    ids[action.id] = true
    contracts[action.contract_id] = true
    assert(type(action.label_key) == "string" and action.label_key ~= "", "missing label key: " .. action.id)
    assert(type(action.labels.en) == "string" and action.labels.en ~= "", "missing English label: " .. action.id)
    assert(type(action.labels.zh) == "string" and action.labels.zh ~= "", "missing Chinese label: " .. action.id)
    assert(type(action.owner) == "table" and action.owner.name, "missing owner: " .. action.id)
    assert(action.mutability ~= "repository_write", "repository mutation entered catalog: " .. action.id)
end

assert(catalog.lookup("n", "<leader>ff", "global").id == "files.find", "global lookup is wrong")
assert(catalog.lookup("n", "<leader>ca", "buffer").id == "lsp.code_action", "buffer lookup is wrong")
assert(catalog.lookup("x", "<leader>cf", "global").id == "code.format", "visual format ownership is wrong")
assert(
    catalog.lookup("x", "<leader>sw", "global").id == "search.project_text",
    "visual project-search ownership is wrong"
)
assert(catalog.lookup("n", "<leader>missing", "global") == nil, "unknown key unexpectedly resolved")

local actions_copy = catalog.actions()
actions_copy[1].labels.zh = "mutated"
assert(catalog.actions()[1].labels.zh ~= "mutated", "catalog leaked mutable action state")
local policy_copy = policy.removals()
policy_copy[1].lhs = "<leader>mutated"
assert(policy.removals()[1].lhs ~= "<leader>mutated", "policy leaked mutable removal state")

local surface_removals = {}
local replacement_overlap = {}
for _, item in ipairs(policy.removals()) do
    if
        (item.origin.kind == "direct" or item.origin.kind == "lazy_spec" or item.origin.kind == "post_load")
        and vim.startswith(item.lhs, "<leader>")
        and vim.tbl_contains(item.modes, "n")
    then
        surface_removals[item.lhs] = true
        if vim.tbl_contains(expected_global, item.lhs) then
            assert(item.decision == "replace", "retained global key is not an explicit replacement: " .. item.lhs)
            replacement_overlap[#replacement_overlap + 1] = item.lhs
        end
    end
end
assert(vim.tbl_count(surface_removals) == 110, "reviewed global disable/replace set drifted")
assert_list(
    replacement_overlap,
    { "<leader>gb", "<leader>gd", "<leader>gl", "<leader>gs" },
    "retained replacement set drifted"
)

print("action catalog tests: OK")
