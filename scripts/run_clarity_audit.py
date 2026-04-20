from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path


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


def main() -> int:
    repo_root = Path(__file__).resolve().parent.parent
    init_path = repo_root / "init.lua"
    nvim = resolve_nvim_binary()
    env = build_env()

    command = [
        nvim,
        "--headless",
        "-u",
        str(init_path),
        "+ClarityAudit!",
        "+qall",
    ]

    result = subprocess.run(
        command,
        cwd=repo_root,
        env=env,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )

    if result.returncode != 0:
        sys.stderr.write(result.stderr or result.stdout)
        return result.returncode

    combined_output = "\n".join(part for part in (result.stdout, result.stderr) if part)
    report_line = ""
    for line in reversed(combined_output.splitlines()):
        candidate = line.strip()
        if candidate.startswith("{") and candidate.endswith("}"):
            report_line = candidate
            break

    if not report_line:
        raise RuntimeError("Could not locate JSON audit output from Neovim.")

    report = json.loads(report_line)

    print(json.dumps(report, indent=2, ensure_ascii=False))
    print(f"Overall readiness: {report['summary']['scores']['overall']}/100")
    print(
        f"Required tools: {report['summary']['required']['ok']}/{report['summary']['required']['total']}"
    )
    print(
        f"Optional tools: {report['summary']['optional']['ok']}/{report['summary']['optional']['total']}"
    )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
