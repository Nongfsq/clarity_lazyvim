from __future__ import annotations

import argparse
import json
import os
import shutil
import tempfile
from datetime import datetime, timezone
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
from run_clarity_smoke import copy_candidate


CHECK_ID = "CLARITY-LOCK-001"


def default_backup_root(env: dict[str, str] | None = None) -> Path:
    source = env or os.environ
    state_home = Path(source.get("XDG_STATE_HOME", Path.home() / ".local" / "state"))
    return state_home / "clarity_lazyvim" / "lock-backups"


def replace_with_backup(source: Path, proposed: Path, backup_root: Path) -> Path:
    backup_root.mkdir(parents=True, exist_ok=True, mode=0o700)
    backup_root.chmod(0o700)
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
    backup = backup_root / f"{timestamp}-{source.name}"
    shutil.copy2(source, backup)
    backup.chmod(0o600)

    file_descriptor, temporary_name = tempfile.mkstemp(prefix=f".{source.name}.", dir=source.parent)
    temporary = Path(temporary_name)
    try:
        with os.fdopen(file_descriptor, "wb") as handle:
            handle.write(proposed.read_bytes())
            handle.flush()
            os.fsync(handle.fileno())
        temporary.chmod(source.stat().st_mode)
        os.replace(temporary, source)
    finally:
        temporary.unlink(missing_ok=True)
    return backup


def write_lazy_lock(path: Path, lock: dict[str, dict[str, str]]) -> None:
    """Write lazy.nvim's stable one-plugin-per-line lock format."""
    lines = ["{"]
    names = sorted(lock)
    for index, name in enumerate(names):
        info = lock[name]
        suffix = "," if index + 1 < len(names) else ""
        lines.append(
            f"  {json.dumps(name, ensure_ascii=False)}: "
            f'{{ "branch": {json.dumps(info["branch"])}, '
            f'"commit": {json.dumps(info["commit"])} }}{suffix}'
        )
    lines.append("}")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def prune_reviewed_exclusions(
    path: Path,
    registry_exclusions: list[str],
    runtime_disabled: list[str],
) -> list[str]:
    """Remove only reviewed exclusions that are disabled in this runtime.

    lazy.nvim keeps disabled plugin entries so a future re-enable can restore
    the old revision. Clarity instead treats its tracked lock as an active-only
    dependency manifest; the reviewed exclusion registry remains the durable
    policy. Conditional runtime specs that are not in that registry must retain
    their lock entries.
    """
    lock = json.loads(path.read_text(encoding="utf-8"))
    confirmed = set(registry_exclusions).intersection(runtime_disabled)
    removed = sorted(confirmed.intersection(lock))
    if removed:
        for name in removed:
            del lock[name]
        write_lazy_lock(path, lock)
    return removed


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Validate a normalized lazy-lock.json candidate and optionally apply it atomically."
    )
    parser.add_argument("--apply", action="store_true", help="Back up and atomically apply validated lock drift.")
    parser.add_argument("--backup-root", type=Path, help="Override the durable lock backup directory.")
    parser.add_argument("--nvim-bin", help="Neovim executable; defaults to NVIM_BIN or PATH.")
    parser.add_argument("--timeout", type=float, default=300, help="Per-start timeout in seconds.")
    args = parser.parse_args()

    source_root = Path(__file__).resolve().parent.parent
    source_lock = source_root / "lazy-lock.json"
    source_before = sha256_file(source_lock)
    nvim = resolve_nvim_binary(args.nvim_bin)

    with tempfile.TemporaryDirectory(prefix="clarity-lock-") as directory:
        runtime_root = Path(directory)
        candidate_root = runtime_root / "candidate"
        copy_candidate(source_root, candidate_root)
        candidate_lock = candidate_root / "lazy-lock.json"
        env = configure_isolated_runtime(build_env(), runtime_root / "runtime")

        first = run_nvim(candidate_root, nvim, [], env, timeout=args.timeout)
        if first.returncode != 0:
            raise RuntimeError(f"Candidate normalization boot failed:\n{combined_output(first)}")

        policy = run_nvim(
            candidate_root,
            nvim,
            [
                "+lua local runtime=vim.tbl_keys(require('lazy.core.config').spec.disabled); "
                "table.sort(runtime); local registry=require('config.product_policy').plugin_exclusion_names(); "
                "print(vim.json.encode({registry_exclusions=registry,runtime_disabled=runtime}))"
            ],
            env,
            timeout=args.timeout,
        )
        if policy.returncode != 0:
            raise RuntimeError(f"Disabled-plugin policy query failed:\n{combined_output(policy)}")
        policy_report = extract_last_json_object(combined_output(policy))
        registry_exclusions = policy_report.get("registry_exclusions", [])
        runtime_disabled = policy_report.get("runtime_disabled", [])
        if not isinstance(registry_exclusions, list) or not all(
            isinstance(name, str) for name in registry_exclusions
        ):
            raise RuntimeError("Product exclusion registry query returned an invalid manifest.")
        if not isinstance(runtime_disabled, list) or not all(isinstance(name, str) for name in runtime_disabled):
            raise RuntimeError("Disabled-plugin policy query returned an invalid manifest.")
        removed_exclusions = prune_reviewed_exclusions(
            candidate_lock,
            registry_exclusions,
            runtime_disabled,
        )
        normalized_hash = sha256_file(candidate_lock)

        audit = run_nvim(candidate_root, nvim, ["+ClarityAudit!"], env, timeout=args.timeout)
        if audit.returncode != 0:
            raise RuntimeError(f"Candidate audit failed:\n{combined_output(audit)}")
        report = extract_last_json_object(combined_output(audit))
        if not report.get("ok"):
            raise RuntimeError("Candidate audit did not satisfy core readiness.")

        stable_hash = sha256_file(candidate_lock)
        if normalized_hash != stable_hash:
            raise RuntimeError(
                f"Candidate lock is unstable across restart: first={normalized_hash} second={stable_hash}"
            )
        if sha256_file(source_lock) != source_before:
            raise RuntimeError("Lock transaction mutated the source repository during candidate validation.")

        changed = source_before != stable_hash
        result: dict[str, object] = {
            "check_id": CHECK_ID,
            "status": "drift" if changed else "clean",
            "applied": False,
            "source_hash": source_before,
            "candidate_hash": stable_hash,
            "candidate_core": report["summary"]["core"]["status"],
            "pruned_exclusions": removed_exclusions,
        }

        if changed and args.apply:
            backup = replace_with_backup(
                source_lock,
                candidate_lock,
                (args.backup_root or default_backup_root()).expanduser().resolve(),
            )
            result.update(
                {
                    "status": "applied",
                    "applied": True,
                    "backup": str(backup),
                    "result_hash": sha256_file(source_lock),
                }
            )

        print(json.dumps(result, indent=2, ensure_ascii=False))
        return 0 if not changed or args.apply else 1


if __name__ == "__main__":
    raise SystemExit(main())
