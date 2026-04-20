local M = {}

local state = {
  buf = nil,
  win = nil,
}

local STARTUP_GUIDE_VERSION = "2026-04-20-startup-guide-v1"

local function repo_root()
  if type(vim.g.clarity_repo_root) == "string" and vim.g.clarity_repo_root ~= "" then
    return vim.g.clarity_repo_root
  end

  return vim.fn.getcwd()
end

local function is_interactive()
  return vim.env.CLARITY_NONINTERACTIVE ~= "1" and #vim.api.nvim_list_uis() > 0
end

local function startup_state_path()
  return vim.fn.stdpath "state" .. "/clarity_startup_guide_version.txt"
end

local function read_startup_state()
  local path = startup_state_path()
  if vim.fn.filereadable(path) ~= 1 then
    return nil
  end

  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok or type(lines) ~= "table" or #lines == 0 then
    return nil
  end

  return lines[1]
end

local function mark_startup_seen()
  local path = startup_state_path()
  local dir = vim.fn.fnamemodify(path, ":h")
  pcall(vim.fn.mkdir, dir, "p")
  pcall(vim.fn.writefile, { STARTUP_GUIDE_VERSION }, path)
end

local function startup_buffer_ready()
  if not is_interactive() or vim.fn.argc() ~= 0 or vim.o.diff then
    return false
  end

  local buf = vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(buf) then
    return false
  end

  if vim.api.nvim_buf_get_name(buf) ~= "" or vim.bo[buf].modified or vim.bo[buf].buftype ~= "" then
    return false
  end

  return true
end

local function should_show_startup_guide()
  return startup_buffer_ready() and read_startup_state() ~= STARTUP_GUIDE_VERSION
end

local function platform_label()
  local uname = vim.loop.os_uname()
  local sysname = uname.sysname

  if sysname == "Linux" and vim.fn.has "wsl" == 1 then
    sysname = "WSL"
  end

  return string.format("%s %s", sysname, uname.release)
end

local function short_repo_root()
  return vim.fn.fnamemodify(repo_root(), ":~")
end

local function clipboard_provider()
  local ok, provider = pcall(function()
    return vim.fn["provider#clipboard#Executable"]()
  end)

  if not ok or not provider or provider == "" then
    return "missing"
  end

  return provider
end

local function option_contains(option_value, expected)
  if type(option_value) == "string" then
    if option_value == "" then
      return false
    end

    return option_value == expected
  end

  return vim.tbl_contains(option_value or {}, expected)
end

local function clipboard_mode()
  local entries = vim.opt.clipboard:get()
  return option_contains(entries, "unnamedplus") and "unnamedplus" or "manual"
end

local function close_panel()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end

  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    vim.api.nvim_buf_delete(state.buf, { force = true })
  end

  state.win = nil
  state.buf = nil
end

local function run_after_close(action)
  close_panel()
  vim.schedule(action)
end

local function feedkeys(keys)
  local termcodes = vim.api.nvim_replace_termcodes(keys, true, false, true)
  vim.api.nvim_feedkeys(termcodes, "mt", false)
end

local function open_float(lines, title)
  close_panel()

  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.min(math.max(84, vim.o.columns - 12), 110)
  local height = math.min(#lines + 2, math.max(18, vim.o.lines - 6))
  local row = math.max(1, math.floor((vim.o.lines - height) / 2) - 1)
  local col = math.max(2, math.floor((vim.o.columns - width) / 2))

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    style = "minimal",
    border = "rounded",
    title = title,
    title_pos = "center",
    width = width,
    height = height,
    row = row,
    col = col,
  })

  state.buf = buf
  state.win = win

  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].modifiable = true

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  vim.bo[buf].modifiable = false
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].cursorline = false
  vim.wo[win].wrap = false
  vim.wo[win].conceallevel = 0

  local function map(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { buffer = buf, nowait = true, silent = true, desc = desc })
  end

  map("q", close_panel, "Close Clarity help")
  map("<Esc>", close_panel, "Close Clarity help")

  return buf
end

