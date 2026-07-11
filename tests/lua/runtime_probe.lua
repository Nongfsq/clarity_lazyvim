local M = {}

local function normalize(path)
    if type(path) ~= "string" then
        return path
    end
    return path:gsub("\\", "/")
end

local function load_catalog()
    local path = assert(vim.env.CLARITY_CONTRACT_CATALOG, "CLARITY_CONTRACT_CATALOG is required")
    return dofile(path)
end

local function module_state(catalog)
    local state = {}
    for name in pairs(catalog.modules) do
        state[name] = package.loaded[name] ~= nil
    end
    return state
end

local function record(event)
    local state = _G.ClarityContractObserver
    if type(state) ~= "table" then
        return
    end
    table.insert(state.events, {
        index = #state.events + 1,
        event = event,
        modules = module_state(state.catalog),
    })
end

function M.observe()
    local catalog = load_catalog()
    _G.ClarityContractObserver = {
        catalog = catalog,
        events = {},
    }
    record("PreInit")

    local group = vim.api.nvim_create_augroup("clarity_contract_observer", { clear = true })
    vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "*",
        callback = function(event)
            record("User:" .. event.match)
        end,
    })
    for _, event_name in ipairs({ "BufEnter", "VimEnter", "UIEnter" }) do
        vim.api.nvim_create_autocmd(event_name, {
            group = group,
            callback = function()
                record(event_name)
            end,
        })
    end
end

local function first_seen(events, module_name)
    for _, event in ipairs(events) do
        if event.modules[module_name] then
            return event.event
        end
    end
    return nil
end

local function map_snapshot(lhs)
    local map = vim.fn.maparg(lhs, "n", false, true)
    if type(map) ~= "table" or next(map) == nil then
        return { exists = false }
    end
    local source
    if type(map.callback) == "function" then
        local info = debug.getinfo(map.callback, "S")
        source = info and normalize(info.source:gsub("^@", "")) or nil
    end
    return {
        exists = true,
        lhs = map.lhs,
        desc = map.desc,
        source = source or vim.NIL,
        buffer = map.buffer == 1,
    }
end

local function autocmd_count(group_name)
    local ok, autocmds = pcall(vim.api.nvim_get_autocmds, { group = group_name })
    return ok and #autocmds or 0
end

local function plugin_count()
    local ok, config = pcall(require, "lazy.core.config")
    if not ok then
        return vim.NIL
    end
    return vim.tbl_count(config.plugins or {})
end

function M.ready(scenario)
    if package.loaded["config.options"] == nil then
        return false
    end
    if scenario == "file_headless" or scenario == "file_ui" then
        if package.loaded["config.autocmds"] == nil then
            return false
        end
    end
    if scenario == "file_ui" then
        return vim.g.did_very_lazy == true and package.loaded["config.keymaps"] ~= nil
    end
    return true
end

function M.snapshot(scenario)
    local observer = assert(_G.ClarityContractObserver, "contract observer was not installed before init")
    local catalog = observer.catalog
    local modules = {}
    for name, loaded in pairs(module_state(catalog)) do
        modules[name] = {
            loaded = loaded,
            first_seen = first_seen(observer.events, name) or vim.NIL,
        }
    end

    local lazy_ok, lazy_config = pcall(require, "lazy.core.config")
    local lazyvim_ok = type(LazyVim) == "table" and LazyVim.config and LazyVim.config.json
    return {
        schema_version = 1,
        scenario = scenario,
        paths = {
            repo = normalize(vim.g.clarity_repo_root),
            lock = lazy_ok and normalize(lazy_config.options.lockfile) or vim.NIL,
            json = lazyvim_ok and normalize(LazyVim.config.json.path) or vim.NIL,
        },
        nvim = vim.version(),
        events = observer.events,
        modules = modules,
        options = {
            number = vim.wo.number,
            relativenumber = vim.wo.relativenumber,
            wrap = vim.wo.wrap,
            linebreak = vim.wo.linebreak,
            breakindent = vim.wo.breakindent,
            conceallevel = vim.wo.conceallevel,
        },
        maps = {
            leader_uw = map_snapshot("<leader>uw"),
            leader_cz = map_snapshot("<leader>cz"),
        },
        autocmds = {
            absolute_line_numbers = autocmd_count("clarity_absolute_line_numbers"),
        },
        plugins = {
            count = plugin_count(),
        },
        unsupported = {},
    }
end

return M
