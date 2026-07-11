local M = {}

local function expanded(lhs)
    return lhs:gsub("<leader>", vim.g.mapleader or "\\")
end

local function feed(lhs)
    vim.v.errmsg = ""
    local ok, error_message = pcall(vim.api.nvim_feedkeys, vim.keycode(expanded(lhs)), "xt", false)
    return ok, error_message and tostring(error_message) or ""
end

local function regular_windows()
    local windows = {}
    for _, window in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.api.nvim_win_get_config(window).relative == "" then
            windows[#windows + 1] = window
        end
    end
    return windows
end

local function neo_window()
    for _, window in ipairs(vim.api.nvim_list_wins()) do
        local buffer = vim.api.nvim_win_get_buf(window)
        if vim.bo[buffer].filetype == "neo-tree" then
            return window
        end
    end
end

local function terminal_window()
    for _, window in ipairs(vim.api.nvim_list_wins()) do
        local buffer = vim.api.nvim_win_get_buf(window)
        if vim.bo[buffer].filetype == "snacks_terminal" and vim.bo[buffer].buftype == "terminal" then
            return window
        end
    end
end

local function active_picker()
    if not (_G.Snacks and Snacks.picker) then
        return nil
    end
    local ok, pickers = pcall(Snacks.picker.get, { tab = false })
    return ok and pickers and pickers[1] or nil
end

local function restore_window(window, buffer)
    if vim.api.nvim_win_is_valid(window) then
        vim.api.nvim_set_current_win(window)
        if vim.api.nvim_buf_is_valid(buffer) then
            vim.api.nvim_win_set_buf(window, buffer)
        end
        return true
    end
    return false
end

local function close_floats(except)
    for _, window in ipairs(vim.api.nvim_list_wins()) do
        if window ~= except and vim.api.nvim_win_get_config(window).relative ~= "" then
            pcall(vim.api.nvim_win_close, window, true)
        end
    end
end

local function close_picker_with_input(picker)
    if not picker or picker.closed then
        return false
    end
    local window = picker.input and picker.input.win and picker.input.win.win
    if window and vim.api.nvim_win_is_valid(window) then
        vim.api.nvim_set_current_win(window)
    end
    feed("<Esc>")
    local closed = vim.wait(500, function()
        return picker.closed == true
    end, 20)
    if not closed then
        feed("<Esc>")
        closed = vim.wait(1000, function()
            return picker.closed == true
        end, 20)
    end
    return closed
end

local function lsp_methods()
    local methods = {}
    local path = vim.env.CLARITY_FAKE_LSP_LOG
    if not path or vim.fn.filereadable(path) ~= 1 then
        return methods
    end
    for _, line in ipairs(vim.fn.readfile(path)) do
        local ok, message = pcall(vim.json.decode, line)
        if ok and type(message) == "table" and type(message.method) == "string" then
            methods[message.method] = true
        end
    end
    return methods
end

local function lsp_method_count(target)
    local count = 0
    local path = vim.env.CLARITY_FAKE_LSP_LOG
    if not path or vim.fn.filereadable(path) ~= 1 then
        return count
    end
    for _, line in ipairs(vim.fn.readfile(path)) do
        local ok, message = pcall(vim.json.decode, line)
        if ok and type(message) == "table" and message.method == target then
            count = count + 1
        end
    end
    return count
end

function M.run(external_actions)
    local catalog = require("config.actions.catalog")
    local original_window = vim.api.nvim_get_current_win()
    local original_buffer = vim.api.nvim_get_current_buf()
    local original_cwd = vim.uv.cwd()
    local original_cursor = vim.api.nvim_win_get_cursor(original_window)
    local original_ui_input = vim.ui.input
    local original_ui_select = vim.ui.select
    local original_wrap = vim.wo[original_window].wrap
    local original_foldmethod = vim.wo[original_window].foldmethod
    local original_foldenable = vim.wo[original_window].foldenable
    local original_foldlevel = vim.wo[original_window].foldlevel
    local original_quickfix = vim.fn.getqflist({ all = 1 })
    local project_root = LazyVim.root({ buf = original_buffer })
    local actions = {}
    local created_buffers = {}
    local diagnostic_namespaces = {}

    local function restore_quickfix()
        local what = {
            items = original_quickfix.items or {},
            title = original_quickfix.title or "",
            context = original_quickfix.context,
        }
        if type(original_quickfix.idx) == "number" and original_quickfix.idx > 0 then
            what.idx = original_quickfix.idx
        end
        vim.fn.setqflist({}, "r", what)
    end

    local function remember(buffer)
        created_buffers[#created_buffers + 1] = buffer
        return buffer
    end

    local function remember_diagnostic_namespace(name)
        local namespace = vim.api.nvim_create_namespace(name)
        diagnostic_namespaces[#diagnostic_namespaces + 1] = namespace
        return namespace
    end

    local function restore_buffer_state(lines, modified, cursor)
        vim.api.nvim_buf_set_lines(original_buffer, 0, -1, false, lines)
        vim.bo[original_buffer].modified = modified
        vim.api.nvim_win_set_cursor(original_window, cursor)
        return vim.deep_equal(vim.api.nvim_buf_get_lines(original_buffer, 0, -1, false), lines)
            and vim.bo[original_buffer].modified == modified
            and vim.deep_equal(vim.api.nvim_win_get_cursor(original_window), cursor)
    end

    local function cleanup()
        local picker = active_picker()
        if picker and not picker.closed then
            pcall(function()
                picker:close()
            end)
        end
        if package.loaded["neo-tree.command"] then
            pcall(require("neo-tree.command").execute, { action = "close" })
        end
        if _G.Snacks and Snacks.zen and Snacks.zen.win and Snacks.zen.win:valid() then
            pcall(function()
                Snacks.zen.win:close()
            end)
        end
        pcall(vim.cmd.cclose)
        vim.ui.input = original_ui_input
        vim.ui.select = original_ui_select
        restore_quickfix()
        for index = #diagnostic_namespaces, 1, -1 do
            vim.diagnostic.reset(diagnostic_namespaces[index])
            table.remove(diagnostic_namespaces, index)
        end
        restore_window(original_window, original_buffer)
        for _, window in ipairs(regular_windows()) do
            if window ~= original_window then
                pcall(vim.api.nvim_win_close, window, true)
            end
        end
        close_floats(original_window)
        restore_window(original_window, original_buffer)
        pcall(vim.api.nvim_win_set_cursor, original_window, original_cursor)
        vim.wo[original_window].wrap = original_wrap
        vim.wo[original_window].foldmethod = original_foldmethod
        vim.wo[original_window].foldenable = original_foldenable
        vim.wo[original_window].foldlevel = original_foldlevel
        pcall(vim.api.nvim_set_current_dir, original_cwd)
        for index = #created_buffers, 1, -1 do
            local buffer = created_buffers[index]
            if buffer ~= original_buffer and vim.api.nvim_buf_is_valid(buffer) then
                pcall(vim.api.nvim_buf_delete, buffer, { force = true })
            end
            table.remove(created_buffers, index)
        end
    end

    local function run(action_id, lhs, callback)
        cleanup()
        local mapping = vim.fn.maparg(lhs, "n", false, true)
        local mapped = type(mapping) == "table" and not vim.tbl_isempty(mapping)
        local ok, postcondition, restored, evidence = xpcall(callback, debug.traceback)
        if not ok then
            evidence = tostring(postcondition)
            postcondition = false
            restored = false
        end
        cleanup()
        actions[#actions + 1] = {
            action_id = action_id,
            lhs = lhs,
            mapped = mapped,
            input = ok,
            postcondition = postcondition == true,
            restored = restored == true,
            ok = mapped and ok and postcondition == true and restored == true,
            evidence = type(evidence) == "table" and evidence or { detail = tostring(evidence or "") },
        }
    end

    local function picker_case(lhs, expected_source, diagnostic_fixture)
        local namespace
        if diagnostic_fixture then
            namespace = remember_diagnostic_namespace("clarity_action_matrix_picker")
            vim.diagnostic.set(namespace, original_buffer, {
                {
                    lnum = 0,
                    col = 0,
                    severity = vim.diagnostic.severity.WARN,
                    message = "Clarity picker fixture",
                },
            })
        end
        restore_window(original_window, original_buffer)
        local sent, input_error = feed(lhs)
        local picker
        local opened = vim.wait(3000, function()
            picker = active_picker()
            return picker ~= nil and not picker.closed
        end, 20)
        local source = opened and picker.opts and picker.opts.source or nil
        local closed = opened and close_picker_with_input(picker)
        if namespace then
            vim.diagnostic.reset(namespace, original_buffer)
        end
        local restored = closed and restore_window(original_window, original_buffer)
        return sent and opened and source == expected_source,
            restored,
            {
                source = source,
                expected_source = expected_source,
                input_error = input_error,
            }
    end

    local function explorer_case(lhs, expected_root)
        restore_window(original_window, original_buffer)
        local sent, input_error = feed(lhs)
        local window
        local opened = vim.wait(3000, function()
            window = neo_window()
            return window ~= nil
        end, 20)
        local root
        local manager
        local semantic = false
        if opened then
            manager = require("neo-tree.sources.manager")
            vim.api.nvim_set_current_win(window)
            semantic = vim.wait(3000, function()
                local state = manager.get_state_for_window(window)
                root = state and state.path or nil
                return root ~= nil and vim.fs.normalize(root) == vim.fs.normalize(expected_root)
            end, 20)
            feed("q")
        end
        local closed = opened
            and vim.wait(1000, function()
                return not vim.api.nvim_win_is_valid(window)
            end, 20)
        local normalized = root and vim.fs.normalize(root) or nil
        local restored = closed and restore_window(original_window, original_buffer)
        return sent and opened and semantic,
            restored,
            {
                root_matches = normalized == vim.fs.normalize(expected_root),
                input_error = input_error,
            }
    end

    local function git_case(lhs, name)
        restore_window(original_window, original_buffer)
        local sent, input_error = feed(lhs)
        local expected = "clarity://git/" .. name
        local view
        local opened = vim.wait(7000, function()
            for _, window in ipairs(vim.api.nvim_list_wins()) do
                if vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(window)) == expected then
                    view = window
                    return true
                end
            end
            return false
        end, 20)
        local readonly = false
        if opened then
            local buffer = vim.api.nvim_win_get_buf(view)
            readonly = vim.bo[buffer].readonly and not vim.bo[buffer].modifiable
            vim.api.nvim_set_current_win(view)
            feed("q")
        end
        local closed = opened
            and vim.wait(1000, function()
                return not vim.api.nvim_win_is_valid(view)
            end, 20)
        local restored = closed and restore_window(original_window, original_buffer)
        return sent and opened and readonly, restored, { view = expected, input_error = input_error }
    end

    run("window.split_below", "<leader>-", function()
        local before = #regular_windows()
        local sent, input_error = feed("<leader>-")
        local opened = vim.wait(500, function()
            return #regular_windows() == before + 1
        end, 20)
        local direction = vim.fn.winlayout()[1]
        local split = vim.api.nvim_get_current_win()
        if split ~= original_window then
            pcall(vim.api.nvim_win_close, split, true)
        end
        return sent and opened and direction == "col",
            #regular_windows() == before,
            {
                direction = direction,
                input_error = input_error,
            }
    end)

    run("window.split_right", "<leader>|", function()
        local before = #regular_windows()
        local sent, input_error = feed("<leader>|")
        local opened = vim.wait(500, function()
            return #regular_windows() == before + 1
        end, 20)
        local direction = vim.fn.winlayout()[1]
        local split = vim.api.nvim_get_current_win()
        if split ~= original_window then
            pcall(vim.api.nvim_win_close, split, true)
        end
        return sent and opened and direction == "row",
            #regular_windows() == before,
            {
                direction = direction,
                input_error = input_error,
            }
    end)

    local cwd_fixture = vim.fs.joinpath(project_root, "lua")
    if vim.fn.isdirectory(cwd_fixture) ~= 1 then
        cwd_fixture = vim.fs.joinpath(vim.g.clarity_repo_root, "nvim", "lua")
    end
    vim.api.nvim_set_current_dir(cwd_fixture)
    run("explorer.cwd", "<leader>E", function()
        vim.api.nvim_set_current_dir(cwd_fixture)
        return explorer_case("<leader>E", cwd_fixture)
    end)
    run("explorer.root", "<leader>e", function()
        return explorer_case("<leader>e", project_root)
    end)

    if external_actions and external_actions["help.buffer_keymaps"] then
        actions[#actions + 1] = external_actions["help.buffer_keymaps"]
    else
        run("help.buffer_keymaps", "<leader>?", function()
            return false, false, { detail = "interactive driver evidence is required" }
        end)
    end

    run("buffer.delete", "<leader>bd", function()
        local scratch = remember(vim.api.nvim_create_buf(true, false))
        vim.api.nvim_buf_set_lines(scratch, 0, -1, false, { "delete fixture" })
        vim.bo[scratch].modified = false
        vim.api.nvim_win_set_buf(original_window, scratch)
        local sent, input_error = feed("<leader>bd")
        local deleted = vim.wait(1000, function()
            return not vim.api.nvim_buf_is_loaded(scratch) and not vim.bo[scratch].buflisted
        end, 20)

        local protected = remember(vim.api.nvim_create_buf(true, false))
        local protected_lines = { "modified fixture", "must survive cancel" }
        vim.api.nvim_buf_set_lines(protected, 0, -1, false, protected_lines)
        vim.bo[protected].modified = true
        vim.api.nvim_win_set_buf(original_window, protected)
        local original_confirm = vim.fn.confirm
        local confirm_seen = false
        vim.fn.confirm = function()
            confirm_seen = true
            return 3
        end
        local safety_ok, safety_sent, safety_error = xpcall(function()
            local input_sent, error_message = feed("<leader>bd")
            return input_sent, error_message
        end, debug.traceback)
        vim.fn.confirm = original_confirm
        if not safety_ok then
            error(safety_sent)
        end
        local modified_preserved = vim.api.nvim_buf_is_loaded(protected)
            and vim.bo[protected].buflisted
            and vim.bo[protected].modified
            and vim.deep_equal(vim.api.nvim_buf_get_lines(protected, 0, -1, false), protected_lines)
        return sent and deleted and safety_sent and confirm_seen and modified_preserved,
            restore_window(original_window, original_buffer),
            {
                input_error = input_error,
                safety_error = safety_error,
                modified_confirm_seen = confirm_seen,
                modified_preserved = modified_preserved,
            }
    end)

    run("code.format", "<leader>cf", function()
        local log = vim.env.CLARITY_FAKE_FORMATTER_LOG
        if log then
            vim.fn.delete(log)
        end
        local buffer = remember(vim.api.nvim_create_buf(true, false))
        vim.api.nvim_buf_set_name(
            buffer,
            vim.fs.joinpath(vim.g.clarity_repo_root, "tests", "fixtures", "runtime", "format-project", "matrix.lua")
        )
        vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "local matrix = {", "    value = 1,", "}" })
        vim.bo[buffer].filetype = "lua"
        vim.api.nvim_win_set_buf(original_window, buffer)
        local sent, input_error = feed("<leader>cf")
        local invoked = log
            and vim.wait(3000, function()
                return vim.fn.filereadable(log) == 1
            end, 20)
        local changed = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)[2] == "  value = 1,"
        return sent and invoked and changed,
            restore_window(original_window, original_buffer),
            {
                formatter_invoked = invoked == true,
                input_error = input_error,
            }
    end)

    run("code.fold_toggle", "<leader>cz", function()
        local buffer = remember(vim.api.nvim_create_buf(false, false))
        vim.api.nvim_win_set_buf(original_window, buffer)
        vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "if true then", "  print(1)", "end", "print(2)" })
        vim.wo.foldmethod = "manual"
        vim.wo.foldenable = true
        vim.wo.foldlevel = 0
        vim.cmd("1,3fold")
        vim.api.nvim_win_set_cursor(original_window, { 1, 0 })
        local initially_closed = vim.fn.foldclosed(1) == 1
        local first_sent = feed("<leader>cz")
        local opened = vim.wait(500, function()
            return vim.fn.foldclosed(1) == -1
        end, 20)
        local second_sent = feed("<leader>cz")
        local reclosed = vim.wait(500, function()
            return vim.fn.foldclosed(1) == 1
        end, 20)
        return initially_closed and first_sent and opened and second_sent and reclosed,
            restore_window(original_window, original_buffer),
            { initially_closed = initially_closed }
    end)

    run("files.new", "<leader>fn", function()
        restore_window(original_window, original_buffer)
        local sent, input_error = feed("<leader>fn")
        local buffer = vim.api.nvim_get_current_buf()
        local created = buffer ~= original_buffer
            and vim.api.nvim_buf_get_name(buffer) == ""
            and vim.api.nvim_buf_line_count(buffer) == 1
        if created then
            remember(buffer)
        end
        return sent and created, restore_window(original_window, original_buffer), { input_error = input_error }
    end)

    for _, spec in ipairs({
        { "buffer.find", "<leader>fb", "buffers" },
        { "files.find", "<leader>ff", "files" },
        { "files.recent", "<leader>fr", "recent" },
        { "search.project_text", "<leader>fw", "grep" },
    }) do
        run(spec[1], spec[2], function()
            return picker_case(spec[2], spec[3], false)
        end)
    end

    for _, spec in ipairs({
        { "git.blame_line", "<leader>gb", "blame_line" },
        { "git.diff", "<leader>gd", "diff" },
        { "git.log", "<leader>gl", "log" },
        { "git.status", "<leader>gs", "status" },
        { "git.branch_graph", "<leader>gt", "branch_graph" },
    }) do
        run(spec[1], spec[2], function()
            return git_case(spec[2], spec[3])
        end)
    end

    run("health.open", "<leader>hh", function()
        local sent, input_error = feed("<leader>hh")
        local buffer
        local opened = vim.wait(2000, function()
            buffer = vim.api.nvim_get_current_buf()
            return vim.api.nvim_buf_get_name(buffer) == "clarity://health"
        end, 20)
        local readonly = opened and vim.bo[buffer].readonly and not vim.bo[buffer].modifiable
        feed("q")
        local closed = opened
            and vim.wait(1000, function()
                return vim.api.nvim_get_current_buf() ~= buffer
            end, 20)
        return sent and opened and readonly,
            closed and restore_window(original_window, original_buffer),
            {
                input_error = input_error,
            }
    end)

    run("diagnostics.list", "<leader>sd", function()
        return picker_case("<leader>sd", "diagnostics", true)
    end)
    run("help.keymaps", "<leader>sk", function()
        return picker_case("<leader>sk", "keymaps", false)
    end)

    run("terminal.float", "<leader>tf", function()
        local sent, input_error = feed("<leader>tf")
        local window
        local opened = vim.wait(3000, function()
            window = terminal_window()
            return window ~= nil
        end, 20)
        local floating = opened and vim.api.nvim_win_get_config(window).relative ~= ""
        local channel_info = {}
        local shell_matches = false
        local environment_isolated = false
        if opened then
            local terminal_buffer = vim.api.nvim_win_get_buf(window)
            channel_info = vim.api.nvim_get_chan_info(vim.bo[terminal_buffer].channel)
            local argv = channel_info.argv or {}
            shell_matches = argv[1] ~= nil and vim.fs.normalize(argv[1]) == vim.fs.normalize(vim.env.SHELL)
            local runtime_root = vim.env.CLARITY_ACTION_MATRIX_RUNTIME_ROOT
            local expected_home = runtime_root and vim.fs.joinpath(runtime_root, "home") or nil
            environment_isolated = expected_home ~= nil
                and vim.fs.normalize(vim.env.HOME) == vim.fs.normalize(expected_home)
                and vim.fs.normalize(vim.env.USERPROFILE) == vim.fs.normalize(expected_home)
                and vim.fs.normalize(vim.env.ZDOTDIR) == vim.fs.normalize(expected_home)
            vim.api.nvim_set_current_win(window)
            vim.cmd.stopinsert()
            feed("<leader>tf")
        end
        local closed = opened
            and vim.wait(1000, function()
                return not vim.api.nvim_win_is_valid(window)
            end, 20)
        return sent and opened and floating and shell_matches and environment_isolated,
            closed and restore_window(original_window, original_buffer),
            {
                input_error = input_error,
                shell_matches = shell_matches,
                environment_isolated = environment_isolated,
            }
    end)

    run("view.wrap_toggle", "<leader>uw", function()
        restore_window(original_window, original_buffer)
        local before = vim.wo.wrap
        local first_sent, input_error = feed("<leader>uw")
        local changed = vim.wo.wrap ~= before
        local second_sent = feed("<leader>uw")
        return first_sent and changed and second_sent, vim.wo.wrap == before, { input_error = input_error }
    end)

    run("window.close", "<leader>wd", function()
        vim.cmd.vsplit()
        local target = vim.api.nvim_get_current_win()
        local sent, input_error = feed("<leader>wd")
        local closed = vim.wait(500, function()
            return not vim.api.nvim_win_is_valid(target)
        end, 20)
        return sent and closed, restore_window(original_window, original_buffer), { input_error = input_error }
    end)

    run("window.zoom_toggle", "<leader>wm", function()
        local first_sent, input_error = feed("<leader>wm")
        local opened = vim.wait(1000, function()
            return Snacks.zen.win and Snacks.zen.win:valid()
        end, 20)
        local second_sent = feed("<leader>wm")
        local closed = vim.wait(1000, function()
            return not (Snacks.zen.win and Snacks.zen.win:valid())
        end, 20)
        return first_sent and opened and second_sent,
            closed and restore_window(original_window, original_buffer),
            {
                input_error = input_error,
            }
    end)

    run("window.only", "<leader>wo", function()
        vim.cmd.split()
        vim.cmd.vsplit()
        vim.api.nvim_set_current_win(original_window)
        local sent, input_error = feed("<leader>wo")
        local only = vim.wait(500, function()
            return #regular_windows() == 1
        end, 20)
        return sent and only, only and restore_window(original_window, original_buffer), { input_error = input_error }
    end)

    run("list.quickfix_toggle", "<leader>xq", function()
        vim.fn.setqflist({}, "r", {
            title = "Clarity action matrix",
            items = { { filename = vim.api.nvim_buf_get_name(original_buffer), lnum = 1, text = "fixture" } },
        })
        local sent, input_error = feed("<leader>xq")
        local window
        local opened = vim.wait(1000, function()
            window = vim.fn.getqflist({ winid = 0 }).winid
            return window ~= 0
        end, 20)
        feed("<leader>xq")
        local closed = opened
            and vim.wait(1000, function()
                return vim.fn.getqflist({ winid = 0 }).winid == 0
            end, 20)
        restore_quickfix()
        local restored_quickfix = vim.fn.getqflist({ items = 1, title = 1, context = 1 })
        local restored_list = vim.deep_equal(restored_quickfix.items, original_quickfix.items or {})
            and restored_quickfix.title == (original_quickfix.title or "")
            and vim.deep_equal(restored_quickfix.context, original_quickfix.context)
        return sent and opened,
            closed and restored_list and restore_window(original_window, original_buffer),
            {
                input_error = input_error,
            }
    end)

    cleanup()
    local contextual = {}
    local function contextual_result(action_id, lhs, callback)
        cleanup()
        restore_window(original_window, original_buffer)
        local mapping = vim.fn.maparg(lhs, "n", false, true)
        local mapped = type(mapping) == "table" and not vim.tbl_isempty(mapping) and mapping.buffer == 1
        local ok, passed, restored, evidence = xpcall(callback, debug.traceback)
        contextual[#contextual + 1] = {
            action_id = action_id,
            mapped = mapped,
            input = ok,
            lhs = lhs,
            ok = mapped and ok and passed == true and restored == true,
            postcondition = ok and passed == true,
            restored = ok and restored == true,
            evidence = type(evidence) == "table" and evidence or { detail = tostring(evidence or passed or "") },
        }
        cleanup()
    end

    contextual_result("format.auto_buffer_toggle", "<leader>uF", function()
        local before_raw = vim.b[original_buffer].autoformat
        local before = LazyVim.format.enabled(original_buffer)
        local first_sent, input_error = feed("<leader>uF")
        local changed = vim.wait(500, function()
            return LazyVim.format.enabled(original_buffer) ~= before
        end, 20)
        local second_sent = feed("<leader>uF")
        local restored = vim.wait(500, function()
            return LazyVim.format.enabled(original_buffer) == before
        end, 20)
        vim.b[original_buffer].autoformat = before_raw
        return first_sent and changed and second_sent,
            restored and restore_window(original_window, original_buffer),
            {
                input_error = input_error,
            }
    end)

    contextual_result("lsp.inlay_hints_toggle", "<leader>uh", function()
        local filter = { bufnr = original_buffer }
        local before = vim.lsp.inlay_hint.is_enabled(filter)
        local first_sent, input_error = feed("<leader>uh")
        local changed = vim.wait(1000, function()
            return vim.lsp.inlay_hint.is_enabled(filter) ~= before
        end, 20)
        local second_sent = feed("<leader>uh")
        local restored = vim.wait(1000, function()
            return vim.lsp.inlay_hint.is_enabled(filter) == before
        end, 20)
        return first_sent and changed and second_sent,
            restored and restore_window(original_window, original_buffer),
            {
                input_error = input_error,
            }
    end)

    contextual_result("lsp.code_action", "<leader>ca", function()
        local method = "textDocument/codeAction"
        local before = lsp_method_count(method)
        local before_lines = vim.api.nvim_buf_get_lines(original_buffer, 0, -1, false)
        local before_modified = vim.bo[original_buffer].modified
        local before_cursor = vim.api.nvim_win_get_cursor(original_window)
        vim.api.nvim_win_set_cursor(original_window, { 1, 6 })
        local select_seen = false
        local action_selected = false
        local select_kind
        vim.ui.select = function(items, opts, on_choice)
            select_seen = true
            select_kind = opts and opts.kind or nil
            local choice
            local choice_index
            for index, item in ipairs(items) do
                local action = item.action or item
                if action.title == "Clarity fixture code action" then
                    choice = item
                    choice_index = index
                    break
                end
            end
            action_selected = choice ~= nil
            vim.schedule(function()
                on_choice(choice, choice_index)
            end)
        end
        local ok, sent, input_error, reached, changed = xpcall(function()
            local input_sent, error_message = feed("<leader>ca")
            local method_reached = vim.wait(2000, function()
                return lsp_method_count(method) > before
            end, 20)
            local buffer_changed = vim.wait(2000, function()
                return vim.api
                    .nvim_buf_get_lines(original_buffer, 0, 1, false)[1]
                    :find("local clarity_action_applied = ", 1, true) == 1
            end, 20)
            return input_sent, error_message, method_reached, buffer_changed
        end, debug.traceback)
        vim.ui.select = original_ui_select
        local restored_state = restore_buffer_state(before_lines, before_modified, before_cursor)
        if not ok then
            error(sent)
        end
        return sent and reached and select_seen and action_selected and changed,
            restored_state and restore_window(original_window, original_buffer),
            {
                input_error = input_error,
                method = method,
                select_seen = select_seen,
                select_kind = select_kind,
                action_selected = action_selected,
                buffer_changed = changed,
                buffer_restored = restored_state,
            }
    end)

    contextual_result("lsp.rename_symbol", "<leader>cr", function()
        local method = "textDocument/rename"
        local before = lsp_method_count(method)
        local before_lines = vim.api.nvim_buf_get_lines(original_buffer, 0, -1, false)
        local before_modified = vim.bo[original_buffer].modified
        local before_cursor = vim.api.nvim_win_get_cursor(original_window)
        vim.api.nvim_win_set_cursor(original_window, { 1, 6 })
        local prompt_seen = false
        local prompt_default
        vim.ui.input = function(opts, on_confirm)
            prompt_seen = true
            prompt_default = opts and opts.default or nil
            vim.schedule(function()
                on_confirm("clarity_fixture_renamed")
            end)
        end
        local ok, sent, input_error, reached, changed = xpcall(function()
            local input_sent, error_message = feed("<leader>cr")
            local method_reached = vim.wait(2000, function()
                return lsp_method_count(method) > before
            end, 20)
            local buffer_changed = vim.wait(2000, function()
                return vim.api
                    .nvim_buf_get_lines(original_buffer, 0, 1, false)[1]
                    :find("local clarity_fixture_renamed = ", 1, true) == 1
            end, 20)
            return input_sent, error_message, method_reached, buffer_changed
        end, debug.traceback)
        vim.ui.input = original_ui_input
        local restored_state = restore_buffer_state(before_lines, before_modified, before_cursor)
        if not ok then
            error(sent)
        end
        return sent and prompt_seen and prompt_default == "message" and reached and changed,
            restored_state and restore_window(original_window, original_buffer),
            {
                input_error = input_error,
                method = method,
                prompt_seen = prompt_seen,
                prompt_default = prompt_default,
                buffer_changed = changed,
                buffer_restored = restored_state,
            }
    end)

    contextual_result("lsp.document_symbols", "<leader>ss", function()
        local method = "textDocument/documentSymbol"
        local before = lsp_method_count(method)
        local passed, restored, evidence = picker_case("<leader>ss", "lsp_symbols", false)
        local reached = vim.wait(1000, function()
            return lsp_method_count(method) > before
        end, 20)
        evidence.method = method
        return passed and reached, restored, evidence
    end)

    contextual_result("lsp.workspace_symbols", "<leader>sS", function()
        local method = "workspace/symbol"
        local before = lsp_method_count(method)
        local passed, restored, evidence = picker_case("<leader>sS", "lsp_workspace_symbols", false)
        local reached = vim.wait(1000, function()
            return lsp_method_count(method) > before
        end, 20)
        evidence.method = method
        return passed and reached, restored, evidence
    end)

    contextual_result("git.hunk_preview", "<leader>ghp", function()
        local preview = require("gitsigns.actions.preview")
        local original_cursor = vim.api.nvim_win_get_cursor(original_window)
        local last_line = vim.api.nvim_buf_line_count(original_buffer)
        vim.api.nvim_win_set_cursor(original_window, { last_line, 0 })
        local sent, input_error = feed("<leader>ghp")
        local opened = vim.wait(2000, function()
            return preview.has_preview_inline(original_buffer)
        end, 20)
        local cleanup_buffer = remember(vim.api.nvim_create_buf(false, true))
        vim.api.nvim_win_set_buf(original_window, cleanup_buffer)
        local closed = vim.wait(1000, function()
            return not preview.has_preview_inline(original_buffer)
        end, 20)
        vim.api.nvim_win_set_buf(original_window, original_buffer)
        vim.api.nvim_win_set_cursor(original_window, original_cursor)
        return sent and opened,
            closed and restore_window(original_window, original_buffer),
            {
                input_error = input_error,
            }
    end)

    cleanup()
    local extras = {}
    local function extra_result(id, lhs, callback)
        cleanup()
        local ok, passed, restored, evidence = xpcall(callback, debug.traceback)
        extras[#extras + 1] = {
            id = id,
            lhs = lhs,
            ok = ok and passed == true and restored == true,
            postcondition = ok and passed == true,
            restored = ok and restored == true,
            evidence = type(evidence) == "table" and evidence or { detail = tostring(evidence or passed or "") },
        }
        cleanup()
    end

    extra_result("lsp.definition", "gd", function()
        restore_window(original_window, original_buffer)
        local sent, input_error = feed("gd")
        local picker
        local opened = vim.wait(3000, function()
            picker = active_picker()
            return picker ~= nil and not picker.closed
        end, 20)
        local method = vim.wait(1000, function()
            return lsp_methods()["textDocument/definition"] == true
        end, 20)
        local source = opened and picker.opts and picker.opts.source or nil
        local closed = opened and close_picker_with_input(picker)
        return sent and opened and method and source == "lsp_definitions",
            closed and restore_window(original_window, original_buffer),
            {
                input_error = input_error,
                method = "textDocument/definition",
                source = source,
                expected_source = "lsp_definitions",
            }
    end)

    extra_result("lsp.references", "gr", function()
        restore_window(original_window, original_buffer)
        local sent, input_error = feed("gr")
        local picker
        local opened = vim.wait(3000, function()
            picker = active_picker()
            return picker ~= nil and not picker.closed
        end, 20)
        local method = vim.wait(1000, function()
            return lsp_methods()["textDocument/references"] == true
        end, 20)
        local source = opened and picker.opts and picker.opts.source or nil
        local closed = opened and close_picker_with_input(picker)
        return sent and opened and method and source == "lsp_references",
            closed and restore_window(original_window, original_buffer),
            {
                input_error = input_error,
                method = "textDocument/references",
                source = source,
                expected_source = "lsp_references",
            }
    end)

    extra_result("lsp.hover", "K", function()
        restore_window(original_window, original_buffer)
        local sent, input_error = feed("K")
        local hover_window
        local opened = vim.wait(3000, function()
            for _, window in ipairs(vim.api.nvim_list_wins()) do
                if vim.api.nvim_win_get_config(window).relative ~= "" then
                    local buffer = vim.api.nvim_win_get_buf(window)
                    local text = table.concat(vim.api.nvim_buf_get_lines(buffer, 0, -1, false), "\n")
                    if text:find("Clarity fixture hover", 1, true) then
                        hover_window = window
                        return true
                    end
                end
            end
            return false
        end, 20)
        local method = lsp_methods()["textDocument/hover"] == true
        if hover_window and vim.api.nvim_win_is_valid(hover_window) then
            vim.api.nvim_win_close(hover_window, true)
        end
        return sent and opened and method,
            restore_window(original_window, original_buffer),
            {
                input_error = input_error,
                method = "textDocument/hover",
            }
    end)

    extra_result("diagnostic.next_previous", "]d|[d", function()
        restore_window(original_window, original_buffer)
        local namespace = remember_diagnostic_namespace("clarity_action_matrix_navigation")
        vim.diagnostic.set(namespace, original_buffer, {
            { lnum = 0, col = 0, severity = vim.diagnostic.severity.WARN, message = "first fixture" },
            { lnum = 3, col = 0, severity = vim.diagnostic.severity.ERROR, message = "second fixture" },
        })
        vim.api.nvim_win_set_cursor(original_window, { 2, 0 })
        local next_sent, next_error = feed("]d")
        local next_ok = vim.wait(1000, function()
            return vim.api.nvim_win_get_cursor(original_window)[1] == 4
        end, 20)
        close_floats(original_window)
        local previous_sent, previous_error = feed("[d")
        local previous_ok = vim.wait(1000, function()
            return vim.api.nvim_win_get_cursor(original_window)[1] == 1
        end, 20)
        vim.diagnostic.reset(namespace, original_buffer)
        close_floats(original_window)
        return next_sent and next_ok and previous_sent and previous_ok,
            restore_window(original_window, original_buffer),
            { next_error = next_error, previous_error = previous_error }
    end)

    local cleanup_probe_namespace = remember_diagnostic_namespace("clarity_action_matrix_cleanup_probe")
    local callback_ok = xpcall(function()
        vim.diagnostic.set(cleanup_probe_namespace, original_buffer, {
            { lnum = 0, col = 0, severity = vim.diagnostic.severity.ERROR, message = "cleanup probe" },
        })
        vim.fn.setqflist({}, "r", {
            title = "Clarity poisoned quickfix",
            items = { { filename = vim.api.nvim_buf_get_name(original_buffer), lnum = 1, text = "poison" } },
        })
        vim.ui.input = function() end
        vim.ui.select = function() end
        if vim.api.nvim_buf_line_count(original_buffer) > 1 then
            vim.api.nvim_win_set_cursor(original_window, { 2, 0 })
        end
        error("injected cleanup failure")
    end, debug.traceback)
    cleanup()
    local cleanup_quickfix = vim.fn.getqflist({ items = 1, title = 1, context = 1 })
    local cleanup_recovery = {
        injected_failure = not callback_ok,
        diagnostics_cleared = #vim.diagnostic.get(original_buffer, { namespace = cleanup_probe_namespace }) == 0,
        quickfix_restored = vim.deep_equal(cleanup_quickfix.items, original_quickfix.items or {})
            and cleanup_quickfix.title == (original_quickfix.title or "")
            and vim.deep_equal(cleanup_quickfix.context, original_quickfix.context),
        cursor_restored = vim.deep_equal(vim.api.nvim_win_get_cursor(original_window), original_cursor),
        ui_restored = vim.ui.input == original_ui_input and vim.ui.select == original_ui_select,
    }
    cleanup_recovery.ok = cleanup_recovery.injected_failure
        and cleanup_recovery.diagnostics_cleared
        and cleanup_recovery.quickfix_restored
        and cleanup_recovery.cursor_restored
        and cleanup_recovery.ui_restored
    local expected = catalog.global_normal_manifest()
    local expected_global = vim.tbl_map(function(binding)
        return { action_id = binding.action_id, lhs = binding.lhs }
    end, catalog.bindings({ visibility = "global", mode = "n" }))
    local expected_contextual = vim.tbl_map(function(binding)
        return { action_id = binding.action_id, lhs = binding.lhs }
    end, catalog.bindings({ visibility = "dynamic", mode = "n" }))
    local actual = vim.tbl_map(function(action)
        return action.lhs
    end, actions)
    table.sort(actual)
    return {
        schema_version = 1,
        actions = actions,
        contextual = contextual,
        extras = extras,
        expected_manifest = expected,
        expected_global_manifest = expected_global,
        expected_contextual_manifest = expected_contextual,
        actual_manifest = actual,
        non_session_count = #actions,
        cleanup_recovery = cleanup_recovery,
    }
end

return M
