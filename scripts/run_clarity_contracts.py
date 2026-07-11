from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import stat
import sys
import tempfile
from contextlib import contextmanager
from pathlib import Path
from typing import Any, Iterator

from clarity_runtime import (
    build_env,
    combined_output,
    configure_isolated_runtime,
    extract_last_json_object,
    resolve_nvim_binary,
    run_command,
    sha256_file,
)
from run_clarity_smoke import copy_candidate, copy_plugin_cache


AUTHORITY_FILES = ("lazy-lock.json", "lazyvim.json")
FAULT_MISSING_NESTED_RUNTIME = "missing_nested_runtime"
FAULT_RAW_FOLD_ACTION = "raw_fold_action"


def lua_string(value: str | Path) -> str:
    return json.dumps(str(value))


def discover_config_modules(repo_root: Path) -> set[str]:
    config_root = repo_root / "nvim" / "lua" / "config"
    return {
        "config." + ".".join(path.relative_to(config_root).with_suffix("").parts)
        for path in config_root.rglob("*.lua")
    }


def discover_task_ids(repo_root: Path) -> set[str]:
    pattern = re.compile(r"^### ([A-Z][A-Z0-9_-]*-[0-9]{3})(?::|\s)")
    task_ids: set[str] = set()
    for path in (repo_root / "progress").glob("*.md"):
        for line in path.read_text(encoding="utf-8").splitlines():
            match = pattern.match(line)
            if match:
                task_ids.add(match.group(1))
    return task_ids


def load_catalog(repo_root: Path, nvim_bin: str, timeout: float = 30) -> dict[str, Any]:
    path = repo_root / "tests" / "contracts" / "runtime_contract.lua"
    command = [
        nvim_bin,
        "--clean",
        "--headless",
        "-u",
        "NONE",
        "+lua print(vim.json.encode(dofile(" + lua_string(path) + ")))",
        "+qall",
    ]
    result = run_command(command, cwd=repo_root, env=build_env(), timeout=timeout)
    if result.returncode != 0:
        raise RuntimeError("Could not load runtime contract catalog:\n" + combined_output(result))
    return extract_last_json_object(combined_output(result))


def catalog_issues(catalog: dict[str, Any], module_names: set[str], task_ids: set[str]) -> list[dict[str, str]]:
    issues: list[dict[str, str]] = []
    classified = set(catalog.get("modules", {}))
    for module in sorted(module_names - classified):
        issues.append({"id": "CLARITY_CONTRACT_UNCLASSIFIED_MODULE", "detail": module})
    for module in sorted(classified - module_names):
        issues.append({"id": "CLARITY_CONTRACT_MISSING_MODULE", "detail": module})

    valid_coverage = {"covered", "planned", "inherited"}
    for capability_id, capability in sorted(catalog.get("capabilities", {}).items()):
        coverage = capability.get("coverage")
        if coverage not in valid_coverage:
            issues.append(
                {"id": "CLARITY_CONTRACT_INVALID_COVERAGE", "detail": f"{capability_id}:{coverage}"}
            )
        if not capability.get("owner"):
            issues.append({"id": "CLARITY_CONTRACT_MISSING_OWNER", "detail": capability_id})
        if coverage == "planned" and capability.get("task") not in task_ids:
            issues.append(
                {
                    "id": "CLARITY_CONTRACT_INVALID_PLANNED_TASK",
                    "detail": f"{capability_id}:{capability.get('task')}",
                }
            )
    return issues


def authority_hashes(repo_root: Path) -> dict[str, str]:
    return {name: sha256_file(repo_root / name) for name in AUTHORITY_FILES}


def directory_digest(root: Path, *, exclude_git: bool = False) -> str:
    digest = hashlib.sha256()
    if not root.exists():
        return digest.hexdigest()
    for path in sorted(item for item in root.rglob("*") if item.is_file() or item.is_symlink()):
        relative = path.relative_to(root)
        if exclude_git and relative.parts and relative.parts[0] == ".git":
            continue
        digest.update(relative.as_posix().encode())
        digest.update(b"\0")
        digest.update(path.read_bytes())
        digest.update(b"\0")
    return digest.hexdigest()


def repository_snapshot(repo_root: Path, env: dict[str, str], timeout: float) -> dict[str, Any]:
    git_dir = repo_root / ".git"
    index = git_dir / "index"
    git_env = dict(env)
    git_env["GIT_OPTIONAL_LOCKS"] = "0"
    status = run_command(
        ["git", "--no-optional-locks", "status", "--porcelain=v2", "-z"],
        cwd=repo_root,
        env=git_env,
        timeout=timeout,
    )
    if status.returncode != 0:
        raise RuntimeError("Could not snapshot attached Git fixture:\n" + combined_output(status))
    index_stat = index.stat()
    return {
        "head": sha256_file(git_dir / "HEAD"),
        "index": sha256_file(index),
        "index_mtime_ns": index_stat.st_mtime_ns,
        "packed_refs": sha256_file(git_dir / "packed-refs") if (git_dir / "packed-refs").exists() else None,
        "refs": directory_digest(git_dir / "refs"),
        "status": status.stdout or "",
        "worktree": directory_digest(repo_root, exclude_git=True),
        "locks": sorted(path.relative_to(git_dir).as_posix() for path in git_dir.rglob("*.lock")),
    }


def hash_drift(before: dict[str, str], after: dict[str, str]) -> dict[str, dict[str, str]]:
    return {
        name: {"before": before[name], "after": after[name]}
        for name in before
        if before[name] != after[name]
    }


def apply_fault(candidate_root: Path, fault: str | None) -> None:
    if fault is None:
        return
    if fault == FAULT_RAW_FOLD_ACTION:
        keymaps_path = candidate_root / "nvim" / "lua" / "config" / "keymaps.lua"
        keymaps_source = keymaps_path.read_text(encoding="utf-8")
        old = 'map("n", "<leader>cz", require("config.actions.fold").toggle, opts)'
        new = 'map("n", "<leader>cz", function()\n    vim.cmd("normal! za")\nend, opts) -- fault: raw fold action'
        if old not in keymaps_source:
            raise RuntimeError("Fault fixture could not locate the typed fold action mapping.")
        keymaps_path.write_text(keymaps_source.replace(old, new, 1), encoding="utf-8")
        return
    if fault != FAULT_MISSING_NESTED_RUNTIME:
        raise ValueError(f"Unknown fault: {fault}")

    lazy_path = candidate_root / "nvim" / "lua" / "config" / "lazy.lua"
    lazy_source = lazy_path.read_text(encoding="utf-8")
    old = "paths = vim.list_extend({ vim.g.clarity_nvim_dir }, bundled_runtime_paths()),"
    new = "paths = bundled_runtime_paths(), -- fault: nested runtime removed"
    if old not in lazy_source:
        raise RuntimeError("Fault fixture could not locate the nested runtime performance path.")
    lazy_path.write_text(lazy_source.replace(old, new, 1), encoding="utf-8")

    init_path = candidate_root / "nvim" / "init.lua"
    init_source = init_path.read_text(encoding="utf-8")
    old = "    vim.opt.rtp:append(nvim_dir)"
    new = "    -- fault: do not restore the nested runtime before UIEnter"
    if old not in init_source:
        raise RuntimeError("Fault fixture could not locate the post-setup nested runtime path.")
    init_path.write_text(init_source.replace(old, new, 1), encoding="utf-8")


