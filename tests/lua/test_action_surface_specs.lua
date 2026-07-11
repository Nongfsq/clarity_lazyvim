local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
vim.opt.runtimepath:append(repo_root .. "/nvim")

local policy = require("config.product_policy")

local sentinel = function()
    return "user-owned"
end
vim.keymap.set("n", "<leader>zz", sentinel, { desc = "User-owned map" })
local before = vim.fn.maparg("<leader>zz", "n", false, true)
local specs = dofile(repo_root .. "/nvim/lua/plugins/action_surface.lua")
local after = vim.fn.maparg("<leader>zz", "n", false, true)
assert(vim.deep_equal(after, before), "loading action-surface specs changed a user mapping")

local by_owner = {}
for _, spec in ipairs(specs) do
    assert(type(spec[1]) == "string", "plugin spec is missing its owner")
    assert(not by_owner[spec[1]], "duplicate action-surface spec: " .. spec[1])
    by_owner[spec[1]] = spec
end

local expected_owners = {
    "folke/noice.nvim",
    "folke/snacks.nvim",
    "mason-org/mason.nvim",
    "neovim/nvim-lspconfig",
    "nvim-neo-tree/neo-tree.nvim",
    "stevearc/conform.nvim",
}
local actual_owners = vim.tbl_keys(by_owner)
table.sort(actual_owners)
table.sort(expected_owners)
assert(vim.deep_equal(actual_owners, expected_owners), "action-surface plugin owners drifted")

local function mode_contains(value, expected)
    if type(value) == "table" then
        return vim.tbl_contains(value, expected)
    end
    return value == expected
end

local function find_key(keys, lhs, mode)
    for _, key in ipairs(keys or {}) do
        if key[1] == lhs and mode_contains(key.mode or "n", mode) then
            return key
        end
    end
end

local function assert_disabled(owner, lhs, mode)
    local spec = assert(by_owner[owner], "missing plugin owner: " .. owner)
    local key = assert(find_key(spec.keys, lhs, mode), "missing disabled key: " .. owner .. ":" .. lhs)
    assert(key[2] == false, "disabled lazy key must use rhs=false: " .. owner .. ":" .. lhs)
end

assert_disabled("folke/snacks.nvim", "<leader>sW", "n")
assert_disabled("folke/snacks.nvim", "<leader>sW", "x")
assert_disabled("folke/snacks.nvim", "<leader>sw", "n")
assert(not find_key(by_owner["folke/snacks.nvim"].keys, "<leader>sw", "x"), "visual word search must remain available")
assert_disabled("nvim-neo-tree/neo-tree.nvim", "<leader>ge", "n")
assert_disabled("stevearc/conform.nvim", "<leader>cF", "n")
assert_disabled("stevearc/conform.nvim", "<leader>cF", "x")
assert_disabled("mason-org/mason.nvim", "<leader>cm", "n")
assert_disabled("folke/noice.nvim", "<leader>sn", "n")

for _, lhs in ipairs({ "<leader>fb", "<leader>ff", "<leader>fr", "<leader>sd", "<leader>sk" }) do
    assert(not find_key(by_owner["folke/snacks.nvim"].keys, lhs, "n"), "promoted Snacks key was disabled: " .. lhs)
end
for _, lhs in ipairs({ "<leader>e", "<leader>E" }) do
    assert(
        not find_key(by_owner["nvim-neo-tree/neo-tree.nvim"].keys, lhs, "n"),
        "promoted explorer key was disabled: " .. lhs
    )
end
assert(not find_key(by_owner["stevearc/conform.nvim"].keys, "<leader>cf", "n"), "promoted format key was disabled")

local lsp = by_owner["neovim/nvim-lspconfig"]
local lsp_keys = assert(lsp.opts.servers["*"].keys, "LSP policy keys are missing")
for _, lhs in ipairs({
    "<leader>cA",
    "<leader>cC",
    "<leader>cR",
    "<leader>cc",
    "<leader>cl",
    "<leader>co",
    "gI",
    "gy",
    "gD",
    "gK",
}) do
    local key = assert(find_key(lsp_keys, lhs, "n"), "missing LSP disable: " .. lhs)
    assert(key[2] == false, "LSP disable must use rhs=false: " .. lhs)
end
local inlay = assert(find_key(lsp_keys, "<leader>uh", "n"), "dynamic inlay-hint action is missing")
assert(type(inlay[2]) == "function", "inlay-hint action is not callable")
assert(inlay.has == "inlayHint", "inlay-hint action is not capability gated")
assert(type(inlay.desc) == "string" and inlay.desc ~= "", "inlay-hint action is not discoverable")
assert(not find_key(lsp_keys, "<leader>ca", "n"), "promoted code action was disabled")
assert(not find_key(lsp_keys, "<leader>cr", "n"), "promoted rename action was disabled")

local function find_policy(kind, owner, lhs)
    for _, item in ipairs(policy.removals()) do
        if item.origin.kind == kind and item.origin.owner == owner and item.lhs == lhs then
            return item
        end
    end
end

for _, lhs in ipairs({ "<leader>gb", "<leader>gl" }) do
    local item = assert(find_policy("direct", "lazyvim.config.keymaps", lhs), "missing direct replacement: " .. lhs)
    assert(item.decision == "replace", "direct Git replacement decision drifted: " .. lhs)
end
for _, lhs in ipairs({ "<leader>uF", "<leader>uh" }) do
    local item = assert(find_policy("direct", "lazyvim.config.keymaps", lhs), "missing relocation: " .. lhs)
    assert(item.decision == "relocate", "dynamic action is not explicitly relocated: " .. lhs)
end
assert(find_policy("post_load", "gitsigns.nvim", "<leader>uG"), "late Gitsigns toggle cleanup is missing")
assert(find_policy("post_load", "mini.pairs", "<leader>up"), "late mini.pairs toggle cleanup is missing")
assert(find_policy("buffer_attach", "gitsigns.nvim", "<leader>ghs"), "attached Gitsigns mutation cleanup is missing")

vim.keymap.del("n", "<leader>zz")
print("action surface spec tests: OK")
