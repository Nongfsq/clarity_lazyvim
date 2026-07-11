local M = {}

local catalog = require("config.actions.catalog")
local i18n = require("config.i18n")

local applied = false

local function mode_copy(mode)
    return type(mode) == "table" and vim.deepcopy(mode) or mode
end

local function action_spec(action, binding)
    local action_id = action.id
    local spec = {
        binding.lhs,
        desc = function()
            return catalog.label(action_id, i18n.get_locale()) or action_id
        end,
        mode = mode_copy(binding.mode),
    }

    -- Dynamic actions are supplied by LSP/Gitsigns/buffer lifecycle handlers.
    -- `real` keeps their metadata invisible unless that buffer owns the actual
    -- mapping, while the function-valued description changes language without
    -- recreating the mapping or accumulating another which-key spec.
    if action.visibility == "dynamic" or binding.scope == "buffer" then
        spec.real = true
    end

    return spec
end

local function group_spec(group)
    local group_id = group.id
    return {
        group.prefix,
        group = function()
            return catalog.group_label(group_id, i18n.get_locale()) or group_id
        end,
    }
end

function M.spec()
    local spec = {}

    for _, group in ipairs(catalog.groups()) do
        if type(group.prefix) == "string" and group.prefix ~= "" then
            spec[#spec + 1] = group_spec(group)
        end
    end

    for _, action in ipairs(catalog.actions()) do
        for _, binding in ipairs(action.bindings or {}) do
            if type(binding.lhs) == "string" and vim.startswith(binding.lhs, "<leader>") then
                spec[#spec + 1] = action_spec(action, binding)
            end
        end
    end

    return spec
end

function M.apply(which_key)
    if applied then
        return false
    end

    if not which_key then
        local ok
        ok, which_key = pcall(require, "which-key")
        if not ok then
            return false
        end
    end

    which_key.add(M.spec(), { create = false })
    applied = true
    return true
end

function M.setup()
    local group = vim.api.nvim_create_augroup("clarity_menu_i18n", { clear = true })

    vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "VeryLazy",
        once = true,
        callback = function()
            vim.schedule(M.apply)
        end,
    })
end

return M
