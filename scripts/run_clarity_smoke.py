from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import tempfile
from pathlib import Path

from clarity_runtime import (
    AUTHORITY_FILES,
    build_env,
    combined_output,
    configure_isolated_runtime,
    extract_last_json_object,
    resolve_nvim_binary,
    run_nvim,
    sha256_file,
)


def copy_plugin_cache(source: Path, runtime_root: Path) -> None:
    destination = runtime_root / "data" / "nvim" / "lazy"
    if destination.exists():
        shutil.rmtree(destination)
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copytree(source, destination, symlinks=True)


def _git_candidate_paths(source: Path) -> list[Path] | None:
    result = subprocess.run(
        ["git", "-C", str(source), "ls-files", "-z", "--cached", "--others", "--exclude-standard"],
        check=False,
        capture_output=True,
    )
    if result.returncode != 0:
        return None
    return [Path(os.fsdecode(item)) for item in result.stdout.split(b"\0") if item]


def copy_candidate(source: Path, destination: Path) -> None:
    if destination.exists():
        shutil.rmtree(destination)

    paths = _git_candidate_paths(source)
    if paths is not None:
        source = source.resolve()
        destination.mkdir(parents=True)
        for relative in paths:
            if relative.is_absolute() or ".." in relative.parts:
                raise RuntimeError(f"Unsafe candidate path returned by Git: {relative}")
            source_path = source / relative
            destination_path = destination / relative
            destination_path.parent.mkdir(parents=True, exist_ok=True)
            if source_path.is_symlink():
                destination_path.symlink_to(os.readlink(source_path))
            elif source_path.is_file():
                shutil.copy2(source_path, destination_path)
            else:
                raise RuntimeError(f"Unsupported candidate entry returned by Git: {relative}")
        return

    ignored = shutil.ignore_patterns(
        ".git",
        ".DS_Store",
        ".clarity-tools",
        "AGENTS.md",
        "__pycache__",
        "*.pyc",
    )
    shutil.copytree(source, destination, ignore=ignored, symlinks=True)


def probe_command() -> str:
    return (
        "+lua local cfg=require('lazy.core.config'); local names={}; "
        "for name,plugin in pairs(cfg.plugins or {}) do "
        "if plugin.enabled ~= false then table.insert(names,name) end end; table.sort(names); "
        "local report={"
        "repo=vim.g.clarity_repo_root,"
        "lock=cfg.options.lockfile,"
        "json=LazyVim.config.json.path,"
        "nvim=vim.version(),"
        "plugin_count=#names,"
        "plugin_names=names"
        "}; io.stdout:write('\\n' .. vim.json.encode(report) .. '\\n'); io.stdout:flush()"
    )


def run() -> int:
    parser = argparse.ArgumentParser(description="Run Clarity in isolated Neovim runtime directories.")
    parser.add_argument("--nvim-bin", help="Neovim executable; defaults to NVIM_BIN or PATH.")
    parser.add_argument("--runtime-root", type=Path, help="Persistent isolated runtime root; temp by default.")
    parser.add_argument("--reuse-plugin-cache", type=Path, help="Copy an existing lazy plugin cache into isolation.")
    parser.add_argument("--timeout", type=float, default=300, help="Per-start timeout in seconds.")
    args = parser.parse_args()

    source_root = Path(__file__).resolve().parent.parent
    source_files = {name: source_root / name for name in AUTHORITY_FILES}
    source_before = {name: sha256_file(path) for name, path in source_files.items()}
    nvim = resolve_nvim_binary(args.nvim_bin)

    temp_context = None
    configured_runtime = args.runtime_root or (Path(os.environ["CLARITY_RUNTIME_ROOT"]) if os.environ.get("CLARITY_RUNTIME_ROOT") else None)
    if configured_runtime:
        runtime_root = configured_runtime.resolve()
        runtime_root.mkdir(parents=True, exist_ok=True)
    else:
        temp_context = tempfile.TemporaryDirectory(prefix="clarity-smoke-")
        runtime_root = Path(temp_context.name)

    try:
        env = configure_isolated_runtime(build_env(), runtime_root)
        repo_root = runtime_root / "candidate"
        copy_candidate(source_root, repo_root)
        init_file = repo_root / "init.lua"
        lockfile = repo_root / "lazy-lock.json"
        lazyvim_json = repo_root / "lazyvim.json"
        candidate_files = {
            "init.lua": init_file,
            "lazy-lock.json": lockfile,
            "lazyvim.json": lazyvim_json,
        }
        before = {name: sha256_file(path) for name, path in candidate_files.items()}
        if args.reuse_plugin_cache:
            copy_plugin_cache(args.reuse_plugin_cache.resolve(), runtime_root)

        boots: list[dict] = []
        offline_bin = runtime_root / "offline-bin"
        offline_bin.mkdir(parents=True, exist_ok=True)
        offline_env = dict(env)
        offline_env.update(
            {
                "PATH": str(offline_bin),
                "GIT_TERMINAL_PROMPT": "0",
                "HTTP_PROXY": "http://127.0.0.1:9",
                "HTTPS_PROXY": "http://127.0.0.1:9",
                "ALL_PROXY": "http://127.0.0.1:9",
                "NO_PROXY": "",
            }
        )
        for phase, phase_env in (("first", env), ("restart", env), ("offline_restart", offline_env)):
            result = run_nvim(repo_root, nvim, [probe_command()], phase_env, timeout=args.timeout)
            output = combined_output(result)
            if result.returncode != 0:
                raise RuntimeError(f"{phase} boot failed with exit {result.returncode}:\n{output}")
            report = extract_last_json_object(output)
            report["phase"] = phase
            boots.append(report)

        expected_lock = str(lockfile.resolve()).replace("\\", "/")
        expected_json = str(lazyvim_json.resolve()).replace("\\", "/")
        expected_repo = str(repo_root.resolve()).replace("\\", "/")
        expected_plugins = sorted(json.loads(lockfile.read_text(encoding="utf-8")))
        for report in boots:
            actual = {key: str(report[key]).replace("\\", "/") for key in ("repo", "lock", "json")}
            expected = {"repo": expected_repo, "lock": expected_lock, "json": expected_json}
            if actual != expected:
                raise RuntimeError(f"Runtime source-of-truth mismatch: expected={expected} actual={actual}")
            version = report.get("nvim", {})
            if (version.get("major", 0), version.get("minor", 0)) < (0, 12):
                raise RuntimeError(f"Unsupported Neovim version: {version}")
            if report.get("plugin_names") != expected_plugins:
                raise RuntimeError(
                    "Resolved active plugin set does not exactly match the lockfile: "
                    f"expected={expected_plugins} actual={report.get('plugin_names')}"
                )

        after = {name: sha256_file(path) for name, path in candidate_files.items()}
        if before != after:
            raise RuntimeError(f"Runtime mutated candidate authority files: before={before} after={after}")

        source_after = {name: sha256_file(path) for name, path in source_files.items()}
        if source_before != source_after:
            raise RuntimeError(f"Smoke harness mutated source repository files: before={source_before} after={source_after}")

        print(
            json.dumps(
                {
                    "check_id": "CLARITY-SMOKE-001",
                    "status": "pass",
                    "runtime_root": str(runtime_root),
                    "candidate_root": str(repo_root),
                    "hashes": after,
                    "lock_plugins": expected_plugins,
                    "boots": boots,
                },
                indent=2,
                ensure_ascii=False,
            )
        )
        return 0
    finally:
        if temp_context:
            temp_context.cleanup()


if __name__ == "__main__":
    raise SystemExit(run())
