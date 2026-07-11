from __future__ import annotations

import argparse
import json
import os
import platform
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from xml.sax.saxutils import escape

from clarity_runtime import (
    AUTHORITY_FILES,
    REQUIRED_PYNVIM_VERSION,
    build_env,
    combined_output,
    configure_isolated_runtime,
    resolve_nvim_binary,
    run_command,
    sha256_file,
)
from run_clarity_smoke import copy_plugin_cache


SCHEMA_VERSION = 1
RAW_LIMIT = 1024 * 1024
STRUCTURED_LIMIT = 256 * 1024
def authority_hashes(repo_root: Path) -> dict[str, str]:
    return {name: sha256_file(repo_root / name) for name in AUTHORITY_FILES}


def default_plugin_cache(
    env: dict[str, str] | None = None,
    *,
    home: Path | None = None,
) -> Path | None:
    source = os.environ if env is None else env
    data_home = Path(source["XDG_DATA_HOME"]) if source.get("XDG_DATA_HOME") else (home or Path.home()) / ".local" / "share"
    candidate = data_home / "nvim" / "lazy"
    return candidate if candidate.is_dir() else None


def truncate_output(value: str, limit: int = RAW_LIMIT) -> tuple[str, bool]:
    encoded = value.encode("utf-8", errors="replace")
    if len(encoded) <= limit:
        return value, False
    marker = b"\n...[clarity output truncated]...\n"
    remaining = max(0, limit - len(marker))
    head = remaining // 2
    tail = remaining - head
    bounded = encoded[:head] + marker + encoded[-tail:]
    return bounded.decode("utf-8", errors="replace"), True


def git_commit(repo_root: Path) -> str:
    result = subprocess.run(
        ["git", "rev-parse", "HEAD"], cwd=repo_root, check=True, capture_output=True, text=True
    )
    return result.stdout.strip()


def git_dirty(repo_root: Path) -> bool:
    result = subprocess.run(
        ["git", "status", "--porcelain"], cwd=repo_root, check=True, capture_output=True, text=True
    )
    return bool(result.stdout.strip())


def nvim_version(nvim: str) -> str:
    result = subprocess.run([nvim, "--version"], check=True, capture_output=True, text=True)
    return result.stdout.splitlines()[0]


def contract_python_command(python: str) -> list[str]:
    try:
        probe = subprocess.run(
            [
                python,
                "-c",
                "import pynvim,sys; "
                f"sys.exit(0 if pynvim.__version__ == '{REQUIRED_PYNVIM_VERSION}' else 1)",
            ],
            capture_output=True,
            text=True,
        )
        if probe.returncode == 0:
            return [python]
    except OSError:
        pass
    uv = shutil.which("uv")
    if uv:
        return [uv, "run", "--with", f"pynvim=={REQUIRED_PYNVIM_VERSION}", "python"]
    return [python]


def build_commands(
    repo_root: Path,
    suite: str,
    python: str,
    nvim: str,
    feature: str | None,
    scenarios: list[str],
    plugin_cache: Path | None,
) -> list[dict[str, Any]]:
    lua_tests = [python, "scripts/run_clarity_lua_tests.py", "--nvim-bin", nvim]
    python_tests = [python, "-m", "unittest", "discover", "-s", "tests/python", "-v"]
    cache_args = ["--reuse-plugin-cache", str(plugin_cache)] if plugin_cache else []
    contracts = [
        *contract_python_command(python),
        "scripts/run_clarity_contracts.py",
        "--nvim-bin",
        nvim,
        "--json",
        *cache_args,
    ]
    action_matrix = [
        *contract_python_command(python),
        "scripts/run_clarity_action_matrix.py",
        "--nvim-bin",
        nvim,
        "--json",
        *cache_args,
    ]

    if suite == "fast":
        return [
            {"id": "CLARITY_TESTS_PYTHON", "command": python_tests},
            {"id": "CLARITY_TESTS_LUA", "command": lua_tests},
        ]
    if suite == "contracts":
        selected = scenarios or ["empty_headless", "file_headless"]
        return [
            {
                "id": "CLARITY_TESTS_CONTRACTS",
                "command": [*contracts, *sum((["--scenario", item] for item in selected), [])],
            }
        ]
    if suite == "behavior":
        if feature != "fold":
            raise ValueError("The behavior suite currently requires --feature fold.")
        return [
            {
                "id": "CLARITY_TESTS_BEHAVIOR_FOLD",
                "command": [*contracts, "--scenario", "file_ui"],
            },
            {"id": "CLARITY_TESTS_ACTION_MATRIX", "command": action_matrix},
        ]
    if suite == "faults":
        if feature != "fold":
            raise ValueError("The faults suite currently requires --feature fold.")
        return [
            {
                "id": "CLARITY_TESTS_FAULT_RAW_FOLD",
                "command": [
                    *contracts,
                    "--scenario",
                    "file_ui",
                    "--fault",
                    "raw_fold_action",
                    "--expect-failure-id",
                    "CLARITY_RUNTIME_FOLD_CONTRACT",
                ],
            }
        ]
    if suite == "release":
        return [
            {"id": "CLARITY_TESTS_PYTHON", "command": python_tests},
            {"id": "CLARITY_TESTS_LUA", "command": lua_tests},
            {
                "id": "CLARITY_TESTS_CONTRACTS_RELEASE",
                "command": [
                    *contracts,
                    "--scenario",
                    "empty_headless",
                    "--scenario",
                    "file_headless",
                    "--scenario",
                    "file_ui",
                ],
            },
            {"id": "CLARITY_TESTS_ACTION_MATRIX", "command": action_matrix},
            {
                "id": "CLARITY_TESTS_FAULT_RAW_FOLD",
                "command": [
                    *contracts,
                    "--scenario",
                    "file_ui",
                    "--fault",
                    "raw_fold_action",
                    "--expect-failure-id",
                    "CLARITY_RUNTIME_FOLD_CONTRACT",
                ],
            },
            {"id": "CLARITY_TESTS_VALIDATE", "command": [python, "scripts/run_clarity_validate.py", "--json"]},
            {
                "id": "CLARITY_TESTS_SMOKE",
                "command": [python, "scripts/run_clarity_smoke.py", "--nvim-bin", nvim, *cache_args],
            },
            {"id": "CLARITY_TESTS_AUDIT", "command": [python, "scripts/run_clarity_audit.py", "--json"]},
        ]
    raise ValueError(f"Unknown suite: {suite}")


