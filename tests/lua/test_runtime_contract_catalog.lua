local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
local catalog = dofile(repo_root .. "/tests/contracts/runtime_contract.lua")

local function assert_true(value, message)
    if not value then
        error(message)
    end
end

assert_true(catalog.schema_version == 1, "runtime contract schema version must be 1")

local valid_classes = {
    pre_plugin = true,
    lifecycle = true,
    eager_service = true,
    on_demand = true,
    test_only = true,
}
for name, module in pairs(catalog.modules) do
    assert_true(valid_classes[module.class], "invalid module class for " .. name)
    assert_true(type(module.owner) == "string" and module.owner ~= "", "missing module owner for " .. name)
end

local config_files = vim.fn.glob(repo_root .. "/nvim/lua/config/**/*.lua", false, true)
vim.list_extend(config_files, vim.fn.glob(repo_root .. "/nvim/lua/config/*.lua", false, true))
for _, path in ipairs(config_files) do
    local relative = path:sub(#(repo_root .. "/nvim/lua/config/") + 1):gsub("%.lua$", ""):gsub("/", ".")
    local name = "config." .. relative
    assert_true(catalog.modules[name] ~= nil, "unclassified config module: " .. name)
end

local valid_coverage = { covered = true, planned = true, inherited = true }
for id, capability in pairs(catalog.capabilities) do
    assert_true(valid_coverage[capability.coverage], "invalid coverage for " .. id)
    assert_true(type(capability.owner) == "string" and capability.owner ~= "", "missing owner for " .. id)
    if capability.coverage == "planned" then
        assert_true(type(capability.task) == "string" and capability.task ~= "", "missing planned task for " .. id)
    end
end

local check_ids = {}
for _, check in ipairs(catalog.checks) do
    assert_true(not check_ids[check.id], "duplicate check id: " .. check.id)
    check_ids[check.id] = true
    for _, scenario in ipairs(check.scenarios) do
        assert_true(catalog.scenarios[scenario] ~= nil, "unknown scenario " .. scenario .. " in " .. check.id)
    end
end

print("runtime contract catalog tests: OK")
