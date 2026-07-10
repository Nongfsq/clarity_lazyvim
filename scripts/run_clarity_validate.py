from __future__ import annotations

import argparse
import json
import re
import shutil
import sys
from dataclasses import asdict, dataclass
from pathlib import Path

from clarity_runtime import (
    build_env,
    combined_output,
    extract_last_json_object,
    resolve_nvim_binary,
    run_command,
    run_nvim,
)


@dataclass
class CheckResult:
    name: str
    ok: bool
    details: str
    required: bool = True

    @property
    def id(self) -> str:
        normalized = re.sub(r"[^A-Z0-9]+", "_", self.name.upper()).strip("_")
        return "CLARITY_VALIDATE_" + normalized


def run_doctor_json(repo_root: Path, env: dict[str, str]) -> dict:
    result = run_command(
        [sys.executable, str(repo_root / "scripts" / "clarity_doctor.py"), "--json"],
        cwd=repo_root,
        env=env,
        timeout=120,
    )

    if result.returncode not in (0, 1):
        raise RuntimeError((result.stderr or result.stdout).strip() or "doctor command failed")

    return json.loads(result.stdout)


def parse_node_major(version_text: str) -> int | None:
    match = re.search(r"v(\d+)\.", version_text)
    return int(match.group(1)) if match else None


def resolve_executable(name: str) -> str | None:
    return shutil.which(name)


