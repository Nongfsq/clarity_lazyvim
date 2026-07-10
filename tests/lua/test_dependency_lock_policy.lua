local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
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
}

local function lock_name(repo)
    local owner, name = repo:match("^([^/]+)/(.+)$")
    return name == "nvim" and owner or name
end

local actual = {}
for _, spec in ipairs(specs) do
    local name = lock_name(spec[1])
    assert(expected[name], "unexpected product-policy exclusion: " .. name)
    assert(spec.enabled == false, "product-policy exclusion must use enabled=false: " .. name)
    assert(lock[name] == nil, "disabled product-policy plugin must not remain locked: " .. name)
    actual[name] = true
end

assert(vim.deep_equal(actual, expected), "product-policy exclusion set drifted")
assert(lock["copilot.lua"] == nil, "embedded AI must not remain in the product lock")
assert(lock["toggleterm.nvim"] == nil, "dedicated terminal dependency must not remain locked")
assert(vim.tbl_count(lock) == 23, "lock must contain active dependencies only")

print("dependency lock policy tests: OK")