def build_headless_command(
    candidate_root: Path,
    nvim_bin: str,
    scenario: str,
    wait_ms: int,
) -> list[str]:
    probe = candidate_root / "tests" / "lua" / "runtime_probe.lua"
    observe = "lua dofile(" + lua_string(probe) + ").observe()"
    emit = (
        "+lua local p=dofile("
        + lua_string(probe)
        + "); local ready=vim.wait("
        + str(wait_ms)
        + ", function() return p.ready("
        + lua_string(scenario)
        + ") end, 20); local report=p.snapshot("
        + lua_string(scenario)
        + "); report.ready=ready; print(vim.json.encode(report))"
    )
    args = [str(candidate_root / "tests" / "fixtures" / "runtime" / "sample.lua")] if scenario == "file_headless" else []
    return [
        nvim_bin,
        "--headless",
        "--cmd",
        observe,
        "-u",
        str(candidate_root / "init.lua"),
        *args,
        emit,
        "+qall",
    ]


@contextmanager
def process_context(cwd: Path, env: dict[str, str]) -> Iterator[None]:
    original_cwd = Path.cwd()
    original_env = dict(os.environ)
    try:
        os.chdir(cwd)
        os.environ.clear()
        os.environ.update(env)
        yield
    finally:
        os.environ.clear()
        os.environ.update(original_env)
        os.chdir(original_cwd)


def prepare_attached_context_fixture(
    candidate_root: Path,
    runtime_root: Path,
    env: dict[str, str],
    timeout: float,
) -> None:
    sample = candidate_root / "tests" / "fixtures" / "runtime" / "sample.lua"
    commands = (
        ["git", "init", "--quiet"],
        ["git", "add", str(sample.relative_to(candidate_root))],
        [
            "git",
            "-c",
            "user.name=Clarity Contract",
            "-c",
            "user.email=clarity@example.invalid",
            "-c",
            "commit.gpgsign=false",
            "commit",
            "--quiet",
            "-m",
            "context fixture",
        ],
    )
    for command in commands:
        result = run_command(command, cwd=candidate_root, env=env, timeout=timeout)
        if result.returncode != 0:
            raise RuntimeError("Could not prepare attached Git context:\n" + combined_output(result))
    with sample.open("a", encoding="utf-8") as handle:
        handle.write("\n-- tracked review change\n")

    if os.name != "nt":
        bin_dir = runtime_root / "system-bin"
        bin_dir.mkdir(parents=True, exist_ok=True)
        server = candidate_root / "tests" / "fixtures" / "lsp" / "fake_server.py"
        executable = bin_dir / "lua-language-server"
        executable.write_text(
            f"#!{sys.executable}\n"
            "import runpy\n"
            f"runpy.run_path({str(server)!r}, run_name='__main__')\n",
            encoding="utf-8",
        )
        executable.chmod(stat.S_IRUSR | stat.S_IWUSR | stat.S_IXUSR)
        formatter_log = runtime_root / "formatter-invocation.json"
        formatter = bin_dir / "stylua"
        formatter.write_text(
            f"#!{sys.executable}\n"
            "import json, os, pathlib, sys\n"
            "args = sys.argv[1:]\n"
            "pathlib.Path(os.environ['CLARITY_FAKE_FORMATTER_LOG']).write_text("
            "json.dumps({'argv': args, 'cwd': os.getcwd()}), encoding='utf-8')\n"
            "source = sys.stdin.read()\n"
            "filename = args[args.index('--stdin-filepath') + 1] if '--stdin-filepath' in args else ''\n"
            "cursor = pathlib.Path(filename).resolve().parent if filename else pathlib.Path.cwd()\n"
            "configured = any((parent / 'stylua.toml').is_file() or (parent / '.stylua.toml').is_file() "
            "for parent in (cursor, *cursor.parents))\n"
            "if configured:\n"
            "    source = '\\n'.join(('  ' + line[4:]) if line.startswith('    ') else line "
            "for line in source.split('\\n'))\n"
            "sys.stdout.write(source)\n",
            encoding="utf-8",
        )
        formatter.chmod(stat.S_IRUSR | stat.S_IWUSR | stat.S_IXUSR)
        format_project = candidate_root / "tests" / "fixtures" / "runtime" / "format-project"
        format_project.mkdir(parents=True, exist_ok=True)
        (format_project / "stylua.toml").write_text("indent_width = 2\n", encoding="utf-8")
        env["PATH"] = str(bin_dir) + os.pathsep + env.get("PATH", "")
        env["CLARITY_FAKE_LSP_BIN"] = str(executable)
        env["CLARITY_FAKE_FORMATTER_BIN"] = str(formatter)
        env["CLARITY_FAKE_FORMATTER_LOG"] = str(formatter_log)


def attached_ui_behavior_setup_lua() -> str:
    return r'''
local results = {}
local wrap_map = vim.fn.maparg('<leader>uw', 'n', false, true)
local fold_map = vim.fn.maparg('<leader>cz', 'n', false, true)
results.wrap_callback = type(wrap_map.callback) == 'function'
results.fold_callback = type(fold_map.callback) == 'function'

local function leader_manifest()
  local leader = vim.g.mapleader or string.char(92)
  local found = {}
  for _, mapping in ipairs(vim.api.nvim_get_keymap('n')) do
    if mapping.lhs ~= leader and mapping.lhs:sub(1, #leader) == leader then
      found[#found + 1] = '<leader>' .. mapping.lhs:sub(#leader + 1)
    end
  end
  table.sort(found)
  return found
end
results.global_leader_manifest = leader_manifest()
results.global_leader_expected = require('config.actions.catalog').global_normal_manifest()
results.global_leader_exact = vim.deep_equal(results.global_leader_manifest, results.global_leader_expected)

local original_buf = vim.api.nvim_get_current_buf()
results.context_lsp_started = vim.lsp.is_enabled('lua_ls')
results.context_lsp_attached = vim.wait(3000, function()
  return #vim.lsp.get_clients({ bufnr = original_buf, name = 'lua_ls' }) == 1
end, 20)
local lsp_clients = vim.lsp.get_clients({ bufnr = original_buf, name = 'lua_ls' })
local client_id = lsp_clients[1] and lsp_clients[1].id or nil
results.context_lsp_system_command = lsp_clients[1]
  and lsp_clients[1].config.cmd[1] == 'lua-language-server'
results.context_lsp_keys_ready = vim.wait(3000, function()
  for _, lhs in ipairs({ '<leader>ca', '<leader>cr', '<leader>ss', '<leader>sS', '<leader>uh' }) do
    if vim.fn.maparg(lhs, 'n', false, true).buffer ~= 1 then
      return false
    end
  end
  return true
end, 20)
results.context_git_attached = vim.wait(3000, function()
  return vim.fn.maparg('<leader>ghp', 'n', false, true).buffer == 1
end, 20)

local function buffer_leader_manifest(bufnr)
  local leader = vim.g.mapleader or string.char(92)
  local found = {}
  for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(bufnr, 'n')) do
    if mapping.lhs ~= leader and mapping.lhs:sub(1, #leader) == leader then
      found[#found + 1] = '<leader>' .. mapping.lhs:sub(#leader + 1)
    end
  end
  table.sort(found)
  return found
end
results.dynamic_leader_manifest = buffer_leader_manifest(original_buf)
results.dynamic_leader_expected = require('config.actions.catalog').dynamic_normal_manifest()
results.dynamic_leader_exact = vim.deep_equal(results.dynamic_leader_manifest, results.dynamic_leader_expected)
results.full_context_count = #results.global_leader_manifest + #results.dynamic_leader_manifest
results.full_context_within_budget = results.full_context_count
  <= require('config.product_policy').budgets().full_context_normal_leader

local original_wrap = vim.wo.wrap
if results.wrap_callback then
  wrap_map.callback()
  results.wrap_changed = vim.wo.wrap ~= original_wrap
  wrap_map.callback()
  results.wrap_restored = vim.wo.wrap == original_wrap
end

local original_foldmethod = vim.wo.foldmethod
local original_foldenable = vim.wo.foldenable
local original_foldlevel = vim.wo.foldlevel
local scratch = vim.api.nvim_create_buf(false, false)
vim.api.nvim_win_set_buf(0, scratch)
vim.api.nvim_buf_set_lines(scratch, 0, -1, false, { 'if true then', '  print(1)', 'end', 'print(2)' })
vim.wo.foldmethod = 'manual'
vim.wo.foldenable = true
vim.wo.foldlevel = 0
vim.cmd('1,3fold')
vim.api.nvim_win_set_cursor(0, { 1, 0 })
results.fold_initially_closed = vim.fn.foldclosed(1) == 1
_G.ClarityAttachedBehavior = {
  original_buf = original_buf,
  original_foldmethod = original_foldmethod,
  original_foldenable = original_foldenable,
  original_foldlevel = original_foldlevel,
  client_id = client_id,
  scratch = scratch,
}
return results
'''