local function show_clipboard_help()
  local provider = clipboard_provider()
  local mode = clipboard_mode()
  local lines = {
    "# Clarity Clipboard Help",
    "",
    string.format("- Current clipboard mode: `%s`", mode),
    string.format("- Current clipboard provider: `%s`", provider),
    "",
    "## Three different copy paths",
    "",
    "1. Terminal copy",
    "   Use mouse selection in Windows Terminal, then press `Ctrl + Shift + C`.",
    "",
    "2. Neovim copy inside the editor",
    "   Use `y`, `yy`, `p`, `P` for normal yank and paste behavior.",
    "",
    "3. Force the system clipboard",
    "   Use `\"+y`, `\"+yy`, `\"+p`, or `:%y+` when you want to be explicit.",
    "",
    "## What this config does",
    "",
    "- `clipboard=unnamedplus` is enabled, so normal yanks usually target the system clipboard when the provider is healthy.",
    "- If copy or paste feels wrong, run `:ClarityAudit` and check the clipboard provider line first.",
    "",
    "## Windows + WSL practical rule",
    "",
    "- Copy from Neovim to Windows apps: yank text normally, or force with `\"+y`.",
    "- Paste from Windows into Neovim running in the terminal: use `Ctrl + Shift + V`.",
    "- `Ctrl + Shift + C` copies terminal selection, not an internal Neovim visual selection by itself.",
    "",
    "## Recovery",
    "",
    "- `a` run `:ClarityAudit`",
    "- `h` return to `:ClarityStart`",
    "- `q` close this panel",
  }

  local buf = open_float(lines, " Clarity Clipboard ")

  vim.keymap.set("n", "a", function()
    run_after_close(function()
      vim.cmd "ClarityAudit"
    end)
  end, { buffer = buf, nowait = true, silent = true, desc = "Run ClarityAudit" })

  vim.keymap.set("n", "h", function()
    run_after_close(function()
      vim.cmd "ClarityStart"
    end)
  end, { buffer = buf, nowait = true, silent = true, desc = "Return to ClarityStart" })
end

local function show_sync_help()
  local uname = vim.loop.os_uname()
  local platform = string.format("%s %s", uname.sysname, uname.release)
  local current_repo = repo_root()
  local repo_note = uname.sysname == "Windows_NT"
      and "- You are currently on Windows. This is the recommended source-of-truth editing environment."
    or "- You are currently on Linux/WSL. Treat this clone as a runtime mirror unless your team decides otherwise."

  local lines = {
    "# Clarity Sync Workflow",
    "",
    string.format("- Current platform: `%s`", platform),
    string.format("- Current repo: `%s`", current_repo),
    repo_note,
    "",
    "## Official rule for this project",
    "",
    "1. Keep one canonical repo that owns edits, commits, and pushes.",
    "2. For the current team workflow, Windows is the source-of-truth workspace.",
    "3. If you also run Neovim inside WSL, treat the WSL clone as the runtime mirror.",
    "",
    "## Recommended update flow",
    "",
    "1. Edit, test, commit, and push from the Windows repo.",
    "2. In WSL, run `git pull --ff-only` inside the mirror clone.",
    "3. Restart Neovim after pulling when behavior still looks stale.",
    "",
    "## If the editor still behaves like an old version",
    "",
    "- Run `:ClarityAudit`.",
    "- Compare `git rev-parse --short HEAD` in Windows and WSL.",
    "- Reopen Neovim after the pull completes.",
    "",
    "## Recovery",
    "",
    "- `a` run `:ClarityAudit`",
    "- `h` return to `:ClarityStart`",
    "- `q` close this panel",
  }

  local buf = open_float(lines, " Clarity Sync ")

  vim.keymap.set("n", "a", function()
    run_after_close(function()
      vim.cmd "ClarityAudit"
    end)
  end, { buffer = buf, nowait = true, silent = true, desc = "Run ClarityAudit" })

  vim.keymap.set("n", "h", function()
    run_after_close(function()
      vim.cmd "ClarityStart"
    end)
  end, { buffer = buf, nowait = true, silent = true, desc = "Return to ClarityStart" })
end

