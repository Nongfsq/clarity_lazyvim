local repo_root = vim.env.CLARITY_REPO_ROOT or vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
package.path = repo_root .. "/nvim/lua/?.lua;" .. repo_root .. "/nvim/lua/?/init.lua;" .. package.path

local git = require("config.actions.git")

local function assert_equal(actual, expected, message)
    assert(vim.deep_equal(actual, expected), message .. ": " .. vim.inspect({ actual = actual, expected = expected }))
end

local function fake_deps(spec)
    spec = spec or {}
    local captured = spec.captured or {}
    local events = spec.events or {}
    local renders = spec.renders or {}
    local notifications = spec.notifications or {}
    return {
        diagnostics = {
            emit = function(level, event)
                events[#events + 1] = { level = level, event = event }
            end,
        },
        executable = function()
            return spec.executable == nil and 1 or spec.executable
        end,
        notify = function(message, level)
            notifications[#notifications + 1] = { message = message, level = level }
        end,
        render = function(action, root, lines)
            renders[#renders + 1] = { action = action, root = root, lines = lines }
            return { test = true }
        end,
        root = function()
            return spec.root == nil and "/repo" or spec.root
        end,
        schedule = function(callback)
            callback()
        end,
        start = function()
            return "/repo/src", "/repo/src/file.lua"
        end,
        system = spec.system or function(argv, opts, on_exit)
            captured.argv = vim.deepcopy(argv)
            captured.opts = vim.deepcopy(opts)
            if spec.stdout then
                opts.stdout(nil, spec.stdout)
            end
            if spec.stderr then
                opts.stderr(nil, spec.stderr)
            end
            on_exit({ code = spec.code or 0, signal = 0 })
            return {
                kill = function(_, signal)
                    captured.kill = signal
                end,
            }
        end,
    },
        captured,
        events,
        renders,
        notifications
end

local actions = {
    blame_line = { fn = git.blame_line, command = "blame" },
    branch_graph = { fn = git.branch_graph, command = "log" },
    diff = { fn = git.diff, command = "diff" },
    log = { fn = git.log, command = "log" },
    status = { fn = git.status, command = "status" },
}

for name, action in pairs(actions) do
    local completed
    local deps, captured, events, renders = fake_deps({ stdout = name .. " output\n" })
    local started = action.fn({
        deps = deps,
        line = 7,
        on_complete = function(result)
            completed = result
        end,
    })
    assert(started.outcome == "started", name .. " must return a typed started outcome")
    assert(completed and completed.outcome == "rendered", name .. " must complete as rendered")
    assert(type(captured.argv) == "table", name .. " must execute an argv table")
    assert(captured.argv[1] == "git", name .. " must invoke Git directly")
    assert(vim.tbl_contains(captured.argv, "--no-optional-locks"), name .. " must disable optional locks")
    assert(vim.tbl_contains(captured.argv, action.command), name .. " command missing")
    assert(captured.opts.cwd == "/repo", name .. " must execute at the resolved repository root")
    assert(captured.opts.env.GIT_OPTIONAL_LOCKS == "0", name .. " environment policy missing")
    assert(captured.opts.timeout == 5000, name .. " timeout must be bounded")
    assert(#renders == 1 and renders[1].action == name, name .. " must render exactly one scratch view")
    assert(events[#events].event.outcome == "rendered", name .. " diagnostics outcome missing")
    assert(events[#events].event.context.path == nil, name .. " persisted an arbitrary repository path")
    assert(events[#events].event.context.scope == "repository", name .. " diagnostics scope missing")
    if name == "blame_line" then
        assert(vim.tbl_contains(captured.argv, "7,7"), "blame must use the current line only")
        assert(vim.tbl_contains(captured.argv, "src/file.lua"), "blame must pass a repository-relative path")
    end
    for _, forbidden in ipairs({
        "add",
        "apply",
        "branch",
        "checkout",
        "commit",
        "merge",
        "pull",
        "push",
        "rebase",
        "reset",
        "restore",
        "stash",
        "switch",
    }) do
        assert(not vim.tbl_contains(captured.argv, forbidden), name .. " contains mutating Git verb: " .. forbidden)
    end
end

do
    local deps, _, events, renders, notifications = fake_deps({ executable = 0 })
    local result = git.status({ deps = deps })
    assert(result.outcome == "missing_git", "missing Git must be a typed outcome")
    assert(#renders == 1 and #notifications == 1, "missing Git must render actionable recovery and notify")
    assert(events[#events].event.event_id == "CLARITY_GIT_STATUS_MISSING_GIT", "missing Git event ID mismatch")
end

do
    local deps, _, _, renders = fake_deps({ root = false })
    local result = git.diff({ deps = deps })
    assert(result.outcome == "not_repo", "non-repository context must be a typed outcome")
    assert(#renders == 1, "non-repository context must render actionable recovery")
end

do
    local completed
    local deps, captured, _, renders = fake_deps({ stdout = string.rep("x", 32) })
    git.log({
        deps = deps,
        max_bytes = 8,
        on_complete = function(result)
            completed = result
        end,
    })
    assert(completed and completed.outcome == "output_limited", "oversized output must be typed and bounded")
    assert(captured.kill == 15, "oversized output must terminate the child process")
    assert(#table.concat(renders[1].lines, "\n") < 256, "bounded output view unexpectedly large")
end

do
    local completed
    local deps = fake_deps({ code = 124 })
    git.branch_graph({
        deps = deps,
        timeout_ms = 9,
        on_complete = function(result)
            completed = result
        end,
    })
    assert(completed and completed.outcome == "timeout", "timeout must be a typed outcome")
end

local function run(argv, cwd)
    local result = vim.system(argv, {
        cwd = cwd,
        env = { GIT_OPTIONAL_LOCKS = "0", LC_ALL = "C", LANGUAGE = "C" },
        text = true,
    }):wait()
    assert(result.code == 0, table.concat(argv, " ") .. " failed: " .. tostring(result.stderr))
    return result.stdout or ""
end

local function read_binary(path)
    local handle = assert(io.open(path, "rb"))
    local value = handle:read("*a")
    handle:close()
    return value
end

local function tree_bytes(root, excluded)
    if not vim.uv.fs_stat(root) then
        return {}
    end
    local result = {}
    local function walk(directory, prefix)
        for name, kind in vim.fs.dir(directory) do
            local relative = prefix == "" and name or (prefix .. "/" .. name)
            if not (excluded and excluded[relative]) then
                local path = directory .. "/" .. name
                if kind == "directory" then
                    walk(path, relative)
                elseif kind == "file" or kind == "link" then
                    result[#result + 1] = relative .. "\0" .. vim.fn.sha256(read_binary(path))
                end
            end
        end
    end
    walk(root, "")
    table.sort(result)
    return result
end

local fixture = vim.fn.tempname() .. "-clarity-git"
vim.fn.mkdir(fixture, "p")
run({ "git", "init", "--quiet" }, fixture)
vim.fn.writefile({ "one" }, fixture .. "/sample.txt")
run({ "git", "add", "sample.txt" }, fixture)
run({
    "git",
    "-c",
    "user.name=Clarity Test",
    "-c",
    "user.email=clarity@example.invalid",
    "-c",
    "commit.gpgsign=false",
    "commit",
    "--quiet",
    "-m",
    "fixture",
}, fixture)
vim.fn.writefile({ "two" }, fixture .. "/sample.txt")

local function snapshot()
    local index = fixture .. "/.git/index"
    local stat = assert(vim.uv.fs_stat(index))
    local locks = {}
    for _, item in ipairs(tree_bytes(fixture .. "/.git")) do
        local path = item:match("^(.-)%z")
        if path and path:match("%.lock$") then
            locks[#locks + 1] = item
        end
    end
    return {
        head = read_binary(fixture .. "/.git/HEAD"),
        resolved_head = vim.trim(run({ "git", "--no-optional-locks", "rev-parse", "HEAD" }, fixture)),
        index = vim.fn.sha256(read_binary(index)),
        index_mtime = { stat.mtime.sec, stat.mtime.nsec },
        locks = locks,
        packed_refs = vim.uv.fs_stat(fixture .. "/.git/packed-refs") and vim.fn.sha256(
            read_binary(fixture .. "/.git/packed-refs")
        ) or false,
        refs = tree_bytes(fixture .. "/.git/refs"),
        status = run({ "git", "--no-optional-locks", "status", "--porcelain=v2", "-z" }, fixture),
        worktree = tree_bytes(fixture, { [".git"] = true }),
    }
end

local before = snapshot()
local actual_events = {}
local actual_deps = {
    diagnostics = {
        emit = function(level, event)
            actual_events[#actual_events + 1] = { level = level, event = event }
        end,
    },
    executable = function()
        return 1
    end,
    notify = function() end,
    render = function(action, root, lines)
        return { action = action, root = root, line_count = #lines }
    end,
    root = function()
        return fixture
    end,
    schedule = vim.schedule,
    start = function()
        return fixture, fixture .. "/sample.txt"
    end,
    system = vim.system,
}

for name, action in pairs(actions) do
    local completed
    local started = action.fn({
        deps = actual_deps,
        line = 1,
        on_complete = function(result)
            completed = result
        end,
    })
    assert(started.outcome == "started", name .. " fixture action did not start")
    assert(
        vim.wait(7000, function()
            return completed ~= nil
        end, 10),
        name .. " fixture action timed out in the test"
    )
    assert(
        completed.outcome == "rendered" or completed.outcome == "empty",
        name .. " fixture action failed: " .. vim.inspect(completed)
    )
    assert_equal(snapshot(), before, name .. " mutated repository identity or bytes")
end

-- Exercise every retained view through the real renderer. These inputs used to
-- stage, restore, or check out content inside inherited Git pickers. Every view
-- must leave them unmapped and preserve the complete disposable repository.
for name, action in pairs(actions) do
    local ui_deps = {}
    for key, value in pairs(actual_deps) do
        if key ~= "render" then
            ui_deps[key] = value
        end
    end

    local completed
    action.fn({
        deps = ui_deps,
        line = 1,
        on_complete = function(result)
            completed = result
        end,
    })
    assert(
        vim.wait(7000, function()
            return completed ~= nil
        end, 10),
        name .. " scratch-renderer fixture timed out"
    )
    assert(
        completed.outcome == "rendered" or completed.outcome == "empty",
        name .. " scratch-renderer fixture did not render"
    )

    local view = completed.view
    assert(view and vim.api.nvim_buf_is_valid(view.buffer), name .. " renderer did not return a valid buffer")
    assert(vim.bo[view.buffer].buftype == "nofile", "Git observation must use a scratch buffer")
    assert(vim.bo[view.buffer].readonly and not vim.bo[view.buffer].modifiable, "Git observation must be read-only")

    local local_maps = {}
    for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(view.buffer, "n")) do
        local_maps[mapping.lhs:lower()] = true
    end
    for _, lhs in ipairs({ "<tab>", "<c-r>", "<cr>" }) do
        assert(not local_maps[lhs], "Git observation retained a mutation-capable local mapping: " .. lhs)
    end

    for _, lhs in ipairs({ "<Tab>", "<C-r>", "<CR>" }) do
        assert(vim.api.nvim_win_is_valid(view.window), "Git observation window closed before input: " .. lhs)
        vim.api.nvim_set_current_win(view.window)
        vim.api.nvim_win_set_buf(view.window, view.buffer)
        vim.api.nvim_input(vim.api.nvim_replace_termcodes(lhs, true, false, true))
        vim.wait(50, function()
            return false
        end, 10)
        assert_equal(snapshot(), before, name .. " " .. lhs .. " input mutated repository identity or bytes")
    end

    vim.api.nvim_feedkeys("q", "xt", false)
    assert(
        vim.wait(500, function()
            return not vim.api.nvim_win_is_valid(view.window)
        end, 10),
        name .. " observation did not close through its real q mapping"
    )
end

assert(vim.tbl_isempty(before.locks), "fixture started with a Git lock file")
vim.fn.delete(fixture, "rf")

local action_source = table.concat(vim.fn.readfile(repo_root .. "/nvim/lua/config/actions/git.lua"), "\n")
local plugin_source = table.concat(vim.fn.readfile(repo_root .. "/nvim/lua/plugins/git.lua"), "\n")
assert(not action_source:find("vim.env.GIT_OPTIONAL_LOCKS", 1, true), "Git action leaked its env policy globally")
assert(not plugin_source:find("vim.env.GIT_OPTIONAL_LOCKS", 1, true), "Gitsigns leaked its env policy globally")

print("Git observation tests: OK")
