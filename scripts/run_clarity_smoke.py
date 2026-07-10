from __future__ import annotations

import argparse
import json
import os
import shutil
import tempfile
from pathlib import Path

from clarity_runtime import (
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


def copy_candidate(source: Path, destination: Path) -> None:
    if destination.exists():
        shutil.rmtree(destination)

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
        "+lua local cfg=require('lazy.core.config'); "
        "print(vim.json.encode({"
        "repo=vim.g.clarity_repo_root,"
        "lock=cfg.options.lockfile,"
        "json=LazyVim.config.json.path,"
        "nvim=vim.version(),"
        "plugins=vim.tbl_count(cfg.plugins or {})"
        "}))"
    )


def run() -> int:
    parser = argparse.ArgumentParser(description="Run Clarity in isolated Neovim runtime directories.")
    parser.add_argument("--nvim-bin", help="Neovim executable; defaults to NVIM_BIN or PATH.")
    parser.add_argument("--runtime-root", type=Path, help="Persistent isolated runtime root; temp by default.")
    parser.add_argument("--reuse-plugin-cache", type=Path, help="Copy an existing lazy plugin cache into isolation.")
    parser.add_argument("--timeout", type=float, default=300, help="Per-start timeout in seconds.")
    args = parser.parse_args()

    source_root = Path(__file__).resolve().parent.parent
    source_files = {
        "lock": source_root / "lazy-lock.json",
        "json": source_root / "lazyvim.json",
    }
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
        lockfile = repo_root / "lazy-lock.json"
        lazyvim_json = repo_root / "lazyvim.json"
        before = {"lock": sha256_file(lockfile), "json": sha256_file(lazyvim_json)}
        if args.reuse_plugin_cache:
            copy_plugin_cache(args.reuse_plugin_cache.resolve(), runtime_root)

        boots: list[dict] = []
        for phase in ("first", "restart"):
            result = run_nvim(repo_root, nvim, [probe_command()], env, timeout=args.timeout)
            output = combined_output(result)
            if result.returncode != 0:
                raise RuntimeError(f"{phase} boot failed with exit {result.returncode}:\n{output}")
            report = extract_last_json_object(output)
            report["phase"] = phase
            boots.append(report)

        expected_lock = str(lockfile.resolve()).replace("\\", "/")
        expected_json = str(lazyvim_json.resolve()).replace("\\", "/")
        expected_repo = str(repo_root.resolve()).replace("\\", "/")
        for report in boots:
            actual = {key: str(report[key]).replace("\\", "/") for key in ("repo", "lock", "json")}
            expected = {"repo": expected_repo, "lock": expected_lock, "json": expected_json}
            if actual != expected:
                raise RuntimeError(f"Runtime source-of-truth mismatch: expected={expected} actual={actual}")
            version = report.get("nvim", {})
            if (version.get("major", 0), version.get("minor", 0)) < (0, 12):
                raise RuntimeError(f"Unsupported Neovim version: {version}")

        after = {"lock": sha256_file(lockfile), "json": sha256_file(lazyvim_json)}
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