local function show_start(opts)
  opts = opts or {}

  local intro = opts.auto_open
      and "This guide opened automatically because this is your first empty startup with the current onboarding version."
    or "Use this panel whenever you forget the safest next step."
  local lines = {
    "# Clarity Start",
    "",
    intro,
    "Reopen any time with `:ClarityStart` or `<leader>hh`.",
    "",
    string.format("- Platform: `%s`", platform_label()),
    string.format("- Clipboard provider: `%s`", clipboard_provider()),
    string.format("- Repo root: `%s`", short_repo_root()),
    "",
    "## Start with these 10 actions",
    "",
    "1. `Space` then pause -> open the command menu",
    "2. `f` Find files -> `<leader>ff`",
    "3. `w` Search project text -> `<leader>fw`",
    "4. `e` Toggle explorer -> `<leader>e`",
    "5. `b` Switch open buffers -> `<leader>fb`",
    "6. `t` Open the floating terminal -> `<leader>tf`",
    "7. `gd` in code -> jump to definition",
    "8. `gl` in code -> explain the current line diagnostic",
    "9. `<leader>cf` -> format the current file",
    "10. `<leader>cr` -> rename the current symbol",
    "",
    "## Recovery if something feels wrong",
    "",
    "- `k` Search keymaps -> `<leader>sk`",
    "- `a` Run `:ClarityAudit` for environment health",
    "- `v` Run `:ClarityValidate` for behavior checks",
    "- `c` Open clipboard help for Windows + WSL",
    "- `s` Open repo sync help",
    "",
    "## If search looks stale or broken",
    "",
    "- This config expects the Snacks picker, not Telescope.",
    "- If `<leader>ff` or `<leader>fw` mention Telescope, pull the latest repo and open `:ClaritySync`.",
    "",
    "## Close",
    "",
    "- `q` or `Esc` close this panel",
  }

  local buf = open_float(lines, opts.auto_open and " Clarity First Start " or " Clarity Start ")

  local actions = {
    f = function()
      run_after_close(function()
        require("lazyvim.util.pick").open("files")
      end)
    end,
    w = function()
      run_after_close(function()
        require("lazyvim.util.pick").open("live_grep")
      end)
    end,
    e = function()
      run_after_close(function()
        vim.cmd("Neotree toggle " .. vim.fn.getcwd())
      end)
    end,
    b = function()
      run_after_close(function()
        require("lazyvim.util.pick").open("buffers")
      end)
    end,
    t = function()
      run_after_close(function()
        feedkeys("<leader>tf")
      end)
    end,
    k = function()
      run_after_close(function()
        feedkeys("<leader>sk")
      end)
    end,
    a = function()
      run_after_close(function()
        vim.cmd "ClarityAudit"
      end)
    end,
    v = function()
      run_after_close(function()
        vim.cmd "ClarityValidate"
      end)
    end,
    c = show_clipboard_help,
    s = show_sync_help,
  }

  for lhs, action in pairs(actions) do
    vim.keymap.set("n", lhs, action, {
      buffer = buf,
      nowait = true,
      silent = true,
      desc = "ClarityStart action",
    })
  end
end

function M.setup()
  if vim.fn.exists(":ClarityStart") ~= 2 then
    vim.api.nvim_create_user_command("ClarityStart", show_start, {
      desc = "Open the Clarity in-editor onboarding panel",
    })
  end

  if vim.fn.exists(":ClarityClipboard") ~= 2 then
    vim.api.nvim_create_user_command("ClarityClipboard", show_clipboard_help, {
      desc = "Open clipboard help for Windows and WSL workflows",
    })
  end

  if vim.fn.exists(":ClaritySync") ~= 2 then
    vim.api.nvim_create_user_command("ClaritySync", show_sync_help, {
      desc = "Open source-of-truth and repo sync guidance",
    })
  end

  vim.keymap.set("n", "<leader>hh", function()
    vim.cmd "ClarityStart"
  end, { desc = "Help: Clarity start hub" })

  local group = vim.api.nvim_create_augroup("clarity_startup_guide", { clear = true })
  vim.api.nvim_create_autocmd("VimEnter", {
    group = group,
    once = true,
    callback = function()
      if not should_show_startup_guide() then
        return
      end

      mark_startup_seen()

      vim.defer_fn(function()
        if startup_buffer_ready() then
          show_start({ auto_open = true })
        end
      end, 120)
    end,
  })
end

return M