def parse_child_json(output: str) -> dict[str, Any] | None:
    decoder = json.JSONDecoder()
    parsed: dict[str, Any] | None = None
    parsed_size = -1
    offset = 0
    for line in output.splitlines(keepends=True):
        stripped = line.lstrip()
        if not stripped.startswith("{"):
            offset += len(line)
            continue
        index = offset + len(line) - len(stripped)
        try:
            value, consumed = decoder.raw_decode(output[index:])
        except json.JSONDecodeError:
            offset += len(line)
            continue
        if isinstance(value, dict) and consumed > parsed_size:
            parsed = value
            parsed_size = consumed
        offset += len(line)
    return parsed


def run_suite(
    repo_root: Path,
    commands: list[dict[str, Any]],
    timeout: float,
    env: dict[str, str] | None = None,
) -> list[dict[str, Any]]:
    results: list[dict[str, Any]] = []
    for spec in commands:
        result = run_command(spec["command"], cwd=repo_root, env=env or build_env(), timeout=timeout)
        output = combined_output(result)
        bounded, truncated = truncate_output(output)
        results.append(
            {
                "check_id": spec["id"],
                "command": spec["command"],
                "returncode": result.returncode,
                "ok": result.returncode == 0,
                "output": bounded,
                "output_truncated": truncated,
                "report": parse_child_json(output),
            }
        )
        if result.returncode != 0:
            break
    return results


def junit(results: list[dict[str, Any]]) -> str:
    failures = sum(not result["ok"] for result in results)
    cases = []
    for result in results:
        failure = ""
        if not result["ok"]:
            failure = f'<failure message="exit {result["returncode"]}">{escape(result["output"])}</failure>'
        cases.append(f'<testcase classname="clarity" name="{escape(result["check_id"])}">{failure}</testcase>')
    return f'<testsuite name="clarity" tests="{len(results)}" failures="{failures}">{"".join(cases)}</testsuite>\n'


def write_artifacts(artifact_dir: Path, report: dict[str, Any]) -> None:
    artifact_dir.mkdir(parents=True, exist_ok=True)
    if os.name != "nt":
        artifact_dir.chmod(0o700)
    checks = [
        {
            "schema_version": SCHEMA_VERSION,
            "check_id": result["check_id"],
            "scenario": report["manifest"]["suite"],
            "case": result["check_id"],
            "owner": "scripts.run_clarity_tests",
            "expected": {"returncode": 0},
            "actual": {"returncode": result["returncode"]},
            "ok": result["ok"],
            "returncode": result["returncode"],
            "event_ids": [result["check_id"]],
            "repair": "Run the child command shown in the JSON report and inspect its bounded artifact output.",
            "output_truncated": result["output_truncated"],
        }
        for result in report["checks"]
    ]
    events = [
        {
            "schema_version": SCHEMA_VERSION,
            "seq": index,
            "timestamp": report["generated_at"],
            "level": "info" if result["ok"] else "error",
            "event_id": result["check_id"],
            "component": "scripts.run_clarity_tests",
            "action": "run",
            "outcome": "passed" if result["ok"] else "failed",
            "message_key": "tests.child_result",
            "context": {"check_id": result["check_id"]},
        }
        for index, result in enumerate(report["checks"], 1)
    ]
    stdout = "\n\n".join(result["output"] for result in report["checks"])
    files = {
        "manifest.json": json.dumps(report["manifest"], indent=2, ensure_ascii=False) + "\n",
        "checks.json": json.dumps(checks, indent=2, ensure_ascii=False) + "\n",
        "events.jsonl": "".join(json.dumps(event, ensure_ascii=False) + "\n" for event in events),
        "snapshot-before.json": json.dumps(report["snapshot_before"], indent=2) + "\n",
        "snapshot-after.json": json.dumps(report["snapshot_after"], indent=2) + "\n",
        "messages.txt": "",
        "stdout.txt": stdout,
        "stderr.txt": "",
        "junit.xml": junit(report["checks"]),
    }
    for name, content in files.items():
        if name.endswith((".json", ".jsonl")) and len(content.encode()) > STRUCTURED_LIMIT:
            raise RuntimeError(f"Structured artifact exceeds {STRUCTURED_LIMIT} bytes: {name}")
        path = artifact_dir / name
        path.write_text(content, encoding="utf-8")
        if os.name != "nt":
            path.chmod(0o600)