def run(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Run Clarity behavior validation.")
    parser.add_argument("--json", action="store_true", help="Emit a machine-readable validation report.")
    parser.add_argument("--nvim-bin", help="Neovim executable; defaults to NVIM_BIN or PATH.")
    args = parser.parse_args(argv)

    repo_root = Path(__file__).resolve().parent.parent
    env = build_env()
    nvim_bin = resolve_nvim_binary(args.nvim_bin)
    checks: list[CheckResult] = []

    startup = run_nvim(
        repo_root,
        nvim_bin,
        ["+doautocmd User VeryLazy", "+lua vim.wait(120)"],
        env,
    )
    checks.append(
        CheckResult(
            name="Headless startup",
            ok=startup.returncode == 0,
            details=(startup.stderr or startup.stdout).strip() or "ok",
        )
    )
    if startup.returncode != 0:
        print("Validation failed before runtime assertions.")
        for check in checks:
            marker = "PASS" if check.ok else "FAIL"
            print(f"[{marker}] {check.name}: {check.details}")
        return 1

    audit = run_nvim(repo_root, nvim_bin, ["+ClarityAudit!"], env)
    audit_output = combined_output(audit)
    if audit.returncode != 0:
        checks.append(CheckResult("ClarityAudit command", False, audit_output or "command failed"))
        report = {}
    else:
        report = extract_last_json_object(audit_output)
        core = report.get("summary", {}).get("core", {})
        required_ok = core.get("passed", 0)
        required_total = core.get("total", 0)
        checks.append(
            CheckResult(
                name="ClarityAudit command",
                ok=True,
                details=f"core={core.get('status', 'unknown')}",
            )
        )
        checks.append(
            CheckResult(
                name="Required tools present",
                ok=required_ok == required_total and required_total > 0,
                details=f"{required_ok}/{required_total}",
            )
        )

    runtime_lua = (
        "local function has_map(lhs, mode) "
        "local m = vim.fn.maparg(lhs, mode, false, true); "
        "return type(m) == 'table' and next(m) ~= nil "
        "end; "
        "local function option_contains(option_value, expected) "
        "if type(option_value) == 'string' then "
        "return option_value ~= '' and option_value == expected "
        "end; "
        "return vim.tbl_contains(option_value or {}, expected) "
        "end; "
        "local results = {}; "
        "results.keymap_ff = has_map('<leader>ff', 'n'); "
        "results.keymap_fw = has_map('<leader>fw', 'n'); "
        "results.keymap_gd = has_map('<leader>gd', 'n'); "
        "results.keymap_cz = has_map('<leader>cz', 'n'); "
        "results.keymap_uw = has_map('<leader>uw', 'n'); "
        "results.keymap_tf = has_map('<leader>tf', 'n'); "
        "results.keymap_hh = has_map('<leader>hh', 'n'); "
        "results.absolute_number = vim.wo.number; "
        "results.relative_number = vim.wo.relativenumber; "
        "results.wrap_default = vim.wo.wrap; "
        "results.options_loaded = package.loaded['config.options'] ~= nil; "
        "results.autocmds_loaded = package.loaded['config.autocmds'] ~= nil; "
        "results.keymaps_loaded = package.loaded['config.keymaps'] ~= nil; "
        "results.absolute_number_autocmd = vim.fn.exists('#clarity_absolute_line_numbers#BufEnter') == 1; "
        "vim.wait(1200, function() return vim.b.gitsigns_head ~= nil and vim.b.clarity_gitsigns_keymaps == true end); "
        "results.gitsigns_head = vim.b.gitsigns_head ~= nil; "
        "results.gitsigns_keymaps = vim.b.clarity_gitsigns_keymaps == true; "
        "results.keymap_hs = has_map('<leader>hs', 'n'); "
        "results.clipboard_unnamedplus = option_contains(vim.opt.clipboard:get(), 'unnamedplus'); "
        "results.clipboard_provider = vim.fn['provider#clipboard#Executable'](); "
        "results.neotree_cmd = (vim.fn.exists(':Neotree') == 2); "
        "local neo_ok, neo_err = pcall(vim.cmd, 'Neotree show'); "
        "results.neotree_open_ok = neo_ok; "
        "if not neo_ok then results.neotree_error = tostring(neo_err); end; "
        "vim.wait(150); "
        "results.neotree_window_found = false; "
        "for _, w in ipairs(vim.api.nvim_list_wins()) do "
        "local b = vim.api.nvim_win_get_buf(w); "
        "if vim.bo[b].filetype == 'neo-tree' then "
        "results.neotree_window_found = true; "
        "results.neotree_number = vim.wo[w].number; "
        "results.neotree_relativenumber = vim.wo[w].relativenumber; "
        "end; end; "
        "print(vim.json.encode(results));"
    )
    runtime = run_nvim(
        repo_root,
        nvim_bin,
        ["+doautocmd User VeryLazy", "+lua vim.wait(150)", f"+lua {runtime_lua}"],
        env,
        str(repo_root / "README.md"),
    )
    runtime_output = combined_output(runtime)
    if runtime.returncode != 0:
        checks.append(CheckResult("Runtime assertions", False, runtime_output or "command failed"))
    else:
        runtime_report = extract_last_json_object(runtime_output)
        checks.extend(
            [
                CheckResult("Keymap <leader>ff exists", bool(runtime_report.get("keymap_ff")), "expected true"),
                CheckResult("Keymap <leader>fw exists", bool(runtime_report.get("keymap_fw")), "expected true"),
                CheckResult("Keymap <leader>gd exists", bool(runtime_report.get("keymap_gd")), "expected true"),
                CheckResult("Keymap <leader>cz exists", bool(runtime_report.get("keymap_cz")), "expected true"),
                CheckResult("Keymap <leader>uw exists", bool(runtime_report.get("keymap_uw")), "expected true"),
                CheckResult("Keymap <leader>hs exists", bool(runtime_report.get("keymap_hs")), "expected true"),
                CheckResult("Keymap <leader>tf exists", bool(runtime_report.get("keymap_tf")), "expected true"),
                CheckResult(
                    "Editing windows use absolute line numbers",
                    runtime_report.get("absolute_number") is True
                    and runtime_report.get("relative_number") is False,
                    (
                        f"number={runtime_report.get('absolute_number')} "
                        f"relativenumber={runtime_report.get('relative_number')}"
                    ),
                ),
                CheckResult(
                    "Visual line wrapping is enabled by default",
                    runtime_report.get("wrap_default") is True,
                    f"wrap={runtime_report.get('wrap_default')}",
                ),
                CheckResult(
                    "Clarity startup modules are loaded",
                    bool(runtime_report.get("options_loaded"))
                    and bool(runtime_report.get("autocmds_loaded"))
                    and bool(runtime_report.get("keymaps_loaded"))
                    and bool(runtime_report.get("absolute_number_autocmd")),
                    (
                        f"options={runtime_report.get('options_loaded')} "
                        f"autocmds={runtime_report.get('autocmds_loaded')} "
                        f"keymaps={runtime_report.get('keymaps_loaded')} "
                        f"number_autocmd={runtime_report.get('absolute_number_autocmd')}"
                    ),
                ),
                CheckResult(
                    "Keymap <leader>hh exists (T-006)",
                    bool(runtime_report.get("keymap_hh")),
                    "expected true",
                    required=False,
                ),
                CheckResult("Gitsigns attached to tracked file", bool(runtime_report.get("gitsigns_head")), "expected true"),
                CheckResult(
                    "Gitsigns hunk keymaps attached",
                    bool(runtime_report.get("gitsigns_keymaps")),
                    "expected true",
                ),
                CheckResult(
                    "Neotree command exists",
                    bool(runtime_report.get("neotree_cmd")),
                    "expected true",
                ),
                CheckResult("Neotree opens in headless runtime", bool(runtime_report.get("neotree_open_ok")), "expected true"),
                CheckResult("Neotree window discovered", bool(runtime_report.get("neotree_window_found")), "expected true"),
                CheckResult(
                    "Neotree window hides line numbers",
                    runtime_report.get("neotree_number") is False and runtime_report.get("neotree_relativenumber") is False,
                    f"number={runtime_report.get('neotree_number')} relativenumber={runtime_report.get('neotree_relativenumber')}",
                ),
                CheckResult(
                    "Clipboard uses unnamedplus",
                    bool(runtime_report.get("clipboard_unnamedplus")),
                    "expected true",
                ),
                CheckResult(
                    "Clipboard provider executable found",
                    bool(runtime_report.get("clipboard_provider")),
                    f"provider={runtime_report.get('clipboard_provider')}",
                    required=False,
                ),
            ]
        )

    editing_controls_lua = (
        "local results = {}; "
        "local wrap_map = vim.fn.maparg('<leader>uw', 'n', false, true); "
        "results.wrap_callback = type(wrap_map.callback) == 'function'; "
        "local wrap_before = vim.wo.wrap; "
        "if results.wrap_callback then "
        "wrap_map.callback(); "
        "results.wrap_changed = vim.wo.wrap ~= wrap_before; "
        "wrap_map.callback(); "
        "results.wrap_restored = vim.wo.wrap == wrap_before; "
        "end; "
        "local fold_map = vim.fn.maparg('<leader>cz', 'n', false, true); "
        "results.fold_callback = type(fold_map.callback) == 'function'; "
        "local original_buf = vim.api.nvim_get_current_buf(); "
        "local original_foldmethod = vim.wo.foldmethod; "
        "local original_foldenable = vim.wo.foldenable; "
        "local original_foldlevel = vim.wo.foldlevel; "
        "local scratch = vim.api.nvim_create_buf(false, false); "
        "vim.api.nvim_win_set_buf(0, scratch); "
        "vim.api.nvim_buf_set_lines(scratch, 0, -1, false, { 'if true then', '    print(1)', 'end', 'print(2)' }); "
        "vim.wo.foldmethod = 'manual'; "
        "vim.wo.foldenable = true; "
        "vim.wo.foldlevel = 0; "
        "vim.cmd('1,3fold'); "
        "vim.api.nvim_win_set_cursor(0, { 1, 0 }); "
        "results.fold_initially_closed = vim.fn.foldclosed(1) == 1; "
        "if results.fold_callback then "
        "results.fold_open_outcome = fold_map.callback(); "
        "results.fold_opened = vim.fn.foldclosed(1) == -1; "
        "results.fold_close_outcome = fold_map.callback(); "
        "results.fold_reclosed = vim.fn.foldclosed(1) == 1; "
        "vim.cmd('normal! zE'); vim.v.errmsg = ''; "
        "local no_fold_ok, no_fold_outcome = pcall(fold_map.callback); "
        "results.fold_no_fold_ok = no_fold_ok; "
        "results.fold_no_fold_outcome = no_fold_outcome; "
        "results.fold_no_fold_error = vim.v.errmsg; "
        "end; "
        "vim.api.nvim_win_set_buf(0, original_buf); "
        "vim.wo.foldmethod = original_foldmethod; "
        "vim.wo.foldenable = original_foldenable; "
        "vim.wo.foldlevel = original_foldlevel; "
        "vim.api.nvim_buf_delete(scratch, { force = true }); "
        "print(vim.json.encode(results));"
    )
    editing_controls = run_nvim(
        repo_root,
        nvim_bin,
        ["+doautocmd User VeryLazy", "+lua vim.wait(150)", f"+lua {editing_controls_lua}"],
        env,
    )
    editing_controls_output = combined_output(editing_controls)
    if editing_controls.returncode != 0:
        checks.append(CheckResult("Editing control behavior", False, editing_controls_output or "command failed"))
    else:
        editing_controls_report = extract_last_json_object(editing_controls_output)
        checks.extend(
            [
                CheckResult(
                    "Line wrap mapping changes and restores the window option",
                    bool(editing_controls_report.get("wrap_callback"))
                    and bool(editing_controls_report.get("wrap_changed"))
                    and bool(editing_controls_report.get("wrap_restored")),
                    (
                        f"callback={editing_controls_report.get('wrap_callback')} "
                        f"changed={editing_controls_report.get('wrap_changed')} "
                        f"restored={editing_controls_report.get('wrap_restored')}"
                    ),
                ),
                CheckResult(
                    "Code fold mapping opens and recloses the current fold",
                    bool(editing_controls_report.get("fold_callback"))
                    and bool(editing_controls_report.get("fold_initially_closed"))
                    and bool(editing_controls_report.get("fold_opened"))
                    and bool(editing_controls_report.get("fold_reclosed"))
                    and editing_controls_report.get("fold_open_outcome") == "toggled"
                    and editing_controls_report.get("fold_close_outcome") == "toggled"
                    and bool(editing_controls_report.get("fold_no_fold_ok"))
                    and editing_controls_report.get("fold_no_fold_outcome") == "no_fold"
                    and editing_controls_report.get("fold_no_fold_error") == "",
                    (
                        f"callback={editing_controls_report.get('fold_callback')} "
                        f"initially_closed={editing_controls_report.get('fold_initially_closed')} "
                        f"opened={editing_controls_report.get('fold_opened')} "
                        f"reclosed={editing_controls_report.get('fold_reclosed')}"
                        f" no_fold_ok={editing_controls_report.get('fold_no_fold_ok')}"
                        f" no_fold_outcome={editing_controls_report.get('fold_no_fold_outcome')}"
                        f" no_fold_error={editing_controls_report.get('fold_no_fold_error')}"
                    ),
                ),
            ]
        )

    directory_start_lua = (
        "vim.wait(600); "
        "local results = { neo_tree_windows = 0, snacks_explorer_windows = 0 }; "
        "for _, win in ipairs(vim.api.nvim_list_wins()) do "
        "local buf = vim.api.nvim_win_get_buf(win); "
        "local ft = vim.bo[buf].filetype; "
        "if ft == 'neo-tree' then results.neo_tree_windows = results.neo_tree_windows + 1; end; "
        "if ft == 'snacks_layout_box' or ft == 'snacks_picker_input' or ft == 'snacks_picker_list' then "
        "results.snacks_explorer_windows = results.snacks_explorer_windows + 1; "
        "end; "
        "end; "
        "results.explorer = vim.g.lazyvim_explorer; "
        "print(vim.json.encode(results));"
    )
    directory_start = run_nvim(
        repo_root,
        nvim_bin,
        [f"+lua {directory_start_lua}"],
        env,
        str(repo_root),
    )
    directory_start_output = combined_output(directory_start)
    if directory_start.returncode != 0:
        checks.append(CheckResult("Directory startup explorer behavior", False, directory_start_output or "command failed"))
    else:
        directory_start_report = extract_last_json_object(directory_start_output)
        checks.append(
            CheckResult(
                "Directory startup opens exactly one Neo-tree explorer",
                directory_start_report.get("explorer") == "neo-tree"
                and directory_start_report.get("neo_tree_windows") == 1
                and directory_start_report.get("snacks_explorer_windows") == 0,
                (
                    f"explorer={directory_start_report.get('explorer')} "
                    f"neo_tree_windows={directory_start_report.get('neo_tree_windows')} "
                    f"snacks_explorer_windows={directory_start_report.get('snacks_explorer_windows')}"
                ),
            )
        )

    dashboard = run_nvim(
        repo_root,
        nvim_bin,
        [
            "+doautocmd User VeryLazy",
            "+lua vim.wait(100)",
            "+lua local buf=vim.api.nvim_get_current_buf(); vim.bo[buf].buftype=''; vim.bo[buf].filetype='snacks_dashboard'; vim.wait(50); vim.api.nvim_exec_autocmds('BufEnter', { buffer = buf, modeline = false }); print(vim.json.encode({ number = vim.wo.number, relativenumber = vim.wo.relativenumber }))",
        ],
        env,
    )
    dashboard_output = combined_output(dashboard)
    if dashboard.returncode != 0:
        checks.append(CheckResult("Dashboard line-number behavior", False, dashboard_output or "command failed"))
    else:
        dashboard_report = extract_last_json_object(dashboard_output)
        checks.append(
            CheckResult(
                "Dashboard hides absolute line numbers",
                dashboard_report.get("number") is False and dashboard_report.get("relativenumber") is False,
                f"number={dashboard_report.get('number')} relativenumber={dashboard_report.get('relativenumber')}",
            )
        )

    pynvim_check = run_command(
        [sys.executable, "-c", "import importlib.util; print(importlib.util.find_spec('pynvim') is not None)"],
        cwd=repo_root,
        env=env,
        timeout=30,
    )
    pynvim_ok = pynvim_check.returncode == 0 and pynvim_check.stdout.strip().lower() == "true"
    checks.append(
        CheckResult(
            "Python provider module (pynvim) installed",
            pynvim_ok,
            pynvim_check.stdout.strip() or pynvim_check.stderr.strip() or "unknown",
            required=False,
        )
    )

    npm_exe = resolve_executable("npm")
    npm_ok = False
    npm_details = "npm executable not found"
    if npm_exe:
        npm_neovim_check = run_command(
            [npm_exe, "list", "-g", "neovim", "--depth=0", "--json"],
            cwd=repo_root,
            env=env,
            timeout=30,
        )
        npm_details = npm_neovim_check.stdout.strip() or npm_neovim_check.stderr.strip() or "unknown"
        if npm_neovim_check.stdout:
            try:
                npm_json = json.loads(npm_neovim_check.stdout)
                deps = npm_json.get("dependencies", {})
                npm_ok = "neovim" in deps
                if npm_ok:
                    npm_details = f"neovim@{deps['neovim'].get('version', 'installed')}"
            except json.JSONDecodeError:
                npm_ok = False
    checks.append(
        CheckResult(
            "Node provider package (npm -g neovim) installed",
            npm_ok,
            npm_details,
            required=False,
        )
    )

    node_exe = resolve_executable("node")
    if node_exe:
        node_version_check = run_command(
            [node_exe, "--version"],
            cwd=repo_root,
            env=env,
            timeout=30,
        )
        node_major = parse_node_major(node_version_check.stdout.strip()) if node_version_check.returncode == 0 else None
        node_details = node_version_check.stdout.strip() or node_version_check.stderr.strip() or "unknown"
    else:
        node_major = None
        node_details = "node executable not found"
    checks.append(
        CheckResult(
            "Node runtime satisfies Copilot floor (>=22)",
            bool(node_major and node_major >= 22),
            node_details,
            required=False,
        )
    )

    try:
        doctor_report = run_doctor_json(repo_root, env)
        doctor_checks = {check.get("id"): check for check in doctor_report.get("checks", [])}
        treesitter_parser = doctor_checks.get("vim_treesitter_parser", {})
        user_override = doctor_checks.get("user_vim_parser_override", {})
        tree_sitter_cli = doctor_checks.get("tree_sitter_cli", {})
        checks.append(
            CheckResult(
                "Clarity doctor command",
                True,
                f"mode={doctor_report.get('mode')} platform={doctor_report.get('platform')}",
                required=False,
            )
        )
        checks.append(
            CheckResult(
                "Tree-sitter vim parser health",
                treesitter_parser.get("status") == "pass",
                treesitter_parser.get("details", "missing doctor result"),
            )
        )
        checks.append(
            CheckResult(
                "User-level stale vim parser override absent",
                user_override.get("status") in ("pass", "warn"),
                user_override.get("details", "missing doctor result"),
            )
        )
        checks.append(
            CheckResult(
                "Tree-sitter CLI available for diagnostics",
                tree_sitter_cli.get("status") == "pass",
                tree_sitter_cli.get("details", "missing doctor result"),
                required=False,
            )
        )
    except Exception as exc:
        checks.append(
            CheckResult(
                "Clarity doctor command",
                False,
                str(exc),
            )
        )

    locale_specs = [
        (
            "en",
            "Go to definition",
            "Search text",
            "Find Files (Root Dir)",
            "Delete Buffer",
            "Toggle current code fold",
            "Toggle Wrap",
        ),
        (
            "zh",
            "跳转到定义",
            "搜索文本",
            "查找文件（项目根目录）",
            "删除缓冲区",
            "切换当前代码折叠",
            "切换自动换行",
        ),
    ]
    for (
        locale_code,
        expected_gd,
        expected_fw,
        expected_ff,
        expected_bd,
        expected_cz,
        expected_uw,
    ) in locale_specs:
        locale_env = build_env(locale_code)
        locale_runtime_lua = (
            "local i18n = require('config.i18n'); "
            "local gd = vim.fn.maparg('gd', 'n', false, true); "
            "local fw = vim.fn.maparg('<leader>fw', 'n', false, true); "
            "local ff = vim.fn.maparg('<leader>ff', 'n', false, true); "
            "local bd = vim.fn.maparg('<leader>bd', 'n', false, true); "
            "local cz = vim.fn.maparg('<leader>cz', 'n', false, true); "
            "local uw = vim.fn.maparg('<leader>uw', 'n', false, true); "
            "local hh = vim.fn.maparg('<leader>hh', 'n', false, true); "
            "local report = i18n.get_validation_report(); "
            "print(vim.json.encode({ "
            "effective = i18n.get_state().effective, "
            "choice = i18n.get_state().choice, "
            "gd = gd.desc, "
            "fw = fw.desc, "
            "ff = ff.desc, "
            "bd = bd.desc, "
            "cz = cz.desc, "
            "uw = uw.desc, "
            "hh = hh.desc, "
            "language_cmd = (vim.fn.exists(':ClarityLanguage') == 2), "
            "translation_ok = report.ok, "
            "missing_in_en = #report.missing_in_en, "
            "missing_in_zh = #report.missing_in_zh "
            "}));"
        )
        locale_runtime = run_nvim(
            repo_root,
            nvim_bin,
            ["+doautocmd User VeryLazy", "+lua vim.wait(150)", f"+lua {locale_runtime_lua}"],
            locale_env,
        )
        locale_output = combined_output(locale_runtime)
        if locale_runtime.returncode != 0:
            checks.append(
                CheckResult(
                    f"Locale runtime ({locale_code})",
                    False,
                    locale_output or "command failed",
                )
            )
            continue

        locale_report = extract_last_json_object(locale_output)
        checks.append(
            CheckResult(
                f"Locale {locale_code} effective selection",
                locale_report.get("effective") == locale_code,
                f"effective={locale_report.get('effective')}",
                required=False,
            )
        )
        checks.append(
            CheckResult(
                f"Locale {locale_code} keymap gd description",
                locale_report.get("gd") == expected_gd,
                f"desc={locale_report.get('gd')}",
                required=False,
            )
        )
        checks.append(
            CheckResult(
                f"Locale {locale_code} keymap <leader>fw description",
                locale_report.get("fw") == expected_fw,
                f"desc={locale_report.get('fw')}",
                required=False,
            )
        )
        checks.append(
            CheckResult(
                f"Locale {locale_code} keymap <leader>ff description",
                locale_report.get("ff") == expected_ff,
                f"desc={locale_report.get('ff')}",
                required=False,
            )
        )
        checks.append(
            CheckResult(
                f"Locale {locale_code} keymap <leader>bd description",
                locale_report.get("bd") == expected_bd,
                f"desc={locale_report.get('bd')}",
                required=False,
            )
        )
        checks.append(
            CheckResult(
                f"Locale {locale_code} keymap <leader>cz description",
                locale_report.get("cz") == expected_cz,
                f"desc={locale_report.get('cz')}",
                required=False,
            )
        )
        checks.append(
            CheckResult(
                f"Locale {locale_code} keymap <leader>uw description",
                locale_report.get("uw") == expected_uw,
                f"desc={locale_report.get('uw')}",
                required=False,
            )
        )
        checks.append(
            CheckResult(
                f"Locale {locale_code} ClarityLanguage command exists",
                bool(locale_report.get("language_cmd")),
                "expected true",
                required=False,
            )
        )
        checks.append(
            CheckResult(
                f"Locale {locale_code} translation parity",
                bool(locale_report.get("translation_ok")),
                f"missing_in_en={locale_report.get('missing_in_en')} missing_in_zh={locale_report.get('missing_in_zh')}",
                required=False,
            )
        )

    required_failures = [check for check in checks if check.required and not check.ok]
    optional_failures = [check for check in checks if (not check.required) and (not check.ok)]

    if args.json:
        print(
            json.dumps(
                {
                    "check_id": "CLARITY-VALIDATE-001",
                    "status": "fail" if required_failures else "pass",
                    "summary": {
                        "required_failures": len(required_failures),
                        "optional_warnings": len(optional_failures),
                        "total": len(checks),
                    },
                    "checks": [{"id": check.id, **asdict(check)} for check in checks],
                },
                indent=2,
                ensure_ascii=False,
            )
        )
    else:
        print("Clarity Runtime Validation")
        for check in checks:
            marker = "PASS" if check.ok else ("WARN" if not check.required else "FAIL")
            requirement = "required" if check.required else "optional"
            print(f"[{marker}] {check.id}: {check.name} ({requirement}) -> {check.details}")

        print(f"Required failures: {len(required_failures)}")
        print(f"Optional warnings: {len(optional_failures)}")

    return 1 if required_failures else 0


if __name__ == "__main__":
    raise SystemExit(run())
