local M = {}

local levels = vim.log.levels
local level_names = {
    [levels.TRACE] = "trace",
    [levels.DEBUG] = "debug",
    [levels.INFO] = "info",
    [levels.WARN] = "warn",
    [levels.ERROR] = "error",
    [levels.OFF] = "off",
}
local level_values = {
    trace = levels.TRACE,
    debug = levels.DEBUG,
    info = levels.INFO,
    warn = levels.WARN,
    error = levels.ERROR,
    off = levels.OFF,
}
local allowed_context = {
    buffer_type = true,
    check_id = true,
    filetype = true,
    foldlevel = true,
    foldmethod = true,
    line = true,
    path = true,
    reason = true,
    scenario = true,
}

local Diagnostics = {}
Diagnostics.__index = Diagnostics

local function default_path()
    return vim.fs.joinpath(vim.fn.stdpath("state"), "clarity", "events.jsonl")
end

local function default_session_id()
    return string.format("%d-%d", os.time(), vim.fn.getpid())
end

local function timestamp()
    return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

local function normalize_path(value)
    local path = tostring(value):gsub("\\", "/")
    local home = (vim.env.HOME or vim.env.USERPROFILE or ""):gsub("\\", "/")
    if home ~= "" and path:sub(1, #home) == home then
        path = "~" .. path:sub(#home + 1)
    end
    local root = tostring(vim.g.clarity_repo_root or ""):gsub("\\", "/")
    if root ~= "" and path:sub(1, #root) == root then
        path = path:sub(#root + 2)
    end
    return path
end

local function sanitize_scalar(key, value)
    local value_type = type(value)
    if value_type ~= "string" and value_type ~= "number" and value_type ~= "boolean" then
        return tostring(value)
    end
    if key == "path" and value_type == "string" then
        return normalize_path(value)
    end
    return value
end

local function sanitize_context(context)
    local safe = {}
    for key, value in pairs(context or {}) do
        if allowed_context[key] then
            safe[key] = sanitize_scalar(key, value)
        end
    end
    return safe
end

local function sanitize_text(value, redact_values)
    local text = tostring(value or "")
    local home = vim.env.HOME or vim.env.USERPROFILE or ""
    if home ~= "" then
        text = text:gsub(vim.pesc(home), "~")
        text = text:gsub(vim.pesc(home:gsub("\\", "/")), "~")
        text = text:gsub(vim.pesc(home:gsub("/", "\\")), "~")
    end
    for _, secret in ipairs(redact_values or {}) do
        if secret ~= "" then
            text = text:gsub(vim.pesc(secret), "[redacted]")
        end
    end
    if #text > 4096 then
        text = text:sub(1, 4096) .. "…[truncated]"
    end
    return text
end

local function default_writer(path, line)
    vim.fn.mkdir(vim.fs.dirname(path), "p")
    local handle, open_error = io.open(path, "a")
    if not handle then
        return false, open_error
    end
    local ok, write_error = handle:write(line, "\n")
    handle:close()
    if ok then
        pcall(vim.uv.fs_chmod, path, 384)
        return true
    end
    return false, write_error
end

local function rotate(path, max_bytes, keep)
    local stat = vim.uv.fs_stat(path)
    if not stat or stat.size < max_bytes then
        return true
    end
    for index = keep, 1, -1 do
        local source = index == 1 and path or (path .. "." .. (index - 1))
        local destination = path .. "." .. index
        if vim.uv.fs_stat(source) then
            pcall(vim.uv.fs_unlink, destination)
            local ok, err = vim.uv.fs_rename(source, destination)
            if not ok then
                return false, err
            end
        end
    end
    return true
end

function M.new(opts)
    opts = opts or {}
    local threshold = opts.persist_level or vim.env.CLARITY_LOG_LEVEL or "warn"
    threshold = type(threshold) == "string" and level_values[threshold:lower()] or threshold
    return setmetatable({
        schema_version = 1,
        seq = 0,
        session_id = opts.session_id or default_session_id(),
        path = opts.path or default_path(),
        capacity = opts.capacity or 200,
        max_bytes = opts.max_bytes or (1024 * 1024),
        rotations = opts.rotations or 2,
        persist_level = threshold or levels.WARN,
        writer = opts.writer or default_writer,
        clock = opts.clock or timestamp,
        redact_values = opts.redact_values or {},
        records = {},
        writing = false,
    }, Diagnostics)
end

function Diagnostics:_remember(event)
    table.insert(self.records, event)
    while #self.records > self.capacity do
        table.remove(self.records, 1)
    end
end

function Diagnostics:_persist(event)
    if self.persist_level == levels.OFF or event.level_value < self.persist_level or self.writing then
        return false
    end
    self.writing = true
    local rotated, rotate_error = rotate(self.path, self.max_bytes, self.rotations)
    local encoded_ok, encoded = pcall(vim.json.encode, event)
    local written, write_error = false, nil
    if rotated and encoded_ok then
        written, write_error = self.writer(self.path, encoded)
    end
    self.writing = false
    if not rotated or not encoded_ok or not written then
        event.persisted = false
        event.persist_error = sanitize_text(rotate_error or write_error or encoded, self.redact_values)
        return false
    end
    event.persisted = true
    return true
end

function Diagnostics:emit(level, spec)
    spec = spec or {}
    self.seq = self.seq + 1
    local numeric_level = type(level) == "string" and level_values[level:lower()] or level
    numeric_level = numeric_level or levels.INFO
    local event = {
        schema_version = self.schema_version,
        seq = self.seq,
        timestamp = self.clock(),
        session_id = self.session_id,
        level = level_names[numeric_level] or "info",
        level_value = numeric_level,
        event_id = spec.event_id or "CLARITY_DIAGNOSTIC_EVENT",
        component = spec.component or "config.diagnostics",
        action = spec.action or "observe",
        outcome = spec.outcome or "recorded",
        message_key = spec.message_key or "diagnostics.event",
        context = sanitize_context(spec.context),
    }
    if spec.error then
        event.error = {
            code = spec.error.code,
            message = sanitize_text(spec.error.message or spec.error, self.redact_values),
            traceback = spec.error.traceback and sanitize_text(spec.error.traceback, self.redact_values) or nil,
        }
    end
    self:_remember(event)
    self:_persist(event)
    return event
end

function Diagnostics:guard(spec, callback)
    local ok, result = xpcall(callback, debug.traceback)
    if ok then
        return true, result
    end
    local event = self:emit(levels.ERROR, {
        event_id = spec.event_id,
        component = spec.component,
        action = spec.action,
        outcome = "failed",
        message_key = spec.message_key,
        context = spec.context,
        error = { code = spec.error_code, message = result, traceback = result },
    })
    local notify = spec.notify or vim.notify
    if notify and spec.user_message then
        pcall(notify, spec.user_message, levels.ERROR, { title = "Clarity" })
    end
    return false, event
end

function Diagnostics:events()
    return vim.deepcopy(self.records)
end

function Diagnostics:export(path)
    local lines = {}
    for _, event in ipairs(self.records) do
        table.insert(lines, vim.json.encode(event))
    end
    local ok, result = pcall(function()
        vim.fn.mkdir(vim.fs.dirname(path), "p")
        return vim.fn.writefile(lines, path) == 0
    end)
    if not ok then
        return false, sanitize_text(result)
    end
    return result, result and nil or "writefile returned non-zero"
end

local singleton
local function instance()
    if not singleton then
        singleton = M.new()
    end
    return singleton
end

function M.emit(level, spec)
    return instance():emit(level, spec)
end

function M.guard(spec, callback)
    return instance():guard(spec, callback)
end

function M.events()
    return instance():events()
end

function M.path()
    return instance().path
end

function M.export(path)
    return instance():export(path)
end

function M._reset(opts)
    singleton = M.new(opts)
    return singleton
end

return M
