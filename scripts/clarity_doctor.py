from __future__ import annotations

import argparse
import json
import os
import platform
import shutil
import subprocess
import sys
from dataclasses import asdict, dataclass
from datetime import datetime
from pathlib import Path


@dataclass
class Check:
    id: str
    name: str
    status: str
    details: str
    hint: str = ""
    fixable: bool = False


def resolve_nvim_binary(configured: str | None = None) -> str:
    if configured:
        return configured

    env_configured = os.environ.get("NVIM_BIN")
    if env_configured:
        return env_configured

    explicit_candidate = Path(r"C:\Program Files\Neovim\bin\nvim.exe")
    if explicit_candidate.exists():
        return str(explicit_candidate)

    resolved = shutil.which("nvim")
    if resolved and "WindowsApps" not in resolved:
        return resolved

    raise FileNotFoundError("Neovim executable not found. Set NVIM_BIN or add `nvim` to PATH.")


def build_env() -> dict[str, str]:
    env = os.environ.copy()
    env["CLARITY_NONINTERACTIVE"] = "1"

    if os.name == "nt":
        compiler_bin = Path(
            os.environ["LOCALAPPDATA"]
        ) / "Microsoft" / "WinGet" / "Packages" / "BrechtSanders.WinLibs.POSIX.UCRT_Microsoft.Winget.Source_8wekyb3d8bbwe" / "mingw64" / "bin"
        if compiler_bin.exists():
            env["PATH"] = str(compiler_bin) + os.pathsep + env.get("PATH", "")

    return env


def is_wsl() -> bool:
    if os.environ.get("WSL_DISTRO_NAME") or os.environ.get("WSL_INTEROP"):
        return True

    proc_version = Path("/proc/version")
    if proc_version.exists():
        try:
            return "microsoft" in proc_version.read_text(encoding="utf-8", errors="ignore").lower()
        except OSError:
            return False

    return False


def platform_kind() -> str:
    if is_wsl():
        return "wsl"

    system = platform.system().lower()
    if system == "darwin":
        return "macos"
    if system == "linux":
        return "linux"
    if system == "windows":
        return "windows"

    return system or "unknown"


def command_version(command: str, env: dict[str, str]) -> str:
    try:
        result = subprocess.run(
            [command, "--version"],
            env=env,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=15,
        )
    except (OSError, subprocess.TimeoutExpired):
        return "version unavailable"

    return (result.stdout or result.stderr).strip() or "version unavailable"


def first_executable(commands: list[str]) -> str | None:
    for command in commands:
        resolved = shutil.which(command)
        if resolved:
            return command

    return None


def install_hint(tool_id: str, kind: str) -> str:
    hints = {
        "macos": {
            "git": "Install Xcode Command Line Tools: xcode-select --install",
            "compiler": "Install Xcode Command Line Tools: xcode-select --install",
            "ripgrep": "brew install ripgrep",
            "fd": "brew install fd",
            "node": "Install Node 22+ with fnm, nvm, volta, or Homebrew.",
            "npm": "Install Node.js 22+; npm ships with most Node distributions.",
            "python": "brew install python",
            "pip": "python3 -m ensurepip --upgrade",
            "tree_sitter_cli": "npm install -g tree-sitter-cli",
            "system_monitor": "brew install htop or brew install btop",
        },
        "linux": {
            "git": "sudo apt-get install -y git",
            "compiler": "sudo apt-get install -y build-essential",
            "ripgrep": "sudo apt-get install -y ripgrep",
            "fd": "sudo apt-get install -y fd-find",
            "node": "Install Node 22+ with fnm, nvm, volta, or your distro package manager.",
            "npm": "Install Node.js 22+; npm ships with most Node distributions.",
            "python": "sudo apt-get install -y python3",
            "pip": "sudo apt-get install -y python3-pip",
            "tree_sitter_cli": "npm install -g tree-sitter-cli",
            "system_monitor": "sudo apt-get install -y htop or sudo apt-get install -y btop",
        },
        "wsl": {
            "git": "sudo apt-get install -y git",
            "compiler": "sudo apt-get install -y build-essential",
            "ripgrep": "sudo apt-get install -y ripgrep",
            "fd": "sudo apt-get install -y fd-find",
            "node": "Install Node 22+ inside WSL with fnm, nvm, volta, or apt-based setup.",
            "npm": "Install Node.js 22+ inside WSL; npm ships with most Node distributions.",
            "python": "sudo apt-get install -y python3",
            "pip": "sudo apt-get install -y python3-pip",
            "tree_sitter_cli": "npm install -g tree-sitter-cli",
            "system_monitor": "sudo apt-get install -y htop or sudo apt-get install -y btop",
        },
    }

    return hints.get(kind, hints["linux"]).get(tool_id, "Install this tool with your platform package manager.")


