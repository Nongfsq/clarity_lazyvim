local M = {}

local valid_choices = {
  auto = true,
  en = true,
  zh = true,
}

local state

local strings = {
  en = {
    locale = {
      choice = {
        auto = "Auto",
        en = "English",
        zh = "Chinese",
      },
      source = {
        env = "environment",
        global = "vim.g.clarity_locale",
        persisted = "saved preference",
        auto = "automatic detection",
      },
      current = "Clarity language choice: %{choice}; effective UI: %{effective}; source: %{source}.",
      usage = "Use `:ClarityLanguage {auto|en|zh}` to change it.",
      updated = "Clarity language preference saved as %{choice}. Effective UI: %{effective}.",
      restart = "Restart Neovim to refresh key descriptions and command menus completely.",
      invalid = "Unsupported locale `%{choice}`. Use one of: auto, en, zh.",
      command_desc = "Show or set the Clarity UI language",
    },
    commands = {
      audit = "Audit layout and external dependency readiness for clarity_lazyvim",
      validate = "Validate critical Clarity commands, keymaps, and UI behavior",
      start = "Open the Clarity in-editor onboarding panel",
      clipboard = "Open clipboard help for Windows and WSL workflows",
      sync = "Open source-of-truth and repo sync guidance",
      language = "Show or set the Clarity UI language",
    },
    help = {
      map_close = "Close Clarity help",
      map_run_audit = "Run ClarityAudit",
      map_return_to_start = "Return to ClarityStart",
      map_show_language = "Show language status",
      map_start_action = "ClarityStart action",
      start_title = " Clarity Start ",
      start_first_title = " Clarity First Start ",
      start_header = "# Clarity Start",
      start_intro_auto = "This guide opened automatically because this is your first empty startup with the current onboarding version.",
      start_intro_manual = "Use this panel whenever you forget the safest next step.",
      start_reopen = "Reopen any time with `:ClarityStart` or `<leader>hh`.",
      start_locale = "- UI language: `%{locale}`",
      start_platform = "- Platform: `%{platform}`",
      start_clipboard_provider = "- Clipboard provider: `%{provider}`",
      start_repo_root = "- Repo root: `%{root}`",
      start_actions_header = "## Start with these 10 actions",
      start_action_1 = "1. `Space` then pause -> open the command menu",
      start_action_2 = "2. `f` Find files -> `<leader>ff`",
      start_action_3 = "3. `w` Search project text -> `<leader>fw`",
      start_action_4 = "4. `e` Toggle explorer -> `<leader>e`",
      start_action_5 = "5. `b` Switch open buffers -> `<leader>fb`",
      start_action_6 = "6. `t` Open the floating terminal -> `<leader>tf`",
      start_action_7 = "7. `gd` in code -> jump to definition",
      start_action_8 = "8. `gl` in code -> explain the current line diagnostic",
      start_action_9 = "9. `<leader>cf` -> format the current file",
      start_action_10 = "10. `<leader>cr` -> rename the current symbol",
      start_recovery_header = "## Recovery if something feels wrong",
      start_recovery_keymaps = "- `k` Search keymaps -> `<leader>sk`",
      start_recovery_audit = "- `a` Run `:ClarityAudit` for environment health",
      start_recovery_validate = "- `v` Run `:ClarityValidate` for behavior checks",
      start_recovery_clipboard = "- `c` Open clipboard help for Windows + WSL",
      start_recovery_sync = "- `s` Open repo sync help",
      start_recovery_language = "- `l` Show or set UI language",
      start_stale_header = "## If search looks stale or broken",
      start_stale_line_1 = "- This config expects the Snacks picker, not Telescope.",
      start_stale_line_2 = "- If `<leader>ff` or `<leader>fw` mention Telescope, pull the latest repo and open `:ClaritySync`.",
      start_close_header = "## Close",
      start_close_line = "- `q` or `Esc` close this panel",
      clipboard_title = " Clarity Clipboard ",
      clipboard_header = "# Clarity Clipboard Help",
      clipboard_current_mode = "- Current clipboard mode: `%{mode}`",
      clipboard_current_provider = "- Current clipboard provider: `%{provider}`",
      clipboard_paths_header = "## Three different copy paths",
      clipboard_path_1 = "1. Terminal copy",
      clipboard_path_1_detail = "   Use mouse selection in Windows Terminal, then press `Ctrl + Shift + C`.",
      clipboard_path_2 = "2. Neovim copy inside the editor",
      clipboard_path_2_detail = "   Use `y`, `yy`, `p`, `P` for normal yank and paste behavior.",
      clipboard_path_3 = "3. Force the system clipboard",
      clipboard_path_3_detail = "   Use `\"+y`, `\"+yy`, `\"+p`, or `:%y+` when you want to be explicit.",
      clipboard_config_header = "## What this config does",
      clipboard_config_line_1 = "- `clipboard=unnamedplus` is enabled, so normal yanks usually target the system clipboard when the provider is healthy.",
      clipboard_config_line_2 = "- If copy or paste feels wrong, run `:ClarityAudit` and check the clipboard provider line first.",
      clipboard_rule_header = "## Windows + WSL practical rule",
      clipboard_rule_line_1 = "- Copy from Neovim to Windows apps: yank text normally, or force with `\"+y`.",
      clipboard_rule_line_2 = "- Paste from Windows into Neovim running in the terminal: use `Ctrl + Shift + V`.",
      clipboard_rule_line_3 = "- `Ctrl + Shift + C` copies terminal selection, not an internal Neovim visual selection by itself.",
      clipboard_recovery_header = "## Recovery",
      clipboard_recovery_line_1 = "- `a` run `:ClarityAudit`",
      clipboard_recovery_line_2 = "- `h` return to `:ClarityStart`",
      clipboard_recovery_line_3 = "- `q` close this panel",
      sync_title = " Clarity Sync ",
      sync_header = "# Clarity Sync Workflow",
      sync_platform = "- Current platform: `%{platform}`",
      sync_repo = "- Current repo: `%{repo}`",
      sync_repo_note_windows = "- You are currently on Windows. This is the recommended source-of-truth editing environment.",
      sync_repo_note_wsl = "- You are currently on Linux/WSL. Treat this clone as a runtime mirror unless your team decides otherwise.",
      sync_rule_header = "## Official rule for this project",
      sync_rule_1 = "1. Keep one canonical repo that owns edits, commits, and pushes.",
      sync_rule_2 = "2. For the current team workflow, Windows is the source-of-truth workspace.",
      sync_rule_3 = "3. If you also run Neovim inside WSL, treat the WSL clone as the runtime mirror.",
      sync_update_header = "## Recommended update flow",
      sync_update_1 = "1. Edit, test, commit, and push from the Windows repo.",
      sync_update_2 = "2. In WSL, run `git pull --ff-only` inside the mirror clone.",
      sync_update_3 = "3. Restart Neovim after pulling when behavior still looks stale.",
      sync_stale_header = "## If the editor still behaves like an old version",
      sync_stale_1 = "- Run `:ClarityAudit`.",
      sync_stale_2 = "- Compare `git rev-parse --short HEAD` in Windows and WSL.",
      sync_stale_3 = "- Reopen Neovim after the pull completes.",
      sync_recovery_header = "## Recovery",
      sync_recovery_line_1 = "- `a` run `:ClarityAudit`",
      sync_recovery_line_2 = "- `h` return to `:ClarityStart`",
      sync_recovery_line_3 = "- `q` close this panel",
    },
    keymaps = {
      declaration = "Go to declaration",
      definition = "Go to definition",
      hover = "Hover documentation",
      implementation = "Go to implementation",
      references = "Find references",
      rename = "Rename symbol",
      code_action = "Code action",
      line_diagnostic = "Show line diagnostic",
      prev_diagnostic = "Previous diagnostic",
      next_diagnostic = "Next diagnostic",
      keep_only_window = "Window: keep only current",
      search_text = "Search text",
      next_hunk = "Next Git hunk",
      prev_hunk = "Previous Git hunk",
      legacy_next_hunk = "Legacy: next Git hunk",
      legacy_prev_hunk = "Legacy: previous Git hunk",
      stage_hunk = "Hunk: stage current hunk",
      reset_hunk = "Hunk: reset current hunk",
      stage_buffer = "Hunk: stage buffer",
      reset_buffer = "Hunk: reset buffer",
      undo_stage_hunk = "Hunk: undo last stage",
      preview_hunk = "Hunk: preview hunk",
      blame_line = "Hunk: blame current line",
      diff_this = "Hunk: diff current file",
      explorer_cwd = "Explorer (current working directory)",
      explorer_root = "Explorer (project root)",
      terminal_float_center = "Floating terminal",
      terminal_float_right = "Right floating terminal",
      terminal_vertical = "Vertical terminal",
      terminal_horizontal = "Horizontal terminal",
      system_monitor = "System monitor",
      system_monitor_missing = "System monitor (missing dependency)",
      help_start_hub = "Help: Clarity start hub",
    },
    notifications = {
      feature_unavailable = "%{feature} is unavailable because `%{commands}` is not installed.",
      install_system_monitor_hint = "Install `htop` or `btop` to enable `<leader>ht`.",
      system_monitor_feature = "System monitor terminal",
    },
  },
  zh = {
    locale = {
      choice = {
        auto = "自动",
        en = "英文",
        zh = "中文",
      },
      source = {
        env = "环境变量",
        global = "vim.g.clarity_locale",
        persisted = "已保存偏好",
        auto = "自动检测",
      },
      current = "Clarity 语言选择：%{choice}；当前界面语言：%{effective}；来源：%{source}。",
      usage = "使用 `:ClarityLanguage {auto|en|zh}` 切换界面语言。",
      updated = "Clarity 语言偏好已保存为 %{choice}。当前界面语言：%{effective}。",
      restart = "请重启 Neovim，以完整刷新键位说明和命令菜单。",
      invalid = "不支持的语言 `%{choice}`。可用值：auto、en、zh。",
      command_desc = "查看或设置 Clarity 界面语言",
    },
    commands = {
      audit = "检查 clarity_lazyvim 的布局与外部依赖就绪度",
      validate = "验证 Clarity 关键命令、键位和界面行为",
      start = "打开 Clarity 编辑器内引导面板",
      clipboard = "打开 Windows 与 WSL 的剪贴板帮助",
      sync = "打开 source-of-truth 与仓库同步帮助",
      language = "查看或设置 Clarity 界面语言",
    },
    help = {
      map_close = "关闭 Clarity 帮助",
      map_run_audit = "运行 ClarityAudit",
      map_return_to_start = "返回 ClarityStart",
      map_show_language = "查看语言状态",
      map_start_action = "ClarityStart 动作",
      start_title = " Clarity 开始 ",
      start_first_title = " Clarity 首次启动 ",
      start_header = "# Clarity 开始",
      start_intro_auto = "这是当前引导版本下，你第一次以空白缓冲区启动，所以这个面板会自动出现一次。",
      start_intro_manual = "当你忘了下一步最稳的操作时，就用这个面板。",
      start_reopen = "随时可以用 `:ClarityStart` 或 `<leader>hh` 再次打开。",
      start_locale = "- 界面语言：`%{locale}`",
      start_platform = "- 当前平台：`%{platform}`",
      start_clipboard_provider = "- 当前剪贴板提供者：`%{provider}`",
      start_repo_root = "- 当前仓库根目录：`%{root}`",
      start_actions_header = "## 先记住这 10 个动作",
      start_action_1 = "1. `Space` 后停一下 -> 打开命令菜单",
      start_action_2 = "2. `f` 找文件 -> `<leader>ff`",
      start_action_3 = "3. `w` 搜索项目文本 -> `<leader>fw`",
      start_action_4 = "4. `e` 切换文件树 -> `<leader>e`",
      start_action_5 = "5. `b` 切换已打开缓冲区 -> `<leader>fb`",
      start_action_6 = "6. `t` 打开浮动终端 -> `<leader>tf`",
      start_action_7 = "7. 代码里按 `gd` -> 跳到定义",
      start_action_8 = "8. 代码里按 `gl` -> 查看当前行诊断",
      start_action_9 = "9. `<leader>cf` -> 格式化当前文件",
      start_action_10 = "10. `<leader>cr` -> 重命名当前符号",
      start_recovery_header = "## 如果感觉哪里不对",
      start_recovery_keymaps = "- `k` 搜索键位 -> `<leader>sk`",
      start_recovery_audit = "- `a` 运行 `:ClarityAudit` 检查环境",
      start_recovery_validate = "- `v` 运行 `:ClarityValidate` 检查行为",
      start_recovery_clipboard = "- `c` 打开 Windows + WSL 剪贴板帮助",
      start_recovery_sync = "- `s` 打开仓库同步帮助",
      start_recovery_language = "- `l` 查看或设置界面语言",
      start_stale_header = "## 如果搜索后端看起来过期或异常",
      start_stale_line_1 = "- 这套配置当前使用的是 Snacks picker，不是 Telescope。",
      start_stale_line_2 = "- 如果 `<leader>ff` 或 `<leader>fw` 提到 Telescope，请先拉取最新仓库，再打开 `:ClaritySync`。",
      start_close_header = "## 关闭",
      start_close_line = "- `q` 或 `Esc` 关闭这个面板",
      clipboard_title = " Clarity 剪贴板 ",
      clipboard_header = "# Clarity 剪贴板帮助",
      clipboard_current_mode = "- 当前剪贴板模式：`%{mode}`",
      clipboard_current_provider = "- 当前剪贴板提供者：`%{provider}`",
      clipboard_paths_header = "## 三种不同的复制路径",
      clipboard_path_1 = "1. 终端复制",
      clipboard_path_1_detail = "   在 Windows Terminal 里先用鼠标选中，再按 `Ctrl + Shift + C`。",
      clipboard_path_2 = "2. 编辑器内部复制",
      clipboard_path_2_detail = "   用 `y`、`yy`、`p`、`P` 进行正常的 yank / paste。",
      clipboard_path_3 = "3. 强制走系统剪贴板",
      clipboard_path_3_detail = "   想显式指定时，用 `\"+y`、`\"+yy`、`\"+p` 或 `:%y+`。",
      clipboard_config_header = "## 这套配置当前的行为",
      clipboard_config_line_1 = "- 已启用 `clipboard=unnamedplus`，所以当 provider 正常时，普通 yank 通常就会进入系统剪贴板。",
      clipboard_config_line_2 = "- 如果复制或粘贴感觉不对，先运行 `:ClarityAudit`，优先看 clipboard provider 那一行。",
      clipboard_rule_header = "## Windows + WSL 实用规则",
      clipboard_rule_line_1 = "- 从 Neovim 复制到 Windows 程序：普通 yank 即可，或显式使用 `\"+y`。",
      clipboard_rule_line_2 = "- 从 Windows 粘贴回终端里的 Neovim：使用 `Ctrl + Shift + V`。",
      clipboard_rule_line_3 = "- `Ctrl + Shift + C` 复制的是终端选区，不是 Neovim 内部可视模式的选区。",
      clipboard_recovery_header = "## 恢复路径",
      clipboard_recovery_line_1 = "- `a` 运行 `:ClarityAudit`",
      clipboard_recovery_line_2 = "- `h` 返回 `:ClarityStart`",
      clipboard_recovery_line_3 = "- `q` 关闭这个面板",
      sync_title = " Clarity 同步 ",
      sync_header = "# Clarity 同步工作流",
      sync_platform = "- 当前平台：`%{platform}`",
      sync_repo = "- 当前仓库：`%{repo}`",
      sync_repo_note_windows = "- 你当前在 Windows 上。这是推荐的 source-of-truth 编辑环境。",
      sync_repo_note_wsl = "- 你当前在 Linux / WSL 上。除非团队另有约定，否则请把这个克隆视为运行镜像。",
      sync_rule_header = "## 当前项目的官方规则",
      sync_rule_1 = "1. 保持一个负责编辑、提交和推送的主仓。",
      sync_rule_2 = "2. 在当前团队工作流里，Windows 是 source-of-truth 工作区。",
      sync_rule_3 = "3. 如果你也在 WSL 里运行 Neovim，请把 WSL 克隆视为运行镜像。",
      sync_update_header = "## 推荐更新流程",
      sync_update_1 = "1. 在 Windows 主仓里编辑、测试、提交并推送。",
      sync_update_2 = "2. 在 WSL 镜像仓里运行 `git pull --ff-only`。",
      sync_update_3 = "3. 如果行为看起来仍然旧，拉取后重启 Neovim。",
      sync_stale_header = "## 如果编辑器看起来还是旧版本",
      sync_stale_1 = "- 先运行 `:ClarityAudit`。",
      sync_stale_2 = "- 比较 Windows 和 WSL 里的 `git rev-parse --short HEAD`。",
      sync_stale_3 = "- 拉取完成后重新打开 Neovim。",
      sync_recovery_header = "## 恢复路径",
      sync_recovery_line_1 = "- `a` 运行 `:ClarityAudit`",
      sync_recovery_line_2 = "- `h` 返回 `:ClarityStart`",
      sync_recovery_line_3 = "- `q` 关闭这个面板",
    },
    keymaps = {
      declaration = "跳转到声明",
      definition = "跳转到定义",
      hover = "查看悬停文档",
      implementation = "跳转到实现",
      references = "查找引用",
      rename = "重命名符号",
      code_action = "代码操作",
      line_diagnostic = "查看当前行诊断",
      prev_diagnostic = "上一个诊断",
      next_diagnostic = "下一个诊断",
      keep_only_window = "窗口：仅保留当前窗口",
      search_text = "搜索文本",
      next_hunk = "下一个 Git hunk",
      prev_hunk = "上一个 Git hunk",
      legacy_next_hunk = "兼容：下一个 Git 改动块",
      legacy_prev_hunk = "兼容：上一个 Git 改动块",
      stage_hunk = "Hunk：暂存当前改动块",
      reset_hunk = "Hunk：重置当前改动块",
      stage_buffer = "Hunk：暂存整个缓冲区",
      reset_buffer = "Hunk：重置整个缓冲区",
      undo_stage_hunk = "Hunk：撤销上次暂存",
      preview_hunk = "Hunk：预览改动",
      blame_line = "Hunk：查看当前行 blame",
      diff_this = "Hunk：查看当前文件 diff",
      explorer_cwd = "文件树（当前工作目录）",
      explorer_root = "文件树（项目根目录）",
      terminal_float_center = "浮动终端",
      terminal_float_right = "右侧浮动终端",
      terminal_vertical = "垂直终端",
      terminal_horizontal = "水平终端",
      system_monitor = "系统监视器",
      system_monitor_missing = "系统监视器（缺少依赖）",
      help_start_hub = "帮助：Clarity 起始中心",
    },
    notifications = {
      feature_unavailable = "%{feature} 当前不可用，因为没有安装 `%{commands}`。",
      install_system_monitor_hint = "安装 `htop` 或 `btop` 后即可启用 `<leader>ht`。",
      system_monitor_feature = "系统监视器终端",
    },
  },
}

