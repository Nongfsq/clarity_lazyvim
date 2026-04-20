local function parse_semver(version)
  local major, minor, patch = tostring(version):match "^v?(%d+)%.(%d+)%.(%d+)"

  if not major then
    return nil
  end

  return tonumber(major), tonumber(minor), tonumber(patch)
end

local function compare_semver(left, right)
  if left.major ~= right.major then
    return left.major > right.major
  end

  if left.minor ~= right.minor then
    return left.minor > right.minor
  end

  return left.patch > right.patch
end

local function read_node_version(command)
  if not command or command == "" or vim.fn.executable(command) ~= 1 then
    return nil
  end

  local output = vim.fn.system { command, "--version" }
  if vim.v.shell_error ~= 0 then
    return nil
  end

  return vim.trim(output)
end

local function collect_fnm_nodes()
  local pattern = vim.fn.expand "$HOME/.local/share/fnm/node-versions/*/installation/bin/node"
  local matches = vim.fn.glob(pattern, true, true)
  local nodes = {}

  for _, path in ipairs(matches) do
    local version = read_node_version(path)
    local major, minor, patch = parse_semver(version)

    if major then
      table.insert(nodes, {
        path = path,
        version = version,
        major = major,
        minor = minor,
        patch = patch,
      })
    end
  end

  table.sort(nodes, compare_semver)
  return nodes
end

local function resolve_copilot_node_command()
  local seen = {}
  local candidates = {}

  local function add_candidate(path)
    if not path or path == "" or seen[path] or vim.fn.executable(path) ~= 1 then
      return
    end

    seen[path] = true
    table.insert(candidates, path)
  end

  for _, node in ipairs(collect_fnm_nodes()) do
    add_candidate(node.path)
  end

  add_candidate(vim.fn.exepath "node")

  for _, command in ipairs(candidates) do
    local version = read_node_version(command)
    local major = parse_semver(version)

    if major and major >= 22 then
      return command
    end
  end

  return vim.fn.exepath "node"
end

return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    opts = function()
      return {
        copilot_node_command = resolve_copilot_node_command(),
        suggestion = {
          accept_keys = { "Tab", false },
          auto_trigger = true,
          keymap = {
            accept = "<Tab>",
            next = "<C-n>",
            prev = "<C-p>",
            dismiss = "<C-e>",
          },
        },
        panel = {
          enabled = true,
          auto_refresh = true,
          keymap = {
            jump_prev = "[[",
            jump_next = "]]",
            accept = "<CR>",
            refresh = "gr",
            open = "<leader>co",
          },
        },
      }
    end,
    init = function()
      local comment_fg = vim.api.nvim_get_hl(0, { name = "Comment" }).fg

      vim.api.nvim_set_hl(0, "CopilotSuggestion", {
        fg = comment_fg,
        underline = true,
      })
    end,
  },
}