def attached_ui_fold_state_lua() -> str:
    return r'''
local events = require('config.diagnostics').events()
local event = events[#events]
return {
  closed = vim.fn.foldclosed(1),
  errmsg = vim.v.errmsg,
  event_id = event and event.event_id or nil,
  outcome = event and event.outcome or nil,
  event_count = #events,
  messages = vim.api.nvim_exec2('messages', { output = true }).output,
}
'''


def attached_ui_behavior_cleanup_lua() -> str:
    return r'''
local state = _G.ClarityAttachedBehavior
if not state then return false end
vim.api.nvim_win_set_buf(0, state.original_buf)
vim.wo.foldmethod = state.original_foldmethod
vim.wo.foldenable = state.original_foldenable
vim.wo.foldlevel = state.original_foldlevel
if vim.api.nvim_buf_is_valid(state.scratch) then
  vim.api.nvim_buf_delete(state.scratch, { force = true })
end
if state.client_id then
  vim.lsp.stop_client(state.client_id)
end
_G.ClarityAttachedBehavior = nil
return true
'''


def attached_ui_locale_probe_lua() -> str:
    return r'''
local results = {}
local state = _G.ClarityAttachedBehavior
local original_buf = state and state.original_buf or vim.api.nvim_get_current_buf()
local i18n = require('config.i18n')
local catalog = require('config.actions.catalog')

require('lazy').load({ plugins = { 'which-key.nvim' } })
require('config.menu_i18n').apply()
local wk = require('which-key.config')
results.which_key_loaded = vim.wait(2000, function() return wk.loaded end, 20)

local function identities()
  local rows = {}
  local function collect(prefix, mappings)
    for _, mapping in ipairs(mappings) do
      rows[#rows + 1] = table.concat({
        prefix,
        mapping.lhs or '',
        mapping.rhs or '',
        tostring(mapping.callback),
        tostring(mapping.expr),
        tostring(mapping.nowait),
        tostring(mapping.noremap),
        tostring(mapping.silent),
      }, '\0')
    end
  end
  collect('global', vim.api.nvim_get_keymap('n'))
  collect('buffer', vim.api.nvim_buf_get_keymap(original_buf, 'n'))
  table.sort(rows)
  return rows
end

local function wk_desc(lhs, mode, group)
  local found
  for _, mapping in ipairs(wk.mappings or {}) do
    if mapping.lhs == lhs and mapping.mode == (mode or 'n') and (group == nil or mapping.group == group) then
      found = mapping.desc
    end
  end
  return found
end

i18n.set_choice('en', { persist = false, silent = true })
local before = identities()
local en = {
  code = wk_desc('<leader>c', 'n', true),
  code_action = wk_desc('<leader>ca', 'n'),
  git_preview = wk_desc('<leader>ghp', 'n'),
  health = wk_desc('<leader>hh', 'n'),
}

local zh_ok = i18n.set_choice('zh', { persist = false, silent = true })
local zh = {
  code = wk_desc('<leader>c', 'n', true),
  code_action = wk_desc('<leader>ca', 'n'),
  git_preview = wk_desc('<leader>ghp', 'n'),
  health = wk_desc('<leader>hh', 'n'),
}
local middle = identities()
local en_ok = i18n.set_choice('en', { persist = false, silent = true })
local restored = {
  code = wk_desc('<leader>c', 'n', true),
  code_action = wk_desc('<leader>ca', 'n'),
  git_preview = wk_desc('<leader>ghp', 'n'),
  health = wk_desc('<leader>hh', 'n'),
}
local after = identities()

results.locale_roundtrip = zh_ok == true and en_ok == true
  and en.code == catalog.group_label('code', 'en')
  and en.code_action == catalog.label('lsp.code_action', 'en')
  and en.git_preview == catalog.label('git.hunk_preview', 'en')
  and en.health == catalog.label('health.open', 'en')
  and zh.code == catalog.group_label('code', 'zh')
  and zh.code_action == catalog.label('lsp.code_action', 'zh')
  and zh.git_preview == catalog.label('git.hunk_preview', 'zh')
  and zh.health == catalog.label('health.open', 'zh')
  and vim.deep_equal(en, restored)
results.locale_behavior_identity = vim.deep_equal(before, middle) and vim.deep_equal(before, after)
return results
'''