local function state_path()
  return vim.fn.stdpath "state" .. "/clarity_locale.txt"
end

local function normalize_choice(choice)
  if type(choice) ~= "string" then
    return nil
  end

  local normalized = vim.trim(choice):lower()
  return valid_choices[normalized] and normalized or nil
end

local function read_saved_choice()
  local path = state_path()
  if vim.fn.filereadable(path) ~= 1 then
    return nil
  end

  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok or type(lines) ~= "table" or #lines == 0 then
    return nil
  end

  return normalize_choice(lines[1])
end

local function write_saved_choice(choice)
  local path = state_path()
  local dir = vim.fn.fnamemodify(path, ":h")
  pcall(vim.fn.mkdir, dir, "p")
  pcall(vim.fn.writefile, { choice }, path)
end

local function detect_auto_locale()
  local candidates = {
    vim.env.LC_ALL,
    vim.env.LC_MESSAGES,
    vim.env.LANG,
    vim.env.LANGUAGE,
  }

  for _, candidate in ipairs(candidates) do
    if type(candidate) == "string" and candidate ~= "" then
      local lowered = candidate:lower()
      if lowered:find "zh" then
        return "zh"
      end
    end
  end

  return "en"
end

local function translate(locale, key)
  local cursor = strings[locale]

  for part in key:gmatch "[^%.]+" do
    if type(cursor) ~= "table" then
      return nil
    end
    cursor = cursor[part]
  end

  return cursor
