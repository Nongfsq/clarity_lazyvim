from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path


@dataclass
class CheckResult:
    name: str
    ok: bool
    details: str
    required: bool = True


def resolve_nvim_binary() -> str:
    configured = os.environ.get("NVIM_BIN")
    if configured:
        return configured

    explicit_candidate = Path(r"C:\Program Files\Neovim\bin\nvim.exe")
    if explicit_candidate.exists():
        return str(explicit_candidate)

    resolved = shutil.which("nvim")
    if resolved and "WindowsApps" not in resolved:
        return resolved

    raise FileNotFoundError("Neovim executable not found. Set NVIM_BIN or add `nvim` to PATH.")


def build_env(locale: str | None = None) -> dict[str, str]:
    env = os.environ.copy()
    env["CLARITY_NONINTERACTIVE"] = "1"
    if locale:
        env["CLARITY_LOCALE"] = locale

    if os.name == "nt":
        compiler_bin = Path(
            os.environ["LOCALAPPDATA"]
        ) / "Microsoft" / "WinGet" / "Packages" / "BrechtSanders.WinLibs.POSIX.UCRT_Microsoft.Winget.Source_8wekyb3d8bbwe" / "mingw64" / "bin"
        if compiler_bin.exists():
            env["PATH"] = str(compiler_bin) + os.pathsep + env.get("PATH", "")

    return env


def run_nvim(repo_root: Path, nvim_bin: str, commands: list[str], env: dict[str, str], *args: str) -> subprocess.CompletedProcess[str]:
    init_path = repo_root / "init.lua"
    command = [nvim_bin, "--headless", "-u", str(init_path), *args, *commands, "+qall"]
    return subprocess.run(
        command,
        cwd=repo_root,
        env=env,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )


def run_doctor_json(repo_root: Path, env: dict[str, str]) -> dict:
    result = subprocess.run(
        [sys.executable, str(repo_root / "scripts" / "clarity_doctor.py"), "--json"],
        cwd=repo_root,
        env=env,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )

    if result.returncode not in (0, 1):
        raise RuntimeError((result.stderr or result.stdout).strip() or "doctor command failed")

    return json.loads(result.stdout)


def extract_last_json_object(text: str) -> dict:
    for line in reversed(text.splitlines()):
        candidate = line.strip()
        if candidate.startswith("{") and candidate.endswith("}"):
            return json.loads(candidate)
    raise RuntimeError("Could not locate JSON output in command logs.")


def parse_node_major(version_text: str) -> int | None:
    match = re.search(r"v(\d+)\.", version_text)
    return int(match.group(1)) if match else None


def resolve_executable(name: str) -> str | None:
    return shutil.which(name)


def run() -> int:
    repo_root = Path(__file__).resolve().parent.parent
    env = build_env()
    nvim_bin = resolve_nvim_binary()
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
    audit_output = "\n".join(part for part in (audit.stdout, audit.stderr) if part)
    if audit.returncode != 0:
        checks.append(CheckResult("ClarityAudit command", False, audit_output or "command failed"))
        report = {}
    else:
        report = extract_last_json_object(audit_output)
        required = report.get("summary", {}).get("required", {})
        required_ok = required.get("ok", 0)
        required_total = required.get("total", 0)
        checks.append(
            CheckResult(
                name="ClarityAudit command",
                ok=True,
                details=f"overall={report.get('summary', {}).get('scores', {}).get('overall', 'n/a')}",
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
        "results.keymap_tf = has_map('<leader>tf', 'n'); "
        "results.keymap_hh = has_map('<leader>hh', 'n'); "
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
    runtime_output = "\n".join(part for part in (runtime.stdout, runtime.stderr) if part)
    if runtime.returncode != 0:
        checks.append(CheckResult("Runtime assertions", False, runtime_output or "command failed"))
    else:
        runtime_report = extract_last_json_object(runtime_output)
        checks.extend(
            [
                CheckResult("Keymap <leader>ff exists", bool(runtime_report.get("keymap_ff")), "expected true"),
                CheckResult("Keymap <leader>fw exists", bool(runtime_report.get("keymap_fw")), "expected true"),
                CheckResult("Keymap <leader>gd exists", bool(runtime_report.get("keymap_gd")), "expected true"),
                CheckResult("Keymap <leader>hs exists", bool(runtime_report.get("keymap_hs")), "expected true"),
                CheckResult("Keymap <leader>tf exists", bool(runtime_report.get("keymap_tf")), "expected true"),
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
    dashboard_output = "\n".join(part for part in (dashboard.stdout, dashboard.stderr) if part)
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

    pynvim_check = subprocess.run(
        [sys.executable, "-c", "import importlib.util; print(importlib.util.find_spec('pynvim') is not None)"],
        cwd=repo_root,
        env=env,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
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
        npm_neovim_check = subprocess.run(
            [npm_exe, "list", "-g", "neovim", "--depth=0", "--json"],
            cwd=repo_root,
            env=env,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
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
        node_version_check = subprocess.run(
            [node_exe, "--version"],
            cwd=repo_root,
            env=env,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
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
        ("en", "Go to definition", "Search text", "Find Files (Root Dir)", "Delete Buffer", "Toggle Wrap"),
        ("zh", "跳转到定义", "搜索文本", "查找文件（项目根目录）", "删除缓冲区", "切换自动换行"),
    ]
    for locale_code, expected_gd, expected_fw, expected_ff, expected_bd, expected_uw in locale_specs:
        locale_env = build_env(locale_code)
        locale_runtime_lua = (
            "local i18n = require('config.i18n'); "
            "local gd = vim.fn.maparg('gd', 'n', false, true); "
            "local fw = vim.fn.maparg('<leader>fw', 'n', false, true); "
            "local ff = vim.fn.maparg('<leader>ff', 'n', false, true); "
            "local bd = vim.fn.maparg('<leader>bd', 'n', false, true); "
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
        locale_output = "\n".join(part for part in (locale_runtime.stdout, locale_runtime.stderr) if part)
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

    print("Clarity Runtime Validation")
    for check in checks:
        marker = "PASS" if check.ok else ("WARN" if not check.required else "FAIL")
        requirement = "required" if check.required else "optional"
        print(f"[{marker}] {check.name} ({requirement}) -> {check.details}")

    print(f"Required failures: {len(required_failures)}")
    print(f"Optional warnings: {len(optional_failures)}")

    return 1 if required_failures else 0


if __name__ == "__main__":
    raise SystemExit(run())