def attached_ui_component_probe_lua() -> str:
    return r'''
local results = {}
local original_buf = vim.api.nvim_get_current_buf()
local original_win = vim.api.nvim_get_current_win()
local i18n = require('config.i18n')

local function map_rows(bufnr)
  local rows = {}
  for _, mode in ipairs({ 'n', 'i', 'x', 'v', 's' }) do
    for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(bufnr, mode)) do
      rows[#rows + 1] = {
        mode = mode,
        lhs = mapping.lhs,
        desc = mapping.desc,
        identity = table.concat({
          mode,
          mapping.lhs or '',
          mapping.rhs or '',
          tostring(mapping.callback),
          tostring(mapping.expr),
          tostring(mapping.nowait),
          tostring(mapping.noremap),
          tostring(mapping.silent),
        }, '\0'),
      }
    end
  end
  table.sort(rows, function(a, b)
    return a.mode == b.mode and a.lhs < b.lhs or a.mode < b.mode
  end)
  return rows
end

local function identities(rows)
  return vim.tbl_map(function(row) return row.identity end, rows)
end

local function descriptions(rows)
  local ret = {}
  for _, row in ipairs(rows) do
    ret[row.mode .. ':' .. row.lhs] = row.desc
  end
  return ret
end

local function has_forbidden(rows, forbidden)
  for _, row in ipairs(rows) do
    if forbidden[row.lhs:lower()] then return true end
  end
  return false
end

local function has_forbidden_exact(rows, forbidden)
  for _, row in ipairs(rows) do
    if forbidden[row.lhs] then return true end
  end
  return false
end

i18n.set_choice('en', { persist = false, silent = true })
require('neo-tree.command').execute({ action = 'show', source = 'filesystem', dir = vim.g.clarity_repo_root })
local neo_win
results.explorer_opened = vim.wait(3000, function()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buffer = vim.api.nvim_win_get_buf(win)
    if vim.bo[buffer].filetype == 'neo-tree' then neo_win = win; return true end
  end
  return false
end, 20)
if neo_win then
  local neo_buf = vim.api.nvim_win_get_buf(neo_win)
  local en_rows = map_rows(neo_buf)
  local en_desc = descriptions(en_rows)
  local before = identities(en_rows)
  i18n.set_choice('zh', { persist = false, silent = true })
  vim.wait(100, function() return false end, 20)
  local zh_rows = map_rows(neo_buf)
  local zh_desc = descriptions(zh_rows)
  i18n.set_choice('en', { persist = false, silent = true })
  vim.wait(100, function() return false end, 20)
  local restored_rows = map_rows(neo_buf)
  local forbidden = {}
  for _, lhs in ipairs({ 'a', 'A', 'd', 'r', 'x', 'y', 'p', 'c', 'm', '<', '>', 's', 'S', 't', '<Tab>' }) do
    forbidden[lhs] = true
  end
  results.explorer_exact_count = #en_rows == 20
  results.explorer_within_budget = #en_rows <= 24
  results.explorer_mutation_absent = not has_forbidden_exact(en_rows, forbidden)
  results.explorer_numbers_hidden = vim.wo[neo_win].number == false and vim.wo[neo_win].relativenumber == false
  results.explorer_locale_roundtrip = not vim.deep_equal(en_desc, zh_desc)
    and vim.deep_equal(en_desc, descriptions(restored_rows))
    and vim.deep_equal(before, identities(zh_rows))
    and vim.deep_equal(before, identities(restored_rows))
  vim.api.nvim_set_current_win(neo_win)
  vim.api.nvim_feedkeys('q', 'xt', false)
  results.explorer_keyboard_close = vim.wait(500, function()
    return not vim.api.nvim_win_is_valid(neo_win)
  end, 20)
end

if vim.api.nvim_win_is_valid(original_win) then
  vim.api.nvim_set_current_win(original_win)
end
if vim.api.nvim_buf_is_valid(original_buf) then
  vim.api.nvim_win_set_buf(0, original_buf)
end

i18n.set_choice('en', { persist = false, silent = true })
local picker = Snacks.picker.files({ cwd = vim.g.clarity_repo_root })
results.picker_opened = vim.wait(3000, function()
  return picker and not picker.closed and picker.input and picker.input.win and picker.input.win:buf_valid()
end, 20)
if results.picker_opened then
  local wins = { picker.input.win, picker.list.win, picker.preview.win }
  local before_rows = {}
  local max_per_mode = 0
  local picker_counts = {}
  local forbidden = {
    ['<tab>'] = true, ['<s-tab>'] = true, ['<c-a>'] = true, ['<c-q>'] = true,
    ['<c-s>'] = true, ['<c-v>'] = true, ['<c-t>'] = true, ['<c-r>'] = true,
  }
  local denied = false
  for _, win in ipairs(wins) do
    local rows = map_rows(win.buf)
    before_rows[win.buf] = rows
    denied = denied or has_forbidden(rows, forbidden)
    local counts = {}
    for _, row in ipairs(rows) do
      counts[row.mode] = (counts[row.mode] or 0) + 1
      if row.lhs == 'dd' then denied = true end
    end
    picker_counts[tostring(win.buf)] = counts
    for _, count in pairs(counts) do max_per_mode = math.max(max_per_mode, count) end
  end
  i18n.set_choice('zh', { persist = false, silent = true })
  vim.wait(100, function() return false end, 20)
  local changed = false
  local identities_stable = true
  for _, win in ipairs(wins) do
    local rows = map_rows(win.buf)
    changed = changed or not vim.deep_equal(descriptions(before_rows[win.buf]), descriptions(rows))
    identities_stable = identities_stable and vim.deep_equal(identities(before_rows[win.buf]), identities(rows))
  end
  i18n.set_choice('en', { persist = false, silent = true })
  vim.wait(100, function() return false end, 20)
  local restored = true
  for _, win in ipairs(wins) do
    local rows = map_rows(win.buf)
    restored = restored and vim.deep_equal(descriptions(before_rows[win.buf]), descriptions(rows))
      and vim.deep_equal(identities(before_rows[win.buf]), identities(rows))
  end
  results.picker_within_budget = max_per_mode <= 20
  results.picker_max_per_mode = max_per_mode
  results.picker_counts = picker_counts
  results.picker_mutation_absent = not denied
  results.picker_locale_roundtrip = changed and identities_stable and restored
  vim.api.nvim_set_current_win(picker.input.win.win)
  vim.api.nvim_feedkeys(vim.keycode('<Esc>'), 'xt', false)
  results.picker_keyboard_close = vim.wait(500, function() return picker.closed end, 20)
end

if vim.api.nvim_win_is_valid(original_win) then
  vim.api.nvim_set_current_win(original_win)
end
if vim.api.nvim_buf_is_valid(original_buf) then
  vim.api.nvim_win_set_buf(0, original_buf)
end
return results
'''


def attached_ui_human_surface_probe_lua() -> str:
    return r'''
local results = {}
local original_buf = vim.api.nvim_get_current_buf()
local original_win = vim.api.nvim_get_current_win()
local i18n = require('config.i18n')

i18n.set_choice('en', { persist = false, silent = true })
local dashboard = Snacks.dashboard.open()
local function dashboard_actions()
  local ret = {}
  for _, item in ipairs(dashboard.items or {}) do
    if item.key then ret[#ret + 1] = { key = item.key, desc = item.desc, action = item.action } end
  end
  return ret
end
local en_dashboard = dashboard_actions()
i18n.set_choice('zh', { persist = false, silent = true })
vim.wait(100, function() return false end, 20)
local zh_dashboard = dashboard_actions()
i18n.set_choice('en', { persist = false, silent = true })
vim.wait(100, function() return false end, 20)
local restored_dashboard = dashboard_actions()
local expected_keys = { 'f', 'g', 'r', 'n', 'h', 'q' }
local exact_keys = #en_dashboard == #expected_keys
for index, key in ipairs(expected_keys) do
  exact_keys = exact_keys and en_dashboard[index] and en_dashboard[index].key == key
end
results.dashboard_exact = exact_keys
results.dashboard_locale_roundtrip = not vim.deep_equal(en_dashboard, zh_dashboard)
  and vim.deep_equal(en_dashboard, restored_dashboard)
vim.api.nvim_set_current_win(dashboard.win)
vim.api.nvim_feedkeys('h', 'xt', false)
results.dashboard_keyboard_action = vim.wait(1000, function()
  return vim.api.nvim_buf_get_name(0) == 'clarity://health'
end, 20)

local health = require('config.health')
local health_buf = results.dashboard_keyboard_action and vim.api.nvim_get_current_buf() or health.open('overview')
local function text(buffer)
  return table.concat(vim.api.nvim_buf_get_lines(buffer, 0, -1, false), '\n')
end
local en_health = text(health_buf)
vim.api.nvim_win_set_cursor(0, { math.min(10, vim.api.nvim_buf_line_count(health_buf)), 0 })
local cursor = vim.api.nvim_win_get_cursor(0)
i18n.set_choice('zh', { persist = false, silent = true })
vim.wait(100, function() return false end, 20)
local zh_health = text(health_buf)
local same_cursor = vim.deep_equal(cursor, vim.api.nvim_win_get_cursor(0))
i18n.set_choice('en', { persist = false, silent = true })
vim.wait(100, function() return false end, 20)
results.health_readonly = vim.bo[health_buf].readonly and not vim.bo[health_buf].modifiable
results.health_locale_roundtrip = health_buf == vim.api.nvim_get_current_buf()
  and not vim.deep_equal(en_health, zh_health)
  and en_health == text(health_buf)
  and same_cursor
results.health_routes_complete = #health.route_order == 7
vim.api.nvim_feedkeys('q', 'xt', false)
results.health_keyboard_close = vim.wait(500, function()
  return vim.api.nvim_get_current_buf() ~= health_buf
end, 20)
if vim.api.nvim_win_is_valid(original_win) then vim.api.nvim_set_current_win(original_win) end
if vim.api.nvim_buf_is_valid(original_buf) then vim.api.nvim_win_set_buf(0, original_buf) end
return results
'''