end

local function interpolate(template, vars)
  if type(template) ~= "string" or type(vars) ~= "table" then
    return template
  end

  return (template:gsub("%%{(.-)}", function(name)
    local value = vars[name]
    if value == nil then
      return "%{" .. name .. "}"
    end

    return tostring(value)
  end))
end

local function source_label(source, locale)
  local key = "locale.source." .. source
  return translate(locale, key) or translate("en", key) or source
end

local function locale_label(locale_code, locale)
  local key = "locale.choice." .. locale_code
  return translate(locale, key) or translate("en", key) or locale_code
end

local function compute_state()
  local choice
  local source

  choice = normalize_choice(vim.env.CLARITY_LOCALE)
  if choice then
    source = "env"
  else
    choice = normalize_choice(vim.g.clarity_locale)
    if choice then
      source = "global"
    else
      choice = read_saved_choice()
      if choice then
        source = "persisted"
      else
        choice = "auto"
        source = "auto"
      end
    end
  end

  local effective = choice == "auto" and detect_auto_locale() or choice

  return {
    choice = choice,
    effective = effective,
    source = source,
  }
end

local function ensure_state()
  if not state then
    state = compute_state()
  end

  return state
end

local function notify(message, level)
  if vim.env.CLARITY_NONINTERACTIVE == "1" or #vim.api.nvim_list_uis() == 0 then
    print(message)
    return
  end

  vim.notify(message, level or vim.log.levels.INFO)
