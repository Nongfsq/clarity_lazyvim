local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
vim.env.CLARITY_CONTRACT_CATALOG = repo_root .. "/tests/contracts/runtime_contract.lua"

local probe = dofile(repo_root .. "/tests/lua/runtime_probe.lua")
probe.observe()

local first = probe.snapshot("unit")
local second = probe.snapshot("unit")

assert(first.schema_version == 1, "probe schema version must be 1")
assert(first.scenario == "unit", "probe must retain scenario id")
assert(type(first.events) == "table" and #first.events == 1, "probe must record only passive pre-init state")
assert(first.modules["config.options"].loaded == false, "probe must report missing modules without loading them")
assert(vim.deep_equal(first, second), "repeated passive snapshots must be stable")
assert(first.unsupported ~= nil, "probe must report an explicit unsupported field")

print("runtime probe tests: OK")