def main() -> int:
    parser = argparse.ArgumentParser(description="Run Clarity's stable test suites and emit bounded evidence.")
    parser.add_argument("suite", choices=("fast", "contracts", "behavior", "faults", "release"))
    parser.add_argument("--feature", choices=("fold",))
    parser.add_argument(
        "--scenario", action="append", choices=("empty_headless", "file_headless", "file_ui"), default=[]
    )
    parser.add_argument("--artifact-dir", type=Path)
    parser.add_argument("--reuse-plugin-cache", type=Path)
    parser.add_argument("--nvim-bin")
    parser.add_argument("--timeout", type=float, default=300)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parent.parent
    nvim = resolve_nvim_binary(args.nvim_bin)
    plugin_cache = args.reuse_plugin_cache
    if plugin_cache is None and args.suite != "fast":
        plugin_cache = default_plugin_cache()
    before = authority_hashes(repo_root)
    try:
        commands = build_commands(
            repo_root,
            args.suite,
            sys.executable,
            nvim,
            args.feature,
            args.scenario,
            plugin_cache.resolve() if plugin_cache else None,
        )
    except ValueError as exc:
        parser.error(str(exc))
    dirty_before = git_dirty(repo_root)
    runtime_context = tempfile.TemporaryDirectory(prefix="clarity-release-runtime-")
    runtime_root = Path(runtime_context.name)
    runtime_env = configure_isolated_runtime(build_env(), runtime_root)
    if plugin_cache and args.suite != "fast":
        copy_plugin_cache(plugin_cache.resolve(), runtime_root)
    if args.suite == "release" and dirty_before:
        checks = [
            {
                "check_id": "CLARITY_TESTS_CLEAN_WORKTREE",
                "command": ["git", "status", "--porcelain"],
                "returncode": 1,
                "ok": False,
                "output": "Release evidence requires a clean, commit-bound worktree.",
                "output_truncated": False,
                "report": None,
            }
        ]
    else:
        checks = run_suite(repo_root, commands, args.timeout, runtime_env)
    runtime_context.cleanup()
    after = authority_hashes(repo_root)
    status = "pass" if checks and all(check["ok"] for check in checks) and before == after else "fail"
    generated_at = datetime.now(timezone.utc).isoformat()
    manifest = {
        "schema_version": SCHEMA_VERSION,
        "suite": args.suite,
        "status": status,
        "commit": git_commit(repo_root),
        "git_dirty": dirty_before,
        "platform": platform.platform(),
        "python": platform.python_version(),
        "pynvim": REQUIRED_PYNVIM_VERSION,
        "nvim": nvim,
        "nvim_version": nvim_version(nvim),
        "authority_hashes": after,
    }
    report = {
        "schema_version": SCHEMA_VERSION,
        "status": status,
        "generated_at": generated_at,
        "manifest": manifest,
        "snapshot_before": {"authority_hashes": before},
        "snapshot_after": {"authority_hashes": after},
        "checks": checks,
    }
    artifact_context = None
    artifact_dir = args.artifact_dir
    if artifact_dir is None:
        if args.suite == "release":
            state_home = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local" / "state"))
            stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
            artifact_dir = state_home / "clarity_lazyvim" / "release-evidence" / f"{stamp}-{manifest['commit'][:12]}"
        else:
            artifact_context = tempfile.TemporaryDirectory(prefix="clarity-tests-")
            artifact_dir = Path(artifact_context.name)
    write_artifacts(artifact_dir.resolve(), report)
    report["artifact_dir"] = str(artifact_dir.resolve()) if artifact_context is None else None
    encoded = json.dumps(report, indent=2, ensure_ascii=False)
    if len(encoded.encode()) > STRUCTURED_LIMIT:
        report["checks"] = [
            {key: value for key, value in check.items() if key != "output"} for check in report["checks"]
        ]
        encoded = json.dumps(report, indent=2, ensure_ascii=False)
    print(encoded)
    if artifact_context:
        artifact_context.cleanup()
    return 0 if status == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