end

local function flatten_keys(tbl, prefix, acc)
  acc = acc or {}
  prefix = prefix or ""

  for key, value in pairs(tbl or {}) do
    local path = prefix == "" and key or (prefix .. "." .. key)
    if type(value) == "table" then
      flatten_keys(value, path, acc)
    else
      acc[path] = true
    end
  end

  return acc
end

function M.get_state()
  local current = ensure_state()
  return {
    choice = current.choice,
    effective = current.effective,
    source = current.source,
  }
end

function M.get_locale()
  return ensure_state().effective
end

function M.label(locale_code, locale_override)
  local locale = locale_override or M.get_locale()
  return locale_label(locale_code, locale)
end

function M.t(key, vars, locale_override)
  local locale = locale_override or M.get_locale()
  local template = translate(locale, key) or translate("en", key) or key
  return interpolate(template, vars)
end

function M.set_choice(choice, opts)
  opts = opts or {}

  local normalized = normalize_choice(choice)
  if not normalized then
    local fallback_locale = state and state.effective or detect_auto_locale()
    local message = M.t("locale.invalid", { choice = tostring(choice) }, fallback_locale)
    if not opts.silent then
      notify(message, vim.log.levels.ERROR)
    end
    return false, message
  end

  if opts.persist ~= false then
    write_saved_choice(normalized)
  end

  state = nil
  local current = ensure_state()

  if not opts.silent then
    notify(M.t("locale.updated", {
      choice = M.label(normalized),
      effective = M.label(current.effective),
    }), vim.log.levels.INFO)
    notify(M.t("locale.restart"), vim.log.levels.INFO)
  end

  return true, M.get_state()