def attached_ui_git_probe_lua() -> str:
    return r'''
local results = {}
local original_buf = vim.api.nvim_get_current_buf()
local original_win = vim.api.nvim_get_current_win()
local actions = {
  { lhs = '<leader>gs', name = 'status' },
  { lhs = '<leader>gd', name = 'diff' },
  { lhs = '<leader>gl', name = 'log' },
  { lhs = '<leader>gt', name = 'branch_graph' },
  { lhs = '<leader>gb', name = 'blame_line' },
}
local opened = 0
local safe = true
local closed = true
for _, action in ipairs(actions) do
  vim.api.nvim_set_current_win(original_win)
  vim.api.nvim_win_set_buf(original_win, original_buf)
  local mapping = vim.fn.maparg(action.lhs, 'n', false, true)
  if type(mapping.callback) == 'function' then mapping.callback() else safe = false end
  local expected = 'clarity://git/' .. action.name
  local ready = vim.wait(7000, function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buffer = vim.api.nvim_win_get_buf(win)
      if vim.api.nvim_buf_get_name(buffer) == expected then return true end
    end
    return false
  end, 20)
  if ready then
    opened = opened + 1
    local view_win
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win)) == expected then view_win = win; break end
    end
    local buffer = vim.api.nvim_win_get_buf(view_win)
    safe = safe and vim.bo[buffer].readonly and not vim.bo[buffer].modifiable
    for _, lhs in ipairs({ '<Tab>', '<C-r>', '<CR>' }) do
      local found = false
      for _, mapping_row in ipairs(vim.api.nvim_buf_get_keymap(buffer, 'n')) do
        if mapping_row.lhs:lower() == lhs:lower() then found = true end
      end
      safe = safe and not found
      vim.api.nvim_set_current_win(view_win)
      vim.api.nvim_feedkeys(vim.keycode(lhs), 'xt', false)
      vim.wait(30, function() return false end, 10)
    end
    vim.api.nvim_set_current_win(view_win)
    vim.api.nvim_feedkeys('q', 'xt', false)
    closed = closed and vim.wait(500, function() return not vim.api.nvim_win_is_valid(view_win) end, 20)
  else
    safe = false
  end
end

vim.api.nvim_set_current_win(original_win)
vim.api.nvim_win_set_buf(original_win, original_buf)
local hunk_inputs = true
for _, lhs in ipairs({ ']h', '[h', '<leader>ghp' }) do
  local mapping = vim.fn.maparg(lhs, 'n', false, true)
  if type(mapping.callback) == 'function' then
    mapping.callback()
    vim.wait(100, function() return false end, 20)
  else
    hunk_inputs = false
  end
end
results.git_observation_views = opened == #actions
results.git_observation_safe = safe and closed
results.gitsigns_observation_input = hunk_inputs
return results
'''


def attached_ui_terminal_probe_lua() -> str:
    return r'''
local results = {}
local original_buf = vim.api.nvim_get_current_buf()
local original_win = vim.api.nvim_get_current_win()
local mapping = vim.fn.maparg('<leader>tf', 'n', false, true)
results.terminal_mapping = type(mapping.callback) == 'function'

vim.api.nvim_feedkeys(' tf', 'xt', false)
local terminal_win
results.terminal_opened = vim.wait(3000, function()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buffer = vim.api.nvim_win_get_buf(win)
    if vim.bo[buffer].filetype == 'snacks_terminal' and vim.bo[buffer].buftype == 'terminal' then
      terminal_win = win
      return true
    end
  end
  return false
end, 20)

if terminal_win then
  results.terminal_float = vim.api.nvim_win_get_config(terminal_win).relative ~= ''
  results.terminal_numbers_hidden = not vim.wo[terminal_win].number and not vim.wo[terminal_win].relativenumber
  vim.api.nvim_set_current_win(terminal_win)
  vim.cmd.stopinsert()
  vim.api.nvim_feedkeys(' tf', 'xt', false)
  results.terminal_keyboard_close = vim.wait(1000, function()
    return not vim.api.nvim_win_is_valid(terminal_win)
  end, 20)
end

if vim.api.nvim_win_is_valid(original_win) then
  vim.api.nvim_set_current_win(original_win)
end
if vim.api.nvim_buf_is_valid(original_buf) then
  vim.api.nvim_win_set_buf(0, original_buf)
end
return results
'''


