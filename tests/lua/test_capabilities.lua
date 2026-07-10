local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
package.path = repo_root .. "/nvim/lua/?.lua;" .. repo_root .. "/nvim/lua/?/init.lua;" .. package.path

local capabilities = require("config.capabilities")

local function equal(actual, expected, message)
    if not vim.deep_equal(actual, expected) then
        error(string.format("%s: expected=%s actual=%s", message, vim.inspect(expected), vim.inspect(actual)))
    end
end

equal(capabilities.nvim_supported({ major = 0, minor = 12, patch = 0 }), true, "minimum Neovim is supported")
equal(capabilities.nvim_supported({ major = 0, minor = 11, patch = 9 }), false, "older Neovim is blocked")
equal(capabilities.nvim_supported({ major = 1, minor = 0, patch = 0 }), true, "future major is supported")

local summary = capabilities.summarize({
    capabilities.check({ id = "core_ok", profile = "core", required = true, status = "pass" }),
    capabilities.check({ id = "optional_warn", profile = "providers", required = false, status = "warn" }),
    capabilities.check({ id = "copilot_missing", profile = "copilot", required = true, status = "fail" }),
})

equal(summary.core.status, "ready", "optional profile failures do not block core")
equal(summary.host.status, "ready", "host status follows core readiness")
equal(summary.profiles.providers.status, "degraded", "optional provider warning is degraded")
equal(summary.profiles.copilot.status, "blocked", "missing required profile capability blocks that profile")
equal(summary.release.status, "unverified", "local checks do not self-certify release quality")

local blocked = capabilities.summarize({
    capabilities.check({ id = "core_missing", profile = "core", required = true, status = "fail" }),
})
equal(blocked.core.status, "blocked", "core failure blocks core readiness")
equal(blocked.host.status, "blocked", "core failure blocks host readiness")

print("capabilities tests: OK")
