from __future__ import annotations

import hashlib
import json
import os
import shutil
import subprocess
from pathlib import Path
from typing import Iterable, Sequence


DEFAULT_TIMEOUT_SECONDS = 120


class CommandTimeoutError(RuntimeError):
    def __init__(self, command: Sequence[str], timeout: float, output: str = "") -> None:
        rendered = " ".join(str(part) for part in command)
        message = f"Command timed out after {timeout:g}s: {rendered}"
        if output.strip():
            message += "\n" + output.strip()
        super().__init__(message)
        self.command = tuple(str(part) for part in command)
        self.timeout = timeout
        self.output = output


def build_env(
    locale: str | None = None,
    *,
    base_env: dict[str, str] | None = None,
    noninteractive: bool = True,
) -> dict[str, str]:
    env = dict(base_env or os.environ)
    if noninteractive:
        env["CLARITY_NONINTERACTIVE"] = "1"
    if locale:
        env["CLARITY_LOCALE"] = locale
    return env


def configure_isolated_runtime(env: dict[str, str], root: Path) -> dict[str, str]:
    isolated = dict(env)
    for name in ("config", "data", "state", "cache"):
        path = root / name
        path.mkdir(parents=True, exist_ok=True)
        isolated[f"XDG_{name.upper()}_HOME"] = str(path)
    isolated["CLARITY_NONINTERACTIVE"] = "1"
    return isolated


def nvim_candidates(env: dict[str, str] | None = None) -> list[Path]:
    source = env or os.environ
    candidates: list[Path] = []
    for configured in (source.get("NVIM_BIN"),):
        if configured:
            candidates.append(Path(configured))

    candidates.extend(
        [
            Path(r"C:\Program Files\Neovim\bin\nvim.exe"),
            Path(r"C:\tools\neovim\nvim-win64\bin\nvim.exe"),
            Path(r"C:\tools\neovim\bin\nvim.exe"),
        ]
    )

    local_app_data = source.get("LOCALAPPDATA")
    if local_app_data:
        candidates.extend(
            [
                Path(local_app_data) / "nvim" / "bin" / "nvim.exe",
                Path(local_app_data) / "Programs" / "Neovim" / "bin" / "nvim.exe",
            ]
        )
    return candidates


def resolve_nvim_binary(
    configured: str | None = None,
    *,
    env: dict[str, str] | None = None,
) -> str:
    source = dict(env or os.environ)
    if configured:
        source["NVIM_BIN"] = configured

    checked: list[str] = []
    for candidate in nvim_candidates(source):
        checked.append(str(candidate))
        if candidate.is_file():
            return str(candidate)

    resolved = shutil.which("nvim", path=source.get("PATH"))
    if resolved and "WindowsApps" not in resolved:
        return resolved

    checked_text = ", ".join(checked) if checked else "no explicit candidates"
    raise FileNotFoundError(
        "Neovim executable not found. Set NVIM_BIN or add nvim to PATH. "
        f"Checked: {checked_text}."
    )


def run_command(
    command: Sequence[str],
    *,
    cwd: Path,
    env: dict[str, str],
    timeout: float = DEFAULT_TIMEOUT_SECONDS,
) -> subprocess.CompletedProcess[str]:
    try:
        return subprocess.run(
            [str(part) for part in command],
            cwd=cwd,
            env=env,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=timeout,
        )
    except subprocess.TimeoutExpired as exc:
        stdout = exc.stdout.decode("utf-8", errors="replace") if isinstance(exc.stdout, bytes) else exc.stdout or ""
        stderr = exc.stderr.decode("utf-8", errors="replace") if isinstance(exc.stderr, bytes) else exc.stderr or ""
        raise CommandTimeoutError(command, timeout, "\n".join(part for part in (stdout, stderr) if part)) from exc


def run_nvim(
    repo_root: Path,
    nvim_bin: str,
    commands: Iterable[str],
    env: dict[str, str],
    *args: str,
    timeout: float = DEFAULT_TIMEOUT_SECONDS,
) -> subprocess.CompletedProcess[str]:
    command = [nvim_bin, "--headless", "-u", str(repo_root / "init.lua"), *args, *commands, "+qall"]
    return run_command(command, cwd=repo_root, env=env, timeout=timeout)


def combined_output(result: subprocess.CompletedProcess[str]) -> str:
    return "\n".join(part for part in (result.stdout, result.stderr) if part)


def extract_last_json_object(text: str) -> dict:
    for line in reversed(text.splitlines()):
        candidate = line.strip()
        if candidate.startswith("{") and candidate.endswith("}"):
            return json.loads(candidate)
    raise RuntimeError("Could not locate JSON output in command logs.")


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()