def attached_ui_dependency_probe_lua() -> str:
    return r'''
local results = {}
local original_buf = vim.api.nvim_get_current_buf()
local original_win = vim.api.nvim_get_current_win()
local lazy_config = require('lazy.core.config')

local function active_plugin(name)
  local plugin = lazy_config.plugins[name]
  return plugin ~= nil and plugin.enabled ~= false
end

results.removed_dependencies_inactive = true
for _, name in ipairs({
  'friendly-snippets', 'lazydev.nvim', 'lush.nvim', 'mason.nvim', 'mason-lspconfig.nvim'
}) do
  results.removed_dependencies_inactive = results.removed_dependencies_inactive and not active_plugin(name)
end
results.no_mason_route = vim.fn.exists(':Mason') == 0
  and vim.fn.isdirectory(vim.fs.joinpath(vim.fn.stdpath('data'), 'mason')) == 0

require('lazy').load({ plugins = { 'blink.cmp', 'mini.pairs', 'conform.nvim' } })
results.blink_loaded = package.loaded['blink.cmp'] ~= nil or pcall(require, 'blink.cmp')

local snippet_buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_win_set_buf(original_win, snippet_buf)
vim.bo[snippet_buf].filetype = 'lua'
local snippet_ok = pcall(vim.snippet.expand, 'local ${1:name} = ${2:value}')
results.native_snippet = snippet_ok and vim.wait(500, function()
  return vim.api.nvim_buf_get_lines(snippet_buf, 0, 1, false)[1] == 'local name = value'
end, 20)
pcall(vim.snippet.stop)

local pair_buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_win_set_buf(original_win, pair_buf)
vim.bo[pair_buf].filetype = 'lua'
vim.api.nvim_buf_set_lines(pair_buf, 0, -1, false, { '' })
vim.api.nvim_feedkeys(vim.keycode('<C-\\><C-n>i('), 'xt', false)
results.mini_pairs_input = vim.wait(500, function()
  return vim.api.nvim_buf_get_lines(pair_buf, 0, 1, false)[1] == '()'
end, 20)
results.mini_pairs_line = vim.api.nvim_buf_get_lines(pair_buf, 0, 1, false)[1]
results.mini_pairs_mode = vim.api.nvim_get_mode().mode
vim.api.nvim_feedkeys(vim.keycode('<Esc>'), 'xt', false)

local conform = require('conform')
local format_buf = vim.api.nvim_create_buf(false, false)
local format_path = vim.fs.joinpath(vim.g.clarity_repo_root, 'tests', 'fixtures', 'runtime', 'format-project', 'sample.lua')
vim.api.nvim_buf_set_name(format_buf, format_path)
vim.api.nvim_win_set_buf(original_win, format_buf)
vim.bo[format_buf].filetype = 'lua'
vim.api.nvim_buf_set_lines(format_buf, 0, -1, false, { 'function example()', "    print('ok')", 'end' })
local present = conform.get_formatter_info('stylua', format_buf)
local format_ok = pcall(conform.format, {
  bufnr = format_buf,
  async = false,
  timeout_ms = 3000,
  formatters = { 'stylua' },
  lsp_format = 'never',
  quiet = true,
})
local formatted = vim.api.nvim_buf_get_lines(format_buf, 0, -1, false)
results.formatter_present = present.available == true and format_ok
results.formatter_project_config = formatted[2] == "  print('ok')"
results.formatter_lines = formatted
local log_ok, invocation = pcall(function()
  return vim.json.decode(table.concat(vim.fn.readfile(vim.env.CLARITY_FAKE_FORMATTER_LOG), '\n'))
end)
local argv = log_ok and invocation.argv or {}
results.formatter_invocation = invocation
local joined = table.concat(argv, '\0')
results.formatter_no_style_args = log_ok
  and not joined:find('%-%-indent%-width')
  and not joined:find('%-%-column%-width')
  and not joined:find('%-%-line%-length')

vim.fn.delete(vim.env.CLARITY_FAKE_FORMATTER_BIN)
local missing = conform.get_formatter_info('stylua', format_buf)
local before_missing = vim.api.nvim_buf_get_lines(format_buf, 0, -1, false)
local missing_ok = pcall(conform.format, {
  bufnr = format_buf,
  async = false,
  timeout_ms = 1000,
  formatters = { 'stylua' },
  lsp_format = 'never',
  quiet = true,
})
results.formatter_missing_detected = not missing.available
  and tostring(missing.available_msg):find('not found', 1, true) ~= nil
results.formatter_missing_stable = missing_ok
  and vim.deep_equal(before_missing, vim.api.nvim_buf_get_lines(format_buf, 0, -1, false))
  and vim.fn.exists(':Mason') == 0

local before_theme = {
  name = vim.g.colors_name,
  normal = vim.api.nvim_get_hl(0, { name = 'Normal', link = false }),
  visual = vim.api.nvim_get_hl(0, { name = 'Visual', link = false }),
}
vim.cmd.colorscheme('custom_colorblind_theme')
results.static_theme_reload = vim.g.colors_name == 'custom_colorblind_theme'
  and before_theme.name == 'custom_colorblind_theme'
  and vim.deep_equal(before_theme.normal, vim.api.nvim_get_hl(0, { name = 'Normal', link = false }))
  and vim.deep_equal(before_theme.visual, vim.api.nvim_get_hl(0, { name = 'Visual', link = false }))

vim.fn.delete(vim.env.CLARITY_FAKE_LSP_BIN)
for _, client in ipairs(vim.lsp.get_clients({ name = 'lua_ls' })) do
  vim.lsp.stop_client(client.id, true)
end
vim.wait(1000, function() return #vim.lsp.get_clients({ name = 'lua_ls' }) == 0 end, 20)
local missing_lsp_buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_name(missing_lsp_buf, vim.fs.joinpath(vim.g.clarity_repo_root, 'missing-server-contract.lua'))
vim.api.nvim_win_set_buf(original_win, missing_lsp_buf)
vim.bo[missing_lsp_buf].filetype = 'lua'
vim.wait(500, function() return false end, 20)
results.missing_lsp_no_install = vim.lsp.is_enabled('lua_ls')
  and #vim.lsp.get_clients({ bufnr = missing_lsp_buf, name = 'lua_ls' }) == 0
  and vim.fn.exists(':Mason') == 0
  and vim.fn.isdirectory(vim.fs.joinpath(vim.fn.stdpath('data'), 'mason')) == 0

if vim.api.nvim_win_is_valid(original_win) then vim.api.nvim_set_current_win(original_win) end
if vim.api.nvim_buf_is_valid(original_buf) then vim.api.nvim_win_set_buf(original_win, original_buf) end
for _, buffer in ipairs({ snippet_buf, pair_buf, format_buf, missing_lsp_buf }) do
  if vim.api.nvim_buf_is_valid(buffer) then pcall(vim.api.nvim_buf_delete, buffer, { force = true }) end
end
return results
'''


