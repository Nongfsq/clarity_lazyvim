local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
local contract = dofile(repo_root .. "/tests/contracts/diagnostic_event.lua")

assert(contract.schema_version == 1, "diagnostic event schema must be version 1")
for _, field in ipairs(contract.required_fields) do
    assert(type(field) == "string" and field ~= "", "required fields must be named")
end
for _, outcome in ipairs({ "toggled", "no_fold", "unsupported_buffer", "degraded", "failed" }) do
    assert(contract.fold_outcomes[outcome], "missing fold outcome: " .. outcome)
end
for _, forbidden in ipairs({ "buffer_text", "clipboard", "environment", "token", "command_args" }) do
    assert(not contract.context_fields[forbidden], "unsafe context field allowed: " .. forbidden)
end

print("diagnostic event contract tests: OK")
