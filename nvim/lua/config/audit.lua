local M = {}

local tool_specs = {
  { id = "git", required = true, commands = { "git" }, feature = "bootstrap lazy.nvim and clone plugins" },
  { id = "compiler", required = true, commands = { "cl", "gcc", "clang", "cc", "zig" }, feature = "build Treesitter parsers" },
  { id = "ripgrep", required = false, commands = { "rg" }, feature = "fast text search" },
  { id = "fd", required = false, commands = { "fd", "fdfind" }, feature = "fast file search" },
  { id = "node", required = false, commands = { "node" }, feature = "Node provider and JS-based tools" },
  { id = "npm", required = false, commands = { "npm" }, feature = "install provider packages manually" },
  { id = "python", required = false, commands = { "python3", "python" }, feature = "Python provider and Python-based tools" },
  { id = "pip", required = false, commands = { "pip3", "pip" }, feature = "install Python provider packages manually" },
  { id = "lazygit", required = false, commands = { "lazygit" }, feature = "LazyGit integration" },
  { id = "system_monitor", required = false, commands = { "htop", "btop" }, feature = "system monitor terminal" },
}

local function source_path()
  return debug.getinfo(1, "S").source:sub(2)
end

local function get_repo_root()
  if type(vim.g.clarity_repo_root) == "string" and vim.fn.isdirectory(vim.g.clarity_repo_root) == 1 then
    return vim.g.clarity_repo_root
  end

  local file = source_path()
  return vim.fn.fnamemodify(file, ":p:h:h:h:h"):gsub("\\", "/")
end

local function get_nvim_dir()
  if type(vim.g.clarity_nvim_dir) == "string" and vim.fn.isdirectory(vim.g.clarity_nvim_dir) == 1 then
    return vim.g.clarity_nvim_dir
  end

  return get_repo_root() .. "/nvim"
end

local function round(value)
  return math.floor(value + 0.5)
end

local function score(ok_count, total_count)
  if total_count == 0 then
    return 100
  end

  return round((ok_count / total_count) * 100)
end

local function file_exists(path)
  return vim.fn.filereadable(path) == 1
end

local function directory_exists(path)
  return vim.fn.isdirectory(path) == 1
end

local function describe_commands(commands)
  return table.concat(commands, " / ")
end

function M.has(commands)
  local candidates = type(commands) == "table" and commands or { commands }

  for _, command in ipairs(candidates) do
    if vim.fn.executable(command) == 1 then
      return true, command
    end
  end

  return false, candidates[1]
end

function M.notify_missing(commands, feature, hint)
  local candidates = type(commands) == "table" and commands or { commands }
  local message = string.format("%s is unavailable because `%s` is not installed.", feature, describe_commands(candidates))

  if hint and hint ~= "" then
    message = message .. " " .. hint
  end

  vim.notify(message, vim.log.levels.WARN)
end

function M.get_report()
  local repo_root = get_repo_root()
  local nvim_dir = get_nvim_dir()
  local root_lock = repo_root .. "/lazy-lock.json"
  local nested_lock = nvim_dir .. "/lazy-lock.json"

  local report = {
    generated_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    platform = vim.loop.os_uname(),
    nvim = vim.version(),
    paths = {
      repo_root = repo_root,
      nvim_dir = nvim_dir,
    },
    layout = {
      root_init = file_exists(repo_root .. "/init.lua"),
      nested_init = file_exists(nvim_dir .. "/init.lua"),
      root_lock = file_exists(root_lock),
      nested_lock = file_exists(nested_lock),
      duplicate_lockfiles = file_exists(root_lock) and file_exists(nested_lock),
      nvim_dir_present = directory_exists(nvim_dir),
    },
    tools = {},
  }

  local required_total = 0
  local required_ok = 0
  local optional_total = 0
  local optional_ok = 0

  for _, spec in ipairs(tool_specs) do
    local present, detected = M.has(spec.commands)
    local entry = {
      id = spec.id,
      required = spec.required,
      commands = spec.commands,
      feature = spec.feature,
      present = present,
      detected = detected,
    }

    table.insert(report.tools, entry)

    if spec.required then
      required_total = required_total + 1
      if present then
        required_ok = required_ok + 1
      end
    else
      optional_total = optional_total + 1
      if present then
        optional_ok = optional_ok + 1
      end
    end
  end

  local layout_score = 100
  if not report.layout.root_init then
    layout_score = layout_score - 40
  end
  if not report.layout.nested_init then
    layout_score = layout_score - 20
  end
  if report.layout.duplicate_lockfiles then
    layout_score = layout_score - 25
  end
  if not report.layout.nvim_dir_present then
    layout_score = layout_score - 15
  end
  layout_score = math.max(layout_score, 0)

  report.summary = {
    required = { ok = required_ok, total = required_total },
    optional = { ok = optional_ok, total = optional_total },
    scores = {
      required = score(required_ok, required_total),
      optional = score(optional_ok, optional_total),
      layout = layout_score,
    },
  }

  report.summary.scores.overall = round(
    (report.summary.scores.required * 0.5)
      + (report.summary.scores.optional * 0.2)
      + (report.summary.scores.layout * 0.3)
  )

  return report
end

function M.render_report(report)
  local lines = {
    "Clarity Audit",
    string.format("Overall readiness: %d/100", report.summary.scores.overall),
    string.format("Required tools: %d/%d", report.summary.required.ok, report.summary.required.total),
    string.format("Optional tools: %d/%d", report.summary.optional.ok, report.summary.optional.total),
    string.format("Layout hygiene: %d/100", report.summary.scores.layout),
    string.format("Repository root: %s", report.paths.repo_root),
    string.format("Nested nvim dir: %s", report.paths.nvim_dir),
  }

  if report.layout.duplicate_lockfiles then
    table.insert(lines, "Warning: duplicate lock files detected.")
  end

  for _, tool in ipairs(report.tools) do
    local marker = tool.present and "OK" or "MISSING"
    local kind = tool.required and "required" or "optional"
    local detected = tool.present and string.format(" -> %s", tool.detected) or ""
    table.insert(
      lines,
      string.format("- [%s] %s (%s): %s%s", marker, tool.id, kind, tool.feature, detected)
    )
  end

  return lines
end

function M.setup()
  if vim.fn.exists(":ClarityAudit") == 2 then
    return
  end

  vim.api.nvim_create_user_command("ClarityAudit", function(info)
    local report = M.get_report()

    if info.bang then
      print(vim.json.encode(report))
      return
    end

    for _, line in ipairs(M.render_report(report)) do
      print(line)
    end
  end, {
    bang = true,
    desc = "Audit layout and external dependency readiness for clarity_lazyvim",
  })
end

return M