def run_attached_ui(
    candidate_root: Path,
    nvim_bin: str,
    env: dict[str, str],
    wait_ms: int,
) -> tuple[dict[str, Any], dict[str, Any]]:
    try:
        import pynvim
    except ImportError as exc:
        raise RuntimeError(
            "file_ui requires pynvim. Run with: uv run --with pynvim python scripts/run_clarity_contracts.py ..."
        ) from exc

    probe = candidate_root / "tests" / "lua" / "runtime_probe.lua"
    observe = "lua dofile(" + lua_string(probe) + ").observe()"
    argv = [
        nvim_bin,
        "--embed",
        "--cmd",
        observe,
        "-u",
        str(candidate_root / "init.lua"),
        str(candidate_root / "tests" / "fixtures" / "runtime" / "sample.lua"),
    ]
    with process_context(candidate_root, env):
        nvim = pynvim.attach("child", argv=argv)
    try:
        nvim.ui_attach(80, 24, rgb=True)
        ready = nvim.exec_lua(
            "local path, wait_ms = ...; local p=dofile(path); "
            "return vim.wait(wait_ms, function() return p.ready('file_ui') end, 20)",
            str(probe),
            wait_ms,
        )
        snapshot = nvim.exec_lua("return dofile(...).snapshot('file_ui')", str(probe))
        snapshot["ready"] = ready
        behavior = nvim.exec_lua(attached_ui_behavior_setup_lua())
        behavior.update(nvim.exec_lua(attached_ui_locale_probe_lua()))
        messages_before = nvim.exec_lua("return vim.api.nvim_exec2('messages', { output = true }).output")

        def input_fold(expected_closed: int | None, before_events: int) -> tuple[bool, str | None]:
            try:
                nvim.input(" cz")
                settled = nvim.exec_lua(
                    "local expected, before = ...; return vim.wait(500, function() "
                    "local count = #require('config.diagnostics').events(); "
                    "return (expected ~= nil and vim.fn.foldclosed(1) == expected) or count > before end, 20)",
                    expected_closed,
                    before_events,
                )
                return bool(settled), None
            except Exception as exc:  # pynvim surfaces mapping errors as RPC failures on the next request
                return False, str(exc)

        before = nvim.exec_lua(attached_ui_fold_state_lua())
        open_ok, open_error = input_fold(-1, before["event_count"])
        opened = nvim.exec_lua(attached_ui_fold_state_lua())
        close_ok, close_error = input_fold(1, opened["event_count"])
        reclosed = nvim.exec_lua(attached_ui_fold_state_lua())
        nvim.exec_lua("vim.cmd('normal! zE'); vim.v.errmsg = ''")
        no_fold_ok, no_fold_rpc_error = input_fold(None, reclosed["event_count"])
        no_fold = nvim.exec_lua(attached_ui_fold_state_lua())
        behavior.update(
            {
                "fold_input": True,
                "fold_open_input_ok": open_ok,
                "fold_open_rpc_error": open_error,
                "fold_opened": opened["closed"] == -1,
                "fold_open_outcome": opened.get("outcome"),
                "fold_close_input_ok": close_ok,
                "fold_close_rpc_error": close_error,
                "fold_reclosed": reclosed["closed"] == 1,
                "fold_close_outcome": reclosed.get("outcome"),
                "fold_no_fold_ok": no_fold_ok,
                "fold_no_fold_rpc_error": no_fold_rpc_error,
                "fold_no_fold_outcome": no_fold.get("outcome"),
                "fold_no_fold_event_id": no_fold.get("event_id"),
                "fold_no_fold_error": no_fold.get("errmsg", ""),
                "fold_messages_delta": no_fold.get("messages", "")[len(messages_before) :],
                "fold_cleanup": nvim.exec_lua(attached_ui_behavior_cleanup_lua()),
            }
        )
        behavior.update(nvim.exec_lua(attached_ui_git_probe_lua()))
        original_buffer = nvim.exec_lua("return vim.api.nvim_get_current_buf()")
        nvim.ui_try_resize(60, 16)
        nvim.command("ClarityLog")
        log_small = nvim.exec_lua(
            "local b=vim.api.nvim_get_current_buf(); return {"
            "name=vim.api.nvim_buf_get_name(b), readonly=vim.bo[b].readonly, "
            "modifiable=vim.bo[b].modifiable, lines=vim.api.nvim_buf_line_count(b), "
            "route=vim.b[b].clarity_health_route}"
        )
        nvim.ui_try_resize(80, 24)
        nvim.command("ClarityLog tail")
        log_tail = nvim.exec_lua(
            "local b=vim.api.nvim_get_current_buf(); return {"
            "name=vim.api.nvim_buf_get_name(b), route=vim.b[b].clarity_health_route}"
        )
        behavior.update(
            {
                "log_health_route": log_small.get("name") == "clarity://health"
                and log_small.get("route") == "events"
                and log_small.get("lines", 0) > 0,
                "log_readonly": log_small.get("readonly") is True and log_small.get("modifiable") is False,
                "log_equivalent_route": log_tail.get("name") == "clarity://health"
                and log_tail.get("route") == "events",
                "log_cleanup": nvim.exec_lua(
                    "local b=...; if vim.api.nvim_buf_is_valid(b) then "
                    "vim.api.nvim_win_set_buf(0,b); return true end; return false",
                    original_buffer,
                ),
            }
        )
        behavior.update(nvim.exec_lua(attached_ui_component_probe_lua()))
        behavior.update(nvim.exec_lua(attached_ui_human_surface_probe_lua()))
        behavior.update(nvim.exec_lua(attached_ui_terminal_probe_lua()))
        behavior.update(nvim.exec_lua(attached_ui_dependency_probe_lua()))
        return snapshot, behavior
    finally:
        try:
            nvim.exec_lua("vim.defer_fn(function() vim.cmd('qall!') end, 10)")
            try:
                nvim.run_loop(lambda _name, _args: None, lambda _name, _args: None)
            except EOFError:
                pass
        finally:
            nvim.close()


def _result(
    check: dict[str, Any],
    scenario: str,
    ok: bool,
    actual: Any,
    phase: str | None = None,
) -> dict[str, Any]:
    return {
        "id": check["id"],
        "scenario": scenario,
        "phase": phase,
        "owner": check["owner"],
        "expected": check["expected"],
        "actual": actual,
        "ok": ok,
        "severity": "required",
        "repair": check["repair"],
        "evidence_source": "runtime_probe",
    }


def evaluate_snapshot(
    catalog: dict[str, Any],
    snapshot: dict[str, Any],
    behavior: dict[str, Any] | None = None,
) -> list[dict[str, Any]]:
    scenario = snapshot["scenario"]
    results: list[dict[str, Any]] = []
    modules = snapshot.get("modules", {})
    for check in catalog["checks"]:
        if scenario not in check["scenarios"]:
            continue
        kind = check["kind"]
        phase = None
        if kind == "module_phase":
            module = modules.get(check["module"], {})
            phase = module.get("first_seen")
            actual = {"loaded": module.get("loaded", False), "first_seen": phase}
            ok = actual["loaded"] and phase == check["expected"]
        elif kind == "autocmds_contract":
            module = modules.get(check["module"], {})
            phase = module.get("first_seen")
            count = snapshot.get("autocmds", {}).get("absolute_line_numbers", 0)
            actual = {"loaded": module.get("loaded", False), "first_seen": phase, "owned_autocmds": count}
            ok = actual["loaded"] and phase == "User:LazyVimAutocmds" and count >= 4
        elif kind == "editing_defaults":
            options = snapshot.get("options", {})
            actual = {
                name: options.get(name)
                for name in ("number", "relativenumber", "wrap", "linebreak", "breakindent", "conceallevel")
            }
            ok = actual == {
                "number": True,
                "relativenumber": False,
                "wrap": True,
                "linebreak": True,
                "breakindent": True,
                "conceallevel": 0,
            }
        elif kind == "keymap_contract":
            module = modules.get(check["module"], {})
            phase = module.get("first_seen")
            maps = snapshot.get("maps", {})
            sources = [maps.get(name, {}).get("source") for name in ("leader_uw", "leader_cz")]
            normalized_sources = [str(source).replace("\\", "/") for source in sources]
            owner_ok = bool(sources[0]) and normalized_sources[0].endswith("/nvim/lua/config/keymaps.lua")
            behavior = behavior or {}
            behavior_ok = all(
                behavior.get(name) is True
                for name in ("global_leader_exact", "dynamic_leader_exact", "full_context_within_budget")
            )
            actual = {
                "loaded": module.get("loaded", False),
                "first_seen": phase,
                "sources": sources,
                "behavior": behavior,
            }
            ok = actual["loaded"] and phase == "User:LazyVimKeymaps" and owner_ok and behavior_ok
        elif kind == "behavior_contract":
            behavior = behavior or {}
            flags = {name: behavior.get(name) for name in check.get("flags", [])}
            equals = {name: behavior.get(name) for name in check.get("equals", {})}
            actual = {"flags": flags, "equals": equals}
            ok = all(value is True for value in flags.values()) and all(
                equals.get(name) == expected for name, expected in check.get("equals", {}).items()
            )
        elif kind == "modules_loaded":
            actual = {name: modules.get(name, {}).get("loaded", False) for name in check["modules"]}
            ok = all(actual.values())
        else:
            actual = f"unsupported check kind: {kind}"
            ok = False
        results.append(_result(check, scenario, ok, actual, phase))
    return results