def run_nvim_probe(repo_root: Path, nvim_bin: str, env: dict[str, str]) -> tuple[dict, str]:
    init_path = repo_root / "init.lua"
    lua = (
        "local report = {}; "
        "report.std_data = vim.fn.stdpath('data'); "
        "report.std_cache = vim.fn.stdpath('cache'); "
        "report.std_state = vim.fn.stdpath('state'); "
        "report.parser_suffix = (vim.fn.has('win32') == 1) and '.dll' or '.so'; "
        "report.user_parser = report.std_data .. '/site/parser/vim' .. report.parser_suffix; "
        "report.user_revision = report.std_data .. '/site/parser-info/vim.revision'; "
        "report.user_parser_present = vim.fn.filereadable(report.user_parser) == 1; "
        "report.user_revision_present = vim.fn.filereadable(report.user_revision) == 1; "
        "report.vim = {}; "
        "local ok_inspect, info = pcall(vim.treesitter.language.inspect, 'vim'); "
        "report.vim.inspect_ok = ok_inspect; "
        "if ok_inspect and type(info) == 'table' then "
        "report.vim.metadata = info.metadata; "
        "report.vim.abi_version = info.abi_version; "
        "else "
        "report.vim.inspect_error = tostring(info); "
        "end; "
        "local ok_query, query = pcall(vim.treesitter.query.get, 'vim', 'highlights'); "
        "report.vim.query_ok = ok_query and query ~= nil; "
        "if not report.vim.query_ok then report.vim.query_error = tostring(query); end; "
        "local ok_parser, parser = pcall(vim.treesitter.get_string_parser, 'set tab\\n', 'vim'); "
        "report.vim.parser_ok = ok_parser; "
        "if ok_parser then "
        "local ok_parse, parse_result = pcall(function() return parser:parse() end); "
        "report.vim.parse_ok = ok_parse; "
        "if not ok_parse then report.vim.parse_error = tostring(parse_result); end; "
        "else "
        "report.vim.parser_error = tostring(parser); "
        "report.vim.parse_ok = false; "
        "end; "
        "local buf = vim.api.nvim_create_buf(false, true); "
        "vim.bo[buf].buftype = 'nofile'; "
        "vim.bo[buf].bufhidden = 'wipe'; "
        "vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'set tab', 'tabnew' }); "
        "vim.bo[buf].filetype = 'vim'; "
        "local ok_highlight, highlighter = pcall(vim.treesitter.start, buf, 'vim'); "
        "report.vim.highlighter_ok = ok_highlight; "
        "if not ok_highlight then report.vim.highlighter_error = tostring(highlighter); end; "
        "pcall(vim.treesitter.stop, buf); "
        "pcall(vim.api.nvim_buf_delete, buf, { force = true }); "
        "print(vim.json.encode(report));"
    )
    command = [nvim_bin, "--headless", "-u", str(init_path), "+lua " + lua, "+qall"]
    result = subprocess.run(
        command,
        cwd=repo_root,
        env=env,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    output = "\n".join(part for part in (result.stdout, result.stderr) if part)

    if result.returncode != 0:
        raise RuntimeError(output or "nvim probe failed")

    for line in reversed(output.splitlines()):
        candidate = line.strip()
        if candidate.startswith("{") and candidate.endswith("}"):
            return json.loads(candidate), output

    raise RuntimeError(output or "nvim probe did not emit JSON")


def make_tool_checks(kind: str, env: dict[str, str]) -> list[Check]:
    tool_specs = [
        ("git", "Git", ["git"], True),
        ("compiler", "C compiler for Treesitter parser builds", ["cl", "gcc", "clang", "cc", "zig"], True),
        ("ripgrep", "ripgrep for fast text search", ["rg"], False),
        ("fd", "fd for fast file search", ["fd", "fdfind"], False),
        ("node", "Node.js runtime for Copilot/provider support", ["node"], False),
        ("npm", "npm for provider package installs", ["npm"], False),
        ("python", "Python runtime for validation scripts", ["python3", "python"], False),
        ("pip", "pip for Python provider installs", ["pip3", "pip"], False),
        ("tree_sitter_cli", "Tree-sitter CLI for parser diagnostics", ["tree-sitter"], False),
        ("system_monitor", "htop or btop terminal monitor", ["htop", "btop"], False),
    ]

    checks: list[Check] = []
    for tool_id, name, commands, required in tool_specs:
        detected = first_executable(commands)
        if detected:
            version = command_version(detected, env)
            checks.append(Check(tool_id, name, "pass", f"{detected}: {version.splitlines()[0]}"))
            continue

        status = "fail" if required else "warn"
        checks.append(
            Check(
                tool_id,
                name,
                status,
                "missing",
                install_hint(tool_id, kind),
            )
        )

    return checks


def provider_checks(env: dict[str, str]) -> list[Check]:
    checks: list[Check] = []
    pynvim_check = subprocess.run(
        [sys.executable, "-c", "import importlib.util; print(importlib.util.find_spec('pynvim') is not None)"],
        env=env,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    pynvim_ok = pynvim_check.returncode == 0 and pynvim_check.stdout.strip().lower() == "true"
    checks.append(
        Check(
            "pynvim",
            "Python provider package (pynvim)",
            "pass" if pynvim_ok else "warn",
            "installed" if pynvim_ok else "missing for this Python runtime",
            "python3 -m pip install pynvim",
        )
    )

    npm = shutil.which("npm")
    if not npm:
        checks.append(
            Check(
                "node_provider",
                "Node provider package (npm -g neovim)",
                "warn",
                "npm executable not found",
                "Install Node.js 22+ and then run: npm install -g neovim",
            )
        )
        return checks

    npm_check = subprocess.run(
        [npm, "list", "-g", "neovim", "--depth=0", "--json"],
        env=env,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    npm_ok = False
    npm_details = npm_check.stderr.strip() or "not installed"
    if npm_check.stdout:
        try:
            data = json.loads(npm_check.stdout)
            dependency = data.get("dependencies", {}).get("neovim")
            if dependency:
                npm_ok = True
                npm_details = "neovim@" + dependency.get("version", "installed")
        except json.JSONDecodeError:
            npm_details = npm_check.stdout.strip() or npm_details

    checks.append(
        Check(
            "node_provider",
            "Node provider package (npm -g neovim)",
            "pass" if npm_ok else "warn",
            npm_details,
            "npm install -g neovim",
        )
    )
    return checks


def treesitter_checks(probe: dict) -> list[Check]:
    checks: list[Check] = []
    vim_info = probe.get("vim", {})
    inspect_ok = bool(vim_info.get("inspect_ok"))
    query_ok = bool(vim_info.get("query_ok"))
    parse_ok = bool(vim_info.get("parse_ok"))
    highlighter_ok = bool(vim_info.get("highlighter_ok"))
    user_parser_present = bool(probe.get("user_parser_present"))
    user_parser = str(probe.get("user_parser") or "")

    if inspect_ok and query_ok and parse_ok and highlighter_ok:
        metadata = vim_info.get("metadata") or {}
        version = ".".join(str(metadata.get(part, 0)) for part in ("major_version", "minor_version", "patch_version"))
        checks.append(
            Check(
                "vim_treesitter_parser",
                "Vim Tree-sitter parser understands current queries",
                "pass",
                f"metadata={version}; query/highlighter/parser OK",
            )
        )
    else:
        detail_parts = [
            f"inspect_ok={inspect_ok}",
            f"query_ok={query_ok}",
            f"parse_ok={parse_ok}",
            f"highlighter_ok={highlighter_ok}",
        ]
        error = (
            vim_info.get("inspect_error")
            or vim_info.get("query_error")
            or vim_info.get("parser_error")
            or vim_info.get("parse_error")
            or vim_info.get("highlighter_error")
        )
        if error:
            detail_parts.append(str(error))
        checks.append(
            Check(
                "vim_treesitter_parser",
                "Vim Tree-sitter parser understands current queries",
                "fail",
                "; ".join(detail_parts),
                "Run python3 scripts/clarity_doctor.py --apply if a stale user parser is present.",
                fixable=user_parser_present,
            )
        )

    stale_override = user_parser_present and (not inspect_ok or not query_ok or not parse_ok or not highlighter_ok)
    if stale_override:
        checks.append(
            Check(
                "user_vim_parser_override",
                "User-level vim parser override",
                "fail",
                user_parser,
                "Will move the parser and revision marker into .clarity-backup-* when --apply is used.",
                fixable=True,
            )
        )
    elif user_parser_present:
        checks.append(
            Check(
                "user_vim_parser_override",
                "User-level vim parser override",
                "warn",
                user_parser,
                "This is currently compatible, but it overrides the Neovim bundled vim parser.",
            )
        )
    else:
        checks.append(
            Check(
                "user_vim_parser_override",
                "User-level vim parser override",
                "pass",
                "none detected",
            )
        )

    return checks


def unique_destination(path: Path) -> Path:
    if not path.exists():
        return path

    stem = path.stem
    suffix = path.suffix
    for index in range(1, 100):
        candidate = path.with_name(f"{stem}-{index}{suffix}")
        if not candidate.exists():
            return candidate

    raise RuntimeError(f"Could not create unique backup name for {path}")


def backup_local_parser_files(probe: dict) -> list[str]:
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    moved: list[str] = []
    for key in ("user_parser", "user_revision"):
        value = probe.get(key)
        if not value:
            continue

        source = Path(value)
        if not source.exists():
            continue

        backup_dir = source.parent / f".clarity-backup-{timestamp}"
        backup_dir.mkdir(parents=True, exist_ok=True)
        destination = unique_destination(backup_dir / source.name)
        shutil.move(str(source), str(destination))
        moved.append(f"{source} -> {destination}")

    return moved


def print_human_report(
    repo_root: Path,
    kind: str,
    nvim_bin: str | None,
    mode: str,
    checks: list[Check],
    moved: list[str],
) -> None:
    print("Clarity Doctor")
    print(f"Repository: {repo_root}")
    print(f"Platform: {kind} ({platform.platform()})")
    print(f"Neovim: {nvim_bin or 'missing'}")
    print(f"Mode: {mode}")
    print()

    marker = {"pass": "PASS", "warn": "WARN", "fail": "FAIL"}
    for check in checks:
        print(f"[{marker.get(check.status, check.status.upper())}] {check.name}: {check.details}")
        if check.hint and check.status != "pass":
            print(f"       Hint: {check.hint}")

    if moved:
        print()
        print("Local files moved:")
        for item in moved:
            print(f"- {item}")

    fixable = [check for check in checks if check.fixable and check.status == "fail"]
    if fixable and mode == "dry-run":
        print()
        print("Safe repair available:")
        print("- python3 scripts/clarity_doctor.py --apply")


def main() -> int:
    parser = argparse.ArgumentParser(description="Diagnose and safely repair local clarity_lazyvim runtime state.")
    parser.add_argument("--apply", action="store_true", help="Apply safe local repairs. Backups are used; files are not deleted.")
    parser.add_argument("--json", action="store_true", help="Emit JSON instead of human-readable output.")
    parser.add_argument("--nvim-bin", help="Path to the Neovim executable. Defaults to NVIM_BIN or PATH.")
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parent.parent
    env = build_env()
    kind = platform_kind()
    checks = make_tool_checks(kind, env) + provider_checks(env)
    moved: list[str] = []
    nvim_bin: str | None = None

    try:
        nvim_bin = resolve_nvim_binary(args.nvim_bin)
        checks.append(Check("nvim", "Neovim executable", "pass", nvim_bin))
        probe, _ = run_nvim_probe(repo_root, nvim_bin, env)
        ts_checks = treesitter_checks(probe)

        stale_fixable = any(check.id == "user_vim_parser_override" and check.status == "fail" for check in ts_checks)
        if args.apply and stale_fixable:
            moved = backup_local_parser_files(probe)
            repaired_probe, _ = run_nvim_probe(repo_root, nvim_bin, env)
            checks.extend(treesitter_checks(repaired_probe))
            checks.append(
                Check(
                    "repair_verification",
                    "Repair verification",
                    "pass"
                    if repaired_probe.get("vim", {}).get("inspect_ok")
                    and repaired_probe.get("vim", {}).get("query_ok")
                    and repaired_probe.get("vim", {}).get("parse_ok")
                    and repaired_probe.get("vim", {}).get("highlighter_ok")
                    else "fail",
                    "verified bundled parser after backup move",
                )
            )
        else:
            checks.extend(ts_checks)
    except Exception as exc:
        checks.append(
            Check(
                "nvim_probe",
                "Neovim runtime probe",
                "fail",
                str(exc),
                "Fix Neovim startup first, then rerun this doctor.",
            )
        )

    if args.json:
        print(
            json.dumps(
                {
                    "repository": str(repo_root),
                    "platform": kind,
                    "nvim": nvim_bin,
                    "mode": "apply" if args.apply else "dry-run",
                    "checks": [asdict(check) for check in checks],
                    "moved": moved,
                },
                indent=2,
                ensure_ascii=False,
            )
        )
    else:
        print_human_report(repo_root, kind, nvim_bin, "apply" if args.apply else "dry-run", checks, moved)

    return 1 if any(check.status == "fail" for check in checks) else 0


if __name__ == "__main__":
    raise SystemExit(main())
