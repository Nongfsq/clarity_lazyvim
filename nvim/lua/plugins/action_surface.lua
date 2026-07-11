local catalog = require("config.actions.catalog")
local policy = require("config.product_policy")

local specs = {}

for _, owner in ipairs(policy.lazy_key_owners()) do
    specs[#specs + 1] = {
        owner,
        keys = policy.lazy_key_overrides(owner),
    }
end

local lsp_keys = policy.lsp_key_overrides()
lsp_keys[#lsp_keys + 1] = {
    "<leader>uh",
    function()
        local filter = { bufnr = vim.api.nvim_get_current_buf() }
        local enabled = vim.lsp.inlay_hint.is_enabled(filter)
        vim.lsp.inlay_hint.enable(not enabled, filter)
    end,
    desc = catalog.label("lsp.inlay_hints_toggle", "en"),
    has = "inlayHint",
}

specs[#specs + 1] = {
    "neovim/nvim-lspconfig",
    opts = {
        servers = {
            ["*"] = {
                keys = lsp_keys,
            },
        },
    },
}

return specs