end

function M.show_status()
  local current = M.get_state()
  local locale = current.effective
  local lines = {
    M.t("locale.current", {
      choice = locale_label(current.choice, locale),
      effective = locale_label(current.effective, locale),
      source = source_label(current.source, locale),
    }),
    M.t("locale.usage", nil, locale),
  }

  notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

function M.get_validation_report()
  local en_keys = flatten_keys(strings.en)
  local zh_keys = flatten_keys(strings.zh)
  local missing_in_en = {}
  local missing_in_zh = {}

  for key in pairs(en_keys) do
    if not zh_keys[key] then
      table.insert(missing_in_zh, key)
    end
  end

  for key in pairs(zh_keys) do
    if not en_keys[key] then
      table.insert(missing_in_en, key)
    end
  end

  table.sort(missing_in_en)
  table.sort(missing_in_zh)

  local current = M.get_state()
  return {
    ok = #missing_in_en == 0 and #missing_in_zh == 0,
    locales = { "en", "zh" },
    missing_in_en = missing_in_en,
    missing_in_zh = missing_in_zh,
    choice = current.choice,
    effective = current.effective,
  }
end

function M.setup()
  ensure_state()

  if vim.fn.exists(":ClarityLanguage") == 2 then
    return
  end

  vim.api.nvim_create_user_command("ClarityLanguage", function(info)
    local choice = info.args and vim.trim(info.args) or ""

    if choice == "" then
      M.show_status()
      return
    end

    M.set_choice(choice)
  end, {
    nargs = "?",
    complete = function()
      return { "auto", "en", "zh" }
    end,
    desc = M.t "commands.language",
  })
end

return M
