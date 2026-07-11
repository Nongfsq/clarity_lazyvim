from __future__ import annotations

import hashlib
import json
import os
import signal
import shutil
import subprocess
from pathlib import Path
from typing import Iterable, Sequence


DEFAULT_TIMEOUT_SECONDS = 120
REQUIRED_PYNVIM_VERSION = "0.6.0"
AUTHORITY_FILES = ("init.lua", "lazy-lock.json", "lazyvim.json")


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


def require_pynvim():
    try:
        import pynvim
    except ImportError as exc:
        raise RuntimeError(
            "Attached-UI verification requires pynvim=="
            f"{REQUIRED_PYNVIM_VERSION}. Run with: uv run --with "
            f"pynvim=={REQUIRED_PYNVIM_VERSION} python ..."
        ) from exc
    version = getattr(pynvim, "__version__", "unknown")
    if version != REQUIRED_PYNVIM_VERSION:
        raise RuntimeError(
            f"Attached-UI verification requires pynvim=={REQUIRED_PYNVIM_VERSION}; found {version}. "
            f"Run with: uv run --with pynvim=={REQUIRED_PYNVIM_VERSION} python ..."
        )
    return pynvim


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


def process_group_popen_options(*, windows: bool | None = None) -> dict[str, object]:
    is_windows = os.name == "nt" if windows is None else windows
    if is_windows:
        return {"creationflags": getattr(subprocess, "CREATE_NEW_PROCESS_GROUP", 0x00000200)}
    return {"start_new_session": True}


def run_command(
    command: Sequence[str],
    *,
    cwd: Path,
    env: dict[str, str],
    timeout: float = DEFAULT_TIMEOUT_SECONDS,
) -> subprocess.CompletedProcess[str]:
    command_parts = [str(part) for part in command]
    popen_options = process_group_popen_options()

    process = subprocess.Popen(
        command_parts,
        cwd=cwd,
        env=env,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        encoding="utf-8",
        errors="replace",
        **popen_options,
    )
    try:
        stdout, stderr = process.communicate(timeout=timeout)
        return subprocess.CompletedProcess(
            command_parts,
            process.returncode,
            stdout,
            stderr,
        )
    except subprocess.TimeoutExpired as exc:
        if os.name == "nt":
            try:
                subprocess.run(
                    ["taskkill", "/PID", str(process.pid), "/T", "/F"],
                    capture_output=True,
                    check=False,
                    timeout=5,
                )
            except (OSError, subprocess.TimeoutExpired):
                pass
            if process.poll() is None:
                process.kill()
        else:
            try:
                os.killpg(process.pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
            try:
                process.wait(timeout=1)
            except subprocess.TimeoutExpired:
                pass
            try:
                os.killpg(process.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
        stdout, stderr = process.communicate()
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
