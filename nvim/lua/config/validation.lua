local audit = require "config.audit"

local M = {}

local function repo_root()
  if type(vim.g.clarity_repo_root) == "string" and vim.g.clarity_repo_root ~= "" then
    return vim.g.clarity_repo_root
  end

  return vim.fn.getcwd()
end

local function add_result(results, group, id, ok, detail)
  table.insert(results, {
    group = group,
    id = id,
    ok = ok,
    detail = detail,
  })
end

local function command_exists(name)
  return vim.fn.exists(":" .. name) == 2
end

local function has_map(lhs, mode)
  local map = vim.fn.maparg(lhs, mode, false, true)
  return type(map) == "table" and next(map) ~= nil
end

local function dashboard_number_check()
  local current_buf = vim.api.nvim_get_current_buf()
  local current_win = vim.api.nvim_get_current_win()
  local scratch = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_win_set_buf(current_win, scratch)
  vim.bo[scratch].buftype = ""
  vim.bo[scratch].filetype = "snacks_dashboard"

  vim.api.nvim_exec_autocmds("FileType", { buffer = scratch, modeline = false })
  vim.api.nvim_exec_autocmds("BufEnter", { buffer = scratch, modeline = false })

  local ok = not vim.wo[current_win].number and not vim.wo[current_win].relativenumber
  local detail = string.format(
    "snacks_dashboard number=%s relativenumber=%s",
    tostring(vim.wo[current_win].number),
    tostring(vim.wo[current_win].relativenumber)
  )

  if vim.api.nvim_buf_is_valid(current_buf) then
    vim.api.nvim_win_set_buf(current_win, current_buf)
  end
  if vim.api.nvim_buf_is_valid(scratch) then
    vim.api.nvim_buf_delete(scratch, { force = true })
  end

  return ok, detail
end

local function neotree_number_check()
  local ok, err = pcall(vim.cmd, "Neotree show")
  if not ok then
    return false, "Neotree show failed: " .. tostring(err)
  end

  vim.wait(250, function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].filetype == "neo-tree" then
        return true
      end
    end
    return false
  end)

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "neo-tree" then
      local valid = not vim.wo[win].number and not vim.wo[win].relativenumber
      local detail = string.format(
        "neo-tree number=%s relativenumber=%s",
        tostring(vim.wo[win].number),
        tostring(vim.wo[win].relativenumber)
      )
      pcall(vim.cmd, "Neotree close")
      return valid, detail
    end
  end

  return false, "neo-tree window was not created"
end

local function toggleterm_check()
  local ok, config = pcall(require, "toggleterm.config")
  if not ok then
    return false, "toggleterm.config unavailable"
  end

  local settings = config.get()
  local valid = settings.hide_numbers and settings.start_in_insert and settings.direction == "float"
  local detail = string.format(
    "hide_numbers=%s start_in_insert=%s direction=%s",
    tostring(settings.hide_numbers),
    tostring(settings.start_in_insert),
    tostring(settings.direction)
  )

  return valid, detail
end

function M.get_report()
  local results = {}
  local root = repo_root()

  vim.cmd "doautocmd User VeryLazy"
  vim.wait(150)

  add_result(results, "commands", "clarity_audit_command", command_exists "ClarityAudit", ":ClarityAudit")
  add_result(results, "commands", "clarity_start_command", command_exists "ClarityStart", ":ClarityStart")
  add_result(results, "commands", "clarity_clipboard_command", command_exists "ClarityClipboard", ":ClarityClipboard")
  add_result(results, "commands", "clarity_sync_command", command_exists "ClaritySync", ":ClaritySync")
  add_result(results, "commands", "clarity_validate_command", command_exists "ClarityValidate", ":ClarityValidate")

  add_result(results, "keymaps", "leader_ff", has_map("<leader>ff", "n"), "<leader>ff")
  add_result(results, "keymaps", "leader_fw", has_map("<leader>fw", "n"), "<leader>fw")
  add_result(results, "keymaps", "leader_gd", has_map("<leader>gd", "n"), "<leader>gd")
  add_result(results, "keymaps", "leader_tf", has_map("<leader>tf", "n"), "<leader>tf")
  add_result(results, "keymaps", "leader_hh", has_map("<leader>hh", "n"), "<leader>hh")

  local readme = root .. "/README.md"
  if vim.fn.filereadable(readme) == 1 then
    vim.cmd("silent edit " .. vim.fn.fnameescape(readme))
    vim.wait(1200, function()
      return vim.b.gitsigns_head ~= nil and vim.b.clarity_gitsigns_keymaps == true
    end)
  end

  add_result(results, "keymaps", "leader_hs", has_map("<leader>hs", "n"), "<leader>hs in a tracked buffer")

  local dashboard_ok, dashboard_detail = dashboard_number_check()
  add_result(results, "ui", "dashboard_numbers_hidden", dashboard_ok, dashboard_detail)

  local neotree_ok, neotree_detail = neotree_number_check()
  add_result(results, "ui", "neo_tree_numbers_hidden", neotree_ok, neotree_detail)

  local toggleterm_ok, toggleterm_detail = toggleterm_check()
  add_result(results, "ui", "toggleterm_defaults", toggleterm_ok, toggleterm_detail)

  local audit_report = audit.get_report()
  local integrations = audit_report.integrations or {}
  local clipboard_ready = integrations.clipboard and integrations.clipboard.present or false
  local picker_ready = integrations.picker and integrations.picker.backend == "snacks"
  local copilot_ready = integrations.copilot and integrations.copilot.satisfied or false

  add_result(results, "integrations", "clipboard_provider_ready", clipboard_ready, "clipboard provider available")
  add_result(results, "integrations", "picker_backend_snacks", picker_ready, "search backend should resolve to Snacks")
  add_result(results, "integrations", "copilot_node_ready", copilot_ready, "Copilot node runtime must satisfy >=22")

  local total = #results
  local passed = 0
  for _, item in ipairs(results) do
    if item.ok then
      passed = passed + 1
    end
  end

  return {
    generated_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    platform = vim.loop.os_uname(),
    ok = passed == total,
    summary = {
      passed = passed,
      failed = total - passed,
      total = total,
    },
    checks = results,
    audit = {
      overall = audit_report.summary and audit_report.summary.scores and audit_report.summary.scores.overall or nil,
      integration_score = audit_report.summary and audit_report.summary.scores and audit_report.summary.scores.integrations
        or nil,
    },
  }
end

function M.render_report(report)
  local lines = {
    "Clarity Validate",
    string.format("Checks passed: %d/%d", report.summary.passed, report.summary.total),
    string.format("Checks failed: %d", report.summary.failed),
  }

  if report.audit.overall then
    table.insert(lines, string.format("Audit overall readiness: %d/100", report.audit.overall))
  end

  if report.audit.integration_score then
    table.insert(lines, string.format("Audit integration readiness: %d/100", report.audit.integration_score))
  end

  for _, item in ipairs(report.checks) do
    local marker = item.ok and "OK" or "FAIL"
    table.insert(lines, string.format("- [%s] %s (%s): %s", marker, item.id, item.group, item.detail))
  end

  return lines
end

function M.setup()
  if vim.fn.exists(":ClarityValidate") == 2 then
    return
  end

  vim.api.nvim_create_user_command("ClarityValidate", function(info)
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
    desc = "Validate critical Clarity commands, keymaps, and UI behavior",
  })
end

return M