def coverage_summary(catalog: dict[str, Any], repo_root: Path) -> dict[str, Any]:
    modules = set(catalog.get("modules", {}))
    discovered = discover_config_modules(repo_root)
    counts: dict[str, int] = {}
    for capability in catalog.get("capabilities", {}).values():
        coverage = capability["coverage"]
        counts[coverage] = counts.get(coverage, 0) + 1
    return {
        "modules": {
            "classified": len(modules & discovered),
            "unclassified": sorted(discovered - modules),
            "missing": sorted(modules - discovered),
        },
        "capabilities": counts,
    }


def run_scenario(
    source_root: Path,
    catalog: dict[str, Any],
    scenario: str,
    nvim_bin: str,
    timeout: float,
    plugin_cache: Path | None,
    fault: str | None,
) -> dict[str, Any]:
    with tempfile.TemporaryDirectory(prefix=f"clarity-contract-{scenario}-") as directory:
        scenario_root = Path(directory)
        candidate_root = scenario_root / "candidate"
        runtime_root = scenario_root / "runtime"
        copy_candidate(source_root, candidate_root)
        apply_fault(candidate_root, fault)
        before = authority_hashes(candidate_root)
        env = configure_isolated_runtime(build_env(), runtime_root)
        env["CLARITY_CONTRACT_CATALOG"] = str(candidate_root / "tests" / "contracts" / "runtime_contract.lua")
        env["CLARITY_CONTRACT_SCENARIO"] = scenario
        if scenario == "file_ui":
            prepare_attached_context_fixture(candidate_root, runtime_root, env, timeout)
        if plugin_cache:
            copy_plugin_cache(plugin_cache, runtime_root)

        behavior = None
        if scenario == "file_ui":
            repository_before = repository_snapshot(candidate_root, env, timeout)
            snapshot, behavior = run_attached_ui(candidate_root, nvim_bin, env, min(int(timeout * 1000), 5000))
            repository_after = repository_snapshot(candidate_root, env, timeout)
            behavior["repository_immutable"] = repository_before == repository_after
            behavior["repository_snapshot_before"] = repository_before
            behavior["repository_snapshot_after"] = repository_after
        else:
            command = build_headless_command(candidate_root, nvim_bin, scenario, min(int(timeout * 1000), 5000))
            result = run_command(command, cwd=candidate_root, env=env, timeout=timeout)
            if result.returncode != 0:
                raise RuntimeError(f"{scenario} failed with exit {result.returncode}:\n{combined_output(result)}")
            snapshot = extract_last_json_object(combined_output(result))

        after = authority_hashes(candidate_root)
        results = evaluate_snapshot(catalog, snapshot, behavior)
        expected_paths = {
            "repo": str(candidate_root.resolve()).replace("\\", "/"),
            "lock": str((candidate_root / "lazy-lock.json").resolve()).replace("\\", "/"),
            "json": str((candidate_root / "lazyvim.json").resolve()).replace("\\", "/"),
        }
        actual_paths = {key: str(snapshot["paths"].get(key)).replace("\\", "/") for key in expected_paths}
        results.extend(
            [
                {
                    "id": "CLARITY_RUNTIME_AUTHORITY_PATHS",
                    "scenario": scenario,
                    "phase": None,
                    "owner": "root bootstrap",
                    "expected": expected_paths,
                    "actual": actual_paths,
                    "ok": actual_paths == expected_paths,
                    "severity": "required",
                    "repair": "Restore explicit repository root lock and LazyVim JSON paths.",
                    "evidence_source": "runtime_probe",
                },
                {
                    "id": "CLARITY_RUNTIME_AUTHORITY_IMMUTABLE",
                    "scenario": scenario,
                    "phase": None,
                    "owner": "scenario runner",
                    "expected": before,
                    "actual": after,
                    "ok": before == after,
                    "severity": "required",
                    "repair": "Move generated updates to an explicit transaction and keep startup read-only.",
                    "evidence_source": "sha256",
                },
            ]
        )
        return {
            "scenario": scenario,
            "fault": fault,
            "snapshot": snapshot,
            "behavior": behavior,
            "hashes": {"before": before, "after": after},
            "checks": results,
        }


def main() -> int:
    parser = argparse.ArgumentParser(description="Run Clarity natural-lifecycle runtime contracts.")
    parser.add_argument(
        "--scenario",
        action="append",
        choices=("empty_headless", "file_headless", "file_ui"),
        help="Scenario to run; repeatable. Defaults to empty_headless and file_headless.",
    )
    parser.add_argument("--fault", choices=(FAULT_MISSING_NESTED_RUNTIME, FAULT_RAW_FOLD_ACTION))
    parser.add_argument("--expect-failure-id", action="append", default=[])
    parser.add_argument("--reuse-plugin-cache", type=Path)
    parser.add_argument("--nvim-bin")
    parser.add_argument("--timeout", type=float, default=120)
    parser.add_argument("--json", action="store_true", help="Retained for command compatibility; output is JSON.")
    args = parser.parse_args()

    source_root = Path(__file__).resolve().parent.parent
    nvim = resolve_nvim_binary(args.nvim_bin)
    catalog = load_catalog(source_root, nvim)
    issues = catalog_issues(catalog, discover_config_modules(source_root), discover_task_ids(source_root))
    if issues:
        print(json.dumps({"status": "fail", "catalog_issues": issues}, indent=2, ensure_ascii=False))
        return 1

    scenarios = args.scenario or ["empty_headless", "file_headless"]
    source_before = authority_hashes(source_root)
    reports = [
        run_scenario(
            source_root,
            catalog,
            scenario,
            nvim,
            args.timeout,
            args.reuse_plugin_cache.resolve() if args.reuse_plugin_cache else None,
            args.fault,
        )
        for scenario in scenarios
    ]
    source_after = authority_hashes(source_root)
    all_checks = [check for report in reports for check in report["checks"]]
    if source_before != source_after:
        all_checks.append(
            {
                "id": "CLARITY_RUNTIME_SOURCE_IMMUTABLE",
                "scenario": "source",
                "phase": None,
                "owner": "scenario runner",
                "expected": source_before,
                "actual": source_after,
                "ok": False,
                "severity": "required",
                "repair": "Never run contract scenarios against source authority files.",
                "evidence_source": "sha256",
            }
        )

    actual_failures = sorted({check["id"] for check in all_checks if not check["ok"]})
    expected_failures = sorted(set(args.expect_failure_id))
    expectation_ok = bool(expected_failures) and actual_failures == expected_failures
    status = "expected_failure" if expectation_ok else ("pass" if not actual_failures else "fail")
    report = {
        "schema_version": 1,
        "status": status,
        "fault": args.fault,
        "scenarios": reports,
        "coverage": coverage_summary(catalog, source_root),
        "failure_ids": actual_failures,
        "expected_failure_ids": expected_failures,
        "source_hashes": {"before": source_before, "after": source_after},
    }
    print(json.dumps(report, indent=2, ensure_ascii=False))
    return 0 if status in {"pass", "expected_failure"} else 1


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (RuntimeError, ValueError) as exc:
        print(str(exc), file=sys.stderr)
        raise SystemExit(1) from exc
